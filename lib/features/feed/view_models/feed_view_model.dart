import '../../../core/view_models/repository_view_model.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/chat.dart';
import '../../../domain/models/feed_post.dart';
import '../../../domain/models/plan_item.dart';

enum FeedScope { following, recommended }

class FeedViewModel extends RepositoryViewModel {
  FeedViewModel(super.repository);

  FeedScope _scope = FeedScope.following;

  FeedScope get scope => _scope;

  List<FeedPost> get posts {
    final sorted = [...repository.posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_scope == FeedScope.recommended) return sorted;
    return sorted
        .where((post) {
          return repository.userById(post.authorId)?.isFollowing ?? false;
        })
        .toList(growable: false);
  }

  List<PlanItem> get activePublicChallenges {
    final now = DateTime.now();
    final challenges = repository.plans
        .where((plan) {
          return plan.progress == PlanProgress.pending &&
              plan.visibility == PlanVisibility.publicChallenge &&
              !plan.scheduledAt.isAfter(now) &&
              plan.verificationDueAt.isAfter(now) &&
              plan.startProof?.sharedToFeed == true;
        })
        .toList(growable: false);
    challenges.sort((a, b) {
      final aRecordedAt = a.startProof?.recordedAt ?? a.scheduledAt;
      final bRecordedAt = b.startProof?.recordedAt ?? b.scheduledAt;
      return bRecordedAt.compareTo(aRecordedAt);
    });
    return challenges;
  }

  AppUser get currentUser => repository.currentUser;

  List<ChatRoom> get shareRooms {
    return repository.chatRooms
        .where((room) => room.kind != ChatRoomKind.system)
        .toList(growable: false);
  }

  AppUser? authorOf(FeedPost post) => repository.userById(post.authorId);

  void changeScope(FeedScope value) {
    if (_scope == value) return;
    _scope = value;
    notifyListeners();
  }

  void toggleLike(String postId) => repository.togglePostLike(postId);

  void toggleSave(String postId) => repository.togglePostSave(postId);

  void addComment(String postId, String message) {
    repository.addComment(postId, message);
  }

  void sharePostToRoom(FeedPost post, String roomId) {
    final result = post.outcome == PostOutcome.success ? '성공' : '실패';
    repository.sendMessage(
      roomId,
      '[$result 인증] ${post.planTitle}\nhttps://motive.app/posts/${post.id}',
    );
  }
}
