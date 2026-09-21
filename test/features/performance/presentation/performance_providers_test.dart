import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/performance/data/supabase_performance_repository.dart';
import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/domain/streak.dart';
import 'package:telos/src/features/performance/presentation/performance_providers.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_performance_repository.dart';

void main() {
  late FakePerformanceRepository performanceRepository;
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');

  setUp(() {
    performanceRepository = FakePerformanceRepository();
    authRepository = FakeAuthRepository(initialUser: testUser);
    container = ProviderContainer(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [
        performanceRepositoryProvider.overrideWithValue(performanceRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    // A bare .read(...future) doesn't keep authStateProvider's stream
    // subscription alive long enough to resolve; ref.listen does, matching
    // how a widget's ref.watch would in the real app.
    container.listen(authStateProvider, (_, _) {});
  });

  group('dailyPerformanceForSelectedDateProvider', () {
    test('returns the repository result for the signed-in user', () async {
      performanceRepository.setDailyPerformance(
        const DailyPerformance(
          totalTasks: 5,
          completedTasks: 3,
          completionRate: 60,
          totalPoints: 100,
          earnedPoints: 60,
        ),
      );

      final DailyPerformance result = await container.read(
        dailyPerformanceForSelectedDateProvider.future,
      );

      expect(result.totalTasks, 5);
      expect(result.completedTasks, 3);
      expect(result.completionRate, 60);
    });

    test('returns an empty result when signed out', () async {
      await authRepository.signOut();

      final DailyPerformance result = await container.read(
        dailyPerformanceForSelectedDateProvider.future,
      );

      expect(result.totalTasks, 0);
      expect(result.completedTasks, 0);
      expect(result.completionRate, 0);
    });

    test('surfaces repository failures as an AppException', () async {
      performanceRepository.throwOnGetDailyPerformance = true;

      await expectLater(
        container.read(dailyPerformanceForSelectedDateProvider.future),
        throwsA(isA<DatabaseAppException>()),
      );
    });
  });

  group('streakProvider', () {
    test('returns the repository result for the signed-in user', () async {
      performanceRepository.setStreak(
        const Streak(currentStreak: 4, longestStreak: 12),
      );

      final Streak result = await container.read(streakProvider.future);

      expect(result.currentStreak, 4);
      expect(result.longestStreak, 12);
    });

    test('returns a zeroed streak when signed out', () async {
      await authRepository.signOut();

      final Streak result = await container.read(streakProvider.future);

      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
    });

    test('surfaces repository failures as an AppException', () async {
      performanceRepository.throwOnGetStreak = true;

      await expectLater(
        container.read(streakProvider.future),
        throwsA(isA<DatabaseAppException>()),
      );
    });
  });
}
