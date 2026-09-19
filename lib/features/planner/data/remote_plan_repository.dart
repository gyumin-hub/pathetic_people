import '../../../core/network/api_exception.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/plan_repository.dart';
import 'plan_api_client.dart';
import 'plan_api_dto.dart';

class RemotePlanRepository implements PlanRepository {
  RemotePlanRepository({
    required PlanApiClient apiClient,
    required String timezone,
  }) : _client = apiClient,
       _timezone = _requireTimezone(timezone);

  final PlanApiClient _client;
  final String _timezone;
  final Map<String, PlanItem> _knownPlans = {};
  bool _isDisposed = false;

  @override
  bool get supportsUpdate => false;

  @override
  bool get supportsDelete => false;

  @override
  Future<List<PlanItem>> fetchPlans({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _client.fetchPlans(from: from, to: to);
    final plans = response.map(_toDomain).toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    for (final plan in plans) {
      _knownPlans[plan.id] = plan;
    }
    return List.unmodifiable(plans);
  }

  @override
  Future<PlanItem> createPlan(PlanDraft draft) async {
    late final PlanCreateRequestDto request;
    try {
      request = PlanCreateRequestDto.fromDomain(draft, timezone: _timezone);
    } on FormatException {
      throw PlanRepositoryException('지원하지 않는 반복 방식입니다: ${draft.recurrence}');
    }

    final plan = _toDomain(await _client.createPlan(request));
    _knownPlans[plan.id] = plan;
    return plan;
  }

  @override
  Future<PlanItem> updatePlan(String planId, PlanDraft draft) async {
    throw const PlanRepositoryException(
      '서버 계획 수정 기능은 아직 준비되지 않았습니다. 새 계획을 만들어 주세요.',
    );
  }

  @override
  Future<void> deletePlan(String planId) async {
    throw const PlanRepositoryException('서버 계획 삭제 기능은 아직 준비되지 않았습니다.');
  }

  @override
  Future<PlanItem> recordStartProof(String planId, PlanProofDraft draft) async {
    if (draft.type != PlanProofType.start) {
      throw ArgumentError.value(
        draft.type,
        'draft.type',
        '시작 인증에는 PlanProofType.start가 필요합니다.',
      );
    }
    _rejectBinaryMedia(draft);

    final plan = _toDomain(
      await _client.recordStartProof(
        planId,
        ProofCreateRequestDto(
          note: _trimmedOrNull(draft.note),
          shareToFeed: draft.sharedToFeed,
        ),
      ),
    );
    _knownPlans[plan.id] = plan;
    return plan;
  }

  @override
  Future<PlanItem> recordCompletionProof(
    String planId,
    PlanProofDraft draft,
  ) async {
    if (draft.type != PlanProofType.completion) {
      throw ArgumentError.value(
        draft.type,
        'draft.type',
        '완료 인증에는 PlanProofType.completion이 필요합니다.',
      );
    }
    _rejectBinaryMedia(draft);
    if (draft.sharedToFeed) {
      throw const PlanRepositoryException(
        '피드 공유에는 업로드된 사진이 필요합니다. 사진 업로드 연결 후 사용할 수 있습니다.',
      );
    }

    final knownPlan =
        _knownPlans[planId] ?? _toDomain(await _client.fetchPlan(planId));
    _knownPlans[knownPlan.id] = knownPlan;
    if (knownPlan.photoProofRequired) {
      throw const PlanRepositoryException(
        '이 계획은 사진 인증이 필수입니다. 사진 업로드 연결 후 완료할 수 있습니다.',
      );
    }

    final plan = _toDomain(
      await _client.recordCompletionProof(
        planId,
        ProofCreateRequestDto(
          note: _trimmedOrNull(draft.note),
          shareToFeed: false,
        ),
      ),
    );
    _knownPlans[plan.id] = plan;
    return plan;
  }

  @override
  Future<void> evaluateOverdue(DateTime now) => Future<void>.value();

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _client.close();
  }

  PlanItem _toDomain(PlanOccurrenceDto dto) {
    try {
      return dto.toDomain();
    } on FormatException {
      throw ApiException.invalidResponse();
    }
  }

  void _rejectBinaryMedia(PlanProofDraft draft) {
    if (draft.mediaBytes != null) {
      throw const PlanRepositoryException(
        '선택한 사진을 서버에 올리는 기능은 아직 연결되지 않았습니다. 사진 없이 다시 시도해 주세요.',
      );
    }
  }

  static String _requireTimezone(String timezone) {
    final normalized = timezone.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(timezone, 'timezone', 'IANA 시간대가 필요합니다.');
    }
    return normalized;
  }

  static String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
