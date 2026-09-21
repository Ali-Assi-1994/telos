import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/tasks/data/task_repository.dart';
import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/domain/task_create_input.dart';

const List<Category> _defaultCategories = <Category>[
  Category(id: 1, name: 'Work'),
  Category(id: 2, name: 'Health'),
];

/// In-memory [TaskRepository] fake for controller and widget tests.
///
/// Mirrors the validation and locking rules the real Supabase RPCs enforce
/// server-side, so controller/widget tests can exercise those paths without
/// a network dependency.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<Category>? categories})
    : _categories = categories ?? _defaultCategories;

  final List<Category> _categories;
  final List<Task> _tasks = <Task>[];
  int _nextId = 1;

  bool throwOnGetTasks = false;
  bool throwOnComplete = false;
  int completeCallCount = 0;
  int uncompleteCallCount = 0;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  void seedTask(Task task) => _tasks.add(task);

  @override
  Future<List<Category>> getCategories() async =>
      List<Category>.unmodifiable(_categories);

  @override
  Future<List<Task>> getTasksForDate({
    required String userId,
    required DateTime date,
  }) async {
    if (throwOnGetTasks) {
      throw const DatabaseAppException(
        'Could not load tasks right now. Please try again.',
      );
    }
    return _tasks
        .where(
          (Task task) =>
              task.userId == userId && _isSameDate(task.assignedDate, date),
        )
        .toList(growable: false);
  }

  @override
  Future<Task> createTask(TaskCreateInput input) async {
    if (input.title.trim().isEmpty) {
      throw const DatabaseAppException('Task title is required.');
    }
    if (input.points < 1 || input.points > 100) {
      throw const DatabaseAppException('Points must be between 1 and 100.');
    }
    if (input.categoryIds.isEmpty) {
      throw const DatabaseAppException('Pick at least one category.');
    }

    final DateTime now = DateTime.now();
    final Task task = Task(
      id: 'task-${_nextId++}',
      userId: input.userId,
      title: input.title.trim(),
      description: input.description,
      points: input.points,
      assignedDate: input.assignedDate,
      createdAt: now,
      updatedAt: now,
      categories: _categories
          .where((Category category) => input.categoryIds.contains(category.id))
          .toList(growable: false),
    );
    _tasks.add(task);
    return task;
  }

  @override
  Future<void> completeTask({
    required String taskId,
    required String userId,
  }) async {
    completeCallCount++;
    if (throwOnComplete) {
      throw const DatabaseAppException(
        'Could not complete this task right now.',
      );
    }
    final Task task = _findTask(taskId);
    if (task.isLocked) {
      throw const DatabaseAppException('Task is locked.');
    }
    _replaceTask(task.copyWith(completed: true, completedAt: DateTime.now()));
  }

  @override
  Future<void> uncompleteTask({
    required String taskId,
    required String userId,
  }) async {
    uncompleteCallCount++;
    final Task task = _findTask(taskId);
    if (task.isLocked) {
      throw const DatabaseAppException('Task is locked.');
    }
    _replaceTask(task.copyWith(completed: false, completedAt: null));
  }

  Task _findTask(String taskId) {
    return _tasks.firstWhere(
      (Task task) => task.id == taskId,
      orElse: () => throw const DatabaseAppException('Task not found.'),
    );
  }

  void _replaceTask(Task updated) {
    final int index = _tasks.indexWhere((Task task) => task.id == updated.id);
    _tasks[index] = updated;
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
