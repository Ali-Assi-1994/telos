import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/task_create_controller.dart';
import 'package:telos/src/features/tasks/presentation/task_mutation_controller.dart';
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';

/// Screen decomposition:
/// TasksScreen
///   ├── _TasksHeader
///   │     ├── _MonthRow
///   │     └── _DateCarousel
///   │           └── _DateChip
///   ├── _TasksTimelineSection
///   │     └── _TaskCard
///   ├── _AnytimeSection
///   │     └── _AnytimeTaskTile
///   └── _CreateTaskSheet
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
    final AsyncValue<List<Task>> tasksState =
        ref.watch(tasksForSelectedDateProvider);
    final Map<String, int> startTimeOverrides =
        ref.watch(taskStartTimeOverridesProvider);
    final int tasksCount = tasksState.valueOrNull?.length ?? 0;
    final bool isViewingToday = _isSameDate(selectedDate, DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TasksHeader(
              selectedDate: selectedDate,
              isViewingToday: isViewingToday,
              streakCount: null,
              fallbackTasksCount: tasksCount,
              onDateSelected: (DateTime date) {
                ref.read(selectedDateProvider.notifier).setDate(date);
              },
              onGoToToday: () {
                final DateTime now = DateTime.now();
                ref.read(selectedDateProvider.notifier).setDate(
                      DateTime(now.year, now.month, now.day),
                    );
              },
            ),
            Expanded(
              child: tasksState.when(
                data: (List<Task> tasks) {
                  final List<Task> todoTasks =
                      tasks.where((Task task) => !task.completed).toList();
                  final List<Task> completedTasks =
                      tasks.where((Task task) => task.completed).toList();

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: <Widget>[
                      _TasksTimelineSection(
                        tasks: todoTasks,
                        startTimeOverrides: startTimeOverrides,
                        onToggleCompleted: _onToggleCompleted,
                        onAddAtTime: (TimeOfDay time) {
                          _openCreateTaskSheet(
                            selectedDate,
                            initialTime: time,
                          );
                        },
                      ),
                      _AnytimeSection(
                        tasks: completedTasks,
                        onToggleCompleted: _onToggleCompleted,
                      ),
                    ],
                  );
                },
                loading: () => const _LoadingList(),
                error: (Object error, StackTrace _) =>
                    _ErrorState(message: _errorMessage(error)),
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
      barrierColor:
          Theme.of(context).colorScheme.shadow.withValues(alpha: 0.16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return _CreateTaskSheet(
          initialDate: selectedDate,
          initialTime: initialTime,
          categories: categories,
          onCreate: ({
            required String title,
            required String? description,
            required int points,
            required DateTime assignedDate,
            required TimeOfDay startTime,
            required List<int> categoryIds,
          }) async {
            await ref.read(taskCreateControllerProvider.notifier).create(
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.selectedDate,
    required this.isViewingToday,
    required this.streakCount,
    required this.fallbackTasksCount,
    required this.onDateSelected,
    required this.onGoToToday,
  });

  final DateTime selectedDate;
  final bool isViewingToday;
  final int? streakCount;
  final int fallbackTasksCount;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onGoToToday;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final String month = _monthName(selectedDate.month);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: _MonthRow(
              monthLabel: month,
              isViewingToday: isViewingToday,
              streakCount: streakCount,
              fallbackTasksCount: fallbackTasksCount,
              textTheme: textTheme,
              colorScheme: colorScheme,
              onGoToToday: onGoToToday,
            ),
          ),
          _DateCarousel(
            selectedDate: selectedDate,
            onSelected: onDateSelected,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.monthLabel,
    required this.isViewingToday,
    required this.streakCount,
    required this.fallbackTasksCount,
    required this.textTheme,
    required this.colorScheme,
    required this.onGoToToday,
  });

  final String monthLabel;
  final bool isViewingToday;
  final int? streakCount;
  final int fallbackTasksCount;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final VoidCallback onGoToToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              monthLabel,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const Spacer(),
        isViewingToday
            ? _StreakOrTasksBadge(
                count: streakCount ?? fallbackTasksCount,
                hasStreak: streakCount != null,
              )
            : _TodayShortcutButton(onPressed: onGoToToday),
      ],
    );
  }
}

class _StreakOrTasksBadge extends StatelessWidget {
  const _StreakOrTasksBadge({
    required this.count,
    required this.hasStreak,
  });

  final int count;
  final bool hasStreak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final String label = '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            hasStreak
                ? Icons.local_fire_department_rounded
                : Icons.checklist_rounded,
            color: colorScheme.tertiary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayShortcutButton extends StatelessWidget {
  const _TodayShortcutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Today',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateCarousel extends StatefulWidget {
  const _DateCarousel({
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_DateCarousel> createState() => _DateCarouselState();
}

class _DateCarouselState extends State<_DateCarousel> {
  static const int _initialPage = 5000;
  late final PageController _pageController;
  late int _referencePage;
  late DateTime _referenceSelectedDate;

  @override
  void initState() {
    super.initState();
    _referencePage = _initialPage;
    _referenceSelectedDate = _dateOnly(widget.selectedDate);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant _DateCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime oldDate = _dateOnly(oldWidget.selectedDate);
    final DateTime newDate = _dateOnly(widget.selectedDate);
    if (oldDate != newDate) {
      _referenceSelectedDate = newDate;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int page) {
          final int weekDelta = page - _referencePage;
          if (weekDelta == 0) return;

          // Product expectation:
          // swipe left  => previous week
          // swipe right => next week
          final int direction = weekDelta > 0 ? -1 : 1;
          final DateTime nextSelectedDate = _dateOnly(
            _referenceSelectedDate.add(Duration(days: direction * 7)),
          );

          setState(() {
            _referencePage = page;
            _referenceSelectedDate = nextSelectedDate;
          });
          widget.onSelected(nextSelectedDate);
        },
        itemBuilder: (BuildContext context, int pageIndex) {
          final int weekOffset = pageIndex - _referencePage;
          final DateTime weekDate = _referenceSelectedDate.add(
            Duration(days: weekOffset * 7),
          );
          final DateTime monday =
              weekDate.subtract(Duration(days: weekDate.weekday - 1));
          final List<DateTime> weekDates = List<DateTime>.generate(
            7,
            (int index) =>
                DateTime(monday.year, monday.month, monday.day + index),
          );

          return _WeekDateRow(
            dates: weekDates,
            selectedDate: widget.selectedDate,
            onSelected: widget.onSelected,
          );
        },
      ),
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _WeekDateRow extends StatelessWidget {
  const _WeekDateRow({
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double horizontalPadding = 16;
        const double chipGap = 8;
        final double availableWidth =
            constraints.maxWidth - (horizontalPadding * 2);
        final double chipWidth = (availableWidth - (chipGap * 6)) / 7;
        final double clampedChipWidth = chipWidth.clamp(40, 56);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: List<Widget>.generate(dates.length, (int index) {
              final DateTime date = dates[index];
              final bool isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              return Padding(
                padding: EdgeInsets.only(
                    right: index == dates.length - 1 ? 0 : chipGap),
                child: SizedBox(
                  width: clampedChipWidth,
                  child: _DateChip(
                    date: date,
                    isActive: isSelected,
                    onPressed: () => onSelected(date),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isActive,
    required this.onPressed,
  });

  final DateTime date;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(52, 72),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        backgroundColor: isActive ? colorScheme.primary : colorScheme.surface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _weekdayLabel(date.weekday),
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksTimelineSection extends StatelessWidget {
  const _TasksTimelineSection({
    required this.tasks,
    required this.startTimeOverrides,
    required this.onToggleCompleted,
    required this.onAddAtTime,
  });

  final List<Task> tasks;
  final Map<String, int> startTimeOverrides;
  final ValueChanged<Task> onToggleCompleted;
  final ValueChanged<TimeOfDay> onAddAtTime;

  @override
  Widget build(BuildContext context) {
    final List<_TimelineItem> timelineItems = _buildTimelineItems(
      tasks,
      startTimeOverrides: startTimeOverrides,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListView.builder(
            itemCount: timelineItems.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final _TimelineItem item = timelineItems[index];
              return switch (item) {
                final _TimelineBoundaryItem boundaryItem => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TimelineBoundaryBlock(
                      time: boundaryItem.time,
                    ),
                  ),
                final _TimelineTaskItem taskItem => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TimelineTaskBlock(
                      task: taskItem.task,
                      startTime: taskItem.startTime,
                      endTime: taskItem.endTime,
                      onToggleCompleted: () => onToggleCompleted(taskItem.task),
                    ),
                  ),
                final _TimelineGapItem gapItem => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TimelineGapBlock(
                      gapMinutes: gapItem.gapMinutes,
                      onAddPressed: () => onAddAtTime(gapItem.gapStartTime),
                    ),
                  ),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineTaskBlock extends StatelessWidget {
  const _TimelineTaskBlock({
    required this.task,
    required this.startTime,
    required this.endTime,
    required this.onToggleCompleted,
  });

  final Task task;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            _formatTimeOfDay(startTime),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _TaskCard(
          task: task,
          startTime: startTime,
          endTime: endTime,
          onToggleCompleted: onToggleCompleted,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(
            _formatTimeOfDay(endTime),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineBoundaryBlock extends StatelessWidget {
  const _TimelineBoundaryBlock({required this.time});

  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        _formatBoundaryTime(time),
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.startTime,
    required this.endTime,
    required this.onToggleCompleted,
  });

  final Task task;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final Category? firstCategory =
        task.categories.isNotEmpty ? task.categories.first : null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CategoryCircleChip(
                      label: _categoryBadge(firstCategory?.name)),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: task.isLocked
                        ? 'Task is locked'
                        : task.completed
                            ? 'Mark incomplete'
                            : 'Mark complete',
                    onPressed: task.isLocked ? null : onToggleCompleted,
                    icon: Icon(
                      task.completed
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: task.completed
                          ? colorScheme.tertiary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCircleChip extends StatelessWidget {
  const _CategoryCircleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _TimelineGapBlock extends StatelessWidget {
  const _TimelineGapBlock({
    required this.gapMinutes,
    required this.onAddPressed,
  });

  final int gapMinutes;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Row(
      children: <Widget>[
        const SizedBox(width: 4),
        const _GapDots(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_formatGapDuration(gapMinutes)} free',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onAddPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _GapDots extends StatelessWidget {
  const _GapDots();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.outline;
    return SizedBox(
      width: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _GapDot(color: color),
          const SizedBox(height: 6),
          _GapDot(color: color),
          const SizedBox(height: 6),
          _GapDot(color: color),
        ],
      ),
    );
  }
}

class _GapDot extends StatelessWidget {
  const _GapDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AnytimeSection extends StatelessWidget {
  const _AnytimeSection({
    required this.tasks,
    required this.onToggleCompleted,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Any time today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            itemCount: tasks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final Task task = tasks[index];
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index == tasks.length - 1 ? 0 : 8),
                child: _AnytimeTaskTile(
                  task: task,
                  onToggleCompleted: () => onToggleCompleted(task),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnytimeTaskTile extends StatelessWidget {
  const _AnytimeTaskTile({
    required this.task,
    required this.onToggleCompleted,
  });

  final Task task;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final Category? firstCategory =
        task.categories.isNotEmpty ? task.categories.first : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: task.isLocked ? null : onToggleCompleted,
            icon: Icon(
              task.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: task.completed
                  ? colorScheme.tertiary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Opacity(
              opacity: task.completed ? 0.6 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration:
                          task.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${firstCategory?.name ?? 'General'} • ${task.points} pt',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTaskSheet extends ConsumerStatefulWidget {
  const _CreateTaskSheet({
    required this.initialDate,
    required this.initialTime,
    required this.categories,
    required this.onCreate,
  });

  final DateTime initialDate;
  final TimeOfDay? initialTime;
  final List<Category> categories;
  final Future<void> Function({
    required String title,
    required String? description,
    required int points,
    required DateTime assignedDate,
    required TimeOfDay startTime,
    required List<int> categoryIds,
  }) onCreate;

  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final Set<int> _selectedCategoryIds = <int>{};
  late DateTime _assignedDate;
  late TimeOfDay _startTime;
  int _points = 40;
  int _selectedDurationMinutes = 60;
  bool _isCustomDurationSelected = false;

  @override
  void initState() {
    super.initState();
    _assignedDate = widget.initialDate;
    _startTime = widget.initialTime ?? TimeOfDay.now();
    _applyRandomAiSuggestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = ref.watch(taskCreateControllerProvider).isLoading;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 16),
                _SheetHeader(
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                _TaskTitleField(
                  controller: _titleController,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),
                _MetaActionsRow(
                  startTime: _startTime,
                  onPickTime: isLoading ? null : _pickTime,
                ),
                const SizedBox(height: 14),
                const _SectionTitle(
                  icon: Icons.hourglass_bottom_rounded,
                  title: 'Time needed',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durationOptions.map((_DurationOption option) {
                    final bool isSelected = option.isCustom
                        ? _isCustomDurationSelected
                        : !_isCustomDurationSelected &&
                            option.minutes == _selectedDurationMinutes;
                    return _InfoTag(
                      icon: option.isCustom ? Icons.tune_rounded : null,
                      text: option.isCustom
                          ? _customDurationChipLabel()
                          : option.label,
                      highlighted: isSelected,
                      onPressed:
                          isLoading ? null : () => _onDurationSelected(option),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 14),
                _SectionTitle(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI suggestions',
                  iconColor: colorScheme.tertiary,
                ),
                const SizedBox(height: 10),
                _AiSuggestionsRow(
                  selectedCategoryName: _selectedCategoryName(),
                  points: _points,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isLoading ? 'Saving...' : 'Save Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDurationSelected(_DurationOption option) async {
    if (option.isCustom) {
      final _CustomDurationResult? result =
          await showDialog<_CustomDurationResult>(
        context: context,
        builder: (BuildContext context) => _CustomDurationDialog(
          initialDurationMinutes: _selectedDurationMinutes,
        ),
      );
      if (result == null) return;
      setState(() {
        _isCustomDurationSelected = true;
        _selectedDurationMinutes = result.totalMinutes;
      });
      return;
    }

    final int minutes = option.minutes ?? 60;
    setState(() {
      _selectedDurationMinutes = minutes;
      _isCustomDurationSelected = false;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) return;

    await widget.onCreate(
      title: _titleController.text.trim(),
      description:
          'Estimated duration: ${_formatDurationLabel(_selectedDurationMinutes)}',
      points: _points,
      assignedDate: _assignedDate,
      startTime: _startTime,
      categoryIds: _selectedCategoryIds.toList(growable: false),
    );
  }

  void _applyRandomAiSuggestions() {
    if (widget.categories.isEmpty) return;
    final Random random = Random();
    final Category category =
        widget.categories[random.nextInt(widget.categories.length)];
    _points = 10 + random.nextInt(91);
    _selectedCategoryIds
      ..clear()
      ..add(category.id);
  }

  String _selectedCategoryName() {
    if (_selectedCategoryIds.isEmpty) return 'General';
    final int selectedId = _selectedCategoryIds.first;
    for (final Category category in widget.categories) {
      if (category.id == selectedId) return category.name;
    }
    return 'General';
  }

  String _customDurationChipLabel() {
    if (!_isCustomDurationSelected) return 'Custom';
    return _formatDurationLabel(_selectedDurationMinutes);
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Add task',
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Quickly place it on today\'s plan',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: 18),
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            maximumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _TaskTitleField extends StatelessWidget {
  const _TaskTitleField({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Task title',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.secondaryContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Write monthly report',
            hintStyle: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a title';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _MetaActionsRow extends StatelessWidget {
  const _MetaActionsRow({
    required this.startTime,
    required this.onPickTime,
  });

  final TimeOfDay startTime;
  final VoidCallback? onPickTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _CompactActionChip(
            icon: Icons.schedule_rounded,
            text: _formatTimeOfDay(startTime),
            onPressed: onPickTime,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _CompactActionChip(
            icon: Icons.repeat_rounded,
            text: 'No repeat',
          ),
        ),
      ],
    );
  }
}

class _CompactActionChip extends StatelessWidget {
  const _CompactActionChip({
    required this.icon,
    required this.text,
    this.onPressed,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Material(
      color: colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 14,
          color: iconColor ?? colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.text,
    required this.highlighted,
    this.icon,
    this.onPressed,
  });

  final String text;
  final bool highlighted;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final Color backgroundColor = highlighted
        ? colorScheme.tertiaryContainer
        : colorScheme.secondaryContainer;
    final Color foregroundColor = highlighted
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSecondaryContainer;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: foregroundColor),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSuggestionsRow extends StatelessWidget {
  const _AiSuggestionsRow({
    required this.selectedCategoryName,
    required this.points,
  });

  final String selectedCategoryName;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _InfoTag(
          icon: Icons.work_outline_rounded,
          text: selectedCategoryName,
          highlighted: true,
        ),
        _InfoTag(
          icon: Icons.bolt_rounded,
          text: '$points pts',
          highlighted: true,
        ),
      ],
    );
  }
}

final class _DurationOption {
  const _DurationOption({
    required this.label,
    required this.minutes,
    this.isCustom = false,
  });

  final String label;
  final int? minutes;
  final bool isCustom;
}

const List<_DurationOption> _durationOptions = <_DurationOption>[
  _DurationOption(label: '15 min', minutes: 15),
  _DurationOption(label: '30 min', minutes: 30),
  _DurationOption(label: '1 hr', minutes: 60),
  _DurationOption(label: '2 hr', minutes: 120),
  _DurationOption(label: 'Custom', minutes: null, isCustom: true),
];

enum _DurationUnit { minutes, hours }

final class _CustomDurationResult {
  const _CustomDurationResult({
    required this.value,
    required this.unit,
  });

  final int value;
  final _DurationUnit unit;

  int get totalMinutes => unit == _DurationUnit.hours ? value * 60 : value;
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog({
    required this.initialDurationMinutes,
  });

  final int initialDurationMinutes;

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  _DurationUnit _unit = _DurationUnit.minutes;

  @override
  void initState() {
    super.initState();
    final int initialMinutes = widget.initialDurationMinutes;
    if (initialMinutes % 60 == 0) {
      _unit = _DurationUnit.hours;
      _valueController = TextEditingController(text: '${initialMinutes ~/ 60}');
    } else {
      _unit = _DurationUnit.minutes;
      _valueController = TextEditingController(text: '$initialMinutes');
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom duration'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'Enter a number',
              ),
              validator: (String? value) {
                final int? parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_DurationUnit>(
              initialValue: _unit,
              decoration: const InputDecoration(
                labelText: 'Unit',
              ),
              items: const <DropdownMenuItem<_DurationUnit>>[
                DropdownMenuItem(
                  value: _DurationUnit.minutes,
                  child: Text('Minutes'),
                ),
                DropdownMenuItem(
                  value: _DurationUnit.hours,
                  child: Text('Hours'),
                ),
              ],
              onChanged: (_DurationUnit? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _unit = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final int value = int.parse(_valueController.text.trim());
    Navigator.of(context).pop(
      _CustomDurationResult(value: value, unit: _unit),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

sealed class _TimelineItem {
  const _TimelineItem();
}

class _TimelineBoundaryItem extends _TimelineItem {
  const _TimelineBoundaryItem({required this.time});

  final TimeOfDay time;
}

class _TimelineTaskItem extends _TimelineItem {
  const _TimelineTaskItem({
    required this.task,
    required this.startTime,
    required this.endTime,
  });

  final Task task;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
}

class _TimelineGapItem extends _TimelineItem {
  const _TimelineGapItem({
    required this.gapStartTime,
    required this.gapMinutes,
  });

  final TimeOfDay gapStartTime;
  final int gapMinutes;
}

List<_TimelineItem> _buildTimelineItems(
  List<Task> tasks, {
  required Map<String, int> startTimeOverrides,
}) {
  const TimeOfDay dayStart = TimeOfDay(hour: 0, minute: 0);
  const TimeOfDay dayEnd = TimeOfDay(hour: 23, minute: 59);
  const int dayEndMinutes = 1439;

  final List<_TimelineTaskItem> sortedTasks = tasks.map(
    (Task task) {
      final int startMinutes = startTimeOverrides[task.id] ??
          _minutesOfDay(TimeOfDay.fromDateTime(task.createdAt.toLocal()));
      final TimeOfDay startTime = _timeFromMinutes(startMinutes);
      return _TimelineTaskItem(
        task: task,
        startTime: startTime,
        endTime: _timeFromMinutes(startMinutes + 30),
      );
    },
  ).toList(growable: false)
    ..sort((a, b) => _minutesOfDay(a.startTime) - _minutesOfDay(b.startTime));

  final List<_TimelineItem> items = <_TimelineItem>[];
  items.add(const _TimelineBoundaryItem(time: dayStart));

  if (sortedTasks.isEmpty) {
    items.add(
      const _TimelineGapItem(
        gapStartTime: dayStart,
        gapMinutes: dayEndMinutes,
      ),
    );
    items.add(const _TimelineBoundaryItem(time: dayEnd));
    return items;
  }

  final int firstStartMinutes = _minutesOfDay(sortedTasks.first.startTime);
  if (firstStartMinutes > 0) {
    items.add(
      _TimelineGapItem(
        gapStartTime: dayStart,
        gapMinutes: firstStartMinutes,
      ),
    );
  }

  for (int i = 0; i < sortedTasks.length; i++) {
    final _TimelineTaskItem current = sortedTasks[i];
    items.add(current);

    if (i >= sortedTasks.length - 1) continue;

    final _TimelineTaskItem next = sortedTasks[i + 1];
    const int estimatedDurationMinutes = 30;
    final int currentEndMinutes =
        _minutesOfDay(current.startTime) + estimatedDurationMinutes;
    final int nextStartMinutes = _minutesOfDay(next.startTime);
    final int gapMinutes = nextStartMinutes - currentEndMinutes;
    if (gapMinutes > 0) {
      items.add(
        _TimelineGapItem(
          gapStartTime: _timeFromMinutes(currentEndMinutes),
          gapMinutes: gapMinutes,
        ),
      );
    }
  }

  final int lastEndMinutes = _minutesOfDay(sortedTasks.last.endTime);
  if (lastEndMinutes < dayEndMinutes) {
    items.add(
      _TimelineGapItem(
        gapStartTime: _timeFromMinutes(lastEndMinutes),
        gapMinutes: dayEndMinutes - lastEndMinutes,
      ),
    );
  }
  items.add(const _TimelineBoundaryItem(time: dayEnd));

  return items;
}

int _minutesOfDay(TimeOfDay time) => (time.hour * 60) + time.minute;

TimeOfDay _timeFromMinutes(int minutes) {
  final int clamped = minutes.clamp(0, 1439);
  return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
}

String _formatGapDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final int hours = minutes ~/ 60;
  final int remainder = minutes % 60;
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}m';
}

String _formatDurationLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  final int hours = minutes ~/ 60;
  final int remainder = minutes % 60;
  if (remainder == 0) return hours == 1 ? '1 hr' : '$hours hr';
  return '$hours hr $remainder min';
}

String _categoryBadge(String? categoryName) {
  if (categoryName == null || categoryName.trim().isEmpty) {
    return 'G';
  }
  return categoryName.trim().substring(0, 1).toUpperCase();
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatTimeOfDay(TimeOfDay time) {
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatBoundaryTime(TimeOfDay time) {
  final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final String minute = time.minute.toString().padLeft(2, '0');
  final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

String _weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => '',
  };
}

String _monthName(int month) {
  const List<String> monthNames = <String>[
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return monthNames[month];
}
