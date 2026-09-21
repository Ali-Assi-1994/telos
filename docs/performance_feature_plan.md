# Performance Feature — Implementation Plan

Build plan for the `performance` feature (daily progress + streaks), written
so implementation can start cold in a new session. Check items off as they
land; each step should be its own commit/PR, matching how the rest of this
repo has been built.

Source of truth for the rules below: `docs/business_rules.md` ("Daily
Performance", "Streaks"), `docs/architecture.md` (§9 Cross-Feature
Dependencies, §10 Decision 1 and Decision 7), and `docs/database_schema.md`
(the `get_streak` RPC spec). Don't re-derive the rules here — read those docs
when implementing; this plan only tracks sequencing and file layout.

---

## Decide first: full `performance/` feature extraction, or minimal?

`getDailyPerformance()` and the `DailyPerformance` model currently live
inside `tasks/` (an architecture drift — `docs/architecture.md` specifies a
standalone `performance/` feature that only depends on `tasks`, not the
other way around). Two options:

- **Recommended: full extraction.** Move `DailyPerformance` out of `tasks/`
  into a proper `performance/` feature alongside the new `Streak` work, per
  the documented architecture. Small refactor of already-working, tested
  code, but avoids letting more code accumulate in the wrong feature.
- **Minimal**: leave `getDailyPerformance` where it is, add only the new
  streak piece as its own feature.

Confirm which before starting Step 3. This plan assumes **full extraction**.

---

## What already exists (verified in code, not assumed from docs)

- `DailyPerformance` freezed model — `lib/src/features/tasks/domain/daily_performance.dart`
- `DailyPerformanceDto` — `lib/src/features/tasks/data/task_dto.dart:61`
- `getDailyPerformance()` on `TaskRepository`/`SupabaseTaskRepository`, calling the real, already-deployed `get_daily_performance` RPC
- `dailyPerformanceForSelectedDateProvider` — `lib/src/features/tasks/presentation/tasks_providers.dart:51`, correctly invalidated on task create/complete/uncomplete, but **nothing renders it today**
- `TasksHeader`'s streak badge slot — `lib/src/features/tasks/presentation/tasks_screen.dart:64` — hardcoded `streakCount: null`, silently falling back to a plain task count

## What's genuinely new

- The `get_streak` RPC itself (not deployed — no code anywhere calls it)
- The `Streak` domain model
- Any widget that actually displays daily performance (currently computed and thrown away)

---

## Steps

### Step 0 — Supabase baseline (prerequisite, from the earlier Supabase-depth plan)

- [ ] Install Supabase CLI (`brew install supabase/tap/supabase`)
- [ ] `supabase login` (browser OAuth), `supabase link --project-ref gwvseuxuafjkygqcxeae`
- [ ] `supabase db pull` — generates the first migration from what's actually live. This alone closes "no `supabase/` directory in git" from the gap report.
- [ ] Diff the pulled schema against `docs/database_schema.md`. Expect `profiles`, `categories`, `tasks`, `task_categories` live; expect `task_templates`/`groups`/`group_members`/`app_settings` to be missing or unused — don't "fix" that here, it's out of scope (see below).
- [ ] Commit `supabase/migrations/`.

### Step 1 — Add the `get_streak` RPC

- [ ] `supabase migration new add_get_streak_rpc`
- [ ] Use the exact SQL from `docs/database_schema.md` §6 "`get_streak(p_user_id)`" — **the MVP signature, `get_streak(p_user_id UUID)`**, not the timezone-aware version mentioned as a "future" signature in `docs/technical_documentation.md:732`. Timezones are explicitly deferred (Decision 7).
- [ ] `supabase db push`, verify with a manual RPC call (MCP `execute_sql` or Studio) before wiring Dart to it.

### Step 2 — Domain layer

- [ ] Move `lib/src/features/tasks/domain/daily_performance.dart` → `lib/src/features/performance/domain/daily_performance.dart` (only if doing the full extraction from the decision above)
- [ ] New `lib/src/features/performance/domain/streak.dart` — freezed, `{ currentStreak, longestStreak }`

### Step 3 — Data layer

- [ ] `lib/src/features/performance/data/performance_repository.dart` (abstract): `getDailyPerformance()`, `getStreak()`
- [ ] `lib/src/features/performance/data/performance_dto.dart` — move `DailyPerformanceDto` out of `tasks/data/task_dto.dart`, add `StreakDto`
- [ ] `lib/src/features/performance/data/supabase_performance_repository.dart` — calls `get_daily_performance` (moved) and `get_streak` (new)
- [ ] Remove `getDailyPerformance` from `TaskRepository`/`SupabaseTaskRepository`
- [ ] Move the `DailyPerformanceDto` test group out of `test/features/tasks/data/task_dto_test.dart` into `test/features/performance/data/performance_dto_test.dart`; add `StreakDto` tests
- [ ] New `test/features/performance/data/fakes/fake_performance_repository.dart`

### Step 4 — Providers

- [ ] `lib/src/features/performance/presentation/performance_providers.dart`:
  - `performanceRepositoryProvider` (`keepAlive: true`, matches the repository-provider convention)
  - `dailyPerformanceForSelectedDateProvider` (moved from `tasks_providers.dart`; still depends on `tasks`'s `selectedDateProvider` — that's an allowed cross-feature dependency per `docs/architecture.md` §9, `performance → tasks`)
  - `streakProvider` (new — depends only on `authStateProvider`, not on the selected date; a streak is "as of today," not scoped to whichever date the user is browsing)
- [ ] Update invalidation in `task_create_controller.dart` and `task_mutation_controller.dart`: keep the existing `dailyPerformanceForSelectedDateProvider` invalidation (now from the new import path), and add `ref.invalidate(streakProvider)` on complete/uncomplete only (per the invalidation table in `docs/technical_documentation.md:373-376` — streak reacts to completion, not to task creation)

### Step 5 — Widgets

- [ ] `lib/src/features/performance/presentation/daily_progress_widget.dart` — "X / Y tasks (Z%)" + points, per `docs/business_rules.md` §"Daily Performance". **When `totalTasks == 0`, render nothing (not "0%")** — this is an explicit rule, not a style choice.
- [ ] Mount `DailyProgressWidget` in `TasksScreen`, under `TasksHeader`
- [ ] Replace `streakCount: null` at `tasks_screen.dart:64` with the real value from `streakProvider`
- [ ] Tone check against `docs/business_rules.md` §"UX & Tone": no red/negative states, no "streak broken" language anywhere in the new widgets

### Step 6 — Tests

- [ ] Widget tests for `DailyProgressWidget`: shows the rate correctly, hides entirely at zero tasks, no punitive copy
- [ ] Provider tests for `streakProvider`/`dailyPerformanceForSelectedDateProvider` against `FakePerformanceRepository`
- [ ] Update `test/features/tasks/presentation/tasks_screen_test.dart` for the new widget's presence
- [ ] Regenerate `test/golden/goldens/tasks_screen.png` (`make update_goldens`) once the screen's layout changes — review the diff before committing, per the existing convention in `docs/testing-strategy.md`

### Step 7 — Docs cleanup

- [ ] Check off "Daily performance widget" and "Streak display" in `docs/technical_documentation.md`'s roadmap (§20)
- [ ] Update the local `docs/EVIDENCE_GAP_REPORT.md` (gitignored, not pushed) to reflect the new feature
- [ ] Delete this plan file once the feature is fully merged, or fold anything still relevant into `docs/todo.md`

---

## Explicitly out of scope for this feature

- Timezone-aware streaks (Decision 7 defers this to post-MVP; UTC drift is accepted)
- `groups`/`leaderboard` — `performance` depends only on `tasks`, not on group membership
- `task_templates`/recurring tasks — unrelated to this feature
- Deploying the other undeployed RPCs (`get_leaderboard`, `lock_expired_tasks`, `generate_template_instances`) — no consumers exist yet, would just be unused surface area
