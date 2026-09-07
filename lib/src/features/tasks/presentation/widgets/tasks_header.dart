import 'package:flutter/material.dart';

import 'package:telos/src/features/tasks/presentation/widgets/date_carousel.dart';

/// Month label, streak/task-count badge, and the swipeable week date picker
/// shown at the top of [TasksScreen].
class TasksHeader extends StatelessWidget {
  const TasksHeader({
    super.key,
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
          DateCarousel(
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
