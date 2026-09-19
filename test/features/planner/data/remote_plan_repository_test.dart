import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathetic_people/core/network/api_exception.dart';
import 'package:pathetic_people/domain/models/plan_item.dart';
import 'package:pathetic_people/domain/repositories/plan_repository.dart';
import 'package:pathetic_people/features/planner/data/plan_api_client.dart';
import 'package:pathetic_people/features/planner/data/remote_plan_repository.dart';

void main() {
  group('RemotePlanRepository', () {
    test(
      'maps server IDs, enums, dates, and proof metadata explicitly',
      () async {
        final repository = _repository(
          MockClient((_) async {
            return _jsonResponse([
              _occurrenceJson(
                startProof: {
                  'id': 31,
                  'proofType': 'START',
                  'mediaUrl': 'https://cdn.example/proof.jpg',
                  'mediaName': 'proof.jpg',
                  'note': '출발',
                  'sharedToFeed': true,
                  'recordedAt': '2026-08-25T19:05:00+09:00',
                },
              ),
            ]);
          }),
        );

        final plan = (await repository.fetchPlans(
          from: DateTime.utc(2026, 8, 25),
          to: DateTime.utc(2026, 8, 26),
        )).single;

        expect(plan.id, '22');
        expect(plan.seriesId, '11');
        expect(plan.category, PlanCategory.health);
        expect(plan.recurrence, '월·수·금');
        expect(plan.visibility, PlanVisibility.publicChallenge);
        expect(plan.progress, PlanProgress.pending);
        expect(plan.scheduledAt.toUtc(), DateTime.utc(2026, 8, 25, 10));
        expect(plan.startProof?.type, PlanProofType.start);
        expect(plan.startProof?.mediaUrl, 'https://cdn.example/proof.jpg');
        expect(plan.startProof?.sharedToFeed, isTrue);
      },
    );

    test('preserves the server failure mentor message', () async {
      final repository = _repository(
        MockClient((_) async {
          return _jsonResponse([
            _occurrenceJson(status: 'FAILED', failureMessage: '서버가 만든 실패 메시지'),
          ]);
        }),
      );

      final plan = (await repository.fetchPlans(
        from: DateTime.utc(2026, 8, 25),
        to: DateTime.utc(2026, 8, 26),
      )).single;

      expect(plan.progress, PlanProgress.failed);
      expect(plan.failureMessage, '서버가 만든 실패 메시지');
      expect(plan.copyWith(title: '제목 변경').failureMessage, plan.failureMessage);
      expect(plan.copyWith(clearFailureMessage: true).failureMessage, isNull);
    });

    test(
      'records text-only completion proof when a photo is not required',
      () async {
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return _jsonResponse([_occurrenceJson()]);
          }
          return _jsonResponse(
            _occurrenceJson(
              status: 'COMPLETED',
              completionProof: {
                'id': 32,
                'proofType': 'COMPLETION',
                'mediaUrl': null,
                'mediaName': null,
                'note': '완료했습니다',
                'sharedToFeed': false,
                'recordedAt': '2026-08-25T19:45:00+09:00',
              },
            ),
          );
        });
        final repository = _repository(client);
        await repository.fetchPlans(
          from: DateTime.utc(2026, 8, 25),
          to: DateTime.utc(2026, 8, 26),
        );

        final plan = await repository.recordCompletionProof(
          '22',
          const PlanProofDraft(
            type: PlanProofType.completion,
            note: '  완료했습니다  ',
            sharedToFeed: false,
          ),
        );

        expect(requests.last.method, 'POST');
        expect(requests.last.url.path, '/api/v1/plans/22/proofs/completion');
        expect(jsonDecode(requests.last.body), {
          'note': '완료했습니다',
          'shareToFeed': false,
        });
        expect(plan.progress, PlanProgress.completed);
        expect(plan.completionProof?.note, '완료했습니다');
      },
    );

    test('blocks Flutter image bytes until media upload exists', () async {
      var requestCount = 0;
      final repository = _repository(
        MockClient((_) async {
          requestCount += 1;
          return _jsonResponse(_occurrenceJson());
        }),
      );

      await expectLater(
        repository.recordStartProof(
          '22',
          PlanProofDraft(
            type: PlanProofType.start,
            mediaBytes: Uint8List.fromList([1, 2, 3]),
            mediaName: 'proof.jpg',
            note: '',
            sharedToFeed: false,
          ),
        ),
        throwsA(
          isA<PlanRepositoryException>().having(
            (error) => error.userMessage,
            'userMessage',
            contains('사진을 서버에 올리는 기능'),
          ),
        ),
      );
      expect(requestCount, 0);
    });

    test(
      'blocks shared completion because it requires an uploaded photo',
      () async {
        var requestCount = 0;
        final repository = _repository(
          MockClient((_) async {
            requestCount += 1;
            return _jsonResponse(_occurrenceJson());
          }),
        );

        await expectLater(
          repository.recordCompletionProof(
            '22',
            const PlanProofDraft(
              type: PlanProofType.completion,
              note: '완료',
              sharedToFeed: true,
            ),
          ),
          throwsA(
            isA<PlanRepositoryException>().having(
              (error) => error.userMessage,
              'userMessage',
              contains('피드 공유에는 업로드된 사진'),
            ),
          ),
        );
        expect(requestCount, 0);
      },
    );

    test('blocks a photo-required plan before sending completion', () async {
      var requestCount = 0;
      final repository = _repository(
        MockClient((_) async {
          requestCount += 1;
          return _jsonResponse([_occurrenceJson(photoProofRequired: true)]);
        }),
      );
      await repository.fetchPlans(
        from: DateTime.utc(2026, 8, 25),
        to: DateTime.utc(2026, 8, 26),
      );

      await expectLater(
        repository.recordCompletionProof(
          '22',
          const PlanProofDraft(
            type: PlanProofType.completion,
            note: '완료',
            sharedToFeed: false,
          ),
        ),
        throwsA(
          isA<PlanRepositoryException>().having(
            (error) => error.userMessage,
            'userMessage',
            contains('사진 인증이 필수'),
          ),
        ),
      );
      expect(requestCount, 1);
    });

    test('unknown response enum is an invalid-response ApiException', () async {
      final repository = _repository(
        MockClient((_) async {
          return _jsonResponse([_occurrenceJson(category: 'UNKNOWN')]);
        }),
      );

      await expectLater(
        repository.fetchPlans(
          from: DateTime.utc(2026, 8, 25),
          to: DateTime.utc(2026, 8, 26),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.invalidResponse,
          ),
        ),
      );
    });

    test(
      'advertises unsupported server update and delete operations',
      () async {
        final repository = _repository(
          MockClient((_) async => _jsonResponse(_occurrenceJson())),
        );
        final draft = PlanDraft(
          title: '수정',
          scheduledAt: DateTime.utc(2026, 8, 25, 10),
          verificationDueAt: DateTime.utc(2026, 8, 25, 11),
          category: PlanCategory.study,
          recurrence: '없음',
          experiencePoint: 5,
          visibility: PlanVisibility.private,
          photoProofRequired: false,
        );

        expect(repository.supportsUpdate, isFalse);
        expect(repository.supportsDelete, isFalse);
        await expectLater(
          repository.updatePlan('22', draft),
          throwsA(isA<PlanRepositoryException>()),
        );
        await expectLater(
          repository.deletePlan('22'),
          throwsA(isA<PlanRepositoryException>()),
        );
      },
    );
  });
}

RemotePlanRepository _repository(http.Client client) {
  return RemotePlanRepository(
    apiClient: PlanApiClient(
      client: client,
      baseUrl: 'http://127.0.0.1:8080',
      accessTokenReader: () async => 'jwt-token',
    ),
    timezone: 'Asia/Seoul',
  );
}

Map<String, Object?> _occurrenceJson({
  bool photoProofRequired = false,
  String status = 'PENDING',
  String category = 'HEALTH',
  String? failureMessage,
  Map<String, Object?>? startProof,
  Map<String, Object?>? completionProof,
}) {
  return {
    'planId': 11,
    'occurrenceId': 22,
    'title': '저녁 운동',
    'scheduledAt': '2026-08-25T19:00:00+09:00',
    'verificationDueAt': '2026-08-25T20:30:00+09:00',
    'category': category,
    'recurrence': 'MON_WED_FRI',
    'visibility': 'PUBLIC_CHALLENGE',
    'photoProofRequired': photoProofRequired,
    'experiencePoint': 10,
    'timezone': 'Asia/Seoul',
    'status': status,
    'completedAt': status == 'COMPLETED' ? '2026-08-25T19:45:00+09:00' : null,
    'failureMessage': failureMessage,
    'startProof': startProof,
    'completionProof': completionProof,
  };
}

http.Response _jsonResponse(Object? body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
