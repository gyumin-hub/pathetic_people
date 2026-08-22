enum PlanProgress { pending, completed, failed }

enum PlanCategory { health, study, routine, record }

class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.category,
    required this.recurrence,
    required this.experiencePoint,
    required this.progress,
    this.completedAt,
    this.seriesId,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final PlanCategory category;
  final String recurrence;
  final int experiencePoint;
  final PlanProgress progress;
  final DateTime? completedAt;
  final String? seriesId;

  PlanItem copyWith({
    String? title,
    DateTime? scheduledAt,
    PlanCategory? category,
    String? recurrence,
    int? experiencePoint,
    PlanProgress? progress,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? seriesId,
    bool clearSeriesId = false,
  }) {
    return PlanItem(
      id: id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      experiencePoint: experiencePoint ?? this.experiencePoint,
      progress: progress ?? this.progress,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      seriesId: clearSeriesId ? null : seriesId ?? this.seriesId,
    );
  }
}

class PlanDraft {
  const PlanDraft({
    required this.title,
    required this.scheduledAt,
    required this.category,
    required this.recurrence,
    required this.experiencePoint,
  });

  final String title;
  final DateTime scheduledAt;
  final PlanCategory category;
  final String recurrence;
  final int experiencePoint;
}
