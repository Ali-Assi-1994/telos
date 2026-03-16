# Database Schema
# Productivity & Accountability App
# Stack: Supabase (Postgres)
# @-mention this file when writing repositories, DTOs, RPCs, or migrations

---

## Table of Contents

1. [Extensions](#1-extensions)
2. [Tables](#2-tables)
3. [Indexes](#3-indexes)
4. [Triggers](#4-triggers)
5. [Row-Level Security](#5-row-level-security)
6. [RPC Functions](#6-rpc-functions)
7. [Scheduled Jobs](#7-scheduled-jobs)
8. [Column Type Reference](#8-column-type-reference)
9. [Entity Relationship Overview](#9-entity-relationship-overview)

---

## 1. Extensions

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pg_cron";     -- scheduled jobs
```

---

## 2. Tables

---

### `profiles`

Extends `auth.users` with app-specific data.
Created automatically on user signup via trigger.

```sql
CREATE TABLE profiles (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username     TEXT        UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID` | PK, mirrors `auth.users.id` |
| `username` | `TEXT` | Unique, required |
| `display_name` | `TEXT` | Optional display name |
| `avatar_url` | `TEXT` | Optional profile image URL |
| `created_at` | `TIMESTAMPTZ` | Auto |
| `updated_at` | `TIMESTAMPTZ` | Auto, updated by trigger |

---

### `categories`

System-defined, fixed list. Seeded at setup — users cannot create or delete.

```sql
CREATE TABLE categories (
  id         SERIAL      PRIMARY KEY,
  name       TEXT        UNIQUE NOT NULL,
  icon       TEXT,
  color      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO categories (name, icon, color) VALUES
  ('Health',          'favorite',             '#E53935'),
  ('Fitness',         'fitness_center',       '#E91E63'),
  ('Work',            'work',                 '#3949AB'),
  ('Study',           'school',               '#1E88E5'),
  ('Personal Growth', 'trending_up',          '#8E24AA'),
  ('Creative',        'palette',              '#F4511E'),
  ('Social',          'people',               '#00ACC1'),
  ('Household',       'home',                 '#6D4C41'),
  ('Financial',       'attach_money',         '#43A047'),
  ('Admin',           'admin_panel_settings', '#757575');
```

| Column | Type | Notes |
|---|---|---|
| `id` | `SERIAL` | PK |
| `name` | `TEXT` | Unique category name |
| `icon` | `TEXT` | Material icon name for Flutter |
| `color` | `TEXT` | Hex color string |
| `created_at` | `TIMESTAMPTZ` | Auto |

---

### `task_templates`

Defines recurring task patterns. Only created when a task has a recurrence rule.
Non-recurring tasks go directly into `tasks` with `template_id = NULL`.

```sql
CREATE TABLE task_templates (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           TEXT        NOT NULL CHECK (LENGTH(TRIM(title)) > 0),
  description     TEXT,
  points          INTEGER     NOT NULL CHECK (points >= 1 AND points <= 100),
  recurrence_type     TEXT        NOT NULL
                      CHECK (recurrence_type IN ('daily', 'weekly', 'monthly')),
  recurrence_interval INTEGER     NOT NULL DEFAULT 1
                      CHECK (recurrence_interval >= 1),
  start_date      DATE        NOT NULL,
  end_date        DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT end_after_start CHECK (end_date IS NULL OR end_date >= start_date)
);
```

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID` | PK |
| `user_id` | `UUID` | FK → `profiles.id` |
| `title` | `TEXT` | Required, non-empty |
| `description` | `TEXT` | Optional |
| `points` | `INTEGER` | 1–100 |
| `recurrence_type` | `TEXT` | `'daily'`, `'weekly'`, or `'monthly'` |
| `recurrence_interval` | `INTEGER` | Default `1`. e.g. `2` = every 2 weeks |
| `start_date` | `DATE` | First occurrence |
| `end_date` | `DATE` | Optional. `NULL` = open-ended |
| `created_at` | `TIMESTAMPTZ` | Auto |
| `updated_at` | `TIMESTAMPTZ` | Auto, updated by trigger |

---

### `task_template_categories`

Junction table. Links a template to one or more categories.
At least one category is required per template (enforced at app level).

```sql
CREATE TABLE task_template_categories (
  template_id UUID    NOT NULL REFERENCES task_templates(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  PRIMARY KEY (template_id, category_id)
);
```

| Column | Type | Notes |
|---|---|---|
| `template_id` | `UUID` | FK → `task_templates.id` |
| `category_id` | `INTEGER` | FK → `categories.id` |

---

### `tasks`

Actual task instances the user interacts with. Covers both:
- **Standalone tasks** — `template_id IS NULL`, created directly by the user.
- **Recurring instances** — `template_id IS NOT NULL`, generated from a template.

Snapshot fields (`title`, `description`, `points`) are copied from the template
at generation time and are never updated by template edits — preserving historical accuracy.

```sql
CREATE TABLE tasks (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id   UUID        REFERENCES task_templates(id) ON DELETE SET NULL,
  user_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Snapshot fields — copied from template at creation, independent after that
  title         TEXT        NOT NULL CHECK (LENGTH(TRIM(title)) > 0),
  description   TEXT,
  points        INTEGER     NOT NULL CHECK (points >= 1 AND points <= 100),

  assigned_date DATE        NOT NULL,
  completed     BOOLEAN     NOT NULL DEFAULT FALSE,
  completed_at  TIMESTAMPTZ,
  is_locked     BOOLEAN     NOT NULL DEFAULT FALSE,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One instance per template per date — prevents duplicate generation
  CONSTRAINT unique_template_instance UNIQUE (template_id, assigned_date),

  -- completed_at must be set if and only if completed is true
  CONSTRAINT completed_consistency CHECK (
    (completed = FALSE AND completed_at IS NULL) OR
    (completed = TRUE  AND completed_at IS NOT NULL)
  )
);
```

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID` | PK |
| `template_id` | `UUID` | FK → `task_templates.id`. `NULL` for standalone tasks |
| `user_id` | `UUID` | FK → `profiles.id`. Redundant but enables RLS and fast queries |
| `title` | `TEXT` | Snapshot from template or direct user input |
| `description` | `TEXT` | Snapshot, optional |
| `points` | `INTEGER` | Snapshot, 1–100 |
| `assigned_date` | `DATE` | The date this task belongs to |
| `completed` | `BOOLEAN` | Default `FALSE` |
| `completed_at` | `TIMESTAMPTZ` | Set on completion, cleared on un-completion |
| `is_locked` | `BOOLEAN` | Set by scheduled job after late window passes |
| `created_at` | `TIMESTAMPTZ` | Auto |
| `updated_at` | `TIMESTAMPTZ` | Auto, updated by trigger |

---

### `task_categories`

Junction table. Links a task instance to one or more categories.
Categories are snapshotted from the template at generation time.
At least one category required per task (enforced at app level).

```sql
CREATE TABLE task_categories (
  task_id     UUID    NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  PRIMARY KEY (task_id, category_id)
);
```

| Column | Type | Notes |
|---|---|---|
| `task_id` | `UUID` | FK → `tasks.id` |
| `category_id` | `INTEGER` | FK → `categories.id` |

---

### `groups`

Optional social spaces for leaderboard competition.

```sql
CREATE TABLE groups (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT        NOT NULL CHECK (LENGTH(TRIM(name)) > 0),
  description TEXT,
  invite_code TEXT        UNIQUE NOT NULL
                          DEFAULT UPPER(SUBSTRING(uuid_generate_v4()::TEXT, 1, 6)),
  created_by  UUID        NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID` | PK |
| `name` | `TEXT` | Required, non-empty |
| `description` | `TEXT` | Optional |
| `invite_code` | `TEXT` | Unique 6-char uppercase code for joining |
| `created_by` | `UUID` | FK → `profiles.id` |
| `created_at` | `TIMESTAMPTZ` | Auto |
| `updated_at` | `TIMESTAMPTZ` | Auto, updated by trigger |

---

### `group_members`

Membership table. A user can belong to multiple groups.
Group creator is auto-inserted as `admin` via trigger.

```sql
CREATE TABLE group_members (
  group_id  UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role      TEXT        NOT NULL DEFAULT 'member'
                        CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);
```

| Column | Type | Notes |
|---|---|---|
| `group_id` | `UUID` | FK → `groups.id` |
| `user_id` | `UUID` | FK → `profiles.id` |
| `role` | `TEXT` | `'admin'` or `'member'` |
| `joined_at` | `TIMESTAMPTZ` | Auto |

---

### `app_settings`

Configurable system values. Updated here without a code release.

```sql
CREATE TABLE app_settings (
  key        TEXT        PRIMARY KEY,
  value      TEXT        NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO app_settings (key, value) VALUES
  ('late_completion_days', '2'),
  ('streak_min_tasks',     '1');
```

| Key | Default | Description |
|---|---|---|
| `late_completion_days` | `2` | Days after `assigned_date` that completion is allowed |
| `streak_min_tasks` | `1` | Min tasks completed per day to count toward streak |

---

## 3. Indexes

```sql
-- profiles
CREATE INDEX profiles_username_idx           ON profiles(username);

-- tasks — general access
CREATE INDEX tasks_user_id_idx               ON tasks(user_id);
CREATE INDEX tasks_assigned_date_idx         ON tasks(assigned_date);
CREATE INDEX tasks_template_id_idx           ON tasks(template_id);

-- tasks — leaderboard aggregation (user_id + date range + completed in one scan)
CREATE INDEX tasks_user_date_completed_idx
  ON tasks (user_id, assigned_date, completed);

-- tasks — locking job (partial index: only unlocked, incomplete rows)
CREATE INDEX tasks_locking_idx
  ON tasks (assigned_date)
  WHERE completed = FALSE AND is_locked = FALSE;

-- task_templates — active template scan used by the generation scheduled job
CREATE INDEX templates_active_idx            ON task_templates(end_date);
CREATE INDEX templates_user_id_idx           ON task_templates(user_id);
CREATE INDEX templates_start_date_idx        ON task_templates(start_date);

-- task_categories
CREATE INDEX task_cat_task_id_idx            ON task_categories(task_id);
CREATE INDEX task_cat_category_id_idx        ON task_categories(category_id);

-- task_template_categories
CREATE INDEX ttc_template_id_idx             ON task_template_categories(template_id);

-- group_members
CREATE INDEX gm_user_id_idx                  ON group_members(user_id);
CREATE INDEX gm_group_id_idx                 ON group_members(group_id);

-- groups
CREATE INDEX groups_invite_code_idx          ON groups(invite_code);
```

---

## 4. Triggers

### Auto-update `updated_at`

```sql
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_task_templates_updated_at
  BEFORE UPDATE ON task_templates
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### Auto-create profile on signup

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::TEXT, 8)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'New User')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Auto-assign group creator as admin

```sql
CREATE OR REPLACE FUNCTION handle_group_created()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_group_created
  AFTER INSERT ON groups
  FOR EACH ROW EXECUTE FUNCTION handle_group_created();
```

---

## 5. Row-Level Security

```sql
ALTER TABLE profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories               ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_templates           ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_template_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_categories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members            ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings             ENABLE ROW LEVEL SECURITY;

-- profiles: anyone can read; only owner can update
CREATE POLICY "profiles_select_all"  ON profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles_update_own"  ON profiles FOR UPDATE USING (auth.uid() = id);

-- categories: read-only for authenticated users
CREATE POLICY "categories_read"      ON categories FOR SELECT
  USING (auth.role() = 'authenticated');

-- app_settings: read-only for authenticated users
CREATE POLICY "settings_read"        ON app_settings FOR SELECT
  USING (auth.role() = 'authenticated');

-- tasks: full access to owner only
CREATE POLICY "tasks_select_own"     ON tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tasks_insert_own"     ON tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tasks_update_own"     ON tasks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "tasks_delete_own"     ON tasks FOR DELETE USING (auth.uid() = user_id);

-- task_categories: access scoped to task ownership
CREATE POLICY "task_cat_select"      ON task_categories FOR SELECT
  USING (task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid()));
CREATE POLICY "task_cat_insert"      ON task_categories FOR INSERT
  WITH CHECK (task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid()));
CREATE POLICY "task_cat_delete"      ON task_categories FOR DELETE
  USING (task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid()));

-- task_templates: full access to owner only
CREATE POLICY "templates_select_own" ON task_templates FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "templates_insert_own" ON task_templates FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "templates_update_own" ON task_templates FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "templates_delete_own" ON task_templates FOR DELETE USING (auth.uid() = user_id);

-- task_template_categories: access scoped to template ownership
CREATE POLICY "ttc_select"           ON task_template_categories FOR SELECT
  USING (template_id IN (SELECT id FROM task_templates WHERE user_id = auth.uid()));
CREATE POLICY "ttc_insert"           ON task_template_categories FOR INSERT
  WITH CHECK (template_id IN (SELECT id FROM task_templates WHERE user_id = auth.uid()));
CREATE POLICY "ttc_delete"           ON task_template_categories FOR DELETE
  USING (template_id IN (SELECT id FROM task_templates WHERE user_id = auth.uid()));

-- groups: visible to members only
CREATE POLICY "groups_select_member" ON groups FOR SELECT
  USING (id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));
CREATE POLICY "groups_insert_auth"   ON groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- group_members: visible to members of the same group
CREATE POLICY "gm_select_member"     ON group_members FOR SELECT
  USING (group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));
CREATE POLICY "gm_insert_self"       ON group_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "gm_delete_self"       ON group_members FOR DELETE
  USING (auth.uid() = user_id);
```

---

## 6. RPC Functions

All business-critical operations run as `SECURITY DEFINER` Postgres functions.
The Flutter client calls these via `.rpc()` — never raw `.update()`.

---

### `complete_task(p_task_id, p_user_id)`

Marks a task complete. Validates lock and late window.
Returns `{ success, points, error }`.

```sql
CREATE OR REPLACE FUNCTION complete_task(p_task_id UUID, p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_task       tasks%ROWTYPE;
  v_delay_days INTEGER;
  v_cutoff     DATE;
BEGIN
  SELECT value::INTEGER INTO v_delay_days
  FROM app_settings WHERE key = 'late_completion_days';
  v_cutoff := CURRENT_DATE - v_delay_days;

  SELECT * INTO v_task FROM tasks WHERE id = p_task_id AND user_id = p_user_id;

  IF NOT FOUND   THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task not found'); END IF;
  IF v_task.is_locked THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task is locked'); END IF;
  IF v_task.assigned_date < v_cutoff THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Completion window has passed'); END IF;
  IF v_task.completed THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task already completed'); END IF;

  UPDATE tasks
  SET completed = TRUE, completed_at = NOW(), updated_at = NOW()
  WHERE id = p_task_id;

  RETURN jsonb_build_object('success', TRUE, 'points', v_task.points);
END;
$$;
```

---

### `uncomplete_task(p_task_id, p_user_id)`

Reverts a completed task. Only allowed while not locked.
Returns `{ success, points_revoked, error }`.

```sql
CREATE OR REPLACE FUNCTION uncomplete_task(p_task_id UUID, p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_task tasks%ROWTYPE;
BEGIN
  SELECT * INTO v_task FROM tasks WHERE id = p_task_id AND user_id = p_user_id;

  IF NOT FOUND        THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task not found'); END IF;
  IF v_task.is_locked THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task is locked'); END IF;
  IF NOT v_task.completed THEN RETURN jsonb_build_object('success', FALSE, 'error', 'Task is not completed'); END IF;

  UPDATE tasks
  SET completed = FALSE, completed_at = NULL, updated_at = NOW()
  WHERE id = p_task_id;

  RETURN jsonb_build_object('success', TRUE, 'points_revoked', v_task.points);
END;
$$;
```

---

### `get_daily_performance(p_user_id, p_date)`

Returns completion stats for a user on a given date.

```sql
CREATE OR REPLACE FUNCTION get_daily_performance(p_user_id UUID, p_date DATE)
RETURNS TABLE (
  total_tasks     INTEGER,
  completed_tasks INTEGER,
  completion_rate NUMERIC,
  total_points    INTEGER,
  earned_points   INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::INTEGER,
    COUNT(*) FILTER (WHERE completed = TRUE)::INTEGER,
    CASE WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE completed = TRUE)::NUMERIC / COUNT(*) * 100, 1)
    END,
    COALESCE(SUM(points), 0)::INTEGER,
    COALESCE(SUM(points) FILTER (WHERE completed = TRUE), 0)::INTEGER
  FROM tasks
  WHERE user_id = p_user_id AND assigned_date = p_date;
END;
$$;
```

---

### `get_streak(p_user_id)`

Returns current and longest streak. Days with no tasks assigned are neutral —
they do not break the streak. Days with tasks assigned but none completed break it.

```sql
CREATE OR REPLACE FUNCTION get_streak(p_user_id UUID)
RETURNS TABLE (current_streak INTEGER, longest_streak INTEGER)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_min_tasks  INTEGER;
  v_check_date DATE := CURRENT_DATE;
  v_task_count INTEGER;
  v_has_tasks  BOOLEAN;
  v_current    INTEGER := 0;
  v_longest    INTEGER := 0;
  v_running    INTEGER := 0;
  v_gap_found  BOOLEAN := FALSE;
BEGIN
  SELECT value::INTEGER INTO v_min_tasks
  FROM app_settings WHERE key = 'streak_min_tasks';

  LOOP
    SELECT COUNT(*) INTO v_task_count
    FROM tasks
    WHERE user_id = p_user_id AND assigned_date = v_check_date AND completed = TRUE;

    SELECT EXISTS(
      SELECT 1 FROM tasks
      WHERE user_id = p_user_id AND assigned_date = v_check_date
    ) INTO v_has_tasks;

    IF v_task_count >= v_min_tasks THEN
      v_running := v_running + 1;
      IF NOT v_gap_found THEN v_current := v_running; END IF;
    ELSIF v_has_tasks THEN
      -- Tasks existed but none completed — breaks streak
      IF v_running > v_longest THEN v_longest := v_running; END IF;
      v_running   := 0;
      v_gap_found := TRUE;
    END IF;
    -- Days with no tasks are skipped silently

    v_check_date := v_check_date - 1;
    EXIT WHEN v_check_date < CURRENT_DATE - 365;
  END LOOP;

  IF v_running > v_longest THEN v_longest := v_running; END IF;

  current_streak := v_current;
  longest_streak := v_longest;
  RETURN NEXT;
END;
$$;
```

---

### `get_leaderboard(p_group_id, p_start, p_end)`

Returns group leaderboard ranked by earned points DESC, completion rate as tiebreaker.

```sql
CREATE OR REPLACE FUNCTION get_leaderboard(
  p_group_id UUID,
  p_start    DATE,
  p_end      DATE
)
RETURNS TABLE (
  rank            BIGINT,
  user_id         UUID,
  username        TEXT,
  display_name    TEXT,
  avatar_url      TEXT,
  earned_points   BIGINT,
  total_tasks     BIGINT,
  completed_tasks BIGINT,
  completion_rate NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH member_stats AS (
    SELECT
      gm.user_id,
      p.username,
      p.display_name,
      p.avatar_url,
      COALESCE(SUM(t.points) FILTER (WHERE t.completed = TRUE), 0) AS earned_points,
      COUNT(t.id)                                                    AS total_tasks,
      COUNT(t.id) FILTER (WHERE t.completed = TRUE)                 AS completed_tasks,
      CASE WHEN COUNT(t.id) = 0 THEN 0
        ELSE ROUND(
          COUNT(t.id) FILTER (WHERE t.completed = TRUE)::NUMERIC / COUNT(t.id) * 100, 1
        )
      END                                                            AS completion_rate
    FROM group_members gm
    JOIN profiles p ON p.id = gm.user_id
    LEFT JOIN tasks t
      ON t.user_id = gm.user_id
      AND t.assigned_date BETWEEN p_start AND p_end
    WHERE gm.group_id = p_group_id
    GROUP BY gm.user_id, p.username, p.display_name, p.avatar_url
  )
  SELECT
    RANK() OVER (ORDER BY ms.earned_points DESC, ms.completion_rate DESC),
    ms.*
  FROM member_stats ms;
END;
$$;
```

---

### `lock_expired_tasks()`

Locks all incomplete tasks past the late completion window.
Called by daily scheduled job.

```sql
CREATE OR REPLACE FUNCTION lock_expired_tasks()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_delay_days INTEGER;
BEGIN
  SELECT value::INTEGER INTO v_delay_days
  FROM app_settings WHERE key = 'late_completion_days';

  UPDATE tasks
  SET is_locked = TRUE, updated_at = NOW()
  WHERE completed = FALSE
    AND is_locked = FALSE
    AND assigned_date < CURRENT_DATE - v_delay_days;
END;
$$;
```

---

### `generate_template_instances(p_template_id, p_from_date, p_to_date)`

Generates task instances for a template within a date range.
Idempotent — safe to call multiple times due to `ON CONFLICT DO NOTHING`.
Returns the number of new instances inserted.

```sql
CREATE OR REPLACE FUNCTION generate_template_instances(
  p_template_id UUID,
  p_from_date   DATE,
  p_to_date     DATE
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_template  task_templates%ROWTYPE;
  v_date      DATE;
  v_task_id   UUID;
  v_inserted  INTEGER := 0;
BEGIN
  SELECT * INTO v_template FROM task_templates WHERE id = p_template_id;
  IF NOT FOUND THEN RETURN 0; END IF;

  v_date := GREATEST(p_from_date, v_template.start_date);

  LOOP
    EXIT WHEN v_date > p_to_date;
    EXIT WHEN v_template.end_date IS NOT NULL AND v_date > v_template.end_date;

    INSERT INTO tasks (template_id, user_id, title, description, points, assigned_date)
    VALUES (p_template_id, v_template.user_id, v_template.title,
            v_template.description, v_template.points, v_date)
    ON CONFLICT (template_id, assigned_date) DO NOTHING
    RETURNING id INTO v_task_id;

    IF v_task_id IS NOT NULL THEN
      -- Snapshot categories from template
      INSERT INTO task_categories (task_id, category_id)
      SELECT v_task_id, category_id
      FROM task_template_categories
      WHERE template_id = p_template_id
      ON CONFLICT DO NOTHING;

      v_inserted := v_inserted + 1;
      v_task_id  := NULL;
    END IF;

    -- Advance date based on recurrence type and interval
    v_date := CASE v_template.recurrence_type
      WHEN 'daily'   THEN v_date + v_template.recurrence_interval
      WHEN 'weekly'  THEN v_date + (v_template.recurrence_interval * 7)
      WHEN 'monthly' THEN (v_date + (INTERVAL '1 month' * v_template.recurrence_interval))::DATE
      ELSE v_date + 1
    END;
  END LOOP;

  RETURN v_inserted;
END;
$$;
```

---

## 7. Scheduled Jobs

```sql
-- Lock expired tasks — runs daily at 00:00 UTC
SELECT cron.schedule(
  'lock-expired-tasks',
  '0 0 * * *',
  'SELECT lock_expired_tasks()'
);

-- Generate recurring instances — runs daily at 00:05 UTC
-- Generates up to today + 30 days for all active templates
SELECT cron.schedule(
  'generate-recurring-instances',
  '5 0 * * *',
  $$
    SELECT generate_template_instances(id, CURRENT_DATE, CURRENT_DATE + 30)
    FROM task_templates
    WHERE end_date IS NULL OR end_date >= CURRENT_DATE
  $$
);
```

---

## 8. Column Type Reference

| Postgres type | Dart type | DTO conversion |
|---|---|---|
| `UUID` | `String` | `json['id'] as String` |
| `TEXT` | `String` | `json['title'] as String` |
| `TEXT` nullable | `String?` | `json['description'] as String?` |
| `INTEGER` | `int` | `json['points'] as int` |
| `SERIAL` | `int` | `json['id'] as int` |
| `BOOLEAN` | `bool` | `json['completed'] as bool` |
| `DATE` | `DateTime` | `DateTime.parse(json['assigned_date'] as String)` |
| `TIMESTAMPTZ` | `DateTime` | `DateTime.parse(json['created_at'] as String)` |
| `TIMESTAMPTZ` nullable | `DateTime?` | `json['completed_at'] == null ? null : DateTime.parse(json['completed_at'] as String)` |

**DATE serialization — always `'yyyy-MM-dd'`, never full ISO-8601:**
```dart
date.toIso8601String().split('T').first
```

---

## 9. Entity Relationship Overview

```
auth.users
    │
    ▼
profiles ─────────────────────────────────────┐
    │                                          │
    ├──► task_templates                        │
    │         │                                │
    │         ├──► task_template_categories    │
    │         │         └──► categories ◄──────┤
    │         │                                │
    │         └──► tasks (recurring instances) │
    │                   │                      │
    ├──► tasks ◄─────────┘                     │
    │   (standalone,                           │
    │   template_id = NULL)                    │
    │                   └──► task_categories   │
    │                             └──► categories
    │
    ├──► group_members ◄──► groups
    │
    └── app_settings (global, not per-user)
```

### Key relationships

| Relationship | Type | Via |
|---|---|---|
| User → Tasks | One-to-many | `tasks.user_id` |
| User → Templates | One-to-many | `task_templates.user_id` |
| Template → Tasks | One-to-many | `tasks.template_id` |
| Tasks ↔ Categories | Many-to-many | `task_categories` |
| Templates ↔ Categories | Many-to-many | `task_template_categories` |
| Users ↔ Groups | Many-to-many | `group_members` |
| Standalone task | `template_id IS NULL` | — |
| Recurring task instance | `template_id IS NOT NULL` | — |
