import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/app_repository.dart';
import '../../../domain/repositories/plan_repository.dart';
import '../../../domain/services/mentor_message_service.dart';

class PlannerViewModel extends ChangeNotifier {
  PlannerViewModel(this.repository, this.planRepository)
    : _selectedDate = AppDateUtils.startOfDay(DateTime.now()),
      _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month),
      _usesAppRepositoryPlans =
          planRepository.supportsUpdate && planRepository.supportsDelete,
      _plans = planRepository.supportsUpdate && planRepository.supportsDelete
          ? List<PlanItem>.of(repository.plans)
          : <PlanItem>[] {
    repository.addListener(_onAppRepositoryChanged);
    _sortPlans();
  }

  final AppRepository repository;
  final PlanRepository planRepository;
  final bool _usesAppRepositoryPlans;

  DateTime _selectedDate;
  DateTime _visibleMonth;
  List<PlanItem> _plans;
  DateTime? _loadedFrom;
  DateTime? _loadedTo;
  DateTime? _loadingFrom;
  DateTime? _loadingTo;
  bool _isLoading = false;
  bool _isSubmittingPlan = false;
  bool _isSubmittingProof = false;
  bool _isEvaluatingOverdue = false;
  bool _isDisposed = false;
  int _loadGeneration = 0;
  String? _loadErrorMessage;
  String? _submitErrorMessage;
  String? _proofErrorMessage;

  DateTime get selectedDate => _selectedDate;
  DateTime get visibleMonth => _visibleMonth;
  bool get isLoading => _isLoading;
  bool get isSubmittingPlan => _isSubmittingPlan;
  bool get isSubmittingProof => _isSubmittingProof;
  bool get supportsUpdate => planRepository.supportsUpdate;
  bool get supportsDelete => planRepository.supportsDelete;
  bool get supportsProofMediaUpload => _usesAppRepositoryPlans;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  String? get proofErrorMessage => _proofErrorMessage;

  List<PlanItem> get selectedPlans {
    return _plans
        .where(
          (plan) => AppDateUtils.isSameDay(plan.scheduledAt, _selectedDate),
        )
        .toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<PlanItem> plansFor(DateTime date) {
    return _plans
        .where((plan) => AppDateUtils.isSameDay(plan.scheduledAt, date))
        .toList(growable: false);
  }

  PlanItem? planById(String planId) {
    for (final plan in _plans) {
      if (plan.id == planId) return plan;
    }
    return null;
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
      final serverMessage = failed.first.failureMessage?.trim();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        return serverMessage;
      }
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

  Future<void> initialize() => loadPlans();

  Future<void> loadPlans({bool force = false}) async {
    if (_isDisposed) return;

    final from = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final to = DateTime(_visibleMonth.year, _visibleMonth.month + 2);
    if (!force && _rangeContains(from, to)) {
      return;
    }
    if (!force && _isLoading && _loadingFrom == from && _loadingTo == to) {
      return;
    }

    final generation = ++_loadGeneration;
    _isLoading = true;
    _loadingFrom = from;
    _loadingTo = to;
    _loadErrorMessage = null;
    _notifyListeners();

    try {
      final plans = await planRepository.fetchPlans(from: from, to: to);
      if (!_accepts(generation)) return;
      _plans = List<PlanItem>.of(plans);
      _sortPlans();
      _loadedFrom = from;
      _loadedTo = to;
    } catch (error) {
      if (!_accepts(generation)) return;
      _loadErrorMessage = _messageFor(
        error,
        fallback: '계획을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    } finally {
      if (_accepts(generation)) {
        _isLoading = false;
        _loadingFrom = null;
        _loadingTo = null;
        _notifyListeners();
      }
    }
  }

  Future<void> refreshPlans() => loadPlans(force: true);

  void selectDate(DateTime date) {
    _selectedDate = AppDateUtils.startOfDay(date);
    _visibleMonth = DateTime(date.year, date.month);
    _notifyListeners();
    unawaited(loadPlans());
  }

  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    _selectMatchingDayInVisibleMonth();
    _notifyListeners();
    unawaited(loadPlans());
  }

  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    _selectMatchingDayInVisibleMonth();
    _notifyListeners();
    unawaited(loadPlans());
  }

  Future<bool> addPlan(PlanDraft draft) async {
    if (_isDisposed || _isSubmittingPlan) return false;
    _beginPlanSubmission();
    try {
      final created = await planRepository.createPlan(draft);
      if (_isDisposed) return false;
      _invalidateActiveLoad();
      _upsert(created);
      await loadPlans(force: true);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      _submitErrorMessage = _messageFor(
        error,
        fallback: '계획을 추가하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
      return false;
    } finally {
      _endPlanSubmission();
    }
  }

  Future<bool> updatePlan(String planId, PlanDraft draft) async {
    if (!supportsUpdate) {
      _submitErrorMessage = '서버 계획 수정 기능은 아직 준비되지 않았습니다.';
      _notifyListeners();
      return false;
    }
    if (_isDisposed || _isSubmittingPlan) return false;
    _beginPlanSubmission();
    try {
      final updated = await planRepository.updatePlan(planId, draft);
      if (_isDisposed) return false;
      _invalidateActiveLoad();
      _upsert(updated);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      _submitErrorMessage = _messageFor(
        error,
        fallback: '계획을 수정하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
      return false;
    } finally {
      _endPlanSubmission();
    }
  }

  Future<bool> deletePlan(String planId) async {
    if (!supportsDelete) {
      _submitErrorMessage = '서버 계획 삭제 기능은 아직 준비되지 않았습니다.';
      _notifyListeners();
      return false;
    }
    if (_isDisposed || _isSubmittingPlan) return false;
    _beginPlanSubmission();
    try {
      await planRepository.deletePlan(planId);
      if (_isDisposed) return false;
      _invalidateActiveLoad();
      _plans.removeWhere((plan) => plan.id == planId);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      _submitErrorMessage = _messageFor(
        error,
        fallback: '계획을 삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
      return false;
    } finally {
      _endPlanSubmission();
    }
  }

  Future<bool> startPlan(String planId, PlanProofDraft proofDraft) {
    return _recordProof(
      () => planRepository.recordStartProof(planId, proofDraft),
      fallback: '시작 인증을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
    );
  }

  Future<bool> completePlan(String planId, PlanProofDraft proofDraft) {
    return _recordProof(
      () => planRepository.recordCompletionProof(planId, proofDraft),
      fallback: '완료 인증을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
    );
  }

  String? proofUnavailableMessage(PlanItem plan, PlanProofType type) {
    if (type == PlanProofType.completion &&
        plan.photoProofRequired &&
        !supportsProofMediaUpload) {
      return '사진 업로드 API가 아직 없어 사진 필수 계획은 완료 인증할 수 없습니다.';
    }
    return null;
  }

  Future<void> evaluateOverduePlans() async {
    if (_isDisposed || _isEvaluatingOverdue) return;
    _isEvaluatingOverdue = true;
    try {
      await planRepository.evaluateOverdue(DateTime.now());
      if (_isDisposed) return;
      await loadPlans(force: _loadedFrom != null);
    } catch (error) {
      if (_isDisposed) return;
      _loadErrorMessage = _messageFor(error, fallback: '계획 상태를 새로 확인하지 못했습니다.');
      _notifyListeners();
    } finally {
      _isEvaluatingOverdue = false;
    }
  }

  Set<DateTime> get _successfulDays {
    final plansByDay = <DateTime, List<PlanItem>>{};
    for (final plan in _plans) {
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

  Future<bool> _recordProof(
    Future<PlanItem> Function() action, {
    required String fallback,
  }) async {
    if (_isDisposed || _isSubmittingProof) return false;
    _isSubmittingProof = true;
    _proofErrorMessage = null;
    _notifyListeners();
    try {
      final updated = await action();
      if (_isDisposed) return false;
      _invalidateActiveLoad();
      _upsert(updated);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      _proofErrorMessage = _messageFor(error, fallback: fallback);
      return false;
    } finally {
      if (!_isDisposed) {
        _isSubmittingProof = false;
        _notifyListeners();
      }
    }
  }

  void _beginPlanSubmission() {
    _isSubmittingPlan = true;
    _submitErrorMessage = null;
    _notifyListeners();
  }

  void _endPlanSubmission() {
    if (_isDisposed) return;
    _isSubmittingPlan = false;
    _notifyListeners();
  }

  void _upsert(PlanItem plan) {
    final index = _plans.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      _plans.add(plan);
    } else {
      _plans[index] = plan;
    }
    _sortPlans();
    _notifyListeners();
  }

  void _sortPlans() {
    _plans.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  void _invalidateActiveLoad() {
    _loadGeneration++;
    _isLoading = false;
    _loadingFrom = null;
    _loadingTo = null;
  }

  bool _rangeContains(DateTime from, DateTime to) {
    final loadedFrom = _loadedFrom;
    final loadedTo = _loadedTo;
    return loadedFrom != null &&
        loadedTo != null &&
        !from.isBefore(loadedFrom) &&
        !to.isAfter(loadedTo);
  }

  bool _accepts(int generation) {
    return !_isDisposed && generation == _loadGeneration;
  }

  String _messageFor(Object error, {required String fallback}) {
    if (error is ApiException) return error.userMessage;
    if (error is PlanRepositoryException) return error.userMessage;
    if (error is StateError) return error.message;
    if (error is ArgumentError && error.message != null) {
      return '${error.message}';
    }
    return fallback;
  }

  void _onAppRepositoryChanged() {
    if (_isDisposed) return;
    if (_usesAppRepositoryPlans) {
      _plans = List<PlanItem>.of(repository.plans);
      _sortPlans();
    }
    _notifyListeners();
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

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _loadGeneration++;
    repository.removeListener(_onAppRepositoryChanged);
    super.dispose();
  }
}
