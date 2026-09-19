import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/data/repositories/mock_app_repository.dart';
import 'package:pathetic_people/domain/models/plan_item.dart';
import 'package:pathetic_people/domain/repositories/plan_repository.dart';
import 'package:pathetic_people/features/planner/view_models/planner_view_model.dart';

void main() {
  group('PlannerViewModel', () {
    test('initialize exposes loading and stores fetched plans', () async {
      final planRepository = _FakePlanRepository();
      final viewModel = _createViewModel(planRepository);
      final completer = Completer<List<PlanItem>>();
      final plan = _plan(id: 'loaded-plan');
      final visibleMonth = viewModel.visibleMonth;
      planRepository.fetchHandler = (_, _) => completer.future;

      final load = viewModel.initialize();

      expect(viewModel.isLoading, isTrue);
      expect(viewModel.loadErrorMessage, isNull);
      expect(planRepository.fetchCalls, 1);

      completer.complete([plan]);
      await load;

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.loadErrorMessage, isNull);
      expect(viewModel.planById(plan.id), same(plan));
      expect(planRepository.requestedRanges, hasLength(1));
      final range = planRepository.requestedRanges.single;
      expect(range.from, DateTime(visibleMonth.year, visibleMonth.month - 1));
      expect(range.to, DateTime(visibleMonth.year, visibleMonth.month + 2));
    });

    test(
      'load failure exposes an error and retry replaces it with data',
      () async {
        final planRepository = _FakePlanRepository();
        final viewModel = _createViewModel(planRepository);
        final plan = _plan(id: 'retry-plan');
        var attempt = 0;
        planRepository.fetchHandler = (_, _) async {
          attempt += 1;
          if (attempt == 1) {
            throw const PlanRepositoryException('계획 조회 실패');
          }
          return [plan];
        };

        await viewModel.initialize();

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.loadErrorMessage, '계획 조회 실패');
        expect(viewModel.planById(plan.id), isNull);

        await viewModel.loadPlans();

        expect(planRepository.fetchCalls, 2);
        expect(viewModel.loadErrorMessage, isNull);
        expect(viewModel.planById(plan.id), same(plan));
      },
    );

    test(
      'duplicate create is rejected and success refreshes the range',
      () async {
        final planRepository = _FakePlanRepository();
        final viewModel = _createViewModel(planRepository);
        final createCompleter = Completer<PlanItem>();
        final created = _plan(id: 'created-plan', title: '첫 회차');
        final repeated = _plan(
          id: 'repeated-plan',
          title: '다음 회차',
          scheduledAt: _todayAt(10).add(const Duration(days: 1)),
        );
        planRepository.createHandler = (_) => createCompleter.future;
        planRepository.fetchHandler = (_, _) async => [created, repeated];

        final firstCreate = viewModel.addPlan(_draft());

        expect(viewModel.isSubmittingPlan, isTrue);
        expect(planRepository.createCalls, 1);
        expect(await viewModel.addPlan(_draft(title: '중복 요청')), isFalse);
        expect(planRepository.createCalls, 1);

        createCompleter.complete(created);
        expect(await firstCreate, isTrue);

        expect(viewModel.isSubmittingPlan, isFalse);
        expect(viewModel.submitErrorMessage, isNull);
        expect(planRepository.fetchCalls, 1);
        expect(viewModel.planById(created.id), same(created));
        expect(viewModel.planById(repeated.id), same(repeated));
      },
    );

    test(
      'proof success upserts the plan and failure exposes its message',
      () async {
        final planRepository = _FakePlanRepository();
        final viewModel = _createViewModel(planRepository);
        final pending = _plan(id: 'proof-plan');
        final proof = PlanProof(
          id: 'completion-proof',
          type: PlanProofType.completion,
          recordedAt: _todayAt(10, minute: 30),
          note: '완료했습니다.',
          sharedToFeed: false,
        );
        final completed = pending.copyWith(
          progress: PlanProgress.completed,
          completedAt: proof.recordedAt,
          completionProof: proof,
        );
        planRepository.fetchHandler = (_, _) async => [pending];
        planRepository.completeProofHandler = (_, _) async => completed;
        planRepository.startProofHandler = (_, _) async {
          throw const PlanRepositoryException('이미 시작 인증했습니다.');
        };
        await viewModel.initialize();

        final completionSaved = await viewModel.completePlan(
          pending.id,
          _proofDraft(PlanProofType.completion),
        );

        expect(completionSaved, isTrue);
        expect(viewModel.isSubmittingProof, isFalse);
        expect(viewModel.proofErrorMessage, isNull);
        expect(
          viewModel.planById(pending.id)?.progress,
          PlanProgress.completed,
        );
        expect(viewModel.planById(pending.id)?.completionProof?.id, proof.id);

        final startSaved = await viewModel.startPlan(
          pending.id,
          _proofDraft(PlanProofType.start),
        );

        expect(startSaved, isFalse);
        expect(viewModel.isSubmittingProof, isFalse);
        expect(viewModel.proofErrorMessage, '이미 시작 인증했습니다.');
        expect(planRepository.completeProofCalls, 1);
        expect(planRepository.startProofCalls, 1);
      },
    );

    test('a late list response cannot overwrite a successful proof', () async {
      final planRepository = _FakePlanRepository();
      final viewModel = _createViewModel(planRepository);
      final fetchCompleter = Completer<List<PlanItem>>();
      final pending = _plan(id: 'race-plan');
      final completed = pending.copyWith(
        progress: PlanProgress.completed,
        completedAt: DateTime.now(),
      );
      planRepository.fetchHandler = (_, _) => fetchCompleter.future;
      planRepository.completeProofHandler = (_, _) async => completed;

      final load = viewModel.initialize();
      final saved = await viewModel.completePlan(
        pending.id,
        _proofDraft(PlanProofType.completion),
      );
      fetchCompleter.complete([pending]);
      await load;

      expect(saved, isTrue);
      expect(viewModel.planById(pending.id)?.progress, PlanProgress.completed);
    });

    test(
      'remote update and delete capabilities prevent unsupported calls',
      () async {
        final planRepository = _FakePlanRepository(
          supportsUpdate: false,
          supportsDelete: false,
        );
        final viewModel = _createViewModel(planRepository);

        expect(viewModel.supportsUpdate, isFalse);
        expect(viewModel.supportsDelete, isFalse);

        expect(await viewModel.updatePlan('remote-plan', _draft()), isFalse);
        expect(viewModel.submitErrorMessage, '서버 계획 수정 기능은 아직 준비되지 않았습니다.');
        expect(planRepository.updateCalls, 0);

        expect(await viewModel.deletePlan('remote-plan'), isFalse);
        expect(viewModel.submitErrorMessage, '서버 계획 삭제 기능은 아직 준비되지 않았습니다.');
        expect(planRepository.deleteCalls, 0);
      },
    );

    test('a late load response is ignored after dispose', () async {
      final planRepository = _FakePlanRepository();
      final appRepository = MockAppRepository();
      final viewModel = PlannerViewModel(appRepository, planRepository);
      final completer = Completer<List<PlanItem>>();
      final latePlan = _plan(id: 'late-plan');
      addTearDown(() {
        viewModel.dispose();
        appRepository.dispose();
      });
      planRepository.fetchHandler = (_, _) => completer.future;

      final load = viewModel.initialize();
      expect(viewModel.isLoading, isTrue);

      viewModel.dispose();
      completer.complete([latePlan]);
      await load;

      expect(planRepository.fetchCalls, 1);
      expect(viewModel.planById(latePlan.id), isNull);
    });
  });
}

PlannerViewModel _createViewModel(_FakePlanRepository planRepository) {
  final appRepository = MockAppRepository();
  final viewModel = PlannerViewModel(appRepository, planRepository);
  addTearDown(() {
    viewModel.dispose();
    appRepository.dispose();
  });
  return viewModel;
}

PlanItem _plan({
  required String id,
  String title = '테스트 계획',
  DateTime? scheduledAt,
  PlanProgress progress = PlanProgress.pending,
  bool photoProofRequired = false,
}) {
  final scheduled = scheduledAt ?? _todayAt(10);
  return PlanItem(
    id: id,
    title: title,
    scheduledAt: scheduled,
    verificationDueAt: scheduled.add(const Duration(hours: 1)),
    category: PlanCategory.study,
    recurrence: '없음',
    experiencePoint: 10,
    progress: progress,
    visibility: PlanVisibility.private,
    photoProofRequired: photoProofRequired,
  );
}

PlanDraft _draft({String title = '새 계획'}) {
  final scheduledAt = _todayAt(10);
  return PlanDraft(
    title: title,
    scheduledAt: scheduledAt,
    verificationDueAt: scheduledAt.add(const Duration(hours: 1)),
    category: PlanCategory.study,
    recurrence: '없음',
    experiencePoint: 10,
    visibility: PlanVisibility.private,
    photoProofRequired: false,
  );
}

PlanProofDraft _proofDraft(PlanProofType type) {
  return PlanProofDraft(type: type, note: '인증', sharedToFeed: false);
}

DateTime _todayAt(int hour, {int minute = 0}) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class _RequestedRange {
  const _RequestedRange(this.from, this.to);

  final DateTime from;
  final DateTime to;
}

class _FakePlanRepository implements PlanRepository {
  _FakePlanRepository({
    this.supportsUpdate = false,
    this.supportsDelete = false,
  });

  @override
  final bool supportsUpdate;

  @override
  final bool supportsDelete;

  Future<List<PlanItem>> Function(DateTime from, DateTime to)? fetchHandler;
  Future<PlanItem> Function(PlanDraft draft)? createHandler;
  Future<PlanItem> Function(String planId, PlanDraft draft)? updateHandler;
  Future<void> Function(String planId)? deleteHandler;
  Future<PlanItem> Function(String planId, PlanProofDraft draft)?
  startProofHandler;
  Future<PlanItem> Function(String planId, PlanProofDraft draft)?
  completeProofHandler;
  Future<void> Function(DateTime now)? evaluateHandler;

  int fetchCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int startProofCalls = 0;
  int completeProofCalls = 0;
  int evaluateCalls = 0;
  int disposeCalls = 0;
  final List<_RequestedRange> requestedRanges = [];

  @override
  Future<List<PlanItem>> fetchPlans({
    required DateTime from,
    required DateTime to,
  }) async {
    fetchCalls += 1;
    requestedRanges.add(_RequestedRange(from, to));
    final handler = fetchHandler;
    if (handler == null) {
      return const <PlanItem>[];
    }
    return handler(from, to);
  }

  @override
  Future<PlanItem> createPlan(PlanDraft draft) {
    createCalls += 1;
    final handler = createHandler;
    if (handler == null) {
      throw StateError('createHandler가 설정되지 않았습니다.');
    }
    return handler(draft);
  }

  @override
  Future<PlanItem> updatePlan(String planId, PlanDraft draft) {
    updateCalls += 1;
    final handler = updateHandler;
    if (handler == null) {
      throw StateError('updateHandler가 설정되지 않았습니다.');
    }
    return handler(planId, draft);
  }

  @override
  Future<void> deletePlan(String planId) {
    deleteCalls += 1;
    final handler = deleteHandler;
    if (handler == null) {
      throw StateError('deleteHandler가 설정되지 않았습니다.');
    }
    return handler(planId);
  }

  @override
  Future<PlanItem> recordStartProof(String planId, PlanProofDraft draft) {
    startProofCalls += 1;
    final handler = startProofHandler;
    if (handler == null) {
      throw StateError('startProofHandler가 설정되지 않았습니다.');
    }
    return handler(planId, draft);
  }

  @override
  Future<PlanItem> recordCompletionProof(String planId, PlanProofDraft draft) {
    completeProofCalls += 1;
    final handler = completeProofHandler;
    if (handler == null) {
      throw StateError('completeProofHandler가 설정되지 않았습니다.');
    }
    return handler(planId, draft);
  }

  @override
  Future<void> evaluateOverdue(DateTime now) async {
    evaluateCalls += 1;
    final handler = evaluateHandler;
    if (handler != null) {
      await handler(now);
    }
  }

  @override
  void dispose() {
    disposeCalls += 1;
  }
}
