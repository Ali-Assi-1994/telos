import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/domain/streak.dart';

class DailyPerformanceDto {
  const DailyPerformanceDto(this.json);

  final Map<String, dynamic> json;

  DailyPerformance toDomain() {
    return DailyPerformance(
      totalTasks: _toInt(json['total_tasks']),
      completedTasks: _toInt(json['completed_tasks']),
      completionRate: _toDouble(json['completion_rate']),
      totalPoints: _toInt(json['total_points']),
      earnedPoints: _toInt(json['earned_points']),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class StreakDto {
  const StreakDto(this.json);

  final Map<String, dynamic> json;

  Streak toDomain() {
    return Streak(
      currentStreak: _toInt(json['current_streak']),
      longestStreak: _toInt(json['longest_streak']),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
