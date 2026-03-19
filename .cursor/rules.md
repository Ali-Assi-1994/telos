# Cursor Rules — Productivity & Accountability App

# Stack: Flutter · Supabase · Riverpod (Bizzotto Feature-first Architecture)

# Reference: https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/

---

## Role & Context

You are an expert Flutter/Dart engineer building a cross-platform productivity
app (mobile + web). The backend is Supabase, state management is Riverpod with
code generation, and navigation uses GoRouter. The architecture follows Andrea
Bizzotto's feature-first Riverpod architecture with four layers per feature:
**data → domain → application (optional) → presentation**.

Before writing any code, identify which layer and which feature the change
belongs to. Never put business logic in widgets. Never put UI concerns in
repositories.

Product-specific validation rules, UX constraints, and domain logic are in
BUSINESS_RULES.md — @-mention it when working on feature-specific logic.

---

## Architecture Overview

Four layers, applied **per feature** (not globally):

```
presentation  →  widgets + AsyncNotifier controllers
application   →  services (optional, only when logic spans multiple repos)
domain        →  pure Dart model classes (immutable, no dependencies)
data          →  repositories (abstract + impl), DTOs, Supabase datasource
```

Dependencies flow **downward only**:

```
presentation → application → data
presentation →    domain    ← data
```

- `domain` models are imported freely by all layers.
- `presentation` never imports `data` directly — only through `domain` models
  and repository providers.
- `application` services exist only when a controller would otherwise need to
  coordinate two or more repositories.

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                        # MaterialApp.router, ProviderScope
│
├── src/
│   ├── common_widgets/             # Truly shared UI: AppButton, ErrorCard, etc.
│   ├── constants/                  # AppSizes, AppStrings
│   ├── exceptions/                 # AppException sealed class
│   ├── routing/
│   │   ├── app_router.dart         # GoRouter instance and route definitions
│   │   ├── app_routes.dart         # Route path constants ('/tasks', '/auth/login')
│   │   └── auth_guard.dart         # Redirect logic
│   ├── services/                   # External system wrappers (no data domain)
│   │   ├── supabase_service.dart   # Client init, connection state
│   │   ├── analytics_service.dart
│   │   └── notification_service.dart
│   ├── utils/                      # Date helpers, string extensions, AppLogger
│   │
│   └── features/
│       │
│       ├── auth/                   # "What the user does: authenticate"
│       │   ├── data/
│       │   │   ├── auth_repository.dart        # abstract interface
│       │   │   └── supabase_auth_repository.dart
│       │   ├── domain/
│       │   │   └── app_user.dart
│       │   └── presentation/
│       │       ├── login_screen.dart
│       │       ├── register_screen.dart
│       │       └── sign_in_controller.dart     # AsyncNotifier subclass
│       │
│       ├── tasks/                  # "What the user does: manage tasks"
│       │   ├── data/
│       │   │   ├── task_repository.dart        # abstract interface
│       │   │   ├── supabase_task_repository.dart
│       │   │   └── task_dto.dart               # raw Supabase JSON → domain
│       │   ├── domain/
│       │   │   ├── task.dart                   # freezed model
│       │   │   └── category.dart               # freezed model
│       │   └── presentation/
│       │       ├── home_screen.dart
│       │       ├── task_create_screen.dart
│       │       ├── task_edit_screen.dart
│       │       ├── tasks_list_controller.dart  # AsyncNotifier
│       │       ├── task_create_controller.dart # AsyncNotifier
│       │       └── widgets/
│       │           ├── task_card.dart
│       │           ├── category_selector.dart
│       │           └── points_badge.dart
│       │
│       ├── performance/            # "What the user does: track progress"
│       │   ├── data/
│       │   │   ├── performance_repository.dart
│       │   │   └── supabase_performance_repository.dart
│       │   ├── domain/
│       │   │   ├── daily_performance.dart      # freezed model
│       │   │   └── streak.dart                 # freezed model
│       │   └── presentation/
│       │       ├── daily_progress_widget.dart
│       │       └── streak_widget.dart
│       │
│       ├── groups/                 # "What the user does: join groups"
│       │   ├── data/
│       │   │   ├── group_repository.dart
│       │   │   └── supabase_group_repository.dart
│       │   ├── domain/
│       │   │   ├── group.dart
│       │   │   └── group_member.dart
│       │   └── presentation/
│       │       ├── groups_screen.dart
│       │       ├── group_detail_screen.dart
│       │       ├── join_group_screen.dart
│       │       ├── groups_controller.dart
│       │       └── widgets/
│       │           └── group_card.dart
│       │
│       └── leaderboard/            # "What the user does: compete"
│           ├── data/
│           │   ├── leaderboard_repository.dart
│           │   └── supabase_leaderboard_repository.dart
│           ├── domain/
│           │   └── leaderboard_entry.dart
│           └── presentation/
│               ├── leaderboard_screen.dart
│               ├── leaderboard_controller.dart
│               └── widgets/
│                   ├── leaderboard_card.dart
│                   └── time_window_selector.dart

test/                               # Mirrors lib/src/features/ exactly
├── features/
│   ├── auth/
│   ├── tasks/
│   ├── performance/
│   ├── groups/
│   └── leaderboard/
└── common_widgets/
```

### What counts as a "feature"?

Features are **functional areas** (what the user does), not UI screens.
Do not create a feature folder for every screen.

```
✅  tasks/          — the user manages their tasks
✅  auth/           — the user authenticates
✅  leaderboard/    — the user competes with a group
✅  performance/    — the user tracks their daily progress

❌  home_screen/    — that's a UI concern, not a feature
❌  task_list_page/ — that belongs inside tasks/presentation/
```

### Services vs Repositories

- **Repositories** own a data domain (tasks, groups). They return domain models.
- **Services** wrap external systems with no data domain of their own
  (analytics, notifications, Supabase client initialisation).
- Repositories receive the Supabase client via injection from `SupabaseService`.
  They never call `Supabase.instance.client` directly.

### When to use the application layer

Only create `application/` inside a feature when a controller would otherwise
need to coordinate two or more repositories. For MVP, most features won't
need it.

```
// application/ IS needed when:
// TaskCompletionService coordinates TaskRepository + PerformanceRepository

// application/ is NOT needed when:
// A controller only calls one repository
```

---

## Environment Configuration

Use `flutter_dotenv` for environment-specific config. Never hardcode keys.

```
.env.dev      # local Supabase instance
.env.staging  # shared test environment
.env.prod     # production
```

- All `.env*` files must be listed in `.gitignore` — never commit secrets.
- Load the correct file in `main.dart` based on the build flavor.
- Access values via `dotenv.env['KEY']` — never via a hardcoded constants file.

---

## The Data Layer

### Repository Pattern: Always Abstract + Concrete

Every repository must have an abstract interface and a Supabase implementation.
This makes features testable with fakes.

```dart
// tasks/data/task_repository.dart  <- abstract interface
abstract class TaskRepository {
}

// tasks/data/supabase_task_repository.dart  <- concrete implementation
class SupabaseTaskRepository implements TaskRepository {
}
```

### DTOs

- DTOs are allowed only in the `data/` layer.
- DTOs convert raw API/database JSON into domain models.
- Repositories always return domain models, never DTOs — conversion happens
  inside the repository before returning.
- Controllers and widgets must never import or reference a DTO class.

### Supabase-specific rules

- Always call business operations via `.rpc()` — never raw `.update()` for
  state changes that have server-side rules (locking, scoring, date checks).
- Serialize `DATE` columns as `'yyyy-MM-dd'` strings, never full ISO-8601.
- Catch `PostgrestException` and `AuthException`; rethrow as `AppException`.
- Never import `supabase_flutter` outside the `data/` layer.

```dart
// Correct date serialization
'assigned_date
'
: date.toIso8601String().split('T').first,

// Wrong — includes time and timezone offset
'assigned_date': date.toIso8601String
(
)
,
```

---

## Supabase Transport Layer

The repository decides which transport to use — nothing above it should know
or care. Use each approach where it fits:

| Operation                                                             | Transport                           | Why                                              |
|-----------------------------------------------------------------------|-------------------------------------|--------------------------------------------------|
| Simple reads and writes (tasks, profiles)                             | SDK direct `.from().select()`       | Fast, real-time capable, minimal overhead        |
| Atomic or integrity-critical operations (complete task, lock tasks)   | Postgres RPC `.rpc()`               | DB-level atomicity, cannot be bypassed           |
| Computed aggregates (leaderboard, streak, daily performance)          | Postgres RPC `.rpc()`               | Complex SQL runs close to the data               |
| External API calls or secret-dependent logic (AI category suggestion) | Edge Function `.functions.invoke()` | Secrets stay server-side, supports external HTTP |
| Live updates (leaderboard, task changes)                              | SDK Realtime                        | Built-in, no alternative                         |
| Auth (sign in, sign up, sign out)                                     | SDK Auth                            | Designed exactly for this                        |

Rules:

- Simple reads and writes → Supabase Flutter SDK.
- Atomic or integrity-critical operations → Postgres RPC.
- External API calls or secret-dependent logic → Edge Functions.
- The repository is the only class that decides which transport to use.
- Controllers call repository methods — they never know which transport was used.

---

## The Domain Layer

Domain models are **pure Dart**. They have zero dependencies on Supabase,
Flutter, or any third-party package except `freezed`/`json_serializable`.

Rules for domain models:

- Always `freezed` — immutable, `==`, `copyWith`, pattern matching for free.
- No `BuildContext`, no `SupabaseClient`, no repository references.
- No business logic methods — that belongs in services or repositories.
- Can be imported by any layer.

---

## The Presentation Layer

### Controllers: Always AsyncNotifier

Controllers mediate between widgets and repositories/services. They manage
widget state and perform async mutations. Always use `@riverpod` generator
syntax.

```dart
// tasks/presentation/task_create_controller.dart
part 'task_create_controller.g.dart';

@riverpod
class TaskCreateController extends _$TaskCreateController {
  @override
  FutureOr<void> build() {
    // Initial state is void — this is a mutation-only controller
  }

  Future<void> createTask(Task task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(taskRepositoryProvider).createTask(task),
    );
  }
}
```

**When to use which base class:**

| Base class            | Use case                                            |
|-----------------------|-----------------------------------------------------|
| `AsyncNotifier<void>` | Mutation-only (create, complete, delete)            |
| `AsyncNotifier<T>`    | Load + mutate a single resource                     |
| `Notifier<T>`         | Synchronous UI state (selected date, active filter) |

**Read-only data providers** use plain `@riverpod` functions, no class needed:

```dart
@riverpod
Future<List<Task>> tasksForDate(TasksForDateRef ref) async {
  final date = ref.watch(selectedDateProvider);
  final userId = ref
      .watch(currentUserProvider)
      .requireValue
      .uid;
  return ref.read(taskRepositoryProvider).getTasksForDate(userId, date);
}
```

### ConsumerWidget vs ConsumerStatefulWidget

Default to `ConsumerWidget`. Only use `ConsumerStatefulWidget` when you need
lifecycle methods (`initState`, `dispose`) or an `AnimationController`.

### Listening for side effects

Use `ref.listen` for navigation and snackbars after mutations, not `ref.watch`.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(taskCreateControllerProvider, (_, state) {
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toUserMessage())),
      );
    }
    if (!state.isLoading && !state.hasError) {
      context.pop();
    }
  });
  ...
}
```

### Always handle all three AsyncValue states

```dart
ref.watch
(
tasksForDateProvider).when(
data: (tasks) => TaskListWidget(tasks: tasks),
loading: () => const TaskListSkeleton(),
error: (e, _) => ErrorCard(message: e.
toUserMessage
(
)
)
,
);
```

### Private widget classes, not helper methods

```dart
// Correct
class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) =>

  ...;
}

// Wrong
Widget _buildPointsBadge(int points) =>
...;
```

---

## Riverpod Provider Rules

### Always use @riverpod code generation — never manual providers

```dart
// Correct
@riverpod
Future<List<Task>> tasksForDate(TasksForDateRef ref) async {
  ...
}

// Wrong — never write manual providers
final tasksProvider = Provider<List<Task>>((ref) => []);
final tasksProvider = FutureProvider<List<Task>>((ref) async => []);
```

### Repository providers live alongside their implementation

```dart
// tasks/data/supabase_task_repository.dart

@Riverpod(keepAlive: true)
TaskRepository taskRepository(TaskRepositoryRef ref) =>
    SupabaseTaskRepository(ref.watch(supabaseClientProvider));
```

Use `keepAlive: true` for repositories and services — they are singletons.
All other providers use default auto-dispose.

### Supabase client provider lives in services

```dart
// src/services/supabase_service.dart

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(SupabaseClientRef ref) =>
    Supabase.instance.client;
```

### ref.watch vs ref.read

- `ref.watch` — inside `build()` and provider body functions only.
- `ref.read` — inside callbacks, event handlers, and async mutation methods.
- Never call `ref.watch` inside `if`, loops, or async gaps.

### Invalidation after mutations

```dart
Future<void> completeTask(String taskId) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(
        () => ref.read(taskRepositoryProvider).completeTask(taskId, _userId),
  );
  if (!state.hasError) {
    ref.invalidate(tasksForDateProvider);
    ref.invalidate(dailyPerformanceProvider);
    ref.invalidate(streakProvider);
  }
}
```

### select() to limit rebuilds

```dart
// Rebuilds only when task count changes, not on any field mutation
final count = ref.watch(
  tasksForDateProvider.select((v) => v.valueOrNull?.length ?? 0),
);
```

---

## Code Generation

- Never edit `.g.dart` or `.freezed.dart` files manually.
- Every `@riverpod` file needs `part 'filename.g.dart'`.
- Every `@freezed` model with `fromJson` needs both part files.
- Run: `dart run build_runner build --delete-conflicting-outputs`

---

## Error Handling

- Use the `AppException` sealed class in `src/exceptions/app_exception.dart`.
- Catch `PostgrestException` and `AuthException` in repositories; rethrow as `AppException`.
- Never expose raw Supabase/Postgres error messages to the UI.
- Use `.toUserMessage()` extension for all user-facing error strings.

---

## Business Logic — Where It Lives

| Rule type                      | Where it lives                 | Why                                |
|--------------------------------|--------------------------------|------------------------------------|
| Data integrity, atomic updates | Postgres RPC                   | Cannot be bypassed by any client   |
| Cross-record consistency       | Postgres RPC                   | Requires DB transaction guarantees |
| UI and form validation         | Dart — form/controller layer   | Immediate feedback, no round trip  |
| Presentation logic             | Dart — controller              | Belongs with the UI it serves      |
| Computed display values        | Dart — domain model extensions | Pure and testable                  |

- Never duplicate in Dart a rule that already exists in Postgres — they will drift.
- Never push UI validation or presentation logic into Postgres.

---

## Routing

- GoRouter config lives in `src/routing/app_router.dart`.
- Route path constants live in `src/routing/app_routes.dart`.
- Auth redirect logic lives in `src/routing/auth_guard.dart`, not inline in the router.
- `context.go()` for replacing routes, `context.push()` for drilling in.
- Never use `Navigator.push` for main app flows.

---

## Naming Conventions

| Element                  | Convention                | Example                               |
|--------------------------|---------------------------|---------------------------------------|
| Files                    | `snake_case`              | `task_create_controller.dart`         |
| Classes                  | `PascalCase`              | `SupabaseTaskRepository`              |
| Abstract interfaces      | plain noun                | `TaskRepository`                      |
| Supabase implementations | `Supabase` prefix         | `SupabaseTaskRepository`              |
| Riverpod providers       | `camelCaseProvider`       | `taskRepositoryProvider`              |
| Controllers              | `FeatureActionController` | `TaskCreateController`                |
| DTOs                     | `EntityDto`               | `TaskDto`                             |
| Domain models            | plain noun                | `Task`, `Category`, `Group`           |
| Services                 | `EntityService`           | `SupabaseService`, `AnalyticsService` |

---

## Imports

- Use **relative imports** within the same feature.
- Use **package imports** when crossing feature boundaries.

```dart
// Within the same feature — relative
import '../domain/task.dart';
import '../../data/task_repository.dart';

// Crossing feature boundaries — package
import 'package:my_app/src/features/auth/domain/app_user.dart';
```

A package import is a signal that you are crossing a feature boundary.
If you see many package imports inside one feature, consider whether a
shared domain model belongs in `common_widgets/` or a shared `domain/` area.

---

## Theming

All colors come from `Theme.of(context).colorScheme`. Never hardcode
`Colors.*` values in widgets. Support both light and dark modes.
All `ThemeData` config lives in `app.dart`.

```dart
// Correct
color: Theme.of
(
context).colorScheme.primary,

// Wrong
color: Colors.blue
,
```

Category colors (stored as hex strings in Supabase) are parsed in a domain
layer extension — the only place color hex-to-Color conversion happens:

```dart
extension CategoryX on Category {
  Color get flutterColor {
    final hex = (color ?? 'FF9E9E9E').replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
```

---

## Testing

Test folder mirrors `lib/src/features/` exactly.

| Layer                       | Test type                           | Tool               |
|-----------------------------|-------------------------------------|--------------------|
| `data/` repository          | Unit with fake Supabase             | `mocktail`         |
| `domain/` models            | Unit                                | `package:test`     |
| `application/` services     | Unit with fake repos                | `mocktail`         |
| `presentation/` controllers | Unit with fake repos                | `mocktail`         |
| `presentation/` widgets     | Widget with ProviderScope overrides | `flutter_test`     |
| Full flows                  | Integration                         | `integration_test` |

### ProviderScope overrides in widget tests

```dart
testWidgets
('task card shows completed checkmark
'
, (tester) async {
await tester.pumpWidget(
ProviderScope(
overrides: [
tasksForDateProvider.overrideWith((_) async => [completedTask]),
],
child: const MaterialApp(home: HomeScreen()),
),
);
expect(find.byIcon(Icons.check_circle), findsOneWidget);
});
```

### Prefer fake repositories over mocks

- Implement the abstract repository interface as a fake with in-memory state.
- Only use `mocktail` when a full fake is disproportionate to the test.

---

## Logging

- Never use `print()` or `dart:developer` directly.
- Always use `AppLogger.<feature>.info` / `.warning` / `.error()`.
- `AppLogger` is defined in `src/utils/logger.dart`.

---

## Cursor-Specific Code Generation Rules

- **Always output complete Dart files.** Include all imports, class definitions,
  part statements, and annotations. Never write partial files or placeholder
  `// TODO` stubs unless explicitly asked.
- **Always use `@riverpod` code generation.** Never write manual provider
  constructors (`Provider(...)`, `FutureProvider(...)`, etc.).
- **Before generating any file, state which feature and layer it belongs to
  and confirm the full file path.** Place the file inside the correct feature
  folder based on the architecture described above.

---

## Hard Rules — Never Violate

- Never import `supabase_flutter` outside the `data/` layer.
- Never call `Supabase.instance.client` directly in a repository — receive
  the client via injection from `SupabaseService`.
- Never write a manual Riverpod provider — always use `@riverpod` generation.
- Never use `setState` for anything beyond ephemeral local widget state.
- Never use `print()` or `dart:developer` directly — always use `AppLogger.<feature>`.
- Never access `.value` on an `AsyncValue` without guarding loading/error.
- Never call `ref.watch` inside a callback, event handler, or async function.
- Never name a feature folder after a screen (`login_page/`, `home_screen/`).
- Never skip the abstract repository interface — fakes in tests require it.
- Never manually edit `.g.dart` or `.freezed.dart` files.
- Never hardcode `Colors.*` values in widgets.
- Never hardcode environment keys — always use `flutter_dotenv`.
- Never commit `.env*` files — they must be in `.gitignore`.
- Never let a DTO cross the `data/` layer boundary — repositories return
  domain models only.
- Never duplicate in Dart a data integrity rule that already exists in Postgres.
- Never watch an entire provider when only one field is needed — use
  `ref.watch(provider.select(...))`.

### Logos & Icon Assets

- Never use `CustomPainter` to draw logos, brand icons, or product icons unless explicitly asked to do so.
- Logos and brand icons must come from image or SVG assets, or from standard `Icon` data where appropriate.
- When design-specific logo/icon assets cannot be fetched programmatically, ask the user to provide the asset files (SVG/PNG) and wire them in as Flutter assets.

---

## UI Composition & Analysis Rules

- **Split large widgets into smaller components**
  - Any screen widget that grows beyond ~150–200 lines must be refactored into private widgets (e.g. `_Header`, `_FormSection`, `_Footer`) rather than one giant `build` method.
  - Prefer small, focused `StatelessWidget`/`ConsumerWidget` components over helper methods for complex sections of UI.
  - Keep layout readable: break Banani/figma-style screens into logical sections (header, body, footer, etc.).

- **Always run `dart analyze` and fix issues after changes**
  - After any non-trivial code change, run `dart analyze` and fix all errors and reasonable lints before considering the work done.
  - Treat analyzer warnings like TODOs: either fix them or consciously document why they are being suppressed.
  - Do not leave unused fields, imports, or obvious `const` hints unresolved in committed code.
