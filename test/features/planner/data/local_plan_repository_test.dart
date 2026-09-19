import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/data/repositories/local_plan_repository.dart';
import 'package:pathetic_people/data/repositories/mock_app_repository.dart';
import 'package:pathetic_people/domain/models/plan_item.dart';

void main() {
  test('LocalPlanRepository adapts synchronous mock plan operations', () async {
    final now = DateTime(2026, 8, 25, 12);
    final appRepository = MockAppRepository(clock: () => now);
    final repository = LocalPlanRepository(appRepository);
    addTearDown(appRepository.dispose);
    final draft = PlanDraft(
      title: '로컬 어댑터 계획',
      scheduledAt: now.subtract(const Duration(minutes: 10)),
      verificationDueAt: now.add(const Duration(hours: 1)),
      category: PlanCategory.study,
      recurrence: '없음',
      experiencePoint: 10,
      visibility: PlanVisibility.private,
      photoProofRequired: false,
    );

    final created = await repository.createPlan(draft);
    final started = await repository.recordStartProof(
      created.id,
      const PlanProofDraft(
        type: PlanProofType.start,
        note: '시작',
        sharedToFeed: false,
      ),
    );
    final completed = await repository.recordCompletionProof(
      created.id,
      const PlanProofDraft(
        type: PlanProofType.completion,
        note: '완료',
        sharedToFeed: false,
      ),
    );
    final fetched = await repository.fetchPlans(
      from: now.subtract(const Duration(days: 1)),
      to: now.add(const Duration(days: 1)),
    );

    expect(repository.supportsUpdate, isTrue);
    expect(repository.supportsDelete, isTrue);
    expect(started.startProof?.note, '시작');
    expect(completed.progress, PlanProgress.completed);
    expect(fetched.any((plan) => plan.id == created.id), isTrue);
  });
}
