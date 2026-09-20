import 'package:flutter/material.dart';

import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';

/// List of completed tasks for the selected day, shown below the timeline.
class AnytimeSection extends StatelessWidget {
  const AnytimeSection({
    super.key,
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            itemCount: tasks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final Task task = tasks[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == tasks.length - 1 ? 0 : 8,
                ),
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
  const _AnytimeTaskTile({required this.task, required this.onToggleCompleted});

  final Task task;
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
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
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
