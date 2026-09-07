---
name: supabase-rpc-helper
description: Call Supabase Postgres RPC functions from the Flutter data layer. Use for atomic operations, integrity-critical actions, and complex aggregations that live in Postgres functions.
---

# Supabase RPC Helper

## What This Skill Does
Generates correct RPC calls in the Flutter `data/` layer for Postgres
functions defined in Supabase. Handles parameter naming, result parsing,
success/failure patterns, and error handling.

## When to Use RPC (vs SDK direct)
- Atomic operations that must not be partially applied (e.g. complete task + award points).
- Operations with server-side integrity rules (locking, window expiry).
- Complex aggregations run close to the data (leaderboard, streak, daily performance).
- Any operation where the DB enforces rules the client must not bypass.

## RPC Naming Convention

| Postgres function | Flutter call |
|---|---|
| `complete_task` | `_client.rpc('complete_task', params: {...})` |
| `get_leaderboard` | `_client.rpc('get_leaderboard', params: {...})` |
| `get_streak` | `_client.rpc('get_streak', params: {...})` |
| `get_daily_performance` | `_client.rpc('get_daily_performance', params: {...})` |

Postgres function parameters are prefixed `p_` by convention.
Flutter params map drops the prefix in the key name:

```dart
// Postgres: complete_task(p_task_id uuid, p_user_id uuid)
params: {
  'p_task_id': taskId,
  'p_user_id': userId,
}
```

## Result Patterns

### Pattern 1 — Success/Failure Object
Used for mutation RPCs that return `{ success: bool, error?: text, data?: ... }`.

```dart
Future<CompleteTaskResult> completeTask(
  String taskId,
  String userId,
) async {
  try {
    final result = await _client.rpc(
      'complete_task',
      params: {
        'p_task_id': taskId,
        'p_user_id': userId,
      },
    ) as Map<String, dynamic>;

    if (result['success'] == true) {
      return CompleteTaskResult.success(
        points: result['points'] as int,
      );
    }
    return CompleteTaskResult.failure(
      error: result['error'] as String,
    );
  } on PostgrestException catch (e) {
    throw AppException.database(e.message, code: e.code);
  }
}
```

### Pattern 2 — List of Rows
Used for aggregate RPCs that return a table (leaderboard, performance).

```dart
Future<List<LeaderboardEntry>> getLeaderboard(
  String groupId,
  DateTime start,
  DateTime end,
) async {
  try {
    final response = await _client.rpc(
      'get_leaderboard',
      params: {
        'p_group_id': groupId,
        'p_start':    start.toIso8601String().split('T').first,
        'p_end':      end.toIso8601String().split('T').first,
      },
    ) as List<dynamic>;

    return response
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntryDto.new)
        .map((dto) => dto.toDomain())
        .toList();
  } on PostgrestException catch (e) {
    throw AppException.database(e.message, code: e.code);
  }
}
```

### Pattern 3 — Single Row
Used for RPCs that return one record (streak, daily performance).

```dart
Future<Streak> getStreak(String userId) async {
  try {
    final response = await _client.rpc(
      'get_streak',
      params: {'p_user_id': userId},
    ) as List<dynamic>;

    final row = response.cast<Map<String, dynamic>>().first;
    return StreakDto(row).toDomain();
  } on PostgrestException catch (e) {
    throw AppException.database(e.message, code: e.code);
  }
}
```

## Result Model Pattern (for mutation RPCs)

Always define a sealed result type for mutation RPCs — never return `bool` or throw for expected failure states:

```dart
// features/<feature>/domain/complete_task_result.dart
@freezed
sealed class CompleteTaskResult with _$CompleteTaskResult {
  const factory CompleteTaskResult.success({required int points}) =
      CompleteTaskSuccess;
  const factory CompleteTaskResult.failure({required String error}) =
      CompleteTaskFailure;
}
```

Handle in the controller with pattern matching:

```dart
final result = await ref
    .read(taskRepositoryProvider)
    .completeTask(taskId, userId);

switch (result) {
  case CompleteTaskSuccess(:final points):
    // show points animation
  case CompleteTaskFailure(:final error):
    // show error snackbar
}
```

## Rules
- Never call RPC outside the `data/` layer.
- Always cast the raw result before accessing fields — never use dynamic directly.
- Always use the `p_` prefix for Postgres parameter names.
- DATE parameters: always `'yyyy-MM-dd'` strings, never full ISO-8601.
- Always wrap in try/catch and rethrow as `AppException`.
- Never re-implement RPC logic in Dart — trust the Postgres function.
- For list results, always `.cast<Map<String, dynamic>>()` before mapping.
