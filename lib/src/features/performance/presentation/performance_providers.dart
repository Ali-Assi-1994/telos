import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/performance/data/supabase_performance_repository.dart';
import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/domain/streak.dart';
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';

part 'performance_providers.g.dart';

@riverpod
Future<DailyPerformance> dailyPerformanceForSelectedDate(Ref ref) async {
  final DateTime date = ref.watch(selectedDateProvider);
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    return const DailyPerformance(
      totalTasks: 0,
      completedTasks: 0,
      completionRate: 0,
      totalPoints: 0,
      earnedPoints: 0,
    );
  }

  return ref
      .read(performanceRepositoryProvider)
      .getDailyPerformance(userId: user.id, date: date);
}

@riverpod
Future<Streak> streak(Ref ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    return const Streak(currentStreak: 0, longestStreak: 0);
  }

  return ref.read(performanceRepositoryProvider).getStreak(userId: user.id);
}
