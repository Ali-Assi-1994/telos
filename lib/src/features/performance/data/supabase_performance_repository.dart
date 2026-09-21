import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/performance/data/performance_dto.dart';
import 'package:telos/src/features/performance/data/performance_repository.dart';
import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/domain/streak.dart';
import 'package:telos/src/services/supabase_service.dart';
import 'package:telos/src/utils/logger.dart';

part 'supabase_performance_repository.g.dart';

@Riverpod(keepAlive: true)
PerformanceRepository performanceRepository(Ref ref) {
  return SupabasePerformanceRepository(ref.watch(supabaseClientProvider));
}

class SupabasePerformanceRepository implements PerformanceRepository {
  const SupabasePerformanceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DailyPerformance> getDailyPerformance({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_daily_performance',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_date': _dateOnly(date),
        },
      );

      if (response is List<dynamic> && response.isNotEmpty) {
        return DailyPerformanceDto(
          response.first as Map<String, dynamic>,
        ).toDomain();
      }
      if (response is Map<String, dynamic>) {
        return DailyPerformanceDto(response).toDomain();
      }
      return const DailyPerformance(
        totalTasks: 0,
        completedTasks: 0,
        completionRate: 0,
        totalPoints: 0,
        earnedPoints: 0,
      );
    } on PostgrestException catch (e, st) {
      AppLogger.performance.error(
        'Failed to load daily performance',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load today\'s progress right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<Streak> getStreak({required String userId}) async {
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_streak',
        params: <String, dynamic>{'p_user_id': userId},
      );

      if (response is List<dynamic> && response.isNotEmpty) {
        return StreakDto(response.first as Map<String, dynamic>).toDomain();
      }
      if (response is Map<String, dynamic>) {
        return StreakDto(response).toDomain();
      }
      return const Streak(currentStreak: 0, longestStreak: 0);
    } on PostgrestException catch (e, st) {
      AppLogger.performance.error(
        'Failed to load streak',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load your streak right now. Please try again.',
        cause: e,
      );
    }
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
