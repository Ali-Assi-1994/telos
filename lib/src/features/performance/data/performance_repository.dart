import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/domain/streak.dart';

abstract class PerformanceRepository {
  Future<DailyPerformance> getDailyPerformance({
    required String userId,
    required DateTime date,
  });

  Future<Streak> getStreak({required String userId});
}
