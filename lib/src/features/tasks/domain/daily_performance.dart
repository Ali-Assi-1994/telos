import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_performance.freezed.dart';
part 'daily_performance.g.dart';

@freezed
class DailyPerformance with _$DailyPerformance {
  const factory DailyPerformance({
    required int totalTasks,
    required int completedTasks,
    required double completionRate,
    required int totalPoints,
    required int earnedPoints,
  }) = _DailyPerformance;

  factory DailyPerformance.fromJson(Map<String, dynamic> json) =>
      _$DailyPerformanceFromJson(json);
}
