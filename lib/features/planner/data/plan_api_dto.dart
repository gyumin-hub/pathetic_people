import 'dart:typed_data';

import '../../../domain/models/plan_item.dart';

class PlanCreateRequestDto {
  const PlanCreateRequestDto({
    required this.title,
    required this.scheduledAt,
    required this.verificationDueAt,
    required this.category,
    required this.recurrence,
    required this.visibility,
    required this.photoProofRequired,
    required this.experiencePoint,
    required this.timezone,
  });

  factory PlanCreateRequestDto.fromDomain(
    PlanDraft draft, {
    required String timezone,
  }) {
    return PlanCreateRequestDto(
      title: draft.title.trim(),
      scheduledAt: draft.scheduledAt.toUtc(),
      verificationDueAt: draft.verificationDueAt.toUtc(),
      category: _categoryToApi(draft.category),
      recurrence: _recurrenceToApi(draft.recurrence),
      visibility: _visibilityToApi(draft.visibility),
      photoProofRequired: draft.photoProofRequired,
      experiencePoint: draft.experiencePoint,
      timezone: timezone,
    );
  }

  final String title;
  final DateTime scheduledAt;
  final DateTime verificationDueAt;
  final String category;
  final String recurrence;
  final String visibility;
  final bool photoProofRequired;
  final int experiencePoint;
  final String timezone;

  Map<String, Object?> toJson() => {
    'title': title,
    'scheduledAt': scheduledAt.toIso8601String(),
    'verificationDueAt': verificationDueAt.toIso8601String(),
    'category': category,
    'recurrence': recurrence,
    'visibility': visibility,
    'photoProofRequired': photoProofRequired,
    'experiencePoint': experiencePoint,
    'timezone': timezone,
  };
}

class ProofCreateRequestDto {
  const ProofCreateRequestDto({
    required this.shareToFeed,
    this.mediaBytes,
    this.mediaName,
    this.note,
  });

  final Uint8List? mediaBytes;
  final String? mediaName;
  final String? note;
  final bool shareToFeed;

  Map<String, Object?> toJson() => {
    if (note != null) 'note': note,
    'shareToFeed': shareToFeed,
  };
}

class PlanOccurrenceDto {
  const PlanOccurrenceDto({
    required this.planId,
    required this.occurrenceId,
    required this.title,
    required this.scheduledAt,
    required this.verificationDueAt,
    required this.category,
    required this.recurrence,
    required this.visibility,
    required this.photoProofRequired,
    required this.experiencePoint,
    required this.timezone,
    required this.status,
    this.completedAt,
    this.failureMessage,
    this.startProof,
    this.completionProof,
  });

  factory PlanOccurrenceDto.fromJson(Map<String, dynamic> json) {
    return PlanOccurrenceDto(
      planId: _requiredInt(json, 'planId'),
      occurrenceId: _requiredInt(json, 'occurrenceId'),
      title: _requiredString(json, 'title'),
      scheduledAt: _requiredOffsetDateTime(json, 'scheduledAt'),
      verificationDueAt: _requiredOffsetDateTime(json, 'verificationDueAt'),
      category: _requiredString(json, 'category'),
      recurrence: _requiredString(json, 'recurrence'),
      visibility: _requiredString(json, 'visibility'),
      photoProofRequired: _requiredBool(json, 'photoProofRequired'),
      experiencePoint: _requiredInt(json, 'experiencePoint'),
      timezone: _requiredString(json, 'timezone'),
      status: _requiredString(json, 'status'),
      completedAt: _optionalOffsetDateTime(json, 'completedAt'),
      failureMessage: _optionalString(json, 'failureMessage'),
      startProof: _optionalProof(json, 'startProof'),
      completionProof: _optionalProof(json, 'completionProof'),
    );
  }

  final int planId;
  final int occurrenceId;
  final String title;
  final DateTime scheduledAt;
  final DateTime verificationDueAt;
  final String category;
  final String recurrence;
  final String visibility;
  final bool photoProofRequired;
  final int experiencePoint;
  final String timezone;
  final String status;
  final DateTime? completedAt;
  final String? failureMessage;
  final PlanProofDto? startProof;
  final PlanProofDto? completionProof;

  PlanItem toDomain() {
    return PlanItem(
      id: occurrenceId.toString(),
      seriesId: planId.toString(),
      title: title,
      scheduledAt: scheduledAt.toLocal(),
      verificationDueAt: verificationDueAt.toLocal(),
      category: _categoryFromApi(category),
      recurrence: _recurrenceFromApi(recurrence),
      experiencePoint: experiencePoint,
      progress: _progressFromApi(status),
      visibility: _visibilityFromApi(visibility),
      photoProofRequired: photoProofRequired,
      completedAt: completedAt?.toLocal(),
      failureMessage: failureMessage,
      startProof: startProof?.toDomain(),
      completionProof: completionProof?.toDomain(),
    );
  }
}

class PlanProofDto {
  const PlanProofDto({
    required this.id,
    required this.proofType,
    required this.sharedToFeed,
    required this.recordedAt,
    this.mediaUrl,
    this.mediaName,
    this.note,
  });

  factory PlanProofDto.fromJson(Map<String, dynamic> json) {
    return PlanProofDto(
      id: _requiredInt(json, 'id'),
      proofType: _requiredString(json, 'proofType'),
      mediaUrl: _optionalString(json, 'mediaUrl'),
      mediaName: _optionalString(json, 'mediaName'),
      note: _optionalString(json, 'note'),
      sharedToFeed: _requiredBool(json, 'sharedToFeed'),
      recordedAt: _requiredOffsetDateTime(json, 'recordedAt'),
    );
  }

  final int id;
  final String proofType;
  final String? mediaUrl;
  final String? mediaName;
  final String? note;
  final bool sharedToFeed;
  final DateTime recordedAt;

  PlanProof toDomain() {
    return PlanProof(
      id: id.toString(),
      type: _proofTypeFromApi(proofType),
      recordedAt: recordedAt.toLocal(),
      mediaUrl: mediaUrl,
      mediaName: mediaName,
      note: note ?? '',
      sharedToFeed: sharedToFeed,
    );
  }
}

String _categoryToApi(PlanCategory category) => switch (category) {
  PlanCategory.health => 'HEALTH',
  PlanCategory.study => 'STUDY',
  PlanCategory.routine => 'ROUTINE',
  PlanCategory.record => 'RECORD',
};

PlanCategory _categoryFromApi(String value) => switch (value) {
  'HEALTH' => PlanCategory.health,
  'STUDY' => PlanCategory.study,
  'ROUTINE' => PlanCategory.routine,
  'RECORD' => PlanCategory.record,
  _ => throw FormatException('Unknown plan category: $value'),
};

String _recurrenceToApi(String recurrence) => switch (recurrence) {
  '없음' => 'NONE',
  '매일' => 'DAILY',
  '평일' => 'WEEKDAYS',
  '주말' => 'WEEKENDS',
  '월·수·금' => 'MON_WED_FRI',
  _ => throw FormatException('Unknown plan recurrence: $recurrence'),
};

String _recurrenceFromApi(String value) => switch (value) {
  'NONE' => '없음',
  'DAILY' => '매일',
  'WEEKDAYS' => '평일',
  'WEEKENDS' => '주말',
  'MON_WED_FRI' => '월·수·금',
  _ => throw FormatException('Unknown plan recurrence: $value'),
};

String _visibilityToApi(PlanVisibility visibility) => switch (visibility) {
  PlanVisibility.private => 'PRIVATE',
  PlanVisibility.publicChallenge => 'PUBLIC_CHALLENGE',
};

PlanVisibility _visibilityFromApi(String value) => switch (value) {
  'PRIVATE' => PlanVisibility.private,
  'PUBLIC_CHALLENGE' => PlanVisibility.publicChallenge,
  _ => throw FormatException('Unknown plan visibility: $value'),
};

PlanProgress _progressFromApi(String value) => switch (value) {
  'PENDING' => PlanProgress.pending,
  'COMPLETED' => PlanProgress.completed,
  'FAILED' => PlanProgress.failed,
  _ => throw FormatException('Unknown plan status: $value'),
};

PlanProofType _proofTypeFromApi(String value) => switch (value) {
  'START' => PlanProofType.start,
  'COMPLETION' => PlanProofType.completion,
  _ => throw FormatException('Unknown proof type: $value'),
};

PlanProofDto? _optionalProof(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected $key to be a JSON object.');
  }
  return PlanProofDto.fromJson(value);
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite && value == value.toInt()) {
    return value.toInt();
  }
  throw FormatException('Expected $key to be an integer.');
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Expected $key to be a boolean.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected $key to be a string.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Expected $key to be a string or null.');
  }
  return value;
}

DateTime _requiredOffsetDateTime(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  return _parseOffsetDateTime(value, key);
}

DateTime? _optionalOffsetDateTime(Map<String, dynamic> json, String key) {
  final value = _optionalString(json, key);
  return value == null ? null : _parseOffsetDateTime(value, key);
}

DateTime _parseOffsetDateTime(String value, String key) {
  final hasOffset = RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value);
  final parsed = DateTime.tryParse(value);
  if (!hasOffset || parsed == null) {
    throw FormatException('Expected $key to include a valid UTC offset.');
  }
  return parsed;
}
