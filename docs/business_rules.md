# Business Rules
# Productivity & Accountability App
# @-mention this file when working on feature-specific logic, validation, or UX behaviour

---

## Tasks

### Creation
- A task must have a title, assigned date, at least one category, and points before it can be saved.
- Title must not be empty or whitespace only.
- Points must be an integer between 1 and 100 inclusive.
- At least one category must be selected. Multiple categories are allowed.
- Description is optional.
- Recurrence is optional. If no recurrence rule is provided, a single task instance is created directly in the `tasks` table with no `template_id`.
- If a recurrence rule is provided, a `task_templates` record is created first and task instances are generated from it.

### Editing
- Assigned date is editable after creation.
- A locked task cannot be edited or completed.
- Editing a recurring task instance only affects that instance — the template is unchanged.
- Editing a template (this and future tasks) closes the existing template and creates a new one starting from the edit date. Past instances are never modified.
- Future restrictions on editing older tasks may be introduced — design with this in mind.

### Completion
- A task can only be marked complete if it is not locked.
- Completion is allowed up to N days after the assigned date, where N is the `late_completion_days` value in `app_settings` (default: 2).
- Completion always counts toward the original assigned date — never the date it was marked.
- When marked complete, the completion timestamp is recorded and points are awarded.
- A completed task can be marked incomplete if it was completed by mistake, provided it is not locked.
- Un-completion is not allowed after the late completion window has passed — once locked, the state is final.
- Points awarded on completion are revoked when a task is marked incomplete.

### Locking
- Tasks that are not completed and whose late completion window has passed become locked automatically.
- Locking is performed server-side via a scheduled Postgres job — never by the Flutter client.
- Locked tasks are visible but no actions can be taken on them.

### No Automatic Rescheduling
- Incomplete tasks are not carried forward to the next day.
- If a user wants to retry a missed task, they create a new task for the new date.

---

## Recurring Tasks

### Data Model
Two tables handle recurrence:

**`task_templates`** — defines the recurrence pattern:
- `id`, `user_id`, `title`, `description`, `points`, `category_id`
- `start_date` — first occurrence date
- `end_date` — optional end of recurrence
- `recurrence_rule` — iCal RRULE string (e.g. `FREQ=DAILY`)
- `created_at`, `updated_at`

**`tasks`** — actual instances the user interacts with:
- `id`, `user_id`, `assigned_date`, `completed` (bool, default false)
- `template_id` — nullable FK to `task_templates`
- `title`, `description`, `points`, `category_id` — snapshots from template at generation time
- `created_at`, `updated_at`

### Snapshot Fields
The following fields are copied from the template onto each task instance at generation time:
`title`, `description`, `points`, `category_id`, `user_id`

This ensures historical accuracy — editing a template never changes past instances.

### Instance Generation
- On template creation: generate instances synchronously from `start_date` through end of the current month.
- Daily scheduled job: generate instances up to today + 30 days on a rolling basis.
- Idempotent: a `unique(template_id, assigned_date)` constraint prevents duplicate instances.
- Indexes required on `(template_id, assigned_date)` and `(user_id)` for fast lookups.

### Editing Rules
- **Edit this instance only** — update the task row directly. Template is unchanged.
- **Edit this and future tasks** — close the current template by setting `end_date = edit_date - 1`, create a new template starting from `edit_date` with the updated values. Future instances are generated from the new template.
- Past instances are immutable through template edits. A user may edit a single past instance directly if needed, but bulk updates to past tasks are not allowed.

### Non-Recurring Tasks
- Tasks with no `template_id` are standalone. They are created directly in `tasks` with `template_id = null`.
- All completion, locking, and performance logic applies equally to both recurring and non-recurring tasks.

---

## Points

- Each task has a points value representing effort, difficulty, and importance.
- Points are awarded when a task is marked complete.
- Uncompleted or locked tasks award zero points — there is no penalty or deduction.
- Points accumulate over time and contribute to leaderboard ranking and analytics.
- Points do not decrease under any circumstance.

---

## Daily Performance

- The primary metric is: completed tasks / total tasks assigned for that day x 100.
- Example: 3 completed out of 5 assigned = 60%.
- A day with no tasks assigned has no completion rate — do not show 0%, show nothing.
- Late completions count toward the assigned date's performance, not the marking date.
- This metric is displayed as a progress widget on the home screen.

---

## Streaks

- A streak is the number of consecutive days with meaningful completion activity.
- Meaningful activity is defined as: at least 1 task completed on that day.
  (The threshold is configurable via `streak_min_tasks` in `app_settings`, default: 1.)
- Streaks are calculated server-side via the `get_streak` RPC — never in Dart.
- Breaking a streak resets the current streak counter to 0. There is no penalty beyond the reset.
- The longest streak is tracked separately and never resets.
- A day with no tasks assigned does not count for or against the streak.

---

## Categories

- Every task must have at least one category. Multiple categories are allowed.
- Categories are system-defined and fixed — users cannot create or delete categories.
- The 10 base categories are: Health, Fitness, Work, Study, Personal Growth, Creative, Social, Household, Financial, Admin.
- AI may suggest a category when the user types a task title, but the user always has final control.
- If the AI suggestion is wrong or irrelevant, the user dismisses it and selects manually.
- Category selection must not block task creation — AI suggestion is advisory only.

---

## Leaderboards

### Access
- Leaderboards are only visible within a group.
- A user with no group membership has no leaderboard.
- Joining a group is entirely optional.

### Ranking
- Leaderboard ranking is based on total points earned within the selected time window.
- In case of equal points, higher completion rate breaks the tie.
- Ranking is computed server-side via the `get_leaderboard` RPC — never in Dart.
- There is no minimum activity threshold to appear on the leaderboard.

### Time Windows
- Supported windows: Today, Last 7 days, Calendar week, Calendar month, Custom range.
- Time windows are filters on existing data — they do not affect how tasks are stored.

### Visibility
- Only performance metrics (completion rate, points) are visible to group members.
- Completion timestamps are not publicly visible in MVP.
- Individual task titles and descriptions are not visible to other group members.

---

## Groups

- Groups are optional social spaces — the core app works fully without them.
- A user can create a group or join one via a 6-character invite code.
- A user can belong to multiple groups.
- Leaving a group removes the user from that group's leaderboard.
- For MVP: no complex privacy levels, role permissions, or group moderation.
- Group creator is automatically assigned the `admin` role.
- Other members are assigned the `member` role on join.

---

## UX & Tone

### No Penalties, No Punishment
- The app never shows negative scores, red warning states, or punitive language.
- Uncompleted tasks are simply incomplete — they are not failures.
- Never use language like "You failed", "Streak broken", "Behind schedule".
- Always frame progress positively: show what was achieved, not what was missed.

### Encouragement Over Enforcement
- Progress is always visible.
- Streaks exist to encourage consistency, not to punish breaks.
- Leaderboards exist to motivate, not to shame.
- Empty states are encouraging — e.g. "No tasks yet. Add your first one!" not "Nothing here."

---

## App Settings (Configurable)

These values live in the `app_settings` table and can be changed without a code release.

| Key | Default | Description |
|---|---|---|
| `late_completion_days` | 2 | Days after assigned date that completion is still allowed |
| `streak_min_tasks` | 1 | Minimum tasks completed per day to count as an active streak day |

---

## Data Integrity — What the DB Enforces vs What Flutter Validates

| Rule | Enforced by | Flutter validates too? |
|---|---|---|
| Points range 1–100 | DB check constraint | Yes — form slider/field |
| At least one category required | DB constraint | Yes — submit disabled until selected |
| No duplicate recurring instances | `unique(template_id, assigned_date)` | No — DB prevents silently |
| Completion window check | `complete_task` RPC | No — trust the RPC result |
| Task locking | Scheduled Postgres job | No — read `is_locked` from DB |
| Late completion date scoring | `complete_task` RPC | No — trust the RPC result |
| Past instances immutable via template | App-level convention | Yes — never send past bulk updates |
| Leaderboard ranking | `get_leaderboard` RPC | No — render result directly |
| Streak calculation | `get_streak` RPC | No — render result directly |

Flutter validates early for user experience. The DB is the final authority.
Never duplicate DB integrity logic in Dart — they will drift.
