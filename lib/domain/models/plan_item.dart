import 'dart:typed_data';

enum PlanProgress { pending, completed, failed }

enum PlanCategory { health, study, routine, record }

enum PlanVisibility { private, publicChallenge }

enum PlanProofType { start, completion }

class PlanProof {
  const PlanProof({
    required this.id,
    required this.type,
    required this.recordedAt,
    required this.note,
    required this.sharedToFeed,
    this.mediaBytes,
    this.mediaName,
  });

  final String id;
  final PlanProofType type;
  final DateTime recordedAt;
  final Uint8List? mediaBytes;
  final String? mediaName;
  final String note;
  final bool sharedToFeed;
}

class PlanProofDraft {
  const PlanProofDraft({
    required this.type,
    required this.note,
    required this.sharedToFeed,
    this.mediaBytes,
    this.mediaName,
  });

  final PlanProofType type;
  final Uint8List? mediaBytes;
  final String? mediaName;
  final String note;
  final bool sharedToFeed;
}

class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.verificationDueAt,
    required this.category,
    required this.recurrence,
    required this.experiencePoint,
    required this.progress,
    required this.visibility,
    required this.photoProofRequired,
    this.completedAt,
    this.seriesId,
    this.startProof,
    this.completionProof,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final DateTime verificationDueAt;
  final PlanCategory category;
  final String recurrence;
  final int experiencePoint;
  final PlanProgress progress;
  final PlanVisibility visibility;
  final bool photoProofRequired;
  final DateTime? completedAt;
  final String? seriesId;
  final PlanProof? startProof;
  final PlanProof? completionProof;

  PlanItem copyWith({
    String? title,
    DateTime? scheduledAt,
    DateTime? verificationDueAt,
    PlanCategory? category,
    String? recurrence,
    int? experiencePoint,
    PlanProgress? progress,
    PlanVisibility? visibility,
    bool? photoProofRequired,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? seriesId,
    bool clearSeriesId = false,
    PlanProof? startProof,
    bool clearStartProof = false,
    PlanProof? completionProof,
    bool clearCompletionProof = false,
  }) {
    return PlanItem(
      id: id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      verificationDueAt: verificationDueAt ?? this.verificationDueAt,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      experiencePoint: experiencePoint ?? this.experiencePoint,
      progress: progress ?? this.progress,
      visibility: visibility ?? this.visibility,
      photoProofRequired: photoProofRequired ?? this.photoProofRequired,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      seriesId: clearSeriesId ? null : seriesId ?? this.seriesId,
      startProof: clearStartProof ? null : startProof ?? this.startProof,
      completionProof: clearCompletionProof
          ? null
          : completionProof ?? this.completionProof,
    );
  }
}

class PlanDraft {
  const PlanDraft({
    required this.title,
    required this.scheduledAt,
    required this.verificationDueAt,
    required this.category,
    required this.recurrence,
    required this.experiencePoint,
    required this.visibility,
    required this.photoProofRequired,
  });

  final String title;
  final DateTime scheduledAt;
  final DateTime verificationDueAt;
  final PlanCategory category;
  final String recurrence;
  final int experiencePoint;
  final PlanVisibility visibility;
  final bool photoProofRequired;
}
