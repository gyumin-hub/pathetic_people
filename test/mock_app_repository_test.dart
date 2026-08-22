import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/data/repositories/mock_app_repository.dart';
import 'package:pathetic_people/domain/models/app_preferences.dart';
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

    test('새 계획을 선택한 날짜에 추가한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final beforeCount = repository.plans.length;
      final scheduledAt = DateTime.now().add(const Duration(days: 2));

      repository.addPlan(
        PlanDraft(
          title: '테스트 계획',
          scheduledAt: scheduledAt,
          category: PlanCategory.study,
          recurrence: '한 번',
          experiencePoint: 10,
        ),
      );

      expect(repository.plans, hasLength(beforeCount + 1));
      expect(repository.plans.any((plan) => plan.title == '테스트 계획'), isTrue);
    });

    test('계획을 완료하면 성공 게시물을 자동 생성한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = repository.plans.firstWhere(
        (item) => item.progress == PlanProgress.pending,
      );

      repository.togglePlanCompletion(plan.id);

      expect(
        repository.posts.any(
          (post) => post.id == 'generated-${plan.id}-success',
        ),
        isTrue,
      );
    });

    test('마감된 계획은 실패 게시물과 시스템 메시지를 생성한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final beforeMessageCount = repository
          .messagesForRoom('system-room')
          .length;

      repository.markOverduePlans(DateTime.now().add(const Duration(days: 1)));

      expect(
        repository.posts.any((post) => post.id.endsWith('-failure')),
        isTrue,
      );
      expect(
        repository.messagesForRoom('system-room').length,
        greaterThan(beforeMessageCount),
      );
    });

    test('메시지를 보내면 채팅방의 마지막 메시지도 변경한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      const roomId = 'minji-room';
      const message = '에뮬레이터 테스트 메시지';

      repository.sendMessage(roomId, message);

      expect(repository.messagesForRoom(roomId).last.message, message);
      expect(
        repository.chatRooms.firstWhere((room) => room.id == roomId).subtitle,
        message,
      );
    });

    test('반복 계획은 이후 날짜의 실행 항목도 만든다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final scheduledAt = DateTime.now().add(const Duration(days: 2));

      repository.addPlan(
        PlanDraft(
          title: '매일 반복 테스트',
          scheduledAt: scheduledAt,
          category: PlanCategory.routine,
          recurrence: '매일',
          experiencePoint: 5,
        ),
      );

      final occurrences = repository.plans
          .where((plan) => plan.title == '매일 반복 테스트')
          .toList();
      expect(occurrences.length, greaterThan(1));
      expect(
        occurrences
            .skip(1)
            .every(
              (plan) => plan.scheduledAt.isAfter(occurrences.first.scheduledAt),
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

    test('공개와 채팅 알림을 끄면 실패를 외부에 발행하지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final postCount = repository.posts.length;
      final messageCount = repository.messagesForRoom('system-room').length;
      repository.updatePreferences(
        publicFailureEnabled: false,
        systemChatAlertEnabled: false,
        mentorIntensity: MentorIntensity.mild,
      );
      repository.addPlan(
        PlanDraft(
          title: '비공개 실패 테스트',
          scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
          category: PlanCategory.study,
          recurrence: '없음',
          experiencePoint: 5,
        ),
      );

      repository.markOverduePlans(DateTime.now());

      final plan = repository.plans.firstWhere(
        (item) => item.title == '비공개 실패 테스트',
      );
      expect(plan.progress, PlanProgress.failed);
      expect(repository.posts, hasLength(postCount));
      expect(
        repository.messagesForRoom('system-room'),
        hasLength(messageCount),
      );
    });

    test('반복 계획을 수정해도 회차 ID가 중복되지 않는다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final scheduledAt = DateTime.now().add(const Duration(days: 2));
      final draft = PlanDraft(
        title: '수정 반복 테스트',
        scheduledAt: scheduledAt,
        category: PlanCategory.health,
        recurrence: '매일',
        experiencePoint: 10,
      );
      repository.addPlan(draft);
      final before = repository.plans
          .where((plan) => plan.title == draft.title)
          .toList();
      repository.togglePlanCompletion(before[1].id);

      repository.updatePlan(before.first.id, draft);

      final after = repository.plans
          .where((plan) => plan.title == draft.title)
          .toList();
      expect(after.map((plan) => plan.id).toSet(), hasLength(after.length));
    });

    test('계획 삭제 시 자동 생성 게시물도 함께 정리한다', () {
      final repository = MockAppRepository();
      addTearDown(repository.dispose);
      final plan = repository.plans.firstWhere(
        (item) => item.progress == PlanProgress.pending,
      );
      repository.togglePlanCompletion(plan.id);
      expect(repository.posts.any((post) => post.id.contains(plan.id)), isTrue);

      repository.deletePlan(plan.id);

      expect(
        repository.posts.any((post) => post.id.contains(plan.id)),
        isFalse,
      );
    });
  });
}
