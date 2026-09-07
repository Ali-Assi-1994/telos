import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/daily_performance.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/domain/task_create_input.dart';

abstract class TaskRepository {
  Future<List<Category>> getCategories();

  Future<List<Task>> getTasksForDate({
    required String userId,
    required DateTime date,
  });

  Future<Task> createTask(TaskCreateInput input);

  Future<void> completeTask({
    required String taskId,
    required String userId,
  });

  Future<void> uncompleteTask({
    required String taskId,
    required String userId,
  });

  Future<DailyPerformance> getDailyPerformance({
    required String userId,
    required DateTime date,
  });
}
