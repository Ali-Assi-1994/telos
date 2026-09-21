import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/services/supabase_service.dart';
import 'package:telos/src/utils/logger.dart';
import 'package:telos/src/features/tasks/data/task_dto.dart';
import 'package:telos/src/features/tasks/data/task_repository.dart';
import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/domain/task_create_input.dart';

part 'supabase_task_repository.g.dart';

@Riverpod(keepAlive: true)
TaskRepository taskRepository(Ref ref) {
  return SupabaseTaskRepository(ref.watch(supabaseClientProvider));
}

class SupabaseTaskRepository implements TaskRepository {
  const SupabaseTaskRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final List<dynamic> rows = await _client
          .from('categories')
          .select('id,name,icon,color')
          .order('name');

      return rows
          .map(
            (dynamic row) =>
                CategoryDto(row as Map<String, dynamic>).toDomain(),
          )
          .toList(growable: false);
    } on PostgrestException catch (e, st) {
      AppLogger.tasks.error(
        'Failed to load categories',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load categories right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<List<Task>> getTasksForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final String assignedDate = _dateOnly(date);
      final List<dynamic> rows = await _client
          .from('tasks')
          .select('''
id,template_id,user_id,title,description,points,assigned_date,completed,completed_at,is_locked,created_at,updated_at,
task_categories(
  category_id,
  categories(id,name,icon,color)
)
''')
          .eq('user_id', userId)
          .eq('assigned_date', assignedDate)
          .order('created_at');

      return rows
          .map((dynamic row) => TaskDto(row as Map<String, dynamic>).toDomain())
          .toList(growable: false);
    } on PostgrestException catch (e, st) {
      AppLogger.tasks.error(
        'Failed to load tasks for date',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load tasks right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<Task> createTask(TaskCreateInput input) async {
    _validateTaskCreateInput(input);

    try {
      final Map<String, dynamic> insertedTask = await _client
          .from('tasks')
          .insert(<String, dynamic>{
            'user_id': input.userId,
            'title': input.title.trim(),
            'description': input.description?.trim(),
            'points': input.points,
            'assigned_date': _dateOnly(input.assignedDate),
          })
          .select('''
id,template_id,user_id,title,description,points,assigned_date,completed,completed_at,is_locked,created_at,updated_at
''')
          .single();

      final String taskId = insertedTask['id'] as String;
      final List<Map<String, dynamic>> categoryRows = input.categoryIds
          .map(
            (int categoryId) => <String, dynamic>{
              'task_id': taskId,
              'category_id': categoryId,
            },
          )
          .toList(growable: false);
      await _client.from('task_categories').insert(categoryRows);

      final List<dynamic> fullRows = await _client
          .from('tasks')
          .select('''
id,template_id,user_id,title,description,points,assigned_date,completed,completed_at,is_locked,created_at,updated_at,
task_categories(
  category_id,
  categories(id,name,icon,color)
)
''')
          .eq('id', taskId)
          .limit(1);
      final Map<String, dynamic> fullTask =
          fullRows.first as Map<String, dynamic>;

      AppLogger.tasks.info('Created task: $taskId');
      return TaskDto(fullTask).toDomain();
    } on PostgrestException catch (e, st) {
      AppLogger.tasks.error('Failed to create task', error: e, stackTrace: st);
      throw DatabaseAppException(
        'Could not create task right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<void> completeTask({
    required String taskId,
    required String userId,
  }) async {
    await _runCompletionRpc(
      rpcName: 'complete_task',
      taskId: taskId,
      userId: userId,
      failureFallback: 'Could not complete this task right now.',
    );
  }

  @override
  Future<void> uncompleteTask({
    required String taskId,
    required String userId,
  }) async {
    await _runCompletionRpc(
      rpcName: 'uncomplete_task',
      taskId: taskId,
      userId: userId,
      failureFallback: 'Could not update this task right now.',
    );
  }

  Future<void> _runCompletionRpc({
    required String rpcName,
    required String taskId,
    required String userId,
    required String failureFallback,
  }) async {
    try {
      final dynamic result = await _client.rpc<dynamic>(
        rpcName,
        params: <String, dynamic>{'p_task_id': taskId, 'p_user_id': userId},
      );

      if (result is! Map<String, dynamic>) {
        throw const DatabaseAppException(
          'Unexpected server response while updating task.',
        );
      }

      final bool success = result['success'] as bool? ?? false;
      if (!success) {
        final String errorMessage =
            result['error'] as String? ?? failureFallback;
        throw DatabaseAppException(errorMessage);
      }
    } on PostgrestException catch (e, st) {
      AppLogger.tasks.error(
        'RPC task mutation failed: $rpcName',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(failureFallback, cause: e);
    }
  }

  void _validateTaskCreateInput(TaskCreateInput input) {
    if (input.title.trim().isEmpty) {
      throw const DatabaseAppException('Task title is required.');
    }
    if (input.points < 1 || input.points > 100) {
      throw const DatabaseAppException('Points must be between 1 and 100.');
    }
    if (input.categoryIds.isEmpty) {
      throw const DatabaseAppException('Pick at least one category.');
    }
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
