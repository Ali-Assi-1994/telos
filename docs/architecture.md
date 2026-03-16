# Architecture
# Productivity & Accountability App
# @-mention this file when working across multiple layers or features

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Layer Architecture](#2-layer-architecture)
3. [Feature Map](#3-feature-map)
4. [Data Flow](#4-data-flow)
5. [Supabase Transport Decisions](#5-supabase-transport-decisions)
6. [Recurring Tasks Architecture](#6-recurring-tasks-architecture)
7. [Auth Architecture](#7-auth-architecture)
8. [Dependency Rules](#8-dependency-rules)
9. [Cross-Feature Dependencies](#9-cross-feature-dependencies)
10. [Key Architectural Decisions](#10-key-architectural-decisions)

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                              │
│                                                                 │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐   │
│   │   Mobile     │   │     Web      │   │  Desktop (future)│   │
│   │ iOS/Android  │   │  Responsive  │   │                  │   │
│   └──────────────┘   └──────────────┘   └──────────────────┘   │
│                                                                 │
│   State: Riverpod    Navigation: GoRouter    Models: Freezed    │
└────────────────────────────┬────────────────────────────────────┘
                             │  Supabase Flutter SDK
┌────────────────────────────▼────────────────────────────────────┐
│                         Supabase                                │
│                                                                 │
│  ┌──────────┐  ┌──────────────┐  ┌──────────┐  ┌───────────┐  │
│  │   Auth   │  │  PostgreSQL  │  │ Realtime │  │  Storage  │  │
│  └──────────┘  └──────────────┘  └──────────┘  └───────────┘  │
│                                                                 │
│  ┌──────────────────────┐   ┌──────────────────────────────┐   │
│  │    Edge Functions    │   │     pg_cron Scheduled Jobs   │   │
│  │  suggest-category    │   │  lock_expired_tasks (00:00)  │   │
│  │  (OpenAI proxy)      │   │  generate_instances (00:05)  │   │
│  └──────────────────────┘   └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Architecture

Each feature contains up to four layers. Dependencies flow downward only.

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION                               │
│                                                                 │
│   Screens           Controllers          Widgets                │
│   ConsumerWidget    AsyncNotifier        StatelessWidget        │
│   ConsumerStateful  Notifier             ConsumerWidget         │
│                                                                 │
│   Knows about: domain models, providers                        │
│   Never imports: supabase_flutter, DTOs, repositories          │
└────────────────────────┬────────────────────────────────────────┘
                         │ reads domain models
                         │ calls repository via provider
┌────────────────────────▼────────────────────────────────────────┐
│                      APPLICATION (optional)                     │
│                                                                 │
│   Services — only created when a controller would otherwise     │
│   need to coordinate two or more repositories                   │
│                                                                 │
│   Example: TaskCompletionService                                │
│     coordinates TaskRepository + PerformanceRepository          │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                        DOMAIN                                   │
│                                                                 │
│   Freezed models     Extensions      Sealed result types        │
│   Task               CategoryX       CompleteTaskResult         │
│   TaskTemplate       TaskListX       UnompleteTaskResult        │
│   Category                                                      │
│                                                                 │
│   Pure Dart — zero external dependencies                        │
│   Imported freely by all layers                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                          DATA                                   │
│                                                                 │
│   Abstract Interface    Supabase Implementation    DTO          │
│   TaskRepository   →    SupabaseTaskRepository  +  TaskDto      │
│                                                                 │
│   Only layer that imports supabase_flutter                      │
│   Returns domain models — never DTOs                            │
│   Catches PostgrestException → rethrows AppException            │
└─────────────────────────────────────────────────────────────────┘
```

### What Lives Where

| Component | Layer | Example |
|---|---|---|
| Screen | Presentation | `TaskCreateScreen` |
| Controller | Presentation | `TaskCreateController` |
| Reusable widget | Presentation | `TaskCard`, `PointsBadge` |
| Read-only provider | Presentation | `tasksForDateProvider` |
| Service | Application | `TaskCompletionService` |
| Domain model | Domain | `Task`, `Category` |
| Result type | Domain | `CompleteTaskResult` |
| Domain extension | Domain | `CategoryX.flutterColor` |
| Abstract repo | Data | `TaskRepository` |
| Supabase impl | Data | `SupabaseTaskRepository` |
| DTO | Data | `TaskDto` |
| Repository provider | Data | `taskRepositoryProvider` |

---

## 3. Feature Map

Five functional features — organised by what the user does, not what they see.

```
src/features/
│
├── auth/                    "The user authenticates"
│   ├── data/                SupabaseAuthRepository
│   ├── domain/              AppUser
│   └── presentation/        LoginScreen, RegisterScreen
│                            SignInController
│
├── tasks/                   "The user manages tasks"
│   ├── data/                SupabaseTaskRepository
│   │                        TaskDto, TaskTemplateDto
│   ├── domain/              Task, TaskTemplate, Category
│   │                        CompleteTaskResult
│   └── presentation/        HomeScreen, TaskCreateScreen
│                            TaskEditScreen
│                            TasksListController
│                            TaskCreateController
│
├── performance/             "The user tracks progress"
│   ├── data/                SupabasePerformanceRepository
│   ├── domain/              DailyPerformance, Streak
│   └── presentation/        DailyProgressWidget
│                            StreakWidget
│
├── groups/                  "The user joins groups"
│   ├── data/                SupabaseGroupRepository
│   ├── domain/              Group, GroupMember
│   └── presentation/        GroupsScreen, GroupDetailScreen
│                            JoinGroupScreen
│                            GroupsController
│
└── leaderboard/             "The user competes"
    ├── data/                SupabaseLeaderboardRepository
    ├── domain/              LeaderboardEntry
    └── presentation/        LeaderboardScreen
                             LeaderboardController
                             TimeWindowSelector
```

### Shared Infrastructure

```
src/
├── common_widgets/          AppButton, ErrorCard, LoadingSkeleton
├── constants/               AppSizes, AppStrings
├── exceptions/              AppException (sealed)
├── routing/                 AppRouter, AppRoutes, AuthGuard
├── services/                SupabaseService, AnalyticsService
└── utils/                   AppLogger, DateUtils, Breakpoints
```

---

## 4. Data Flow

### Read Flow

```
Widget
  └── ref.watch(tasksForDateProvider)
        └── ref.watch(selectedDateProvider)     ← reactive dependency
        └── ref.read(taskRepositoryProvider)
              └── SupabaseTaskRepository
                    └── _client.from('tasks').select()...
                          └── [raw JSON rows]
                                └── TaskDto(row).toDomain()
                                      └── Task (domain model)
                                            └── Widget renders
```

### Write Flow (Mutation)

```
Widget button tap
  └── ref.read(taskCreateControllerProvider.notifier).createTask(task)
        └── state = AsyncLoading()
        └── AsyncValue.guard(() =>
              SupabaseTaskRepository.createTask(task)
                └── _client.from('tasks').insert(...).select().single()
                      └── TaskDto(response).toDomain()
                            └── Task returned
            )
        └── state = AsyncData(void)           ← success
            state = AsyncError(AppException)  ← failure

        └── On success:
              ref.invalidate(tasksForDateProvider)
              ref.invalidate(dailyPerformanceProvider)

Widget (via ref.listen)
  └── state.hasError → SnackBar(e.toUserMessage())
  └── !isLoading && !hasError → context.pop()
```

### RPC Flow

```
Widget
  └── ref.read(taskCompleteControllerProvider.notifier).complete(taskId)
        └── SupabaseTaskRepository.completeTask(taskId, userId)
              └── _client.rpc('complete_task', params: {...})
                    └── Postgres validates: lock, window, already completed
                          └── Returns { success, points } or { success: false, error }
                                └── CompleteTaskResult.success(points) or .failure(error)
        └── switch result {
              CompleteTaskSuccess → invalidate providers, show animation
              CompleteTaskFailure → show SnackBar with error
            }
```

---

## 5. Supabase Transport Decisions

```
                    ┌─────────────────────┐
                    │   Repository method  │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
        Simple CRUD      Atomic / RPC     External API /
        no integrity     integrity        secret-dependent
        rules            critical
              │                │                │
              ▼                ▼                ▼
        SDK direct        Postgres         Edge Function
        .from()           .rpc()           .functions.invoke()
        .select()                          (suggest-category)
        .insert()
        .update()
        .delete()
```

| Operation | Transport | Reason |
|---|---|---|
| Get tasks for date | SDK | Simple filter, no integrity rules |
| Create standalone task | SDK | Simple insert |
| Complete task | RPC | Lock check + window check + atomic |
| Uncomplete task | RPC | Lock check + points revocation + atomic |
| Get daily performance | RPC | Complex aggregation |
| Get streak | RPC | Multi-day calculation, server logic |
| Get leaderboard | RPC | Group aggregation, ranking logic |
| Generate template instances | RPC | Idempotent batch insert |
| Suggest category | Edge Function | OpenAI secret, external HTTP |
| Auth | SDK Auth | Purpose-built |
| Leaderboard updates | SDK Realtime | Live subscription |

---

## 6. Recurring Tasks Architecture

```
User creates recurring task
          │
          ▼
   TaskTemplate row created
   (recurrence_type, recurrence_interval, start_date)
          │
          ▼
   task_template_categories rows created
   (category snapshot)
          │
          ├──► Synchronous generation
          │    generate_template_instances(id, today, end_of_month)
          │    → Task rows for current month
          │    → task_categories rows (category snapshot)
          │
          └──► Daily job (00:05 UTC)
               generate_template_instances(id, today, today+30)
               → Rolls forward 30-day window


TaskTemplate
    id, user_id, title, description, points
    recurrence_type ('daily'|'weekly'|'monthly')
    recurrence_interval (int, default 1)
    start_date, end_date (nullable)
         │
         │ generates
         ▼
Task instances (template_id IS NOT NULL)
    id, template_id, user_id
    title ← snapshot     points ← snapshot
    assigned_date        completed, is_locked
         │
         └──► task_categories (category snapshot)


Standalone tasks (template_id IS NULL)
    id, user_id
    title, description, points (user input)
    assigned_date
         │
         └──► task_categories (user selection)
```

### Editing Decision Tree

```
User edits a recurring task
          │
          ▼
   ┌──────────────────────┐
   │  Edit this task only │──► Update tasks row directly
   └──────────────────────┘    Template unchanged
                               Past instances unaffected

   ┌──────────────────────────────────┐
   │  Edit this and future tasks      │
   └──────────────────────────────────┘
          │
          ▼
   Close current template
   old_template.end_date = edit_date - 1
          │
          ▼
   Create new template
   new_template.start_date = edit_date
   (with updated values)
          │
          ▼
   Generate instances from new template
   Past instances remain unchanged
```

---

## 7. Auth Architecture

```
App Launch
    │
    ▼
authStateProvider (StreamProvider)
    └── auth.onAuthStateChange stream
          │
          ▼
    GoRouter redirect (AuthGuard)
          │
          ├── session == null AND not on /auth → redirect /auth/login
          └── session exists AND on /auth     → redirect /home


Login flow:
    LoginScreen
        └── SignInController (AsyncNotifier<void>)
              └── SupabaseAuthRepository.signIn(email, password)
                    └── _client.auth.signInWithPassword(...)
                          └── Session created
                                └── authStateProvider emits new value
                                      └── GoRouter redirect fires → /home


Profile creation:
    New user signup
        └── auth.users row created
              └── on_auth_user_created trigger fires
                    └── profiles row auto-created
                          (username derived from metadata)
```

---

## 8. Dependency Rules

### Allowed Imports

```
presentation/ → domain/          ✅
presentation/ → other features' domain/  ✅ (via package imports)
application/  → data/            ✅
application/  → domain/          ✅
data/         → domain/          ✅
data/         → supabase_flutter ✅

presentation/ → data/            ❌
presentation/ → supabase_flutter ❌
domain/       → anything external ❌  (pure Dart only)
data/ DTOs    → presentation/    ❌  (DTOs never leave data/)
```

### Import Style

```dart
// Within the same feature — relative imports
import '../domain/task.dart';
import '../../data/task_repository.dart';

// Crossing feature boundaries — package imports
import 'package:my_app/src/features/auth/domain/app_user.dart';
```

A package import signals a cross-feature dependency.
If you see many package imports inside one feature, consider whether
the shared model belongs in `common_widgets/` or a shared domain area.

---

## 9. Cross-Feature Dependencies

```
leaderboard ──────────────► groups
(needs group members)       (owns Group, GroupMember)

performance ──────────────► tasks
(queries tasks table)       (owns Task)

tasks ────────────────────► auth
(scoped to user_id)         (owns AppUser)

groups ───────────────────► auth
(scoped to user_id)         (owns AppUser)

leaderboard ──────────────► auth
(shows user profiles)       (owns AppUser)
```

These dependencies go in one direction only.
`auth` and `tasks` are the two most-depended-upon features.
Neither depends on any other feature.

---

## 10. Key Architectural Decisions

### Decision 1 — Business logic lives in Postgres, not Dart

**Why:** Task completion, locking, streak calculation, and leaderboard ranking
involve multiple rows, integrity checks, and atomic operations. Postgres
functions guarantee atomicity and cannot be bypassed by any client. Dart
implementations would need to be kept in sync and could be circumvented.

**Impact:** Flutter calls `.rpc()` for these operations and trusts the result.
Never re-implement RPC logic in Dart.

---

### Decision 2 — Abstract repository interface always required

**Why:** The abstract interface is what makes features testable. `FakeTaskRepository`
implements `TaskRepository` — not `SupabaseTaskRepository`. If the concrete
class is used directly, tests require a real Supabase connection.

**Impact:** Every feature has `task_repository.dart` (abstract) and
`supabase_task_repository.dart` (concrete). The provider returns the abstract type.

---

### Decision 3 — DTOs never leave the data layer

**Why:** DTOs know about Supabase column names, JSON shapes, and type conversions.
If a DTO reaches a controller or widget, Supabase concerns have leaked into
the presentation layer. Changing a column name would then require changes
across multiple layers.

**Impact:** Every repository method calls `.toDomain()` before returning.
Controllers and widgets only ever see domain models.

---

### Decision 4 — Recurring tasks use pre-generated rows

**Why:** Virtual recurrence (computing occurrences client-side) would make
the `tasks` table incomplete. The streak RPC, leaderboard RPC, and
daily performance RPC all query real `tasks` rows. If instances don't
exist as rows, these calculations are wrong.

**Impact:** Two tables (`task_templates` + `tasks`), a generation RPC,
and a daily scheduled job. Snapshot fields preserve historical accuracy.

---

### Decision 5 — Leaderboard ranked by points, completion rate as tiebreaker

**Why:** Completion rate as the primary ranking metric can be gamed —
a user who assigns 2 tasks and completes both ranks above someone who
assigns 10 tasks and completes 9. Points reflect actual effort and
cannot be inflated by reducing task volume.

**Impact:** `get_leaderboard` RPC orders by `earned_points DESC, completion_rate DESC`.

---

### Decision 6 — Multiple categories per task

**Why:** A task like "Run 5km" naturally belongs to both Health and Fitness.
Forcing a single category either loses information or requires an arbitrary
choice. Junction tables (`task_categories`, `task_template_categories`)
handle this cleanly.

**Impact:** No `category_id` column on `tasks`. All category associations
go through junction tables. DTOs must join and collect category IDs.

---

### Decision 7 — Time zones deferred to post-MVP

**Why:** Timezone-aware streak and performance calculations require storing
user timezone preferences and passing them to every RPC. The complexity
is not justified for MVP where the user base is small.

**Impact:** `assigned_date` is sent as the user's local date string.
Postgres scheduled jobs run at UTC midnight — up to ~12h drift for
UTC+ users. Documented as a known limitation with a clear migration path.
