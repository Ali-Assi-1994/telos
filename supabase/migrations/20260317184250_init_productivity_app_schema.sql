CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "pg_cron";

CREATE TABLE profiles ( id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, username TEXT UNIQUE NOT NULL, display_name TEXT, avatar_url TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW() );

CREATE TABLE categories ( id SERIAL PRIMARY KEY, name TEXT UNIQUE NOT NULL, icon TEXT, color TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW() );

CREATE TABLE task_templates ( id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE, title TEXT NOT NULL CHECK (LENGTH(TRIM(title)) > 0), description TEXT, points INTEGER NOT NULL CHECK (points >= 1 AND points <= 100), recurrence_type TEXT NOT NULL CHECK (recurrence_type IN ('daily', 'weekly', 'monthly')), recurrence_interval INTEGER NOT NULL DEFAULT 1 CHECK (recurrence_interval >= 1), start_date DATE NOT NULL, end_date DATE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), CONSTRAINT end_after_start CHECK (end_date IS NULL OR end_date >= start_date) );

CREATE TABLE task_template_categories ( template_id UUID NOT NULL REFERENCES task_templates(id) ON DELETE CASCADE, category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT, PRIMARY KEY (template_id, category_id) );

CREATE TABLE tasks ( id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), template_id UUID REFERENCES task_templates(id) ON DELETE SET NULL, user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE, title TEXT NOT NULL CHECK (LENGTH(TRIM(title)) > 0), description TEXT, points INTEGER NOT NULL CHECK (points >= 1 AND points <= 100), assigned_date DATE NOT NULL, completed BOOLEAN NOT NULL DEFAULT FALSE, completed_at TIMESTAMPTZ, is_locked BOOLEAN NOT NULL DEFAULT FALSE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), CONSTRAINT unique_template_instance UNIQUE (template_id, assigned_date), CONSTRAINT completed_consistency CHECK ( (completed = FALSE AND completed_at IS NULL) OR (completed = TRUE AND completed_at IS NOT NULL) ) );

CREATE TABLE task_categories ( task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE, category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT, PRIMARY KEY (task_id, category_id) );

CREATE TABLE groups ( id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL CHECK (LENGTH(TRIM(name)) > 0), description TEXT, invite_code TEXT UNIQUE NOT NULL DEFAULT UPPER(SUBSTRING(uuid_generate_v4()::TEXT, 1, 6)), created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW() );

CREATE TABLE group_members ( group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE, user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE, role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')), joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), PRIMARY KEY (group_id, user_id) );

CREATE TABLE app_settings ( key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW() );

CREATE INDEX profiles_username_idx ON profiles(username);

CREATE INDEX tasks_user_id_idx ON tasks(user_id);

CREATE INDEX tasks_assigned_date_idx ON tasks(assigned_date);

CREATE INDEX tasks_template_id_idx ON tasks(template_id);

CREATE INDEX tasks_user_date_completed_idx ON tasks (user_id, assigned_date, completed);

CREATE INDEX tasks_locking_idx ON tasks (assigned_date) WHERE completed = FALSE AND is_locked = FALSE;

CREATE INDEX templates_active_idx ON task_templates(end_date);

CREATE INDEX templates_user_id_idx ON task_templates(user_id);

CREATE INDEX templates_start_date_idx ON task_templates(start_date);

CREATE INDEX task_cat_task_id_idx ON task_categories(task_id);

CREATE INDEX task_cat_category_id_idx ON task_categories(category_id);

CREATE INDEX ttc_template_id_idx ON task_template_categories(template_id);

CREATE INDEX gm_user_id_idx ON group_members(user_id);

CREATE INDEX gm_group_id_idx ON group_members(group_id);

CREATE INDEX groups_invite_code_idx ON groups(invite_code);

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at := NOW();

RETURN NEW;

END;

$$;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_task_templates_updated_at BEFORE UPDATE ON task_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_groups_updated_at BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION handle_new_user() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN INSERT INTO profiles (id, username, display_name) VALUES ( NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::TEXT, 8)), COALESCE(NEW.raw_user_meta_data->>'display_name', 'New User') );

RETURN NEW;

END;

$$;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE OR REPLACE FUNCTION handle_group_created() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN INSERT INTO group_members (group_id, user_id, role) VALUES (NEW.id, NEW.created_by, 'admin');

RETURN NEW;

END;

$$;

CREATE TRIGGER on_group_created AFTER INSERT ON groups FOR EACH ROW EXECUTE FUNCTION handle_group_created();

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;

ALTER TABLE task_template_categories ENABLE ROW LEVEL SECURITY;

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

ALTER TABLE task_categories ENABLE ROW LEVEL SECURITY;

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_all" ON profiles FOR SELECT USING (TRUE);

CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "categories_read" ON categories FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "settings_read" ON app_settings FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "tasks_select_own" ON tasks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "tasks_insert_own" ON tasks FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tasks_update_own" ON tasks FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "tasks_delete_own" ON tasks FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "task_cat_select" ON task_categories FOR SELECT USING (task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid()));

CREATE POLICY "task_cat_insert" ON task_categories FOR INSERT WITH CHECK (task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid()));

CREATE POLICY "task_cat_delete" ON task_categories FOR DELETE USING (task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid()));

CREATE POLICY "templates_select_own" ON task_templates FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "templates_insert_own" ON task_templates FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "templates_update_own" ON task_templates FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "templates_delete_own" ON task_templates FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "ttc_select" ON task_template_categories FOR SELECT USING (template_id IN (SELECT id FROM task_templates WHERE user_id = auth.uid()));

CREATE POLICY "ttc_insert" ON task_template_categories FOR INSERT WITH CHECK (template_id IN (SELECT id FROM task_templates WHERE user_id = auth.uid()));

CREATE POLICY "ttc_delete" ON task_template_categories FOR DELETE USING (template_id IN (SELECT id FROM task_templates WHERE user_id = auth.uid()));

CREATE POLICY "groups_select_member" ON groups FOR SELECT USING (id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));

CREATE POLICY "groups_insert_auth" ON groups FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "gm_select_member" ON group_members FOR SELECT USING (group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));

CREATE POLICY "gm_insert_self" ON group_members FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "gm_delete_self" ON group_members FOR DELETE USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION complete_task(p_task_id UUID, p_user_id UUID) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$ DECLARE v_task tasks%ROWTYPE;

v_delay_days INTEGER;

v_cutoff DATE;

BEGIN SELECT value::INTEGER INTO v_delay_days FROM app_settings WHERE key = 'late_completion_days';

v_cutoff := CURRENT_DATE - v_delay_days;

SELECT * INTO v_task FROM tasks WHERE id = p_task_id AND user_id = p_user_id;

IF NOT FOUND THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task not found');

END IF;

IF v_task.is_locked THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task is locked');

END IF;

IF v_task.assigned_date < v_cutoff THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Completion window has passed');

END IF;

IF v_task.completed THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task already completed');

END IF;

UPDATE tasks SET completed = TRUE, completed_at = NOW(), updated_at = NOW() WHERE id = p_task_id;

RETURN jsonb_build_object('success', TRUE, 'points', v_task.points);

END;

$$;

CREATE OR REPLACE FUNCTION uncomplete_task(p_task_id UUID, p_user_id UUID) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$ DECLARE v_task tasks%ROWTYPE;

BEGIN SELECT * INTO v_task FROM tasks WHERE id = p_task_id AND user_id = p_user_id;

IF NOT FOUND THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task not found');

END IF;

IF v_task.is_locked THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task is locked');

END IF;

IF NOT v_task.completed THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task is not completed');

END IF;

UPDATE tasks SET completed = FALSE, completed_at = NULL, updated_at = NOW() WHERE id = p_task_id;

RETURN jsonb_build_object('success', TRUE, 'points_revoked', v_task.points);

END;

$$;

CREATE OR REPLACE FUNCTION get_daily_performance(p_user_id UUID, p_date DATE) RETURNS TABLE ( total_tasks INTEGER, completed_tasks INTEGER, completion_rate NUMERIC, total_points INTEGER, earned_points INTEGER ) LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN RETURN QUERY SELECT COUNT(*)::INTEGER, COUNT(*) FILTER (WHERE completed = TRUE)::INTEGER, CASE WHEN COUNT(*) = 0 THEN 0 ELSE ROUND(COUNT(*) FILTER (WHERE completed = TRUE)::NUMERIC / COUNT(*) * 100, 1) END, COALESCE(SUM(points), 0)::INTEGER, COALESCE(SUM(points) FILTER (WHERE completed = TRUE), 0)::INTEGER FROM tasks WHERE user_id = p_user_id AND assigned_date = p_date;

END;

$$;

CREATE OR REPLACE FUNCTION get_streak(p_user_id UUID) RETURNS TABLE (current_streak INTEGER, longest_streak INTEGER) LANGUAGE plpgsql SECURITY DEFINER AS $$ DECLARE v_min_tasks INTEGER;

v_check_date DATE := CURRENT_DATE;

v_task_count INTEGER;

v_has_tasks BOOLEAN;

v_current INTEGER := 0;

v_longest INTEGER := 0;

v_running INTEGER := 0;

v_gap_found BOOLEAN := FALSE;

BEGIN SELECT value::INTEGER INTO v_min_tasks FROM app_settings WHERE key = 'streak_min_tasks';

LOOP SELECT COUNT(*) INTO v_task_count FROM tasks WHERE user_id = p_user_id AND assigned_date = v_check_date AND completed = TRUE;

SELECT EXISTS( SELECT 1 FROM tasks WHERE user_id = p_user_id AND assigned_date = v_check_date ) INTO v_has_tasks;

IF v_task_count >= v_min_tasks THEN v_running := v_running + 1;

IF NOT v_gap_found THEN v_current := v_running;

END IF;

ELSIF v_has_tasks THEN IF v_running > v_longest THEN v_longest := v_running;

END IF;

v_running := 0;

v_gap_found := TRUE;

END IF;

v_check_date := v_check_date - 1;

EXIT WHEN v_check_date < CURRENT_DATE - 365;

END LOOP;

IF v_running > v_longest THEN v_longest := v_running;

END IF;

current_streak := v_current;

longest_streak := v_longest;

RETURN NEXT;

END;

$$;

CREATE OR REPLACE FUNCTION get_leaderboard( p_group_id UUID, p_start DATE, p_end DATE ) RETURNS TABLE ( rank BIGINT, user_id UUID, username TEXT, display_name TEXT, avatar_url TEXT, earned_points BIGINT, total_tasks BIGINT, completed_tasks BIGINT, completion_rate NUMERIC ) LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN RETURN QUERY WITH member_stats AS ( SELECT gm.user_id, p.username, p.display_name, p.avatar_url, COALESCE(SUM(t.points) FILTER (WHERE t.completed = TRUE), 0) AS earned_points, COUNT(t.id) AS total_tasks, COUNT(t.id) FILTER (WHERE t.completed = TRUE) AS completed_tasks, CASE WHEN COUNT(t.id) = 0 THEN 0 ELSE ROUND( COUNT(t.id) FILTER (WHERE t.completed = TRUE)::NUMERIC / COUNT(t.id) * 100, 1 ) END AS completion_rate FROM group_members gm JOIN profiles p ON p.id = gm.user_id LEFT JOIN tasks t ON t.user_id = gm.user_id AND t.assigned_date BETWEEN p_start AND p_end WHERE gm.group_id = p_group_id GROUP BY gm.user_id, p.username, p.display_name, p.avatar_url ) SELECT RANK() OVER (ORDER BY ms.earned_points DESC, ms.completion_rate DESC), ms.* FROM member_stats ms;

END;

$$;

CREATE OR REPLACE FUNCTION lock_expired_tasks() RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$ DECLARE v_delay_days INTEGER;

BEGIN SELECT value::INTEGER INTO v_delay_days FROM app_settings WHERE key = 'late_completion_days';

UPDATE tasks SET is_locked = TRUE, updated_at = NOW() WHERE completed = FALSE AND is_locked = FALSE AND assigned_date < CURRENT_DATE - v_delay_days;

END;

$$;

SELECT cron.schedule( 'lock-expired-tasks', '0 0 * * *', 'SELECT lock_expired_tasks()' );

SELECT cron.schedule( 'generate-recurring-instances', '5 0 * * *', $$ SELECT generate_template_instances(id, CURRENT_DATE, CURRENT_DATE + 30) FROM task_templates WHERE end_date IS NULL OR end_date >= CURRENT_DATE $$ );
