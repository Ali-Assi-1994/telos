import 'package:flutter/material.dart';

import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/widgets/task_time_format.dart';
import 'package:telos/src/features/tasks/presentation/widgets/timeline_builder.dart';

/// Vertical timeline of the day's not-yet-completed tasks, with free-time
/// gaps a user can tap to schedule a new task into.
class TasksTimelineSection extends StatelessWidget {
  const TasksTimelineSection({
    super.key,
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
    final List<TimelineItem> timelineItems = buildTimelineItems(
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
              final TimelineItem item = timelineItems[index];
              return switch (item) {
                final TimelineBoundaryItem boundaryItem => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TimelineBoundaryBlock(time: boundaryItem.time),
                ),
                final TimelineTaskItem taskItem => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TimelineTaskBlock(
                    task: taskItem.task,
                    startTime: taskItem.startTime,
                    endTime: taskItem.endTime,
                    onToggleCompleted: () => onToggleCompleted(taskItem.task),
                  ),
                ),
                final TimelineGapItem gapItem => Padding(
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
            formatTimeOfDay(startTime),
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
            formatTimeOfDay(endTime),
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
    final Category? firstCategory = task.categories.isNotEmpty
        ? task.categories.first
        : null;

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
                              '${formatTimeOfDay(startTime)} - ${formatTimeOfDay(endTime)}',
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
                    label: _categoryBadge(firstCategory?.name),
                  ),
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

String _formatGapDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final int hours = minutes ~/ 60;
  final int remainder = minutes % 60;
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}m';
}

String _categoryBadge(String? categoryName) {
  if (categoryName == null || categoryName.trim().isEmpty) {
    return 'G';
  }
  return categoryName.trim().substring(0, 1).toUpperCase();
}

String _formatBoundaryTime(TimeOfDay time) {
  final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final String minute = time.minute.toString().padLeft(2, '0');
  final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}
