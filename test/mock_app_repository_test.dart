import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/data/repositories/mock_app_repository.dart';
import 'package:pathetic_people/domain/models/app_preferences.dart';
import 'package:pathetic_people/domain/models/feed_post.dart';
import 'package:pathetic_people/domain/models/plan_item.dart';

void main() {
  group('MockAppRepository', () {
    test('좋아요 상태와 개수를 함께 변경한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final before = repository.posts.first;

      repository.togglePostLike(before.id);

      final after = repository.posts.first;
      expect(after.isLiked, isNot(before.isLiked));
      expect(after.likes, before.likes + (before.isLiked ? -1 : 1));
    });

    test('새 계획에 시작 시각과 인증 종료 규칙을 저장한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final beforeCount = repository.plans.length;
      final scheduledAt = DateTime.now().add(const Duration(days: 2));
      final verificationDueAt = scheduledAt.add(const Duration(hours: 2));

      repository.addPlan(
        _planDraft(
          title: '테스트 계획',
          scheduledAt: scheduledAt,
          verificationDueAt: verificationDueAt,
          visibility: PlanVisibility.publicChallenge,
          photoProofRequired: true,
        ),
      );

      final plan = repository.plans.firstWhere(
        (item) => item.title == '테스트 계획',
      );
      expect(repository.plans, hasLength(beforeCount + 1));
      expect(plan.scheduledAt, scheduledAt);
      expect(plan.verificationDueAt, verificationDueAt);
      expect(plan.visibility, PlanVisibility.publicChallenge);
      expect(plan.photoProofRequired, isTrue);
    });

    test('인증 종료 시각은 시작 시각보다 반드시 뒤여야 한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final scheduledAt = DateTime(2026, 1, 1, 9);

      expect(
        () => repository.addPlan(
          _planDraft(
            title: '잘못된 인증 시간',
            scheduledAt: scheduledAt,
            verificationDueAt: scheduledAt,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('시작 인증을 계획에 저장한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(repository, title: '시작 인증 테스트');
      final mediaBytes = Uint8List.fromList([1, 2, 3]);

      repository.startPlan(
        plan.id,
        PlanProofDraft(
          type: PlanProofType.start,
          mediaBytes: mediaBytes,
          mediaName: 'start.jpg',
          note: '  운동복 착용 완료  ',
          sharedToFeed: true,
        ),
      );

      final saved = _planById(repository, plan.id).startProof!;
      expect(saved.type, PlanProofType.start);
      expect(saved.mediaBytes, orderedEquals(mediaBytes));
      expect(saved.mediaName, 'start.jpg');
      expect(saved.note, '운동복 착용 완료');
      expect(saved.sharedToFeed, isTrue);
    });

    test('시작 예정 전에는 시작·완료 인증을 저장할 수 없다', () {
      final now = DateTime(2026, 8, 22, 12);
      final repository = MockAppRepository(clock: () => now);
      addTearDown(repository.dispose);
      final plan = _addPlan(
        repository,
        title: '미래 계획 인증 차단',
        scheduledAt: now.add(const Duration(hours: 1)),
        verificationDueAt: now.add(const Duration(hours: 2)),
      );

      expect(
        () => repository.startPlan(
          plan.id,
          const PlanProofDraft(
            type: PlanProofType.start,
            note: '',
            sharedToFeed: false,
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => repository.completePlan(
          plan.id,
          _completionProof(sharedToFeed: false),
        ),
        throwsA(isA<StateError>()),
      );
      expect(_planById(repository, plan.id).startProof, isNull);
      expect(_planById(repository, plan.id).progress, PlanProgress.pending);
    });

    test('완료 인증 공유를 켜면 인증 내용이 포함된 성공 게시물을 만든다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(
        repository,
        title: '성공 공유 테스트',
        photoProofRequired: true,
      );
      final mediaBytes = Uint8List.fromList([4, 5, 6]);

      repository.completePlan(
        plan.id,
        PlanProofDraft(
          type: PlanProofType.completion,
          mediaBytes: mediaBytes,
          mediaName: 'done.jpg',
          note: '  60분 운동 완료  ',
          sharedToFeed: true,
        ),
      );

      final completed = _planById(repository, plan.id);
      final post = repository.posts.firstWhere(
        (item) => item.sourcePlanId == plan.id,
      );
      expect(completed.progress, PlanProgress.completed);
      expect(completed.completionProof?.note, '60분 운동 완료');
      expect(post.outcome, PostOutcome.success);
      expect(post.mediaBytes, orderedEquals(mediaBytes));
      expect(post.proofNote, '60분 운동 완료');

      repository.togglePostLike(post.id);
      final copiedPost = repository.posts.firstWhere(
        (item) => item.id == post.id,
      );
      expect(copiedPost.sourcePlanId, plan.id);
      expect(copiedPost.mediaBytes, orderedEquals(mediaBytes));
      expect(copiedPost.proofNote, '60분 운동 완료');
    });

    test('완료 인증 공유를 끄면 성공 게시물을 만들지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(repository, title: '성공 비공유 테스트');

      repository.completePlan(plan.id, _completionProof(sharedToFeed: false));

      expect(_planById(repository, plan.id).progress, PlanProgress.completed);
      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isFalse,
      );
    });

    test('피드에 공유하려면 완료 사진이 필요하다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(repository, title: '피드 사진 검증 테스트');

      expect(
        () => repository.completePlan(
          plan.id,
          _completionProof(sharedToFeed: true),
        ),
        throwsA(isA<StateError>()),
      );
      expect(_planById(repository, plan.id).progress, PlanProgress.pending);
    });

    test('사진 필수 계획은 사진 없이 완료할 수 없다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(
        repository,
        title: '사진 필수 테스트',
        photoProofRequired: true,
      );

      expect(
        () => repository.completePlan(
          plan.id,
          _completionProof(sharedToFeed: true),
        ),
        throwsA(isA<StateError>()),
      );
      expect(_planById(repository, plan.id).progress, PlanProgress.pending);
      expect(_planById(repository, plan.id).completionProof, isNull);
    });

    test('시작 시각이 지나도 인증 종료 전에는 실패 처리하지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final scheduledAt = DateTime(2026, 1, 1, 9);
      final verificationDueAt = DateTime(2026, 1, 1, 10);
      final plan = _addPlan(
        repository,
        title: '인증 종료 기준 테스트',
        scheduledAt: scheduledAt,
        verificationDueAt: verificationDueAt,
      );

      repository.markOverduePlans(DateTime(2026, 1, 1, 9, 30));
      expect(_planById(repository, plan.id).progress, PlanProgress.pending);

      repository.markOverduePlans(verificationDueAt);
      expect(_planById(repository, plan.id).progress, PlanProgress.failed);
    });

    test('개인 계획 실패는 개인 멘토 메시지만 만들고 외부에 공개하지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final systemMessageCount = repository
          .messagesForRoom('system-room')
          .length;
      final groupMessageCount = repository.messagesForRoom('group-room').length;
      final plan = _addPlan(
        repository,
        title: '개인 실패 테스트',
        scheduledAt: DateTime(2026, 1, 1, 8),
        verificationDueAt: DateTime(2026, 1, 1, 9),
        visibility: PlanVisibility.private,
      );

      repository.markOverduePlans(DateTime(2026, 1, 1, 9));

      expect(_planById(repository, plan.id).progress, PlanProgress.failed);
      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isFalse,
      );
      expect(
        repository.messagesForRoom('system-room').length,
        greaterThan(systemMessageCount),
      );
      expect(
        repository.messagesForRoom('group-room'),
        hasLength(groupMessageCount),
      );
      expect(
        repository.chatRooms
            .firstWhere((room) => room.id == 'system-room')
            .title,
        'motive 독설 멘토',
      );
    });

    test('공개 도전 실패는 실패 피드와 그룹 시스템 메시지를 만든다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final groupMessageCount = repository.messagesForRoom('group-room').length;
      final plan = _addPlan(
        repository,
        title: '공개 실패 테스트',
        scheduledAt: DateTime(2026, 1, 2, 8),
        verificationDueAt: DateTime(2026, 1, 2, 9),
        visibility: PlanVisibility.publicChallenge,
      );

      repository.markOverduePlans(DateTime(2026, 1, 2, 9));

      final post = repository.posts.firstWhere(
        (item) => item.sourcePlanId == plan.id,
      );
      expect(post.outcome, PostOutcome.failure);
      expect(
        repository.messagesForRoom('group-room').length,
        greaterThan(groupMessageCount),
      );
      expect(
        repository.messagesForRoom('group-room').last.message,
        contains(plan.title),
      );
    });

    test('단체방 알림을 꺼도 개인 독설은 남고 그룹에는 보내지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      repository.updatePreferences(systemChatAlertEnabled: false);
      final personalCount = repository.messagesForRoom('system-room').length;
      final groupCount = repository.messagesForRoom('group-room').length;
      final plan = _addPlan(
        repository,
        title: '단체방 알림 끄기 테스트',
        scheduledAt: DateTime(2026, 1, 2, 10),
        verificationDueAt: DateTime(2026, 1, 2, 11),
        visibility: PlanVisibility.publicChallenge,
      );

      repository.markOverduePlans(DateTime(2026, 1, 2, 11));

      expect(
        repository.messagesForRoom('system-room').length,
        greaterThan(personalCount),
      );
      expect(repository.messagesForRoom('group-room'), hasLength(groupCount));
      expect(_planById(repository, plan.id).progress, PlanProgress.failed);
    });

    test('전역 실패 공개를 끄면 공개 도전도 실패 피드를 만들지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      repository.updatePreferences(
        publicFailureEnabled: false,
        mentorIntensity: MentorIntensity.mild,
      );
      final plan = _addPlan(
        repository,
        title: '전역 공개 끄기 테스트',
        scheduledAt: DateTime(2026, 1, 3, 8),
        verificationDueAt: DateTime(2026, 1, 3, 9),
        visibility: PlanVisibility.publicChallenge,
      );

      repository.markOverduePlans(DateTime(2026, 1, 3, 9));

      expect(_planById(repository, plan.id).progress, PlanProgress.failed);
      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isFalse,
      );
    });

    test('실패한 계획은 나중에 완료 처리해 실패 기록을 지울 수 없다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(
        repository,
        title: '실패 보존 테스트',
        scheduledAt: DateTime(2026, 1, 4, 8),
        verificationDueAt: DateTime(2026, 1, 4, 9),
        visibility: PlanVisibility.publicChallenge,
      );
      repository.markOverduePlans(DateTime(2026, 1, 4, 9));

      expect(
        () => repository.completePlan(
          plan.id,
          _completionProof(sharedToFeed: true),
        ),
        throwsA(isA<StateError>()),
      );
      expect(_planById(repository, plan.id).progress, PlanProgress.failed);
      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isTrue,
      );
      expect(
        () => repository.updatePlan(
          plan.id,
          _planDraft(
            title: '실패 기록 덮어쓰기 시도',
            scheduledAt: DateTime(2026, 1, 5, 8),
            verificationDueAt: DateTime(2026, 1, 5, 9),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isTrue,
      );
    });

    test('반복 회차는 시작부터 인증 종료까지의 간격을 보존한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final scheduledAt = DateTime.now().add(const Duration(days: 2));
      final verificationDueAt = scheduledAt.add(
        const Duration(hours: 1, minutes: 30),
      );

      repository.addPlan(
        _planDraft(
          title: '매일 반복 테스트',
          scheduledAt: scheduledAt,
          verificationDueAt: verificationDueAt,
          recurrence: '매일',
        ),
      );

      final occurrences = repository.plans
          .where((plan) => plan.title == '매일 반복 테스트')
          .toList();
      expect(occurrences.length, greaterThan(1));
      expect(
        occurrences.every(
          (plan) =>
              plan.verificationDueAt.difference(plan.scheduledAt) ==
              const Duration(hours: 1, minutes: 30),
        ),
        isTrue,
      );
    });

    test('팔로우 변경은 양쪽 사용자 수치에도 반영한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final target = repository.userById('seoyun')!;
      final followingBefore = repository.currentUser.following;

      repository.toggleFollow(target.id);

      expect(repository.userById(target.id)!.followers, target.followers + 1);
      expect(repository.currentUser.following, followingBefore + 1);
    });

    test('반복 계획을 수정해도 회차 ID가 중복되지 않는다', () {
      var currentTime = DateTime.now();
      final repository = MockAppRepository(clock: () => currentTime);
      addTearDown(repository.dispose);
      final scheduledAt = currentTime.add(const Duration(days: 2));
      final draft = _planDraft(
        title: '수정 반복 테스트',
        scheduledAt: scheduledAt,
        verificationDueAt: scheduledAt.add(const Duration(hours: 1)),
        recurrence: '매일',
      );
      repository.addPlan(draft);
      final before = repository.plans
          .where((plan) => plan.title == draft.title)
          .toList();
      currentTime = before[1].scheduledAt.add(const Duration(minutes: 1));
      repository.completePlan(
        before[1].id,
        _completionProof(sharedToFeed: false),
      );

      repository.updatePlan(before.first.id, draft);

      final after = repository.plans
          .where((plan) => plan.title == draft.title)
          .toList();
      expect(after.map((plan) => plan.id).toSet(), hasLength(after.length));
    });

    test('계획 삭제 시 자동 생성 게시물도 함께 정리한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = _addPlan(repository, title: '삭제 테스트');
      repository.completePlan(
        plan.id,
        PlanProofDraft(
          type: PlanProofType.completion,
          mediaBytes: Uint8List.fromList([7, 8, 9]),
          mediaName: 'delete-test.jpg',
          note: '완료했습니다.',
          sharedToFeed: true,
        ),
      );
      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isTrue,
      );

      repository.deletePlan(plan.id);

      expect(
        repository.posts.any((post) => post.sourcePlanId == plan.id),
        isFalse,
      );
    });

    test('오늘 공개 도전 seed에는 공유된 시작 인증이 있다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);

      final publicPlan = repository.plans.firstWhere(
        (plan) => plan.id == 'plan-workout',
      );
      final privatePlan = repository.plans.firstWhere(
        (plan) => plan.id == 'plan-diary',
      );
      expect(publicPlan.visibility, PlanVisibility.publicChallenge);
      expect(publicPlan.startProof?.type, PlanProofType.start);
      expect(publicPlan.startProof?.sharedToFeed, isTrue);
      expect(privatePlan.visibility, PlanVisibility.private);
    });
  });
}

PlanDraft _planDraft({
  required String title,
  DateTime? scheduledAt,
  DateTime? verificationDueAt,
  PlanCategory category = PlanCategory.study,
  String recurrence = '없음',
  int experiencePoint = 10,
  PlanVisibility visibility = PlanVisibility.private,
  bool photoProofRequired = false,
}) {
  final start = scheduledAt ?? DateTime.now().add(const Duration(days: 1));
  return PlanDraft(
    title: title,
    scheduledAt: start,
    verificationDueAt: verificationDueAt ?? start.add(const Duration(hours: 1)),
    category: category,
    recurrence: recurrence,
    experiencePoint: experiencePoint,
    visibility: visibility,
    photoProofRequired: photoProofRequired,
  );
}

PlanItem _addPlan(
  MockAppRepository repository, {
  required String title,
  DateTime? scheduledAt,
  DateTime? verificationDueAt,
  PlanVisibility visibility = PlanVisibility.private,
  bool photoProofRequired = false,
}) {
  final start =
      scheduledAt ?? DateTime.now().subtract(const Duration(minutes: 1));
  repository.addPlan(
    _planDraft(
      title: title,
      scheduledAt: start,
      verificationDueAt:
          verificationDueAt ?? start.add(const Duration(hours: 1)),
      visibility: visibility,
      photoProofRequired: photoProofRequired,
    ),
  );
  return repository.plans.firstWhere((plan) => plan.title == title);
}

PlanItem _planById(MockAppRepository repository, String planId) {
  return repository.plans.firstWhere((plan) => plan.id == planId);
}

PlanProofDraft _completionProof({required bool sharedToFeed}) {
  return PlanProofDraft(
    type: PlanProofType.completion,
    note: '완료했습니다.',
    sharedToFeed: sharedToFeed,
  );
}
