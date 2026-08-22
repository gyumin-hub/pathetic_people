import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../view_models/profile_view_model.dart';

class ProfileStatsView extends StatelessWidget {
  const ProfileStatsView({
    required this.monthlySuccessRate,
    required this.failureCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.recentDays,
    super.key,
  });

  final double monthlySuccessRate;
  final int failureCount;
  final int currentStreak;
  final int bestStreak;
  final List<ProfileDayStat> recentDays;

  @override
  Widget build(BuildContext context) {
    final successPercentage = (monthlySuccessRate * 100).round();
    final recentCompletedCount = recentDays.fold(
      0,
      (sum, day) => sum + day.completedCount,
    );
    final recentPlanCount = recentDays.fold(
      0,
      (sum, day) => sum + day.totalCount,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 달 기록', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: '계획 성공률',
                  value: '$successPercentage%',
                  icon: Icons.task_alt_rounded,
                  accent: AppPalette.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: '실패 기록',
                  value: '$failureCount회',
                  icon: Icons.warning_amber_rounded,
                  accent: AppPalette.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '최근 7일 달성',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      recentPlanCount == 0
                          ? '기록 없음'
                          : '$recentCompletedCount / $recentPlanCount개',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppPalette.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 116,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: recentDays
                        .map((day) => Expanded(child: _DayBar(day: day)))
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('꾸준함', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: AppPalette.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppPalette.redSoft,
                  foregroundColor: AppPalette.red,
                  child: Icon(Icons.local_fire_department_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StreakValue(label: '현재 연속', value: '$currentStreak일'),
                ),
                Container(width: 1, height: 38, color: AppPalette.line),
                const SizedBox(width: 18),
                Expanded(
                  child: _StreakValue(label: '최고 기록', value: '$bestStreak일'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 18),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  final ProfileDayStat day;

  @override
  Widget build(BuildContext context) {
    final barHeight = day.hasPlans ? (18 + (60 * day.completionRate)) : 8.0;
    final barColor = !day.hasPlans
        ? AppPalette.surfaceStrong
        : day.hasFailure
        ? AppPalette.red
        : day.isSuccessful
        ? AppPalette.blue
        : AppPalette.blue.withValues(alpha: 0.35);
    final status = day.hasPlans
        ? '${day.completedCount}/${day.totalCount}개 달성'
        : '계획 없음';

    return Tooltip(
      message: '${day.date.month}월 ${day.date.day}일 · $status',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 17,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _weekdayLabels[day.date.weekday - 1],
            style: const TextStyle(color: AppPalette.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StreakValue extends StatelessWidget {
  const _StreakValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
