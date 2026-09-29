abstract final class PlanTimingPolicy {
  static const startProofLeadTime = Duration(hours: 1);

  static DateTime startProofOpensAt(DateTime scheduledAt) {
    return scheduledAt.subtract(startProofLeadTime);
  }

  static bool canRecordStartProof({
    required DateTime scheduledAt,
    required DateTime verificationDueAt,
    required DateTime now,
  }) {
    return !now.isBefore(startProofOpensAt(scheduledAt)) &&
        now.isBefore(verificationDueAt);
  }

  static bool canRecordCompletionProof({
    required DateTime scheduledAt,
    required DateTime verificationDueAt,
    required DateTime now,
  }) {
    return !now.isBefore(scheduledAt) && now.isBefore(verificationDueAt);
  }

  static Duration until(DateTime target, DateTime now) {
    final duration = target.toUtc().difference(now.toUtc());
    return duration.isNegative ? Duration.zero : duration;
  }
}
