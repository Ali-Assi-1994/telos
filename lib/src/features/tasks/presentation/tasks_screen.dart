import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/task_create_controller.dart';
import 'package:telos/src/features/tasks/presentation/task_mutation_controller.dart';
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';
import 'package:telos/src/features/tasks/presentation/widgets/anytime_section.dart';
import 'package:telos/src/features/tasks/presentation/widgets/create_task_sheet.dart';
import 'package:telos/src/features/tasks/presentation/widgets/task_list_states.dart';
import 'package:telos/src/features/tasks/presentation/widgets/task_timeline_section.dart';
import 'package:telos/src/features/tasks/presentation/widgets/tasks_header.dart';

/// Screen decomposition:
/// TasksScreen
///   ├── TasksHeader
///   │     └── (month row + swipeable date carousel)
///   ├── TasksTimelineSection
///   │     └── (per-task cards + free-time gaps)
///   ├── AnytimeSection
///   │     └── (completed tasks)
///   └── CreateTaskSheet
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(taskMutationControllerProvider, (_, state) {
      if (state.hasError) {
        _showMessage(_errorMessage(state.error));
      }
    });
    ref.listen<AsyncValue<void>>(taskCreateControllerProvider, (_, state) {
      if (state.hasError) {
        _showMessage(_errorMessage(state.error));
      } else if (!state.isLoading && !state.hasError) {
        _showMessage('Task added.');
      }
    });

    final DateTime selectedDate = ref.watch(selectedDateProvider);
    final AsyncValue<List<Task>> tasksState = ref.watch(
      tasksForSelectedDateProvider,
    );
    final Map<String, int> startTimeOverrides = ref.watch(
      taskStartTimeOverridesProvider,
    );
    final int tasksCount = tasksState.value?.length ?? 0;
    final bool isViewingToday = _isSameDate(selectedDate, DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            TasksHeader(
              selectedDate: selectedDate,
              isViewingToday: isViewingToday,
              streakCount: null,
              fallbackTasksCount: tasksCount,
              onDateSelected: (DateTime date) {
                ref.read(selectedDateProvider.notifier).setDate(date);
              },
              onGoToToday: () {
                final DateTime now = DateTime.now();
                ref
                    .read(selectedDateProvider.notifier)
                    .setDate(DateTime(now.year, now.month, now.day));
              },
            ),
            Expanded(
              child: tasksState.when(
                data: (List<Task> tasks) {
                  final List<Task> todoTasks = tasks
                      .where((Task task) => !task.completed)
                      .toList();
                  final List<Task> completedTasks = tasks
                      .where((Task task) => task.completed)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: <Widget>[
                      TasksTimelineSection(
                        tasks: todoTasks,
                        startTimeOverrides: startTimeOverrides,
                        onToggleCompleted: _onToggleCompleted,
                        onAddAtTime: (TimeOfDay time) {
                          _openCreateTaskSheet(selectedDate, initialTime: time);
                        },
                      ),
                      AnytimeSection(
                        tasks: completedTasks,
                        onToggleCompleted: _onToggleCompleted,
                      ),
                    ],
                  );
                },
                loading: () => const TaskListLoadingSkeleton(),
                error: (Object error, StackTrace _) =>
                    TaskListErrorState(message: _errorMessage(error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggleCompleted(Task task) async {
    await ref
        .read(taskMutationControllerProvider.notifier)
        .toggleCompleted(task);
  }

  Future<void> _openCreateTaskSheet(
    DateTime selectedDate, {
    TimeOfDay? initialTime,
  }) async {
    late final List<Category> categories;
    try {
      categories = await ref.read(categoriesProvider.future);
    } catch (error) {
      _showMessage(_errorMessage(error));
      return;
    }
    if (!mounted) return;
    if (categories.isEmpty) {
      _showMessage('No categories available yet. Please try again.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      barrierColor: Theme.of(
        context,
      ).colorScheme.shadow.withValues(alpha: 0.16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CreateTaskSheet(
          initialDate: selectedDate,
          initialTime: initialTime,
          categories: categories,
          onCreate:
              ({
                required String title,
                required String? description,
                required int points,
                required DateTime assignedDate,
                required TimeOfDay startTime,
                required List<int> categoryIds,
              }) async {
                await ref
                    .read(taskCreateControllerProvider.notifier)
                    .create(
                      title: title,
                      description: description,
                      points: points,
                      assignedDate: assignedDate,
                      startTime: startTime,
                      categoryIds: categoryIds,
                    );
                if (context.mounted &&
                    !ref.read(taskCreateControllerProvider).hasError &&
                    !ref.read(taskCreateControllerProvider).isLoading) {
                  Navigator.of(context).pop();
                }
              },
        );
      },
    );
  }

  String _errorMessage(Object? error) {
    if (error is AppException) return error.toUserMessage();
    return 'Something went wrong. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
