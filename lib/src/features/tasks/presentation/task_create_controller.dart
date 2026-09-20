import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task_create_input.dart';
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';
import 'package:telos/src/utils/logger.dart';

part 'task_create_controller.g.dart';

@riverpod
class TaskCreateController extends _$TaskCreateController {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String title,
    required String? description,
    required int points,
    required DateTime assignedDate,
    required TimeOfDay startTime,
    required List<int> categoryIds,
  }) async {
    state = const AsyncLoading();

    final AsyncValue<void> result = await AsyncValue.guard(() async {
      final user = await ref.read(authStateProvider.future);
      if (user == null) {
        throw StateError('User must be authenticated to create tasks.');
      }

      final TaskCreateInput input = TaskCreateInput(
        userId: user.id,
        title: title,
        description: description,
        points: points,
        assignedDate: assignedDate,
        categoryIds: categoryIds,
      );
      final createdTask = await ref
          .read(taskRepositoryProvider)
          .createTask(input);
      final int minutesOfDay = (startTime.hour * 60) + startTime.minute;
      ref
          .read(taskStartTimeOverridesProvider.notifier)
          .setOverride(taskId: createdTask.id, minutesOfDay: minutesOfDay);
    });

    if (!ref.mounted) return;
    state = result;

    if (!state.hasError) {
      ref.invalidate(tasksForSelectedDateProvider);
      ref.invalidate(dailyPerformanceForSelectedDateProvider);
      final String formattedHour = startTime.hour.toString().padLeft(2, '0');
      final String formattedMinute = startTime.minute.toString().padLeft(
        2,
        '0',
      );
      AppLogger.tasks.info(
        'Task create mutation completed for $formattedHour:$formattedMinute.',
      );
    }
  }
}
