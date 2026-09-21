// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
// The ProviderScope built by buildApp() below is the root scope for the
// widget tree under test (it's passed straight to tester.pumpWidget), but
// riverpod_lint can't trace that through the helper function indirection and
// conservatively warns as if it might be a nested scope.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/presentation/daily_progress_widget.dart';
import 'package:telos/src/features/performance/presentation/performance_providers.dart';

void main() {
  Widget buildApp(AsyncValue<DailyPerformance> state) {
    return ProviderScope(
      overrides: [
        dailyPerformanceForSelectedDateProvider.overrideWith(
          (Ref ref) => state.when(
            data: (DailyPerformance value) =>
                Future<DailyPerformance>.value(value),
            loading: () => Completer<DailyPerformance>().future,
            error: (Object error, StackTrace stackTrace) =>
                Future<DailyPerformance>.error(error, stackTrace),
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: DailyProgressWidget())),
    );
  }

  testWidgets('shows completion rate and points when tasks are assigned', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const AsyncData<DailyPerformance>(
          DailyPerformance(
            totalTasks: 5,
            completedTasks: 3,
            completionRate: 60,
            totalPoints: 100,
            earnedPoints: 60,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/5 tasks'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('60/100 pts'), findsOneWidget);
  });

  testWidgets('renders nothing when no tasks are assigned for the day', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const AsyncData<DailyPerformance>(
          DailyPerformance(
            totalTasks: 0,
            completedTasks: 0,
            completionRate: 0,
            totalPoints: 0,
            earnedPoints: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DailyProgressWidget), findsOneWidget);
    expect(find.textContaining('tasks'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('pts'), findsNothing);
  });

  testWidgets('renders nothing while the daily performance is loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(const AsyncLoading<DailyPerformance>()));
    await tester.pump();

    expect(find.textContaining('tasks'), findsNothing);
  });

  testWidgets('renders nothing (no punitive copy) when loading fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        AsyncError<DailyPerformance>(Exception('boom'), StackTrace.empty),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('tasks'), findsNothing);
    expect(find.textContaining('fail'), findsNothing);
    expect(find.textContaining('error'), findsNothing);
  });
}
