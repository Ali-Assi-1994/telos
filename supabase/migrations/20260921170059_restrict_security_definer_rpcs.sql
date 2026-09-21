-- Security fix: the SECURITY DEFINER RPCs below run with the owner's
-- privileges and bypass RLS, but none of them checked that the caller
-- (auth.uid()) actually matched the user id / group they were querying or
-- mutating. Any anon or authenticated caller could pass an arbitrary
-- p_user_id / p_task_id and act on another user's data.
--
-- Fix: reject the call unless the caller is authorized, and cut off direct
-- client access entirely for the cron-only / trigger-only functions.

-- complete_task: only the calling user may complete their own task.
CREATE OR REPLACE FUNCTION complete_task(p_task_id UUID, p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_task tasks%ROWTYPE;
  v_delay_days INTEGER;
  v_cutoff DATE;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Not authorized');
  END IF;

  SELECT value::INTEGER INTO v_delay_days FROM app_settings WHERE key = 'late_completion_days';
  v_cutoff := CURRENT_DATE - v_delay_days;

  SELECT * INTO v_task FROM tasks WHERE id = p_task_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Task not found');
  END IF;

  IF v_task.is_locked THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Task is locked');
  END IF;

  IF v_task.assigned_date < v_cutoff THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Completion window has passed');
  END IF;

  IF v_task.completed THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Task already completed');
  END IF;

  UPDATE tasks SET completed = TRUE, completed_at = NOW(), updated_at = NOW() WHERE id = p_task_id;

  RETURN jsonb_build_object('success', TRUE, 'points', v_task.points);
END;
$$;

-- uncomplete_task: only the calling user may uncomplete their own task.
CREATE OR REPLACE FUNCTION uncomplete_task(p_task_id UUID, p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_task tasks%ROWTYPE;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Not authorized');
  END IF;

  SELECT * INTO v_task FROM tasks WHERE id = p_task_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Task not found');
  END IF;

  IF v_task.is_locked THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Task is locked');
  END IF;

  IF NOT v_task.completed THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Task is not completed');
  END IF;

  UPDATE tasks SET completed = FALSE, completed_at = NULL, updated_at = NOW() WHERE id = p_task_id;

  RETURN jsonb_build_object('success', TRUE, 'points_revoked', v_task.points);
END;
$$;

-- get_daily_performance: only the calling user may read their own daily performance.
CREATE OR REPLACE FUNCTION get_daily_performance(p_user_id UUID, p_date DATE)
RETURNS TABLE (
  total_tasks INTEGER,
  completed_tasks INTEGER,
  completion_rate NUMERIC,
  total_points INTEGER,
  earned_points INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    COUNT(*)::INTEGER,
    COUNT(*) FILTER (WHERE completed = TRUE)::INTEGER,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE completed = TRUE)::NUMERIC / COUNT(*) * 100, 1)
    END,
    COALESCE(SUM(points), 0)::INTEGER,
    COALESCE(SUM(points) FILTER (WHERE completed = TRUE), 0)::INTEGER
  FROM tasks
  WHERE user_id = p_user_id AND assigned_date = p_date;
END;
$$;

-- get_streak: only the calling user may read their own streak.
CREATE OR REPLACE FUNCTION get_streak(p_user_id UUID)
RETURNS TABLE (current_streak INTEGER, longest_streak INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_min_tasks INTEGER;
  v_check_date DATE := CURRENT_DATE;
  v_task_count INTEGER;
  v_has_tasks BOOLEAN;
  v_current INTEGER := 0;
  v_longest INTEGER := 0;
  v_running INTEGER := 0;
  v_gap_found BOOLEAN := FALSE;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  SELECT value::INTEGER INTO v_min_tasks FROM app_settings WHERE key = 'streak_min_tasks';

  LOOP
    SELECT COUNT(*) INTO v_task_count FROM tasks WHERE user_id = p_user_id AND assigned_date = v_check_date AND completed = TRUE;
    SELECT EXISTS(
      SELECT 1 FROM tasks WHERE user_id = p_user_id AND assigned_date = v_check_date
    ) INTO v_has_tasks;

    IF v_task_count >= v_min_tasks THEN
      v_running := v_running + 1;
      IF NOT v_gap_found THEN
        v_current := v_running;
      END IF;
    ELSIF v_has_tasks THEN
      IF v_running > v_longest THEN
        v_longest := v_running;
      END IF;
      v_running := 0;
      v_gap_found := TRUE;
    END IF;

    v_check_date := v_check_date - 1;
    EXIT WHEN v_check_date < CURRENT_DATE - 365;
  END LOOP;

  IF v_running > v_longest THEN
    v_longest := v_running;
  END IF;

  current_streak := v_current;
  longest_streak := v_longest;
  RETURN NEXT;
END;
$$;

-- get_leaderboard: only members of the group may read that group's leaderboard.
-- (No direct p_user_id param here, so the check is group membership instead.)
CREATE OR REPLACE FUNCTION get_leaderboard(p_group_id UUID, p_start DATE, p_end DATE)
RETURNS TABLE (
  rank BIGINT,
  user_id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  earned_points BIGINT,
  total_tasks BIGINT,
  completed_tasks BIGINT,
  completion_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- group_members is aliased and every column qualified here because this
  -- function's RETURNS TABLE declares its own `user_id` output column, which
  -- would otherwise shadow group_members.user_id inside this query and make
  -- plpgsql raise "column reference is ambiguous".
  IF NOT EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = p_group_id AND gm.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH member_stats AS (
    SELECT
      gm.user_id,
      p.username,
      p.display_name,
      p.avatar_url,
      COALESCE(SUM(t.points) FILTER (WHERE t.completed = TRUE), 0) AS earned_points,
      COUNT(t.id) AS total_tasks,
      COUNT(t.id) FILTER (WHERE t.completed = TRUE) AS completed_tasks,
      CASE
        WHEN COUNT(t.id) = 0 THEN 0
        ELSE ROUND(COUNT(t.id) FILTER (WHERE t.completed = TRUE)::NUMERIC / COUNT(t.id) * 100, 1)
      END AS completion_rate
    FROM group_members gm
    JOIN profiles p ON p.id = gm.user_id
    LEFT JOIN tasks t ON t.user_id = gm.user_id AND t.assigned_date BETWEEN p_start AND p_end
    WHERE gm.group_id = p_group_id
    GROUP BY gm.user_id, p.username, p.display_name, p.avatar_url
  )
  SELECT RANK() OVER (ORDER BY ms.earned_points DESC, ms.completion_rate DESC), ms.*
  FROM member_stats ms;
END;
$$;

-- lock_expired_tasks, handle_new_user, handle_group_created are cron-only /
-- trigger-only: they must never be reachable via /rest/v1/rpc/<name>.
-- Postgres grants EXECUTE to PUBLIC by default, so anon/authenticated inherit
-- it even without an explicit grant to those roles — revoke from PUBLIC too,
-- not just anon/authenticated, or the revoke is a no-op. This doesn't affect
-- pg_cron (runs as the scheduling role, which keeps its own grant) or
-- trigger-fired execution (doesn't require EXECUTE on the trigger function).
REVOKE EXECUTE ON FUNCTION lock_expired_tasks() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION handle_group_created() FROM PUBLIC, anon, authenticated;
