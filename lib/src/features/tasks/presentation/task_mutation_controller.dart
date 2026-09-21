import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/performance/presentation/performance_providers.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';
import 'package:telos/src/utils/logger.dart';

part 'task_mutation_controller.g.dart';

@riverpod
class TaskMutationController extends _$TaskMutationController {
  @override
  FutureOr<void> build() {}

  Future<void> toggleCompleted(Task task) async {
    if (task.isLocked) return;

    state = const AsyncLoading();

    final AsyncValue<void> result = await AsyncValue.guard(() async {
      final user = await ref.read(authStateProvider.future);
      if (user == null) {
        throw StateError('User must be authenticated to update tasks.');
      }

      if (task.completed) {
        await ref
            .read(taskRepositoryProvider)
            .uncompleteTask(taskId: task.id, userId: user.id);
      } else {
        await ref
            .read(taskRepositoryProvider)
            .completeTask(taskId: task.id, userId: user.id);
      }
    });

    if (!ref.mounted) return;
    state = result;

    if (!state.hasError) {
      ref.invalidate(tasksForSelectedDateProvider);
      ref.invalidate(dailyPerformanceForSelectedDateProvider);
      ref.invalidate(streakProvider);
      AppLogger.tasks.info('Toggled completion for task ${task.id}');
    }
  }
}
