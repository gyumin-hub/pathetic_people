import 'package:flutter/foundation.dart';

import '../../domain/models/app_preferences.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/explore_item.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/plan_item.dart';
import '../../domain/repositories/app_repository.dart';
import '../../domain/services/mentor_message_service.dart';

class MockAppRepository extends ChangeNotifier implements AppRepository {
  MockAppRepository() {
    _seedData();
  }

  late AppUser _currentUser;
  AppPreferences _preferences = const AppPreferences(
    pushEnabled: true,
    publicFailureEnabled: true,
    systemChatAlertEnabled: true,
    mentorIntensity: MentorIntensity.spicy,
  );
  final List<AppUser> _users = [];
  final List<FeedPost> _posts = [];
  final List<ExploreItem> _exploreItems = [];
  final List<PlanItem> _plans = [];
  final List<ChatRoom> _chatRooms = [];
  final Map<String, List<ChatMessage>> _messages = {};

  @override
  AppUser get currentUser => _currentUser;

  @override
  AppPreferences get preferences => _preferences;

  @override
  List<AppUser> get users => List.unmodifiable(_users);

  @override
  List<FeedPost> get posts => List.unmodifiable(_posts);

  @override
  List<ExploreItem> get exploreItems => List.unmodifiable(_exploreItems);

  @override
  List<PlanItem> get plans => List.unmodifiable(_plans);

  @override
  List<ChatRoom> get chatRooms => List.unmodifiable(_chatRooms);

  @override
  AppUser? userById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  @override
  List<ChatMessage> messagesForRoom(String roomId) {
    return List.unmodifiable(_messages[roomId] ?? const []);
  }

  @override
  void togglePostLike(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(
      isLiked: !post.isLiked,
      likes: post.likes + (post.isLiked ? -1 : 1),
    );
    notifyListeners();
  }

  @override
  void togglePostSave(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(isSaved: !post.isSaved);
    notifyListeners();
  }

  @override
  void addComment(String postId, String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(
      comments: [
        ...post.comments,
        PostComment(
          id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
          authorName: _currentUser.displayName,
          message: trimmed,
          createdAt: DateTime.now(),
        ),
      ],
    );
    notifyListeners();
  }

  @override
  void toggleFollow(String userId) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1 || userId == _currentUser.id) return;
    final target = _users[index];
    final willFollow = !target.isFollowing;
    _users[index] = target.copyWith(
      isFollowing: willFollow,
      followers: willFollow
          ? target.followers + 1
          : (target.followers > 0 ? target.followers - 1 : 0),
    );
    _currentUser = _currentUser.copyWith(
      following: willFollow
          ? _currentUser.following + 1
          : (_currentUser.following > 0 ? _currentUser.following - 1 : 0),
    );
    final currentUserIndex = _users.indexWhere(
      (user) => user.id == _currentUser.id,
    );
    if (currentUserIndex != -1) _users[currentUserIndex] = _currentUser;
    notifyListeners();
  }

  @override
  void updateCurrentUser({
    required String displayName,
    required String username,
    required String bio,
  }) {
    final trimmedName = displayName.trim();
    final trimmedUsername = username.trim().replaceAll(' ', '_');
    if (trimmedName.isEmpty || trimmedUsername.isEmpty) return;
    _currentUser = _currentUser.copyWith(
      displayName: trimmedName,
      username: trimmedUsername,
      bio: bio.trim(),
    );
    final index = _users.indexWhere((user) => user.id == _currentUser.id);
    if (index != -1) _users[index] = _currentUser;
    notifyListeners();
  }

  @override
  void updatePreferences({
    bool? pushEnabled,
    bool? publicFailureEnabled,
    bool? systemChatAlertEnabled,
    MentorIntensity? mentorIntensity,
  }) {
    _preferences = _preferences.copyWith(
      pushEnabled: pushEnabled,
      publicFailureEnabled: publicFailureEnabled,
      systemChatAlertEnabled: systemChatAlertEnabled,
      mentorIntensity: mentorIntensity,
    );
    notifyListeners();
  }

  @override
  void addPlan(PlanDraft draft) {
    final seriesId = 'plan-${DateTime.now().microsecondsSinceEpoch}';
    final occurrences = _buildPlanOccurrences(draft, seriesId: seriesId).where(
      (occurrence) => !_plans.any((existing) => existing.id == occurrence.id),
    );
    _plans.addAll(occurrences);
    _sortPlans();
    notifyListeners();
  }

  @override
  void updatePlan(String planId, PlanDraft draft) {
    final index = _plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) return;
    final plan = _plans[index];
    final seriesId =
        plan.seriesId ?? 'plan-${DateTime.now().microsecondsSinceEpoch}';
    if (plan.seriesId != null) {
      _plans.removeWhere(
        (item) =>
            item.id == plan.id ||
            (item.seriesId == plan.seriesId &&
                item.progress == PlanProgress.pending &&
                !item.scheduledAt.isBefore(plan.scheduledAt)),
      );
    } else {
      _plans.removeAt(index);
    }
    _removeGeneratedPlanPosts(plan.id);
    final occurrences = _buildPlanOccurrences(draft, seriesId: seriesId).where(
      (occurrence) => !_plans.any((existing) => existing.id == occurrence.id),
    );
    _plans.addAll(occurrences);
    _sortPlans();
    notifyListeners();
  }

  @override
  void deletePlan(String planId) {
    _removeGeneratedPlanPosts(planId);
    _plans.removeWhere((plan) => plan.id == planId);
    notifyListeners();
  }

  @override
  void togglePlanCompletion(String planId) {
    final index = _plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) return;
    final plan = _plans[index];
    final isCompleted = plan.progress == PlanProgress.completed;
    final wasFailed = plan.progress == PlanProgress.failed;
    final nextProgress = isCompleted
        ? PlanProgress.pending
        : PlanProgress.completed;
    _plans[index] = plan.copyWith(
      progress: nextProgress,
      completedAt: isCompleted ? null : DateTime.now(),
      clearCompletedAt: isCompleted,
    );
    _removeGeneratedPlanPosts(plan.id);
    if (nextProgress == PlanProgress.completed) {
      _addPlanPost(_plans[index], PostOutcome.success);
      if (wasFailed && _preferences.systemChatAlertEnabled) {
        _announcePlanRecovery(_plans[index], DateTime.now());
      }
    }
    notifyListeners();
  }

  @override
  void markOverduePlans(DateTime now) {
    final didExtendRecurrence = _extendRecurringPlans(now);
    final newlyFailed = <PlanItem>[];
    for (var index = 0; index < _plans.length; index++) {
      final plan = _plans[index];
      if (plan.progress == PlanProgress.pending &&
          plan.scheduledAt.isBefore(now)) {
        _plans[index] = plan.copyWith(progress: PlanProgress.failed);
        newlyFailed.add(_plans[index]);
      }
    }
    if (newlyFailed.isEmpty) {
      if (didExtendRecurrence) notifyListeners();
      return;
    }

    newlyFailed.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    for (final plan in newlyFailed.take(3)) {
      if (_preferences.publicFailureEnabled) {
        _addPlanPost(plan, PostOutcome.failure);
      }
      if (_preferences.systemChatAlertEnabled) {
        _announcePlanFailure(plan, now);
      }
    }
    if (newlyFailed.length > 3 && _preferences.systemChatAlertEnabled) {
      _announceMissedSummary(newlyFailed.length - 3, now);
    }
    notifyListeners();
  }

  @override
  void readRoom(String roomId) {
    final index = _chatRooms.indexWhere((room) => room.id == roomId);
    if (index == -1 || _chatRooms[index].unreadCount == 0) return;
    _chatRooms[index] = _chatRooms[index].copyWith(unreadCount: 0);
    notifyListeners();
  }

  @override
  void sendMessage(String roomId, String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final newMessage = ChatMessage(
      id: 'message-${now.microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: _currentUser.id,
      message: trimmed,
      sentAt: now,
      isMine: true,
      isSystem: false,
    );
    _messages.putIfAbsent(roomId, () => []).add(newMessage);
    final roomIndex = _chatRooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
        subtitle: trimmed,
        updatedAt: now,
        unreadCount: 0,
      );
      _chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    notifyListeners();
  }

  @override
  ChatRoom createDirectRoom(String userId) {
    final user = userById(userId);
    if (user == null) {
      throw ArgumentError.value(userId, 'userId', '존재하지 않는 사용자입니다.');
    }
    final roomId = 'direct-${user.id}';
    final existingIndex = _chatRooms.indexWhere(
      (room) =>
          room.id == roomId ||
          (room.kind == ChatRoomKind.direct && room.title == user.displayName),
    );
    if (existingIndex != -1) return _chatRooms[existingIndex];
    final now = DateTime.now();
    final room = ChatRoom(
      id: roomId,
      title: user.displayName,
      subtitle: '새 대화를 시작해 보세요.',
      kind: ChatRoomKind.direct,
      memberInitials: [user.initials],
      updatedAt: now,
      unreadCount: 0,
    );
    _chatRooms.insert(0, room);
    _messages[roomId] = [];
    notifyListeners();
    return room;
  }

  @override
  ChatRoom createGroupRoom(String title, List<String> userIds) {
    final members = userIds
        .map(userById)
        .whereType<AppUser>()
        .where((user) => user.id != _currentUser.id)
        .toList(growable: false);
    if (title.trim().isEmpty || members.isEmpty) {
      throw ArgumentError('그룹 이름과 한 명 이상의 친구가 필요합니다.');
    }
    final now = DateTime.now();
    final room = ChatRoom(
      id: 'group-${now.microsecondsSinceEpoch}',
      title: title.trim(),
      subtitle: '새 그룹이 만들어졌습니다.',
      kind: ChatRoomKind.group,
      memberInitials: members.map((user) => user.initials).toList(),
      updatedAt: now,
      unreadCount: 0,
    );
    _chatRooms.insert(0, room);
    _messages[room.id] = [
      ChatMessage(
        id: 'group-created-${now.microsecondsSinceEpoch}',
        roomId: room.id,
        senderId: 'system',
        message: '${room.title} 그룹이 만들어졌습니다.',
        sentAt: now,
        isMine: false,
        isSystem: true,
      ),
    ];
    notifyListeners();
    return room;
  }

  void _sortPlans() {
    _plans.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<PlanItem> _buildPlanOccurrences(
    PlanDraft draft, {
    required String seriesId,
  }) {
    final dates = _recurrenceDates(
      draft.scheduledAt,
      draft.recurrence,
      DateTime.now(),
    );
    final isRepeating = dates.length > 1;
    return dates
        .map((scheduledAt) {
          final dateKey =
              '${scheduledAt.year.toString().padLeft(4, '0')}'
              '${scheduledAt.month.toString().padLeft(2, '0')}'
              '${scheduledAt.day.toString().padLeft(2, '0')}'
              '${scheduledAt.hour.toString().padLeft(2, '0')}'
              '${scheduledAt.minute.toString().padLeft(2, '0')}';
          return PlanItem(
            id: isRepeating ? '$seriesId-$dateKey' : seriesId,
            title: draft.title,
            scheduledAt: scheduledAt,
            category: draft.category,
            recurrence: draft.recurrence,
            experiencePoint: draft.experiencePoint,
            progress: PlanProgress.pending,
            seriesId: isRepeating ? seriesId : null,
          );
        })
        .toList(growable: false);
  }

  List<DateTime> _recurrenceDates(
    DateTime start,
    String recurrence,
    DateTime now,
  ) {
    if (!_isSupportedRecurrence(recurrence)) return [start];

    final dates = <DateTime>[start];
    final today = DateTime(now.year, now.month, now.day);
    final anchor = start.isAfter(now) ? start : now;
    final end = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
    ).add(const Duration(days: 60));
    var candidate = start.add(const Duration(days: 1));
    while (!candidate.isAfter(end)) {
      final candidateDay = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
      );
      if (!candidateDay.isBefore(today) &&
          _matchesRecurrence(candidate.weekday, recurrence)) {
        dates.add(candidate);
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return dates;
  }

  bool _isSupportedRecurrence(String recurrence) {
    return recurrence == '매일' ||
        recurrence == '평일' ||
        recurrence == '주말' ||
        recurrence == '월·수·금';
  }

  bool _matchesRecurrence(int weekday, String recurrence) {
    return switch (recurrence) {
      '매일' => true,
      '평일' => weekday <= DateTime.friday,
      '주말' => weekday >= DateTime.saturday,
      '월·수·금' =>
        weekday == DateTime.monday ||
            weekday == DateTime.wednesday ||
            weekday == DateTime.friday,
      _ => false,
    };
  }

  bool _extendRecurringPlans(DateTime now) {
    final seriesIds = _plans
        .map((plan) => plan.seriesId)
        .whereType<String>()
        .toSet();
    final additions = <PlanItem>[];
    final extensionThreshold = now.add(const Duration(days: 30));
    for (final seriesId in seriesIds) {
      final occurrences =
          _plans
              .where((plan) => plan.seriesId == seriesId)
              .toList(growable: false)
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      if (occurrences.isEmpty) continue;
      final last = occurrences.last;
      if (last.scheduledAt.isAfter(extensionThreshold)) continue;

      final generated = _buildPlanOccurrences(
        PlanDraft(
          title: last.title,
          scheduledAt: last.scheduledAt,
          category: last.category,
          recurrence: last.recurrence,
          experiencePoint: last.experiencePoint,
        ),
        seriesId: seriesId,
      );
      for (final occurrence in generated) {
        final alreadyExists =
            _plans.any((existing) => existing.id == occurrence.id) ||
            additions.any((existing) => existing.id == occurrence.id);
        if (!alreadyExists) additions.add(occurrence);
      }
    }
    if (additions.isEmpty) return false;
    _plans.addAll(additions);
    _sortPlans();
    return true;
  }

  void _seedPlan(PlanItem firstOccurrence) {
    if (!_isSupportedRecurrence(firstOccurrence.recurrence)) {
      _plans.add(firstOccurrence);
      return;
    }
    final seriesId = firstOccurrence.id;
    _plans.add(firstOccurrence.copyWith(seriesId: seriesId));
    final futureOccurrences = _buildPlanOccurrences(
      PlanDraft(
        title: firstOccurrence.title,
        scheduledAt: firstOccurrence.scheduledAt,
        category: firstOccurrence.category,
        recurrence: firstOccurrence.recurrence,
        experiencePoint: firstOccurrence.experiencePoint,
      ),
      seriesId: seriesId,
    ).skip(1);
    _plans.addAll(futureOccurrences);
  }

  void _addPlanPost(PlanItem plan, PostOutcome outcome) {
    final generatedId = 'generated-${plan.id}-${outcome.name}';
    if (_posts.any((post) => post.id == generatedId)) return;
    _posts.insert(
      0,
      FeedPost(
        id: generatedId,
        authorId: _currentUser.id,
        outcome: outcome,
        mediaKind: _mediaKindFor(plan.category),
        planTitle: plan.title,
        mediaHeadline: _headlineFor(plan),
        mentorMessage: outcome == PostOutcome.success
            ? MentorMessageService.successFor(plan)
            : MentorMessageService.failureFor(
                plan,
                intensity: _preferences.mentorIntensity,
              ),
        createdAt: DateTime.now(),
        likes: 0,
        comments: const [],
        isLiked: false,
        isSaved: false,
        streakDays: outcome == PostOutcome.success ? 7 : null,
      ),
    );
  }

  void _removeGeneratedPlanPosts(String planId) {
    _posts.removeWhere((post) => post.id.startsWith('generated-$planId-'));
  }

  void _announcePlanFailure(PlanItem plan, DateTime sentAt) {
    final mentorMessage = MentorMessageService.failureFor(
      plan,
      intensity: _preferences.mentorIntensity,
    );
    final roomIndex = _chatRooms.indexWhere((room) => room.id == 'system-room');
    if (roomIndex != -1) {
      final room = _chatRooms[roomIndex];
      _chatRooms[roomIndex] = room.copyWith(
        subtitle: '${_currentUser.displayName}님이 ‘${plan.title}’ 계획에 실패했습니다.',
        updatedAt: sentAt,
        unreadCount: room.unreadCount + 1,
      );
    }
    _messages.putIfAbsent('system-room', () => []).addAll([
      ChatMessage(
        id: 'failure-${plan.id}-$sentAt',
        roomId: 'system-room',
        senderId: 'system',
        message:
            '${_currentUser.displayName}님이 ‘${plan.title}’ 계획을 달성하지 못했습니다.',
        sentAt: sentAt,
        isMine: false,
        isSystem: true,
      ),
      ChatMessage(
        id: 'roast-${plan.id}-$sentAt',
        roomId: 'system-room',
        senderId: 'system',
        message: mentorMessage,
        sentAt: sentAt,
        isMine: false,
        isSystem: true,
      ),
    ]);
    _broadcastFailureToGroups(plan, mentorMessage, sentAt);
  }

  void _broadcastFailureToGroups(
    PlanItem plan,
    String mentorMessage,
    DateTime sentAt,
  ) {
    final message =
        '${_currentUser.displayName}님이 ‘${plan.title}’ 계획에 실패했습니다.\n$mentorMessage';
    for (var index = 0; index < _chatRooms.length; index++) {
      final room = _chatRooms[index];
      if (room.kind != ChatRoomKind.group) continue;
      _chatRooms[index] = room.copyWith(
        subtitle: message,
        updatedAt: sentAt,
        unreadCount: room.unreadCount + 1,
      );
      _messages
          .putIfAbsent(room.id, () => [])
          .add(
            ChatMessage(
              id: 'group-failure-${room.id}-${plan.id}-${sentAt.microsecondsSinceEpoch}',
              roomId: room.id,
              senderId: 'system',
              message: message,
              sentAt: sentAt,
              isMine: false,
              isSystem: true,
            ),
          );
    }
    _chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _announceMissedSummary(int count, DateTime sentAt) {
    final message = '자리를 비운 동안 계획 $count개를 더 놓쳤습니다. 달력에서 실패 기록을 확인하세요.';
    final roomIndex = _chatRooms.indexWhere((room) => room.id == 'system-room');
    if (roomIndex != -1) {
      final room = _chatRooms[roomIndex];
      _chatRooms[roomIndex] = room.copyWith(
        subtitle: message,
        updatedAt: sentAt,
        unreadCount: room.unreadCount + 1,
      );
    }
    _messages
        .putIfAbsent('system-room', () => [])
        .add(
          ChatMessage(
            id: 'missed-summary-${sentAt.microsecondsSinceEpoch}',
            roomId: 'system-room',
            senderId: 'system',
            message: message,
            sentAt: sentAt,
            isMine: false,
            isSystem: true,
          ),
        );
  }

  void _announcePlanRecovery(PlanItem plan, DateTime sentAt) {
    final message =
        '${_currentUser.displayName}님이 늦게라도 ‘${plan.title}’ 계획을 완료했습니다.';
    final roomIndex = _chatRooms.indexWhere((room) => room.id == 'system-room');
    if (roomIndex != -1) {
      final room = _chatRooms[roomIndex];
      _chatRooms[roomIndex] = room.copyWith(
        subtitle: message,
        updatedAt: sentAt,
        unreadCount: room.unreadCount + 1,
      );
    }
    _messages
        .putIfAbsent('system-room', () => [])
        .add(
          ChatMessage(
            id: 'recovery-${plan.id}-${sentAt.microsecondsSinceEpoch}',
            roomId: 'system-room',
            senderId: 'system',
            message: message,
            sentAt: sentAt,
            isMine: false,
            isSystem: true,
          ),
        );
  }

  MediaKind _mediaKindFor(PlanCategory category) {
    return switch (category) {
      PlanCategory.health => MediaKind.workout,
      PlanCategory.study => MediaKind.study,
      PlanCategory.routine => MediaKind.morning,
      PlanCategory.record => MediaKind.journal,
    };
  }

  String _headlineFor(PlanItem plan) {
    return switch (plan.category) {
      PlanCategory.health => 'TODAY\nWORKOUT',
      PlanCategory.study => 'DEEP\nFOCUS',
      PlanCategory.routine => 'DAILY\nROUTINE',
      PlanCategory.record => 'TODAY\nJOURNAL',
    };
  }

  void _seedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _currentUser = const AppUser(
      id: 'me',
      username: 'pathetic_me',
      displayName: '박한심',
      initials: 'PJ',
      avatarSeed: 0,
      level: 12,
      bio: '말보다 인증. 못 하면 기록으로 남기기.\n러닝 · 영어 · 기록',
      followers: 1248,
      following: 326,
      isFollowing: true,
    );
    _users.addAll([
      _currentUser,
      const AppUser(
        id: 'minji',
        username: 'minji_daily',
        displayName: '김민지',
        initials: 'MJ',
        avatarSeed: 1,
        level: 15,
        bio: '아침형 인간 도전 중',
        followers: 834,
        following: 221,
        isFollowing: true,
      ),
      const AppUser(
        id: 'junhyeok',
        username: 'june.fit',
        displayName: '박준혁',
        initials: 'JH',
        avatarSeed: 2,
        level: 18,
        bio: '운동으로 하루를 마감합니다',
        followers: 2180,
        following: 411,
        isFollowing: true,
      ),
      const AppUser(
        id: 'seoyun',
        username: 'study_sy',
        displayName: '한서윤',
        initials: 'SY',
        avatarSeed: 3,
        level: 29,
        bio: '퇴근 후 90분 공부',
        followers: 3230,
        following: 198,
        isFollowing: false,
      ),
      const AppUser(
        id: 'taehyeon',
        username: 'run_tae',
        displayName: '이태현',
        initials: 'TH',
        avatarSeed: 4,
        level: 32,
        bio: '매일 새벽 서울을 달립니다',
        followers: 5304,
        following: 297,
        isFollowing: false,
      ),
    ]);

    _posts.addAll([
      FeedPost(
        id: 'post-failure',
        authorId: 'minji',
        outcome: PostOutcome.failure,
        mediaKind: MediaKind.morning,
        planTitle: '06:30 기상 후 러닝 3km',
        mediaHeadline: '06:30\nMORNING RUN',
        mentorMessage: '알람은 일어나는 도구지, 끄고 다시 자는 리모컨이 아니야.',
        createdAt: now.subtract(const Duration(minutes: 3)),
        likes: 128,
        comments: [
          PostComment(
            id: 'comment-1',
            authorName: '박준혁',
            message: '계획보다 이불과의 약속을 지켰네',
            createdAt: now.subtract(const Duration(minutes: 2)),
          ),
        ],
        isLiked: false,
        isSaved: false,
      ),
      FeedPost(
        id: 'post-success',
        authorId: 'junhyeok',
        outcome: PostOutcome.success,
        mediaKind: MediaKind.workout,
        planTitle: '퇴근 후 운동 60분',
        mediaHeadline: '60 MIN\nWORKOUT',
        mentorMessage: '오늘만큼은 핑계보다 네가 빨랐네. 이 흐름 유지해.',
        createdAt: now.subtract(const Duration(minutes: 18)),
        likes: 302,
        comments: const [],
        isLiked: true,
        isSaved: false,
        streakDays: 14,
      ),
      FeedPost(
        id: 'post-study',
        authorId: 'seoyun',
        outcome: PostOutcome.success,
        mediaKind: MediaKind.study,
        planTitle: '퇴근 후 자격증 공부 90분',
        mediaHeadline: '90 MIN\nDEEP FOCUS',
        mentorMessage: '꾸준함은 재능을 이긴다. 오늘도 한 칸 전진.',
        createdAt: now.subtract(const Duration(hours: 2)),
        likes: 512,
        comments: const [],
        isLiked: false,
        isSaved: true,
        streakDays: 18,
      ),
      FeedPost(
        id: 'post-my-run',
        authorId: 'me',
        outcome: PostOutcome.success,
        mediaKind: MediaKind.morning,
        planTitle: '한강 러닝 5.2km',
        mediaHeadline: '5.2 KM\nMORNING RUN',
        mentorMessage: '오늘은 생각보다 발이 먼저 움직였네요. 내일도 같은 시간에 봅시다.',
        createdAt: now.subtract(const Duration(days: 1)),
        likes: 284,
        comments: const [],
        isLiked: false,
        isSaved: false,
        streakDays: 7,
      ),
      FeedPost(
        id: 'post-my-book',
        authorId: 'me',
        outcome: PostOutcome.failure,
        mediaKind: MediaKind.reading,
        planTitle: '책 30쪽 읽기',
        mediaHeadline: '0 / 30\nPAGES',
        mentorMessage: '책은 샀는데 펼치지도 않으면 그건 독서가 아니라 인테리어예요.',
        createdAt: now.subtract(const Duration(days: 2)),
        likes: 192,
        comments: const [],
        isLiked: false,
        isSaved: false,
      ),
      FeedPost(
        id: 'post-my-journal',
        authorId: 'me',
        outcome: PostOutcome.success,
        mediaKind: MediaKind.journal,
        planTitle: '오늘 회고 5줄 쓰기',
        mediaHeadline: '5 LINES\nJOURNAL',
        mentorMessage: '기록하는 사람은 같은 핑계에 두 번 속지 않아요.',
        createdAt: now.subtract(const Duration(days: 3)),
        likes: 146,
        comments: const [],
        isLiked: true,
        isSaved: false,
        streakDays: 5,
      ),
    ]);

    _exploreItems.addAll(const [
      ExploreItem(
        id: 'e1',
        title: '05:30\nRUN',
        label: '7일 연속',
        category: '운동',
        mediaKind: MediaKind.morning,
        outcome: PostOutcome.success,
        isVideo: true,
        popularity: 99,
      ),
      ExploreItem(
        id: 'e2',
        title: '0 / 30',
        label: '미달성',
        category: '공부',
        mediaKind: MediaKind.reading,
        outcome: PostOutcome.failure,
        isVideo: false,
        popularity: 96,
      ),
      ExploreItem(
        id: 'e3',
        title: '90\nMIN',
        label: '12일 연속',
        category: '공부',
        mediaKind: MediaKind.study,
        outcome: PostOutcome.success,
        isVideo: false,
        popularity: 94,
      ),
      ExploreItem(
        id: 'e4',
        title: '08\nALARMS',
        label: '실패',
        category: '실패담',
        mediaKind: MediaKind.morning,
        outcome: PostOutcome.failure,
        isVideo: true,
        popularity: 93,
      ),
      ExploreItem(
        id: 'e5',
        title: '60\nMIN',
        label: '달성',
        category: '운동',
        mediaKind: MediaKind.workout,
        outcome: PostOutcome.success,
        isVideo: false,
        popularity: 91,
      ),
      ExploreItem(
        id: 'e6',
        title: 'DAY\n24',
        label: '기록',
        category: '기록',
        mediaKind: MediaKind.journal,
        outcome: PostOutcome.success,
        isVideo: false,
        popularity: 89,
      ),
      ExploreItem(
        id: 'e7',
        title: 'DAY\n03',
        label: '레전드',
        category: '실패담',
        mediaKind: MediaKind.morning,
        outcome: PostOutcome.failure,
        isVideo: true,
        popularity: 88,
      ),
      ExploreItem(
        id: 'e8',
        title: '2.0\nL',
        label: '달성',
        category: '건강',
        mediaKind: MediaKind.water,
        outcome: PostOutcome.success,
        isVideo: false,
        popularity: 82,
      ),
      ExploreItem(
        id: 'e9',
        title: '23:40',
        label: '공부',
        category: '공부',
        mediaKind: MediaKind.study,
        outcome: PostOutcome.success,
        isVideo: false,
        popularity: 80,
      ),
    ]);

    for (var daysAgo = 6; daysAgo >= 1; daysAgo--) {
      final scheduledAt = today
          .subtract(Duration(days: daysAgo))
          .add(const Duration(hours: 7));
      final didFail = daysAgo == 2;
      _plans.add(
        PlanItem(
          id: 'history-$daysAgo',
          title: didFail ? '저녁 스트레칭 15분' : '아침 루틴 완료',
          scheduledAt: scheduledAt,
          category: didFail ? PlanCategory.health : PlanCategory.routine,
          recurrence: '없음',
          experiencePoint: 5,
          progress: didFail ? PlanProgress.failed : PlanProgress.completed,
          completedAt: didFail
              ? null
              : scheduledAt.add(const Duration(minutes: 5)),
        ),
      );
    }

    _seedPlan(
      PlanItem(
        id: 'plan-water',
        title: '일어나서 물 한 잔',
        scheduledAt: today.add(const Duration(hours: 6, minutes: 30)),
        category: PlanCategory.health,
        recurrence: '매일',
        experiencePoint: 5,
        progress: PlanProgress.completed,
        completedAt: today.add(const Duration(hours: 6, minutes: 28)),
      ),
    );
    _seedPlan(
      PlanItem(
        id: 'plan-words',
        title: '영어 단어 30개',
        scheduledAt: today.add(const Duration(hours: 7)),
        category: PlanCategory.study,
        recurrence: '평일',
        experiencePoint: 10,
        progress: PlanProgress.completed,
        completedAt: today.add(const Duration(hours: 6, minutes: 52)),
      ),
    );
    _seedPlan(
      PlanItem(
        id: 'plan-workout',
        title: '퇴근 후 운동 60분',
        scheduledAt: today.add(const Duration(hours: 18, minutes: 30)),
        category: PlanCategory.health,
        recurrence: '월·수·금',
        experiencePoint: 10,
        progress: PlanProgress.pending,
      ),
    );
    _seedPlan(
      PlanItem(
        id: 'plan-diary',
        title: '오늘 회고 5줄 쓰기',
        scheduledAt: today.add(const Duration(hours: 23)),
        category: PlanCategory.record,
        recurrence: '매일',
        experiencePoint: 5,
        progress: PlanProgress.pending,
      ),
    );
    _sortPlans();

    _chatRooms.addAll([
      ChatRoom(
        id: 'system-room',
        title: '공개처형소',
        subtitle: '민지님이 아침 러닝에 실패했습니다.',
        kind: ChatRoomKind.system,
        memberInitials: const ['M'],
        updatedAt: now,
        unreadCount: 3,
      ),
      ChatRoom(
        id: 'minji-room',
        title: '김민지',
        subtitle: '너도 오늘 실패하면 진짜다 ㅋㅋ',
        kind: ChatRoomKind.direct,
        memberInitials: const ['MJ'],
        updatedAt: now.subtract(const Duration(minutes: 10)),
        unreadCount: 1,
      ),
      ChatRoom(
        id: 'group-room',
        title: '갓생은 내일부터',
        subtitle: '준혁: 오늘 운동 도망갈 사람?',
        kind: ChatRoomKind.group,
        memberInitials: const ['JH', 'SY'],
        updatedAt: now.subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      ChatRoom(
        id: 'taehyeon-room',
        title: '이태현',
        subtitle: '내일 6시에 뛰는 거 잊지 마',
        kind: ChatRoomKind.direct,
        memberInitials: const ['TH'],
        updatedAt: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
      ChatRoom(
        id: 'study-room',
        title: '퇴근 후 공부 인증방',
        subtitle: '서윤: 오늘 인증 완료!',
        kind: ChatRoomKind.group,
        memberInitials: const ['SY', 'JH'],
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
        unreadCount: 0,
      ),
    ]);

    _messages.addAll({
      'system-room': [
        ChatMessage(
          id: 'sm1',
          roomId: 'system-room',
          senderId: 'system',
          message: '김민지님이 오늘의 계획 ‘아침 러닝 3km’를 달성하지 못했습니다.',
          sentAt: now.subtract(const Duration(minutes: 4)),
          isMine: false,
          isSystem: true,
        ),
        ChatMessage(
          id: 'sm2',
          roomId: 'system-room',
          senderId: 'system',
          message: '알람은 일어나는 도구지, 끄고 다시 자는 리모컨이 아니야.',
          sentAt: now.subtract(const Duration(minutes: 3)),
          isMine: false,
          isSystem: true,
        ),
      ],
      'minji-room': [
        ChatMessage(
          id: 'mm1',
          roomId: 'minji-room',
          senderId: 'minji',
          message: '오늘 운동 계획 아직 안 했지?',
          sentAt: now.subtract(const Duration(minutes: 20)),
          isMine: false,
          isSystem: false,
        ),
        ChatMessage(
          id: 'mm2',
          roomId: 'minji-room',
          senderId: 'me',
          message: '퇴근하고 바로 갈 예정',
          sentAt: now.subtract(const Duration(minutes: 16)),
          isMine: true,
          isSystem: false,
        ),
        ChatMessage(
          id: 'mm3',
          roomId: 'minji-room',
          senderId: 'minji',
          message: '너도 오늘 실패하면 진짜다 ㅋㅋ',
          sentAt: now.subtract(const Duration(minutes: 10)),
          isMine: false,
          isSystem: false,
        ),
      ],
      'group-room': [
        ChatMessage(
          id: 'gm1',
          roomId: 'group-room',
          senderId: 'junhyeok',
          message: '오늘 운동 도망갈 사람?',
          sentAt: now.subtract(const Duration(hours: 1)),
          isMine: false,
          isSystem: false,
        ),
      ],
      'taehyeon-room': [
        ChatMessage(
          id: 'tm1',
          roomId: 'taehyeon-room',
          senderId: 'taehyeon',
          message: '내일 6시에 뛰는 거 잊지 마',
          sentAt: now.subtract(const Duration(days: 1)),
          isMine: false,
          isSystem: false,
        ),
      ],
      'study-room': [
        ChatMessage(
          id: 'stm1',
          roomId: 'study-room',
          senderId: 'seoyun',
          message: '오늘 인증 완료!',
          sentAt: now.subtract(const Duration(days: 1, hours: 2)),
          isMine: false,
          isSystem: false,
        ),
      ],
    });
  }
}
