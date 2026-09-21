# Technical Documentation
# Productivity & Accountability App
# Stack: Flutter · Supabase · Riverpod
# @-mention this file for architecture decisions, implementation patterns, and stack guidance

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture](#3-architecture)
4. [Project Structure](#4-project-structure)
5. [Supabase Transport Layer](#5-supabase-transport-layer)
6. [Data Flow](#6-data-flow)
7. [State Management](#7-state-management)
8. [Recurring Tasks System](#8-recurring-tasks-system)
9. [Auth Flow](#9-auth-flow)
10. [Routing](#10-routing)
11. [Error Handling](#11-error-handling)
12. [Logging](#12-logging)
13. [Environment Configuration](#13-environment-configuration)
14. [AI Category Suggestion](#14-ai-category-suggestion)
15. [Realtime](#15-realtime)
16. [Time Zones](#16-time-zones)
17. [Adaptive Layout](#17-adaptive-layout)
18. [Testing Strategy](#18-testing-strategy)
19. [Code Generation](#19-code-generation)
20. [Implementation Roadmap](#20-implementation-roadmap)

---

## 1. Project Overview

A cross-platform productivity and accountability app for mobile (iOS, Android)
and web. Users create time-bound tasks with difficulty points, track daily
completion rates, maintain streaks, and optionally compete in group leaderboards.

**Core philosophy:** encourage progress through structure and visibility.
No penalties, no punishment — only structured encouragement.

**Reference documents:**
- `BUSINESS_RULES.md` — product rules, validation logic, UX constraints
- `DATABASE_SCHEMA.md` — full Postgres schema, RPC functions, indexes, RLS

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (iOS, Android, Web) |
| Backend | Supabase (Postgres, Auth, Realtime, Edge Functions, Storage) |
| State management | Riverpod with code generation (`riverpod_annotation`) |
| Navigation | GoRouter |
| Data models | `freezed` + `json_serializable` |
| Dependency injection | Riverpod `keepAlive` providers |
| Environment config | `flutter_dotenv` |
| Logging | `AppLogger` service (`dart:developer` under the hood) |
| AI suggestions | Supabase Edge Function → OpenAI |
| Scheduled jobs | Supabase pg_cron |

---

## 3. Architecture

Follows Andrea Bizzotto's **feature-first Riverpod architecture** with four
layers applied per feature:

```
presentation  →  widgets + AsyncNotifier controllers
application   →  services (only when logic spans multiple repos)
domain        →  pure Dart model classes, no external dependencies
data          →  repositories (abstract + impl), DTOs, Supabase calls
```

**Dependency direction — downward only:**

```
presentation → application → data
presentation →    domain    ← data
```

**Key rules:**
- `domain` models are imported freely by all layers
- `presentation` never imports `data` directly
- `supabase_flutter` is only imported in `data/` layer files
- Business logic (locking, scoring, streaks) lives in Postgres — not Dart
- Repositories are the only decision-makers about which transport to use

### Services vs Repositories

| Class | Responsibility |
|---|---|
| **Repository** | Owns a data domain (tasks, groups). Returns domain models. |
| **Service** | Wraps an external system with no data domain (Supabase client init, analytics, notifications). |

Repositories receive the Supabase client via injection from `SupabaseService`.
They never call `Supabase.instance.client` directly.

---

## 4. Project Structure

```
lib/
├── main.dart                          # Entry point, dotenv + Supabase init
├── app.dart                           # MaterialApp.router, ProviderScope
│
└── src/
    ├── common_widgets/                # Shared UI: AppButton, ErrorCard, etc.
    ├── constants/                     # AppSizes, AppStrings
    ├── exceptions/                    # AppException sealed class
    ├── routing/
    │   ├── app_router.dart            # GoRouter instance + route definitions
    │   ├── app_routes.dart            # Path constants ('/tasks', '/auth/login')
    │   └── auth_guard.dart            # Redirect logic
    ├── services/                      # External system wrappers
    │   ├── supabase_service.dart      # Client init + keepAlive provider
    │   ├── analytics_service.dart
    │   └── notification_service.dart
    ├── utils/
    │   └── logger.dart                # AppLogger service
    │
    └── features/
        ├── auth/
        │   ├── data/
        │   │   ├── auth_repository.dart           # abstract interface
        │   │   └── supabase_auth_repository.dart
        │   ├── domain/
        │   │   └── app_user.dart
        │   └── presentation/
        │       ├── login_screen.dart
        │       ├── register_screen.dart
        │       └── sign_in_controller.dart
        │
        ├── tasks/
        │   ├── data/
        │   │   ├── task_repository.dart           # abstract interface
        │   │   ├── supabase_task_repository.dart
        │   │   └── task_dto.dart
        │   ├── domain/
        │   │   ├── task.dart                      # freezed model
        │   │   ├── task_template.dart             # freezed model
        │   │   ├── category.dart                  # freezed model
        │   │   └── complete_task_result.dart      # sealed result type
        │   └── presentation/
        │       ├── home_screen.dart
        │       ├── task_create_screen.dart
        │       ├── task_edit_screen.dart
        │       ├── tasks_list_controller.dart
        │       ├── task_create_controller.dart
        │       └── widgets/
        │           ├── task_card.dart
        │           ├── category_selector.dart
        │           └── points_badge.dart
        │
        ├── performance/
        │   ├── data/
        │   │   ├── performance_repository.dart
        │   │   └── supabase_performance_repository.dart
        │   ├── domain/
        │   │   ├── daily_performance.dart
        │   │   └── streak.dart
        │   └── presentation/
        │       ├── daily_progress_widget.dart
        │       └── streak_widget.dart
        │
        ├── groups/
        │   ├── data/
        │   │   ├── group_repository.dart
        │   │   └── supabase_group_repository.dart
        │   ├── domain/
        │   │   ├── group.dart
        │   │   └── group_member.dart
        │   └── presentation/
        │       ├── groups_screen.dart
        │       ├── group_detail_screen.dart
        │       ├── join_group_screen.dart
        │       ├── groups_controller.dart
        │       └── widgets/
        │           └── group_card.dart
        │
        └── leaderboard/
            ├── data/
            │   ├── leaderboard_repository.dart
            │   └── supabase_leaderboard_repository.dart
            ├── domain/
            │   └── leaderboard_entry.dart
            └── presentation/
                ├── leaderboard_screen.dart
                ├── leaderboard_controller.dart
                └── widgets/
                    ├── leaderboard_card.dart
                    └── time_window_selector.dart

test/                                  # Mirrors lib/src/features/ exactly
├── features/
│   ├── auth/
│   ├── tasks/
│   ├── performance/
│   ├── groups/
│   └── leaderboard/
├── common_widgets/
└── helpers/                           # Shared fakes and fixtures
    ├── fake_task_repository.dart
    └── task_fixtures.dart
```

---

## 5. Supabase Transport Layer

The repository decides which transport to use. Nothing above it should
know or care. Use each approach where it fits:

| Operation | Transport | Why |
|---|---|---|
| Simple reads and writes | SDK direct `.from().select()` | Fast, minimal overhead |
| Atomic / integrity-critical operations | Postgres RPC `.rpc()` | DB-level atomicity |
| Computed aggregates (leaderboard, streak, performance) | Postgres RPC `.rpc()` | Complex SQL runs close to data |
| External API / secret-dependent logic | Edge Function `.functions.invoke()` | Secrets stay server-side |
| Live updates | SDK Realtime | Built-in, no alternative |
| Auth | SDK Auth | Designed exactly for this |

### Operations by Transport

**SDK direct:**
- `getTasksForDate` — query `tasks` by `user_id` and `assigned_date`
- `createTask` — insert into `tasks`, return created row
- `deleteTask` — delete from `tasks` scoped to `user_id`
- `getCategories` — read all from `categories`
- `getProfile` — read from `profiles`
- `joinGroup` — insert into `group_members`

**Postgres RPC:**
- `complete_task` — validates lock + window, marks complete, awards points
- `uncomplete_task` — validates lock, reverts completion, revokes points
- `get_daily_performance` — completion rate and points for a date
- `get_streak` — current and longest streak
- `get_leaderboard` — ranked group leaderboard with tiebreaker
- `generate_template_instances` — creates task rows from a template
- `lock_expired_tasks` — scheduled job, locks overdue incomplete tasks

**Edge Functions:**
- `suggest-category` — sends task title to OpenAI, returns suggested category

---

## 6. Data Flow

### Reading Data

```
Widget
  └── ref.watch(tasksForDateProvider)
        └── SupabaseTaskRepository.getTasksForDate()
              └── _client.from('tasks').select()...
                    └── TaskDto(row).toDomain()
                          └── Task (domain model) → Widget renders
```

### Writing Data (Mutation)

```
Widget button tap
  └── ref.read(taskCreateControllerProvider.notifier).createTask(task)
        └── state = AsyncLoading()
        └── SupabaseTaskRepository.createTask(task)
              └── _client.from('tasks').insert(_toInsertMap(task)).select().single()
                    └── TaskDto(response).toDomain()
        └── state = AsyncData(void)
        └── ref.invalidate(tasksForDateProvider)
        └── ref.invalidate(dailyPerformanceProvider)
  └── ref.listen → context.pop() on success
                 → SnackBar on error
```

### DTOs — Boundary Enforcement

```
Supabase JSON
     │
     ▼
  TaskDto          ← data/ only. Knows about column names, type conversions
     │ .toDomain()
     ▼
   Task             ← domain/. Pure Dart. Used by all layers
     │
     ▼
 Controller         ← presentation/. Knows Task, not TaskDto
     │
     ▼
  Widget            ← renders Task properties
```

DTOs never cross the `data/` boundary. Controllers and widgets never
import a DTO class.

---

## 7. State Management

### Provider Type Decision

| Need | Type |
|---|---|
| Fetch data, no mutation | `@riverpod` async function |
| Mutation only | `AsyncNotifier<void>` |
| Load + mutate a resource | `AsyncNotifier<T>` |
| Synchronous UI state | `Notifier<T>` |
| Realtime stream | `@riverpod` stream function |
| Singleton (repo, service) | `@Riverpod(keepAlive: true)` |

### Key Providers

```dart
// Singleton — Supabase client
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(SupabaseClientRef ref) =>
    Supabase.instance.client;

// Singleton — repository
@Riverpod(keepAlive: true)
TaskRepository taskRepository(TaskRepositoryRef ref) =>
    SupabaseTaskRepository(ref.watch(supabaseClientProvider));

// Mutable UI state
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();
  void setDate(DateTime date) => state = date;
}

// Async data fetch
@riverpod
Future<List<Task>> tasksForDate(TasksForDateRef ref) async {
  final date   = ref.watch(selectedDateProvider);
  final userId = ref.watch(currentUserProvider).requireValue.uid;
  return ref.read(taskRepositoryProvider).getTasksForDate(userId, date);
}

// Mutation controller
@riverpod
class TaskCreateController extends _$TaskCreateController {
  @override
  FutureOr<void> build() {}

  Future<void> createTask(Task task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(taskRepositoryProvider).createTask(task),
    );
    if (!state.hasError) {
      ref.invalidate(tasksForDateProvider);
      ref.invalidate(dailyPerformanceProvider);
    }
  }
}
```

### ref.watch vs ref.read

- `ref.watch` — inside `build()` and provider body functions only
- `ref.read` — inside callbacks, event handlers, mutation methods
- Never `ref.watch` inside `if`, loops, or async gaps

### Invalidation After Mutations

| Mutation | Providers to invalidate |
|---|---|
| Create task | `tasksForDateProvider`, `dailyPerformanceProvider` |
| Complete task | `tasksForDateProvider`, `dailyPerformanceProvider`, `streakProvider` |
| Uncomplete task | `tasksForDateProvider`, `dailyPerformanceProvider`, `streakProvider` |
| Delete task | `tasksForDateProvider`, `dailyPerformanceProvider` |
| Join group | `leaderboardProvider` |

---

## 8. Recurring Tasks System

### Two-Table Design

**`task_templates`** — defines the pattern:
- `recurrence_type`: `'daily'`, `'weekly'`, or `'monthly'`
- `recurrence_interval`: integer, default 1
- `start_date`, `end_date` (nullable)
- Snapshot fields: `title`, `description`, `points`

**`tasks`** — actual instances:
- `template_id` nullable — `NULL` for standalone tasks
- Snapshot fields copied from template at generation time
- `UNIQUE(template_id, assigned_date)` prevents duplicates

### Generation Strategy

1. **On template creation:** generate instances synchronously from `start_date` through end of current month.
2. **Daily scheduled job (00:05 UTC):** generate for all active templates up to `today + 30 days`.
3. **Idempotent:** `ON CONFLICT DO NOTHING` makes the generator safe to run multiple times.

### Editing Rules

| Action | Effect |
|---|---|
| Edit this instance only | Update the `tasks` row directly. Template unchanged. |
| Edit this and future tasks | Close current template (`end_date = edit_date - 1`), create new template from `edit_date`. |
| Past instances | Never modified by template edits. User can edit a single past instance directly. |

### Flutter Implementation

```dart
// Domain models
@freezed
class TaskTemplate with _$TaskTemplate { ... }

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    String? templateId,          // null = standalone
    required String userId,
    required String title,
    String? description,
    required int points,
    required List<int> categoryIds,  // multiple categories
    required DateTime assignedDate,
    @Default(false) bool completed,
    DateTime? completedAt,
    @Default(false) bool isLocked,
    required DateTime createdAt,
  }) = _Task;
}
```

### Known Limitations (MVP)

- Recurrence supports `daily`, `weekly`, and `monthly` intervals only.
  Complex RRULE patterns (`BYDAY`, `UNTIL`, `COUNT`, `BYMONTHDAY`) are not
  supported. Unsupported patterns are rejected by the `recurrence_type`
  CHECK constraint at the DB level.
- The instance generator advances dates with simple arithmetic — it does
  not parse RRULE strings. If more complex recurrence patterns are needed
  in future, replace `generate_template_instances` with a proper RRULE
  engine at that point.

---

## 9. Auth Flow

Supabase Auth with email/password for MVP. OAuth providers added later.

```
App launch
    │
    ▼
Check auth.currentSession
    │
    ├── Session exists → /home
    └── No session → /auth/login
                          │
                    User signs in
                          │
                    authStateProvider updates
                          │
                    GoRouter redirect fires → /home
```

Profile is auto-created on signup via Postgres trigger.
Auth state is exposed as a `StreamProvider` watching `auth.onAuthStateChange`.

---

## 10. Routing

GoRouter with three files:

```dart
// app_routes.dart — path constants only
final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const tasks = '/tasks';
  static const timer = '/timer';
  static const profile = '/profile';
  static const taskCreate = '/tasks/create';
  static const taskEdit = '/tasks/edit';
}

// auth_guard.dart — redirect logic only
String? authGuard(BuildContext context, GoRouterState state, AsyncValue<User?> authState) {
  final isAuthenticated = authState.valueOrNull != null;
  final onAuthRoute = state.matchedLocation.startsWith('/auth');
  if (!isAuthenticated && !onAuthRoute) return AppRoutes.login;
  if (isAuthenticated && onAuthRoute)  return AppRoutes.home;
  return null;
}

// app_router.dart — GoRouter instance
@Riverpod(keepAlive: true)
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    redirect: (context, state) => authGuard(context, state, authState),
    routes: [...],
  );
}
```

Navigation rules:
- `context.go()` — replace current route (post-login, post-logout)
- `context.push()` — drill into a sub-screen
- Never `Navigator.push` for main app flows
- Main tabs (`/home`, `/tasks`, `/timer`, `/profile`) are hosted by a `StatefulShellRoute.indexedStack` so one floating bottom navigation bar stays mounted while only tab content changes

Main bottom navigation tabs (Crystal style):
- Home icon → `AppRoutes.home`
- Backlog icon → `AppRoutes.tasks`
- Timer icon → `AppRoutes.timer`
- Profile icon → `AppRoutes.profile`

---

## 11. Error Handling

Sealed `AppException` class in `src/exceptions/app_exception.dart`:

```dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class DatabaseException  extends AppException { ... }
class AuthAppException   extends AppException { ... }
class NetworkException   extends AppException { ... }
class UnknownException   extends AppException { ... }
```

`toUserMessage()` extension maps exceptions to user-friendly strings.
Raw Supabase/Postgres errors are never shown to users.

Every repository method catches `PostgrestException` and `AuthException`
and rethrows as `AppException` before the error reaches the controller.

### Error Propagation Chain

```
Repository     → catches PostgrestException / AuthException
               → rethrows as typed AppException

Controller     → AsyncValue.guard(() => repository.method())
               → state becomes AsyncError(AppException) on failure

Widget         → ref.listen(controllerProvider, (_, state) {
                   if (state.hasError) → show SnackBar via toUserMessage()
                 })
               → never access .value directly — always use .when()
```

This chain means:
- Widgets never see raw Supabase errors
- Controllers never write try/catch — `AsyncValue.guard()` handles it
- Every error surface is a typed `AppException` with a user-friendly message

---

## 12. Logging

`AppLogger` service in `src/utils/logger.dart`. One named logger per feature.

```dart
class AppLogger {
  AppLogger._(this._name);
  final String _name;

  static final auth        = AppLogger._('app.auth');
  static final tasks       = AppLogger._('app.tasks');
  static final performance = AppLogger._('app.performance');
  static final groups      = AppLogger._('app.groups');
  static final leaderboard = AppLogger._('app.leaderboard');
  static final routing     = AppLogger._('app.routing');

  void info(String message)  => dev.log(message, name: _name);
  void warning(String message) => dev.log(message, name: _name, level: 900);
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      dev.log(message, name: _name, level: 1000,
              error: error, stackTrace: stackTrace);
}
```

Usage: `AppLogger.tasks.info('Task created: $id')`
Never use `print()` or `dart:developer` directly.

---

## 13. Environment Configuration

Three environment files, never committed to git:

```
.env.dev      ← local Supabase instance
.env.staging  ← shared test environment
.env.prod     ← production
```

`.env.example` is committed — shows required keys with empty values:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

Loading in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.dev'); // switch per flavor
  await Supabase.initialize(
    url:     dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ProviderScope(child: App()));
}
```

---

## 14. AI Category Suggestion

Triggered client-side with 800ms debounce on the task title field.
Calls the `suggest-category` Supabase Edge Function which proxies to OpenAI.
The feature is **advisory only** — never blocks task creation.

```
User types title
    │
    ▼ (800ms debounce)
SupabaseTaskRepository.suggestCategory(title)
    │
    ▼
supabase.functions.invoke('suggest-category', body: {'title': title})
    │
    ▼
Edge Function → OpenAI → returns category name string
    │
    ▼
UI shows non-blocking suggestion chip
User accepts or dismisses
```

Failures in `suggestCategory` are caught silently — the UI never shows
an error for this feature.

---

## 15. Realtime

Used for live leaderboard updates when group members complete tasks.
Implemented as `StreamProvider` with channel cleanup on dispose.

```dart
@riverpod
Stream<List<LeaderboardEntry>> leaderboardStream(
  LeaderboardStreamRef ref,
  String groupId,
) {
  return ref.read(leaderboardRepositoryProvider).watchGroup(groupId);
}
```

Repository manages the channel lifecycle:

```dart
Stream<List<LeaderboardEntry>> watchGroup(String groupId) {
  final controller = StreamController<List<LeaderboardEntry>>();
  final channel = _client
      .channel('leaderboard_$groupId')
      .onPostgresChanges(
        event:    PostgresChangeEvent.update,
        schema:   'public',
        table:    'tasks',
        callback: (_) async {
          final entries = await getLeaderboard(groupId, start, end);
          controller.add(entries);
        },
      )
      .subscribe();

  controller.onCancel = () => channel.unsubscribe();
  return controller.stream;
}
```

---

## 16. Time Zones

All timestamps in the database are stored as `TIMESTAMPTZ` (UTC).
`assigned_date` is a `DATE` column — it has no timezone component.

### Decision for MVP

`assigned_date` is interpreted as the **user's local calendar date**.
The Flutter client sends the local date as `'yyyy-MM-dd'` and the server
treats it as-is. No timezone conversion happens at the DB level.

### Known Drift

The Postgres scheduled jobs (`lock_expired_tasks`, `generate_template_instances`)
run at UTC midnight. Users in UTC+ timezones will experience drift between
their local midnight and when jobs execute:

| Scenario | Impact |
|---|---|
| User in UTC+12 completes a task at 11pm local (= next UTC day) | Completion counted toward tomorrow's date in streak/performance |
| Locking job fires at 00:00 UTC | Tasks may lock before the user's local day has ended |
| Generation job fires at 00:05 UTC | Next-day instances appear earlier than local midnight for UTC+ users |

### Accepted for MVP

This drift is acceptable at launch. The fix for a future version is to
store user timezone in `profiles` and pass it to RPCs:

```sql
-- Future RPC signature
get_streak(p_user_id UUID, p_timezone TEXT DEFAULT 'UTC')

-- Inside the function
v_today := (NOW() AT TIME ZONE p_timezone)::DATE;
```

The Flutter client would pass `DateTime.now().timeZoneName` or a stored
preference. No schema change is needed — only RPC signature updates.

---

## 17. Adaptive Layout

Three breakpoints used consistently across the app:

| Breakpoint | Width | Layout |
|---|---|---|
| Mobile | < 600px | `BottomNavigationBar`, single column |
| Tablet | 600–900px | `NavigationRail`, adaptive grid |
| Desktop | > 900px | `NavigationDrawer`, multi-column, max-width constrained |

Content max width on desktop: `800px` via `ConstrainedBox`.

Use `LayoutBuilder` for widget-level decisions, `MediaQuery.sizeOf(context)`
for screen-level decisions. Never hardcode pixel breakpoints inline — always
use the `Breakpoints` constants class.

---

## 18. Testing Strategy

Test folder mirrors `lib/src/features/` exactly.

| Layer | Type | Tool |
|---|---|---|
| `data/` repository | Unit with `FakeRepository` | `mocktail` |
| `domain/` models | Unit | `package:test` |
| `application/` services | Unit with fake repos | `mocktail` |
| `presentation/` controllers | Unit with `ProviderContainer` | `flutter_riverpod` |
| `presentation/` widgets | Widget with `ProviderScope` overrides | `flutter_test` |
| Full flows | Integration | `integration_test` |

Key testing rules:
- Never mock Riverpod providers directly — use `ProviderScope` overrides
- Prefer `FakeRepository` (in-memory) over `mocktail` mocks
- Always test error paths, not just happy paths
- Shared fixtures live in `test/helpers/`
- Arrange-Act-Assert structure in every test

---

## 19. Code Generation

Three packages share one `build_runner` pipeline:

| Annotation | Package |
|---|---|
| `@freezed` | `freezed` |
| `@JsonSerializable` | `json_serializable` |
| `@riverpod` | `riverpod_generator` |

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

Rules:
- Never edit `.g.dart` or `.freezed.dart` files manually
- Every `@riverpod` file needs `part 'filename.g.dart'`
- Every `@freezed` model with `fromJson` needs both part files
- Run after any change to an annotated file before testing

---

## 20. Implementation Roadmap

### Phase 1 — Foundation (Week 1–2)
- [ ] Flutter project scaffold — folder structure, placeholder files
- [ ] Supabase local setup — migrations, seed, verify schema
- [ ] Environment config — dotenv, flavors
- [ ] Auth screens — login, register
- [ ] Profile auto-creation trigger
- [ ] GoRouter setup with auth guard
- [ ] AppLogger, AppException, SupabaseService

### Phase 2 — Core Task System (Week 3–4)
- [ ] Categories — read from DB, display in UI
- [ ] Task creation — form, validation, SDK insert
- [ ] Task list — home screen, date picker, daily view
- [ ] Task completion — `complete_task` RPC
- [ ] Task un-completion — `uncomplete_task` RPC
- [ ] Task locking — read `is_locked` from DB, disable actions
- [x] Daily performance widget — `get_daily_performance` RPC

### Phase 3 — Motivation Layer (Week 5)
- [x] Streak display — `get_streak` RPC
- [ ] Points accumulation display
- [ ] AI category suggestion — Edge Function + debounce
- [ ] Recurring tasks — template creation, instance generation

### Phase 4 — Social / Groups (Week 6–7)
- [ ] Group creation and invite code join
- [ ] Leaderboard screen — `get_leaderboard` RPC
- [ ] Time window selector (Today, Week, Month, Custom)
- [ ] Realtime leaderboard updates

### Phase 5 — Adaptive UI (Week 8)
- [ ] Breakpoint system — mobile, tablet, desktop layouts
- [ ] Navigation pattern switching per breakpoint
- [ ] Content width constraints on web
- [ ] Web-specific hover states and scrollbars

### Phase 6 — Polish & Quality (Week 9–10)
- [ ] Unit + widget + integration tests
- [ ] Error handling audit — all paths covered
- [ ] Empty state screens
- [ ] Light/dark theme
- [ ] Performance profiling
- [ ] Accessibility audit

---

## Appendix: Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case` | `task_create_controller.dart` |
| Classes | `PascalCase` | `SupabaseTaskRepository` |
| Abstract interfaces | plain noun | `TaskRepository` |
| Supabase implementations | `Supabase` prefix | `SupabaseTaskRepository` |
| Riverpod providers | `camelCaseProvider` | `taskRepositoryProvider` |
| Controllers | `FeatureActionController` | `TaskCreateController` |
| DTOs | `EntityDto` | `TaskDto` |
| Domain models | plain noun | `Task`, `Category`, `Group` |
| Services | `NameService` | `SupabaseService`, `AnalyticsService` |
| Postgres functions | `snake_case` | `complete_task` |
| Edge Functions | `kebab-case` | `suggest-category` |
| DB tables | `snake_case` | `task_categories` |
| DB columns | `snake_case` | `assigned_date` |
