import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/performance/data/performance_dto.dart';

void main() {
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

  group('StreakDto', () {
    test('parses numeric fields regardless of int/string shape', () {
      final streak = const StreakDto(<String, dynamic>{
        'current_streak': 4,
        'longest_streak': '12',
      }).toDomain();

      expect(streak.currentStreak, 4);
      expect(streak.longestStreak, 12);
    });

    test('defaults missing or unparsable values to zero', () {
      final streak = const StreakDto(<String, dynamic>{
        'current_streak': null,
        'longest_streak': 'not-a-number',
      }).toDomain();

      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
    });
  });
}
