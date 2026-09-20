import 'package:flutter/material.dart';

import 'package:telos/src/features/tasks/domain/task.dart';

/// Pure data model for [TasksTimelineSection]'s rendering: a flattened,
/// time-ordered sequence of day-boundary markers, tasks, and free-time gaps.
sealed class TimelineItem {
  const TimelineItem();
}

class TimelineBoundaryItem extends TimelineItem {
  const TimelineBoundaryItem({required this.time});

  final TimeOfDay time;
}

class TimelineTaskItem extends TimelineItem {
  const TimelineTaskItem({
    required this.task,
    required this.startTime,
    required this.endTime,
  });

  final Task task;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
}

class TimelineGapItem extends TimelineItem {
  const TimelineGapItem({required this.gapStartTime, required this.gapMinutes});

  final TimeOfDay gapStartTime;
  final int gapMinutes;
}

List<TimelineItem> buildTimelineItems(
  List<Task> tasks, {
  required Map<String, int> startTimeOverrides,
}) {
  const TimeOfDay dayStart = TimeOfDay(hour: 0, minute: 0);
  const TimeOfDay dayEnd = TimeOfDay(hour: 23, minute: 59);
  const int dayEndMinutes = 1439;

  final List<TimelineTaskItem> sortedTasks =
      tasks
          .map((Task task) {
            final int startMinutes =
                startTimeOverrides[task.id] ??
                _minutesOfDay(TimeOfDay.fromDateTime(task.createdAt.toLocal()));
            final TimeOfDay startTime = _timeFromMinutes(startMinutes);
            return TimelineTaskItem(
              task: task,
              startTime: startTime,
              endTime: _timeFromMinutes(startMinutes + 30),
            );
          })
          .toList(growable: false)
        ..sort(
          (a, b) => _minutesOfDay(a.startTime) - _minutesOfDay(b.startTime),
        );

  final List<TimelineItem> items = <TimelineItem>[];
  items.add(const TimelineBoundaryItem(time: dayStart));

  if (sortedTasks.isEmpty) {
    items.add(
      const TimelineGapItem(gapStartTime: dayStart, gapMinutes: dayEndMinutes),
    );
    items.add(const TimelineBoundaryItem(time: dayEnd));
    return items;
  }

  final int firstStartMinutes = _minutesOfDay(sortedTasks.first.startTime);
  if (firstStartMinutes > 0) {
    items.add(
      TimelineGapItem(gapStartTime: dayStart, gapMinutes: firstStartMinutes),
    );
  }

  for (int i = 0; i < sortedTasks.length; i++) {
    final TimelineTaskItem current = sortedTasks[i];
    items.add(current);

    if (i >= sortedTasks.length - 1) continue;

    final TimelineTaskItem next = sortedTasks[i + 1];
    const int estimatedDurationMinutes = 30;
    final int currentEndMinutes =
        _minutesOfDay(current.startTime) + estimatedDurationMinutes;
    final int nextStartMinutes = _minutesOfDay(next.startTime);
    final int gapMinutes = nextStartMinutes - currentEndMinutes;
    if (gapMinutes > 0) {
      items.add(
        TimelineGapItem(
          gapStartTime: _timeFromMinutes(currentEndMinutes),
          gapMinutes: gapMinutes,
        ),
      );
    }
  }

  final int lastEndMinutes = _minutesOfDay(sortedTasks.last.endTime);
  if (lastEndMinutes < dayEndMinutes) {
    items.add(
      TimelineGapItem(
        gapStartTime: _timeFromMinutes(lastEndMinutes),
        gapMinutes: dayEndMinutes - lastEndMinutes,
      ),
    );
  }
  items.add(const TimelineBoundaryItem(time: dayEnd));

  return items;
}

int _minutesOfDay(TimeOfDay time) => (time.hour * 60) + time.minute;

TimeOfDay _timeFromMinutes(int minutes) {
  final int clamped = minutes.clamp(0, 1439);
  return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
}
