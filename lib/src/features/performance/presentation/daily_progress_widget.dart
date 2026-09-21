import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telos/src/features/performance/domain/daily_performance.dart';
import 'package:telos/src/features/performance/presentation/performance_providers.dart';

/// Completion rate and points earned for the selected day.
///
/// Renders nothing when the day has no assigned tasks, is still loading, or
/// fails to load — see docs/business_rules.md "Daily Performance": a day
/// with no tasks has no completion rate, so it shows nothing rather than 0%.
class DailyProgressWidget extends ConsumerWidget {
  const DailyProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DailyPerformance> performanceState = ref.watch(
      dailyPerformanceForSelectedDateProvider,
    );

    return performanceState.when(
      data: (DailyPerformance performance) {
        if (performance.totalTasks == 0) return const SizedBox.shrink();
        return _DailyProgressCard(performance: performance);
      },
      loading: () => const SizedBox.shrink(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.performance});

  final DailyPerformance performance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final int ratePercent = performance.completionRate.round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${performance.completedTasks}/${performance.totalTasks} '
                'tasks',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$ratePercent%',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (performance.completionRate / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${performance.earnedPoints}/${performance.totalPoints} pts',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
