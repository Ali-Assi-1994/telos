# Next Steps Plan — Telos
**Productivity & Accountability App**

This plan is based on:
- **Business rules:** `docs/business_rules.md`
- **Technical design:** `docs/technical_documentation.md` and `docs/database_schema.md`
- **Current codebase:** Flutter scaffold + routing + Supabase service stub (no auth, no features, no DB)

---

## Current State Summary

| Area | Status |
|------|--------|
| **Flutter shell** | ✅ `main.dart`, `app.dart`, `ProviderScope`, `MaterialApp.router` |
| **Routing** | ✅ GoRouter, `AppRoutes`, `auth_guard` (stub), single splash route |
| **Supabase** | ⚠️ Package added; **Supabase not initialized** in `main.dart` |
| **Environment** | ⚠️ `.env.example` and `.env.dev` exist; **no `flutter_dotenv`** in `pubspec` or `main` |
| **Infra** | ✅ `AppLogger`, `AppException`, `SupabaseService` (provider for client) |
| **Backend** | ❌ No Supabase migrations in repo — schema only in `docs/database_schema.md` |
| **Features** | ❌ No auth, tasks, performance, groups, or leaderboard code |

The app currently shows a splash screen and would redirect to `/auth/login` if the guard used a real auth state (it doesn’t yet). The Supabase client is never initialized, so any feature that uses it would fail.

---

## Recommended Order of Work

Follow **Phase 1** of the Implementation Roadmap first, then Phase 2. The steps below are ordered so each builds on the previous one.

---

### Step 1 — Environment & Supabase initialization (Foundation)

**Goal:** App starts with Supabase connected using env-based config.

1. Add **`flutter_dotenv`** to `pubspec.yaml`.
2. In **`main.dart`** (before `runApp`):
   - Call `WidgetsBinding.ensureInitialized()` (already there).
   - Load env: `await dotenv.load(fileName: '.env.dev');` (or switch by flavor later).
   - Initialize Supabase: `await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, anonKey: dotenv.env['SUPABASE_ANON_KEY']!);`
3. Ensure **`.env.dev`** contains valid `SUPABASE_URL` and `SUPABASE_ANON_KEY` (local or hosted).
4. Add **`.env.dev`** to `.gitignore` if not already (keep `.env.example` with empty keys).

**Outcome:** App runs and `Supabase.instance.client` is valid. No new UI.

---


### Step 2 — Auth feature (First feature)

**Goal:** Users can register, log in, and the app redirects by auth state.

1. **Auth state in Flutter:**
   - Add a **StreamProvider** (or equivalent) that listens to `Supabase.instance.client.auth.onAuthStateChange` and exposes the current `User?`.
   - Optionally expose “current user” as a derived provider (e.g. `User?` or a small `AppUser` domain model).

2. **Wire router to auth:**
   - In **`app_router.dart`**, use the auth state provider instead of the hardcoded `isAuthenticated = false`.
   - Implement redirect logic as in the technical doc: unauthenticated → `/auth/login`; authenticated on `/auth/*` → `/home`.

3. **Auth screens:**
   - **Login:** Email + password, call `Supabase.instance.client.auth.signInWithPassword`, then let redirect go to `/home`.
   - **Register:** Email + password (and any required profile fields if you collect them), call `signUp`. Profile row is created by DB trigger.
   - **Logout:** Call `signOut`, then `context.go(AppRoutes.login)` (or splash).

4. **Routes:**
   - Add GoRouter routes for `AppRoutes.login`, `AppRoutes.register`, and `AppRoutes.home`.
   - Splash can redirect to login or home based on auth, or be removed once auth is in place.

5. **Error handling:**
   - Map Supabase `AuthException` to `AppException` (e.g. `AuthAppException`) in an auth repository or service, and show `toUserMessage()` in the UI (e.g. SnackBar).

**Outcome:** User can sign up, log in, log out; router shows login when signed out and home when signed in.

---

### Step 4 — Placeholder home screen

**Goal:** Authenticated users land on a real screen instead of a blank or splash.

1. Add a **Home** screen (e.g. `lib/src/features/home/presentation/home_screen.dart` or under `tasks` as the main list host).
2. Route **`/home`** to this screen.
3. For now: simple scaffold with a title (e.g. “Telos”), optional “Log out” button, and a short message like “Tasks will go here.” No task logic yet.

**Outcome:** Post-login flow feels complete; ready to add task list and daily view.

---

### Step 5 — Core task system (Phase 2 start)

**Goal:** Users can see and create tasks for a chosen date and complete/uncomplete them.

1. **Domain & data layer (tasks):**
   - **Domain models:** `Task`, `Category` (and later `TaskTemplate` for recurrence). Use `freezed` as in the technical doc; task has `id`, `userId`, `title`, `description`, `points`, `categoryIds`, `assignedDate`, `completed`, `completedAt`, `isLocked`, etc.
   - **DTOs:** Map Supabase JSON ↔ domain (e.g. `TaskDto`, `CategoryDto`) in `data/`.
   - **Task repository (abstract + Supabase impl):**
     - `getCategories()` — read from `categories`.
     - `getTasksForDate(userId, date)` — from `tasks` (+ join or separate read for `task_categories`).
     - `createTask(task)` — insert into `tasks` and `task_categories`; validate title, points 1–100, at least one category (business rules).
   - **RPC usage:** Implement `complete_task` and `uncomplete_task` via `.rpc()` and map results to domain (e.g. `CompleteTaskResult`).

2. **State:**
   - Providers: e.g. `categoriesProvider`, `tasksForDateProvider(userId, date)`, `selectedDateProvider` (for date picker).
   - Controllers: e.g. `TaskCreateController` (create task, invalidate `tasksForDateProvider` and daily performance), `TaskListController` or inline actions for complete/uncomplete (invalidate tasks + performance + streak).

3. **UI:**
   - **Home (or Tasks) screen:** Date picker + list of tasks for selected date. Use `tasksForDateProvider` and show locked state (read-only, no complete button).
   - **Task create screen:** Form (title, description, points 1–100, category multi-select, assigned date). Submit → repository create → pop and invalidate.
   - **Task card:** Title, points, categories, complete checkbox (if not locked). On tap complete → call `complete_task` RPC; on uncomplete → `uncomplete_task` RPC.

4. **Daily performance widget:**
   - Call `get_daily_performance` RPC for selected date; show “X / Y tasks (Z%)” and points. Hide or show “no rate” when no tasks (per business rules).

**Outcome:** Full loop: create task → see it on home → complete/uncomplete → see daily performance. Locking is reflected from DB.

---

### Step 6 — Task editing & locking behavior

- **Edit screen:** Load task by id, same form as create; “Edit this instance only” → update `tasks` (and `task_categories`) only.
- **Locking:** No client logic — read `is_locked` from DB; disable edit and complete in UI. Ensure `lock_expired_tasks` cron is scheduled in Supabase (see database_schema.md).

---

### Step 7 — Recurring tasks (optional after Step 6)

- Add `TaskTemplate` domain model and repository methods: create template + generate instances (or call an RPC that does it).
- Task create form: optional recurrence (daily/weekly/monthly + interval). If set, create template and generate instances; if not, create single task with `template_id = null`.
- “Edit this and future” can come later (close template, create new from edit date).

---

### Step 8 — Motivation layer (Phase 3)

- **Streak:** `get_streak` RPC → `Streak` model → streak widget on home.
- **AI category suggestion:** Edge Function `suggest-category` + debounce on title field; suggestion chip, non-blocking (advisory only).
- **Points accumulation:** Already available from tasks; add a small “Total points” or “Today’s points” display from daily performance if desired.

---

### Step 9 — Groups & leaderboard (Phase 4)

- Groups: create group, join by 6-char code; `group_members` and RLS.
- Leaderboard screen: `get_leaderboard` RPC, time window selector (Today, 7 days, week, month, custom).
- Realtime: optional stream for leaderboard updates when group members complete tasks.

---

### Step 10 — Adaptive UI & polish (Phase 5–6)

- Breakpoints (mobile / tablet / desktop), navigation pattern per breakpoint, max content width.
- Empty states, error handling audit, light/dark theme, tests, accessibility.

---

## Immediate Next Steps (What to Do First)

1. **Step 1 — Environment & Supabase init** (about 30 min).  
   Enables all future Supabase usage.

2. **Step 2 — Supabase schema** (half day to a day, depending on local vs hosted).  
   Required for auth (profile trigger) and for any task or category code.

3. **Step 3 — Auth feature** (about 1 day).  
   So the app is “real”: sign up, login, logout, and guarded routes.

4. **Step 4 — Placeholder home** (short).  
   So `/home` is a real screen.

5. **Step 5 — Core task system** (2–4 days).  
   First real value: create tasks, list by date, complete/uncomplete, daily performance.

After that, continue in order: editing/locking → recurring → motivation → groups/leaderboard → adaptive UI & polish. This order keeps the product usable at each stage and aligns with the Implementation Roadmap in `docs/technical_documentation.md`.
