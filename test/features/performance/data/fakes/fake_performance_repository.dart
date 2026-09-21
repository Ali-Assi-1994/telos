import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/performance/data/performance_repository.dart';
import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/domain/streak.dart';

const DailyPerformance _emptyDailyPerformance = DailyPerformance(
  totalTasks: 0,
  completedTasks: 0,
  completionRate: 0,
  totalPoints: 0,
  earnedPoints: 0,
);

const Streak _emptyStreak = Streak(currentStreak: 0, longestStreak: 0);

/// In-memory [PerformanceRepository] fake for provider and widget tests.
class FakePerformanceRepository implements PerformanceRepository {
  FakePerformanceRepository({
    DailyPerformance dailyPerformance = _emptyDailyPerformance,
    Streak streak = _emptyStreak,
  }) : _dailyPerformance = dailyPerformance,
       _streak = streak;

  DailyPerformance _dailyPerformance;
  Streak _streak;

  bool throwOnGetDailyPerformance = false;
  bool throwOnGetStreak = false;

  void setDailyPerformance(DailyPerformance value) {
    _dailyPerformance = value;
  }

  void setStreak(Streak value) {
    _streak = value;
  }

  @override
  Future<DailyPerformance> getDailyPerformance({
    required String userId,
    required DateTime date,
  }) async {
    if (throwOnGetDailyPerformance) {
      throw const DatabaseAppException(
        'Could not load today\'s progress right now. Please try again.',
      );
    }
    return _dailyPerformance;
  }

  @override
  Future<Streak> getStreak({required String userId}) async {
    if (throwOnGetStreak) {
      throw const DatabaseAppException(
        'Could not load your streak right now. Please try again.',
      );
    }
    return _streak;
  }
}
