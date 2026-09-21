import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';

part 'tasks_providers.g.dart';

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

@riverpod
class TaskStartTimeOverrides extends _$TaskStartTimeOverrides {
  @override
  Map<String, int> build() => <String, int>{};

  void setOverride({required String taskId, required int minutesOfDay}) {
    state = <String, int>{...state, taskId: minutesOfDay};
  }
}

@riverpod
Future<List<Category>> categories(Ref ref) {
  return ref.read(taskRepositoryProvider).getCategories();
}

@riverpod
Future<List<Task>> tasksForSelectedDate(Ref ref) async {
  final DateTime date = ref.watch(selectedDateProvider);
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return <Task>[];

  return ref
      .read(taskRepositoryProvider)
      .getTasksForDate(userId: user.id, date: date);
}
