---
name: architecture-check
description: Review code for architecture violations. Use when auditing a file, feature, or the whole codebase for layer boundary violations, wrong imports, missing abstractions, or anti-patterns.
---

# Architecture Check

## What This Skill Does
Audits Flutter code against the project's feature-first Riverpod
architecture. Identifies violations, explains why they matter, and
provides the correct fix for each one.

## How to Use
Point this skill at a file, a feature folder, or ask for a full audit.
For each issue found, report: location, violation type, why it matters,
and the correct fix.

## Checklist — Layer Boundaries

### Presentation Layer Violations
- [ ] Widget imports `supabase_flutter` → move logic to repository
- [ ] Widget calls repository method directly → must go through a provider/controller
- [ ] Widget contains business logic (calculations, transformations) → move to controller or domain extension
- [ ] Widget imports a DTO class → DTOs must not cross the `data/` boundary
- [ ] `ref.watch` used inside a callback or async function → must use `ref.read`
- [ ] `setState` used for non-ephemeral state → use Riverpod
- [ ] `Navigator.push` used for main navigation → use `context.go` or `context.push`
- [ ] `AsyncValue.value` accessed without guarding loading/error → use `.when()`
- [ ] Private widget methods returning `Widget` → must be private widget classes
- [ ] `Colors.*` hardcoded → use `Theme.of(context).colorScheme`
- [ ] `print()` or `dart:developer` used directly → use `AppLogger.<feature>`

### Data Layer Violations
- [ ] Repository returns a DTO instead of a domain model → convert inside repository
- [ ] DTO imported outside `data/` folder → DTOs are `data/`-only
- [ ] `Supabase.instance.client` called directly → inject via `SupabaseService`
- [ ] Business logic (locking, scoring, streaks) implemented in Dart → belongs in Postgres RPC
- [ ] Raw Supabase error message surfaced to caller → catch and rethrow as `AppException`
- [ ] No abstract interface — only concrete class → missing testability contract
- [ ] DATE column serialized as full ISO-8601 → must be `'yyyy-MM-dd'` only
- [ ] Insert map includes `id`, `created_at`, or `updated_at` → server-managed, remove them

### Domain Layer Violations
- [ ] Domain model imports `supabase_flutter` or `flutter` → domain must be pure Dart
- [ ] Domain model contains business logic methods → belongs in service or repository
- [ ] Model not using `freezed` → must be immutable with `freezed`
- [ ] Missing `fromJson` factory → required for deserialization

### Riverpod Violations
- [ ] Manual provider (`Provider(...)`, `FutureProvider(...)`) → use `@riverpod` generation
- [ ] `keepAlive: true` missing on repository or service provider → singletons must persist
- [ ] Missing `part 'filename.g.dart'` on a `@riverpod` file → codegen won't run
- [ ] Provider not invalidated after mutation → stale data will show in UI
- [ ] `ref.watch` used inside `if` block or loop → illegal reactive call
- [ ] `.select()` not used when only one field needed from provider → causes unnecessary rebuilds

### Structural Violations
- [ ] Feature folder named after a screen (`home_screen/`, `login_page/`) → name after functional area
- [ ] Feature imports another feature's `data/` layer directly → must import `domain/` only
- [ ] Package import used within the same feature → should be relative
- [ ] Relative import used across feature boundary → should be package import
- [ ] `application/` layer created for a feature with only one repository → unnecessary layer
- [ ] `.g.dart` or `.freezed.dart` file manually edited → must be generated only

### Environment Violations
- [ ] Supabase URL or key hardcoded in source → use `flutter_dotenv`
- [ ] `.env` file committed to version control → must be in `.gitignore`

## Violation Report Format

For each violation found, report in this format:

```
VIOLATION: <type>
FILE: lib/src/features/tasks/presentation/task_card.dart:42
RULE: DTOs must not cross the data/ layer boundary
FOUND: import '../data/task_dto.dart'
FIX: Remove the import. The TaskCard should receive a Task domain model,
     not a TaskDto. The repository converts before returning.
```

## Severity Levels

| Severity | Examples |
|---|---|
| 🔴 Critical | Supabase key hardcoded, DTO leaking to UI, business logic in widget |
| 🟠 High | Missing abstract interface, manual provider, wrong import direction |
| 🟡 Medium | Missing `.select()`, missing error state, `print()` instead of AppLogger |
| 🟢 Low | Missing `const`, minor naming inconsistency |

## Common Fix Patterns

### DTO leaking out of data layer
```dart
// Found in controller — Wrong
final dto = await _client.from('tasks').select().single();
return TaskDto(dto); // returning DTO

// Fix — convert inside repository
final dto = await _client.from('tasks').select().single();
return TaskDto(dto).toDomain(); // return domain model
```

### Business logic in widget
```dart
// Found in widget — Wrong
final completionRate = tasks.where((t) => t.isCompleted).length / tasks.length;

// Fix — move to domain extension or controller
extension TaskListX on List<Task> {
  double get completionRate =>
      isEmpty ? 0 : where((t) => t.isCompleted).length / length;
}
```

### Manual provider
```dart
// Wrong
final taskRepoProvider = Provider<TaskRepository>(
  (ref) => SupabaseTaskRepository(ref.watch(supabaseClientProvider)),
);

// Fix
@Riverpod(keepAlive: true)
TaskRepository taskRepository(TaskRepositoryRef ref) =>
    SupabaseTaskRepository(ref.watch(supabaseClientProvider));
```

### Missing invalidation after mutation
```dart
// Wrong — stale data after task completion
Future<void> completeTask(String taskId) async {
  await ref.read(taskRepositoryProvider).completeTask(taskId, userId);
  // nothing invalidated — UI shows old data
}

// Fix
Future<void> completeTask(String taskId) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(
    () => ref.read(taskRepositoryProvider).completeTask(taskId, userId),
  );
  if (!state.hasError) {
    ref.invalidate(tasksForDateProvider);
    ref.invalidate(dailyPerformanceProvider);
    ref.invalidate(streakProvider);
  }
}
```

## Quick Audit Command

When asked to audit a feature, check files in this order:
1. `domain/` — pure Dart? No external imports?
2. `data/` DTOs — only in `data/`? No leaking?
3. `data/` repositories — abstract + concrete? Error handling? Correct transport?
4. `presentation/` controllers — `@riverpod`? `AsyncNotifier`? Invalidates after mutation?
5. `presentation/` widgets — No direct repo calls? Theming correct? All AsyncValue states handled?
6. Imports — relative within feature? Package across features?
