import '../../domain/models/plan_item.dart';
import '../../domain/repositories/app_repository.dart';
import '../../domain/repositories/plan_repository.dart';

class LocalPlanRepository implements PlanRepository {
  const LocalPlanRepository(this._appRepository);

  final AppRepository _appRepository;

  @override
  bool get supportsUpdate => true;

  @override
  bool get supportsDelete => true;

  @override
  Future<List<PlanItem>> fetchPlans({
    required DateTime from,
    required DateTime to,
  }) async {
    _validateRange(from, to);
    final plans =
        _appRepository.plans
            .where(
              (plan) =>
                  !plan.scheduledAt.isBefore(from) &&
                  plan.scheduledAt.isBefore(to),
            )
            .toList(growable: false)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return List.unmodifiable(plans);
  }

  @override
  Future<PlanItem> createPlan(PlanDraft draft) async {
    final existingIds = _appRepository.plans.map((plan) => plan.id).toSet();
    _appRepository.addPlan(draft);
    final created =
        _appRepository.plans
            .where((plan) => !existingIds.contains(plan.id))
            .toList(growable: false)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (created.isEmpty) {
      throw const PlanRepositoryException('계획을 저장하지 못했습니다. 다시 시도해 주세요.');
    }
    return created.first;
  }

  @override
  Future<PlanItem> updatePlan(String planId, PlanDraft draft) async {
    final original = _findPlan(planId);
    final existingIds = _appRepository.plans.map((plan) => plan.id).toSet();
    _appRepository.updatePlan(planId, draft);

    final exactMatch = _findPlanOrNull(planId);
    if (exactMatch != null) {
      return exactMatch;
    }

    final replacement =
        _appRepository.plans
            .where(
              (plan) =>
                  !existingIds.contains(plan.id) ||
                  (original.seriesId != null &&
                      plan.seriesId == original.seriesId &&
                      plan.scheduledAt == draft.scheduledAt),
            )
            .toList(growable: false)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (replacement.isEmpty) {
      throw const PlanRepositoryException('수정한 계획을 불러오지 못했습니다. 다시 시도해 주세요.');
    }
    return replacement.first;
  }

  @override
  Future<void> deletePlan(String planId) async {
    _appRepository.deletePlan(planId);
  }

  @override
  Future<PlanItem> recordStartProof(String planId, PlanProofDraft draft) async {
    _appRepository.startPlan(planId, draft);
    return _findPlan(planId);
  }

  @override
  Future<PlanItem> recordCompletionProof(
    String planId,
    PlanProofDraft draft,
  ) async {
    _appRepository.completePlan(planId, draft);
    return _findPlan(planId);
  }

  @override
  Future<void> evaluateOverdue(DateTime now) async {
    _appRepository.markOverduePlans(now);
  }

  @override
  void dispose() {
    // AppContentSession owns and disposes the shared AppRepository.
  }

  PlanItem _findPlan(String planId) {
    final plan = _findPlanOrNull(planId);
    if (plan == null) {
      throw PlanRepositoryException('계획을 찾을 수 없습니다. ($planId)');
    }
    return plan;
  }

  PlanItem? _findPlanOrNull(String planId) {
    for (final plan in _appRepository.plans) {
      if (plan.id == planId) {
        return plan;
      }
    }
    return null;
  }

  void _validateRange(DateTime from, DateTime to) {
    if (!to.isAfter(from)) {
      throw ArgumentError.value(to, 'to', '조회 종료 시각은 시작 시각보다 뒤여야 합니다.');
    }
  }
}
