import '../../../core/utils/date_utils.dart';
import '../../../core/view_models/repository_view_model.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/services/mentor_message_service.dart';

class PlannerViewModel extends RepositoryViewModel {
  PlannerViewModel(super.repository)
    : _selectedDate = AppDateUtils.startOfDay(DateTime.now()),
      _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime _selectedDate;
  DateTime _visibleMonth;

  DateTime get selectedDate => _selectedDate;
  DateTime get visibleMonth => _visibleMonth;

  List<PlanItem> get selectedPlans {
    return repository.plans
        .where(
          (plan) => AppDateUtils.isSameDay(plan.scheduledAt, _selectedDate),
        )
        .toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<PlanItem> plansFor(DateTime date) {
    return repository.plans
        .where((plan) => AppDateUtils.isSameDay(plan.scheduledAt, date))
        .toList(growable: false);
  }

  int get completedCount {
    return selectedPlans
        .where((plan) => plan.progress == PlanProgress.completed)
        .length;
  }

  double get completionRate {
    if (selectedPlans.isEmpty) return 0;
    return completedCount / selectedPlans.length;
  }

  int get currentStreak {
    final successfulDays = _successfulDays;
    if (successfulDays.isEmpty) return 0;
    final today = AppDateUtils.startOfDay(DateTime.now());
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
    final successfulDays = _successfulDays.toList()..sort();
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

  String get mentorMessage {
    final failed = selectedPlans.where(
      (plan) => plan.progress == PlanProgress.failed,
    );
    if (failed.isNotEmpty) {
      return MentorMessageService.failureFor(
        failed.first,
        intensity: repository.preferences.mentorIntensity,
      );
    }
    if (selectedPlans.isNotEmpty && completedCount == selectedPlans.length) {
      return '오늘은 핑계보다 행동이 빨랐네요. 이 흐름을 내일까지 가져가세요.';
    }
    return '아직 포기하기엔 이릅니다. 남은 계획 하나부터 바로 시작하세요.';
  }

  void selectDate(DateTime date) {
    _selectedDate = AppDateUtils.startOfDay(date);
    _visibleMonth = DateTime(date.year, date.month);
    notifyListeners();
  }

  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    _selectMatchingDayInVisibleMonth();
    notifyListeners();
  }

  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    _selectMatchingDayInVisibleMonth();
    notifyListeners();
  }

  void addPlan(PlanDraft draft) {
    repository.addPlan(draft);
    repository.markOverduePlans(DateTime.now());
  }

  void updatePlan(String planId, PlanDraft draft) {
    repository.updatePlan(planId, draft);
    repository.markOverduePlans(DateTime.now());
  }

  void deletePlan(String planId) => repository.deletePlan(planId);

  void toggleCompletion(String planId) {
    repository.togglePlanCompletion(planId);
    repository.markOverduePlans(DateTime.now());
  }

  void evaluateOverduePlans() {
    repository.markOverduePlans(DateTime.now());
  }

  Set<DateTime> get _successfulDays {
    final plansByDay = <DateTime, List<PlanItem>>{};
    for (final plan in repository.plans) {
      final day = AppDateUtils.startOfDay(plan.scheduledAt);
      plansByDay.putIfAbsent(day, () => []).add(plan);
    }
    return plansByDay.entries
        .where(
          (entry) =>
              entry.value.isNotEmpty &&
              entry.value.every(
                (plan) => plan.progress == PlanProgress.completed,
              ),
        )
        .map((entry) => entry.key)
        .toSet();
  }

  void _selectMatchingDayInVisibleMonth() {
    final lastDay = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final day = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
    _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
  }
}
