import '../models/plan_item.dart';

abstract interface class PlanRepository {
  bool get supportsUpdate;
  bool get supportsDelete;

  Future<List<PlanItem>> fetchPlans({
    required DateTime from,
    required DateTime to,
  });

  Future<PlanItem> createPlan(PlanDraft draft);
  Future<PlanItem> updatePlan(String planId, PlanDraft draft);
  Future<void> deletePlan(String planId);
  Future<PlanItem> recordStartProof(String planId, PlanProofDraft draft);
  Future<PlanItem> recordCompletionProof(String planId, PlanProofDraft draft);
  Future<void> evaluateOverdue(DateTime now);

  void dispose();
}

class PlanRepositoryException implements Exception {
  const PlanRepositoryException(this.userMessage);

  final String userMessage;

  @override
  String toString() => 'PlanRepositoryException($userMessage)';
}
