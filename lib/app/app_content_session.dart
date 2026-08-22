import '../domain/repositories/app_repository.dart';
import '../features/auth/domain/auth_user.dart';
import '../features/chat/view_models/chat_view_model.dart';
import '../features/explore/view_models/explore_view_model.dart';
import '../features/feed/view_models/feed_view_model.dart';
import '../features/planner/view_models/planner_view_model.dart';
import '../features/profile/view_models/profile_view_model.dart';

typedef ContentRepositoryFactory = AppRepository Function(int userId);

class AppContentSession {
  AppContentSession({required this.userId, required this.repository})
    : feedViewModel = FeedViewModel(repository),
      exploreViewModel = ExploreViewModel(repository),
      plannerViewModel = PlannerViewModel(repository),
      chatViewModel = ChatViewModel(repository),
      profileViewModel = ProfileViewModel(repository);

  final int userId;
  final AppRepository repository;
  final FeedViewModel feedViewModel;
  final ExploreViewModel exploreViewModel;
  final PlannerViewModel plannerViewModel;
  final ChatViewModel chatViewModel;
  final ProfileViewModel profileViewModel;

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  void syncAuthenticatedUser(AuthUser authUser) {
    if (_isDisposed || authUser.id != userId) {
      return;
    }

    final currentUser = repository.currentUser;
    if (currentUser.displayName == authUser.nickname) {
      return;
    }

    repository.updateCurrentUser(
      displayName: authUser.nickname,
      username: currentUser.username,
      bio: currentUser.bio,
    );
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    feedViewModel.dispose();
    exploreViewModel.dispose();
    plannerViewModel.dispose();
    chatViewModel.dispose();
    profileViewModel.dispose();
    repository.dispose();
  }
}
