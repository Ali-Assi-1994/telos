import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/tasks/data/task_dto.dart';
import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';

void main() {
  group('CategoryDto', () {
    test('maps all fields', () {
      final Category category = const CategoryDto(<String, dynamic>{
        'id': 1,
        'name': 'Work',
        'icon': 'briefcase',
        'color': '#FF9E9E9E',
      }).toDomain();

      expect(category.id, 1);
      expect(category.name, 'Work');
      expect(category.icon, 'briefcase');
      expect(category.color, '#FF9E9E9E');
    });

    test('leaves icon and color null when absent', () {
      final Category category = const CategoryDto(<String, dynamic>{
        'id': 2,
        'name': 'Health',
      }).toDomain();

      expect(category.icon, isNull);
      expect(category.color, isNull);
    });
  });

  group('TaskDto', () {
    Map<String, dynamic> baseRow({
      dynamic taskCategories,
      bool? completed,
      String? completedAt,
      bool? isLocked,
    }) {
      return <String, dynamic>{
        'id': 'task-1',
        'template_id': null,
        'user_id': 'user-1',
        'title': 'Write report',
        'description': 'Quarterly report',
        'points': 20,
        'assigned_date': '2026-01-15',
        'completed': completed,
        'completed_at': completedAt,
        'is_locked': isLocked,
        'created_at': '2026-01-15T09:00:00.000Z',
        'updated_at': '2026-01-15T09:00:00.000Z',
        if (taskCategories != null) 'task_categories': taskCategories,
      };
    }

    test('maps a full row with nested categories', () {
      final Task task = TaskDto(
        baseRow(
          taskCategories: <Map<String, dynamic>>[
            <String, dynamic>{
              'category_id': 1,
              'categories': <String, dynamic>{
                'id': 1,
                'name': 'Work',
                'icon': null,
                'color': null,
              },
            },
          ],
          completed: true,
          completedAt: '2026-01-15T18:00:00.000Z',
          isLocked: false,
        ),
      ).toDomain();

      expect(task.id, 'task-1');
      expect(task.title, 'Write report');
      expect(task.points, 20);
      expect(task.completed, isTrue);
      expect(task.completedAt, DateTime.parse('2026-01-15T18:00:00.000Z'));
      expect(task.categories, hasLength(1));
      expect(task.categories.single.name, 'Work');
    });

    test(
        'defaults completed/isLocked to false and categories to empty '
        'when the row omits them', () {
      final Task task = TaskDto(baseRow()).toDomain();

      expect(task.completed, isFalse);
      expect(task.isLocked, isFalse);
      expect(task.completedAt, isNull);
      expect(task.categories, isEmpty);
    });

    test('filters out task_categories entries whose category was deleted', () {
      final Task task = TaskDto(
        baseRow(
          taskCategories: <Map<String, dynamic>>[
            <String, dynamic>{'category_id': 1, 'categories': null},
            <String, dynamic>{
              'category_id': 2,
              'categories': <String, dynamic>{
                'id': 2,
                'name': 'Health',
              },
            },
          ],
        ),
      ).toDomain();

      expect(task.categories, hasLength(1));
      expect(task.categories.single.name, 'Health');
    });
  });

  group('DailyPerformanceDto', () {
    test('parses numeric fields regardless of int/double/string shape', () {
      final performance = const DailyPerformanceDto(<String, dynamic>{
        'total_tasks': 5,
        'completed_tasks': '3',
        'completion_rate': 60.0,
        'total_points': 100,
        'earned_points': '60',
      }).toDomain();

      expect(performance.totalTasks, 5);
      expect(performance.completedTasks, 3);
      expect(performance.completionRate, 60.0);
      expect(performance.totalPoints, 100);
      expect(performance.earnedPoints, 60);
    });

    test('defaults missing or unparsable values to zero', () {
      final performance = const DailyPerformanceDto(<String, dynamic>{
        'total_tasks': null,
        'completed_tasks': 'not-a-number',
      }).toDomain();

      expect(performance.totalTasks, 0);
      expect(performance.completedTasks, 0);
      expect(performance.completionRate, 0);
      expect(performance.totalPoints, 0);
      expect(performance.earnedPoints, 0);
    });
  });
}
