import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/domain/rules/plan_timing_policy.dart';

void main() {
  group('PlanTimingPolicy', () {
    test('시작 인증은 예정 시각 정확히 1시간 전부터 가능하다', () {
      final scheduledAt = DateTime.utc(2026, 9, 19, 10);
      final dueAt = scheduledAt.add(const Duration(hours: 2));

      expect(
        PlanTimingPolicy.canRecordStartProof(
          scheduledAt: scheduledAt,
          verificationDueAt: dueAt,
          now: scheduledAt.subtract(const Duration(hours: 1, seconds: 1)),
        ),
        isFalse,
      );
      expect(
        PlanTimingPolicy.canRecordStartProof(
          scheduledAt: scheduledAt,
          verificationDueAt: dueAt,
          now: scheduledAt.subtract(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });

    test('완료 인증은 시작 예정 시각부터 가능하다', () {
      final scheduledAt = DateTime.utc(2026, 9, 19, 10);
      final dueAt = scheduledAt.add(const Duration(hours: 2));

      expect(
        PlanTimingPolicy.canRecordCompletionProof(
          scheduledAt: scheduledAt,
          verificationDueAt: dueAt,
          now: scheduledAt.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(
        PlanTimingPolicy.canRecordCompletionProof(
          scheduledAt: scheduledAt,
          verificationDueAt: dueAt,
          now: scheduledAt,
        ),
        isTrue,
      );
    });

    test('남은 시간은 서로 다른 UTC offset이어도 실제 순간 기준으로 계산한다', () {
      final now = DateTime.parse('2026-09-19T19:11:00+09:00');
      final target = DateTime.parse('2026-09-19T10:15:00Z');

      expect(PlanTimingPolicy.until(target, now), const Duration(minutes: 4));
    });
  });
}
