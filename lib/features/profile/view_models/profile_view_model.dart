import '../../../core/view_models/repository_view_model.dart';
import '../../../domain/models/app_preferences.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/feed_post.dart';
import '../../../domain/models/plan_item.dart';

enum ProfileContent { posts, stats, saved }

class ProfileViewModel extends RepositoryViewModel {
  ProfileViewModel(super.repository);

  static const _experiencePointPerLevel = 100;

  ProfileContent _content = ProfileContent.posts;

  ProfileContent get content => _content;
  AppUser get user => repository.currentUser;
  AppPreferences get preferences => repository.preferences;
  List<FeedPost> get posts {
    return repository.posts
        .where((post) => post.authorId == user.id)
        .toList(growable: false);
  }

  List<FeedPost> get savedPosts {
    return repository.posts
        .where((post) => post.isSaved)
        .toList(growable: false);
  }

  int get postCount => posts.length;

  int get experiencePoint {
    final earnedPoint = repository.plans
        .where((plan) => plan.progress == PlanProgress.completed)
        .fold(0, (sum, plan) => sum + plan.experiencePoint);
    return (user.level * _experiencePointPerLevel) + earnedPoint;
  }

  int get nextLevelPoint {
    final levelBoundary = (user.level + 1) * _experiencePointPerLevel;
    final experienceBoundary =
        ((experiencePoint ~/ _experiencePointPerLevel) + 1) *
        _experiencePointPerLevel;
    return experienceBoundary > levelBoundary
        ? experienceBoundary
        : levelBoundary;
  }

  int get level => experiencePoint ~/ _experiencePointPerLevel;

  double get levelProgress {
    final currentLevelPoint = level * _experiencePointPerLevel;
    final requiredPoint = nextLevelPoint - currentLevelPoint;
    if (requiredPoint <= 0) return 0;
    return (experiencePoint - currentLevelPoint) / requiredPoint;
  }

  int get currentStreak {
    final successfulDays = _successfulPlanDays;
    if (successfulDays.isEmpty) return 0;

    final today = _startOfDay(DateTime.now());
    if (_statFor(today).hasFailure) return 0;
    var cursor = successfulDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (successfulDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get bestStreak {
    final successfulDays = _successfulPlanDays.toList()..sort();
    if (successfulDays.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var index = 1; index < successfulDays.length; index++) {
      final isConsecutive =
          successfulDays[index].difference(successfulDays[index - 1]).inDays ==
          1;
      current = isConsecutive ? current + 1 : 1;
      if (current > best) best = current;
    }
    return best;
  }

  List<ProfileDayStat> get recentDays {
    final today = _startOfDay(DateTime.now());
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return _statFor(date);
    }, growable: false);
  }

  double get monthlySuccessRate {
    final plans = _currentMonthPlans;
    if (plans.isEmpty) return 0;
    final completed = plans
        .where((plan) => plan.progress == PlanProgress.completed)
        .length;
    return completed / plans.length;
  }

  int get failureCount {
    return _currentMonthPlans
        .where((plan) => plan.progress == PlanProgress.failed)
        .length;
  }

  void selectContent(ProfileContent value) {
    if (_content == value) return;
    _content = value;
    notifyListeners();
  }

  void updateProfile({
    required String displayName,
    required String username,
    required String bio,
  }) {
    repository.updateCurrentUser(
      displayName: displayName,
      username: username,
      bio: bio,
    );
  }

  void updatePreferences({
    bool? pushEnabled,
    bool? publicFailureEnabled,
    bool? systemChatAlertEnabled,
    MentorIntensity? mentorIntensity,
  }) {
    repository.updatePreferences(
      pushEnabled: pushEnabled,
      publicFailureEnabled: publicFailureEnabled,
      systemChatAlertEnabled: systemChatAlertEnabled,
      mentorIntensity: mentorIntensity,
    );
  }

  Set<DateTime> get _successfulPlanDays {
    final dates = repository.plans
        .map((plan) => _startOfDay(plan.scheduledAt))
        .toSet();
    return dates.where((date) => _statFor(date).isSuccessful).toSet();
  }

  List<PlanItem> get _currentMonthPlans {
    final now = DateTime.now();
    return repository.plans
        .where((plan) {
          return plan.scheduledAt.year == now.year &&
              plan.scheduledAt.month == now.month &&
              !plan.scheduledAt.isAfter(now);
        })
        .toList(growable: false);
  }

  ProfileDayStat _statFor(DateTime date) {
    final normalizedDate = _startOfDay(date);
    final plans = repository.plans
        .where((plan) {
          return _startOfDay(plan.scheduledAt) == normalizedDate;
        })
        .toList(growable: false);
    return ProfileDayStat(
      date: normalizedDate,
      totalCount: plans.length,
      completedCount: plans
          .where((plan) => plan.progress == PlanProgress.completed)
          .length,
      failedCount: plans
          .where((plan) => plan.progress == PlanProgress.failed)
          .length,
    );
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class ProfileDayStat {
  const ProfileDayStat({
    required this.date,
    required this.totalCount,
    required this.completedCount,
    required this.failedCount,
  });

  final DateTime date;
  final int totalCount;
  final int completedCount;
  final int failedCount;

  bool get hasPlans => totalCount > 0;
  bool get hasFailure => failedCount > 0;
  bool get isSuccessful =>
      hasPlans && completedCount == totalCount && !hasFailure;

  double get completionRate {
    if (!hasPlans) return 0;
    return completedCount / totalCount;
  }
}
