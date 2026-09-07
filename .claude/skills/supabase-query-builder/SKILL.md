---
name: supabase-query-builder
description: Build correct and efficient Supabase Flutter SDK queries. Use when writing any direct SDK call — selects, filters, inserts, updates, deletes, and joins.
---

# Supabase Query Builder

## What This Skill Does
Generates correct Supabase Flutter SDK queries for the `data/` layer.
Covers selects, filters, joins, pagination, and real-time subscriptions.
Use this for SDK direct calls — for RPC use `supabase-rpc-helper`.

## When to Use SDK Direct (vs RPC)
- Simple reads and writes with no cross-table integrity rules.
- No atomic multi-step operations.
- No complex aggregations (use RPC for those).

## Select Patterns

```dart
// Basic select all columns
final response = await _client
    .from('tasks')
    .select();

// Select specific columns
final response = await _client
    .from('tasks')
    .select('id, title, assigned_date, points, is_completed');

// Select with related table (join)
final response = await _client
    .from('tasks')
    .select('*, categories(id, name, color)');

// Select single row — throws if not found
final response = await _client
    .from('tasks')
    .select()
    .eq('id', taskId)
    .single();

// Select single row — returns null if not found
final response = await _client
    .from('tasks')
    .select()
    .eq('id', taskId)
    .maybeSingle();
```

## Filter Patterns

```dart
// Equality
.eq('user_id', userId)

// Multiple filters (AND)
.eq('user_id', userId)
.eq('assigned_date', dateString)

// Date range
.gte('assigned_date', startDate)   // >=
.lte('assigned_date', endDate)     // <=

// Null check
.is_('completed_at', null)         // IS NULL
.not('completed_at', 'is', null)   // IS NOT NULL

// Boolean
.eq('is_completed', false)

// In list
.inFilter('category_id', [1, 2, 3])

// Text search
.ilike('title', '%$query%')
```

## Ordering and Pagination

```dart
// Order
.order('assigned_date', ascending: false)
.order('created_at', ascending: false)

// Limit
.limit(20)

// Pagination with range (0-indexed)
.range(0, 19)   // first 20 rows
.range(20, 39)  // next 20 rows
```

## Insert Patterns

```dart
// Insert and return the created row
final response = await _client
    .from('tasks')
    .insert(_toInsertMap(task))
    .select()
    .single();

// Insert multiple rows
await _client
    .from('tasks')
    .insert(tasks.map(_toInsertMap).toList());
```

## Update Patterns

```dart
// Update and return the updated row
final response = await _client
    .from('tasks')
    .update({'title': newTitle, 'updated_at': DateTime.now().toIso8601String()})
    .eq('id', taskId)
    .eq('user_id', userId)   // always scope to user
    .select()
    .single();
```

## Delete Patterns

```dart
// Delete by id — always scope to user_id for safety
await _client
    .from('tasks')
    .delete()
    .eq('id', taskId)
    .eq('user_id', userId);
```

## Realtime Subscription Pattern

```dart
Stream<List<Task>> watchTasksForDate(String userId, DateTime date) {
  final controller = StreamController<List<Task>>();

  final channel = _client
      .channel('tasks_${userId}_$date')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tasks',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) async {
          final items = await getTasksForDate(userId, date);
          controller.add(items);
        },
      )
      .subscribe();

  controller.onCancel = () => channel.unsubscribe();
  return controller.stream;
}
```

## Error Handling — Always Wrap

```dart
try {
  final response = await _client.from('tasks').select()...;
  return response.map((e) => TaskDto(e).toDomain()).toList();
} on PostgrestException catch (e) {
  throw AppException.database(e.message, code: e.code);
}
```

## Rules
- Always scope write operations to `user_id` — never update/delete without it.
- Always call `.select().single()` after insert/update to get the returned row.
- Always serialize `DATE` values as `'yyyy-MM-dd'` strings.
- Always wrap in try/catch and rethrow as `AppException`.
- Never use `.execute()` — it was removed in newer SDK versions.
- Never return raw responses — always convert through DTO first.
- Never call these methods outside the `data/` layer.
