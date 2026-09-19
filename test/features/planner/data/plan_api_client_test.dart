import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathetic_people/core/network/api_exception.dart';
import 'package:pathetic_people/domain/models/plan_item.dart';
import 'package:pathetic_people/features/planner/data/plan_api_client.dart';
import 'package:pathetic_people/features/planner/data/plan_api_dto.dart';

void main() {
  group('PlanApiClient', () {
    test(
      'fetchPlans sends bearer auth and an offset-aware UTC range',
      () async {
        late http.Request capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return _jsonResponse([_occurrenceJson()]);
        });
        final apiClient = _client(client);

        final plans = await apiClient.fetchPlans(
          from: DateTime.parse('2026-08-25T09:00:00+09:00'),
          to: DateTime.parse('2026-08-26T09:00:00+09:00'),
        );

        expect(capturedRequest.method, 'GET');
        expect(capturedRequest.url.path, '/api/v1/plans');
        expect(capturedRequest.headers['authorization'], 'Bearer jwt-token');
        expect(capturedRequest.url.queryParameters['from'], endsWith('Z'));
        expect(capturedRequest.url.queryParameters['to'], endsWith('Z'));
        expect(
          DateTime.parse(capturedRequest.url.queryParameters['from']!),
          DateTime.parse('2026-08-25T00:00:00Z'),
        );
        expect(plans.single.occurrenceId, 22);
      },
    );

    test('createPlan sends the exact server enum and time contract', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return _jsonResponse(_occurrenceJson());
      });
      final apiClient = _client(client);
      final request = PlanCreateRequestDto.fromDomain(
        PlanDraft(
          title: '  저녁 운동  ',
          scheduledAt: DateTime.parse('2026-08-25T19:00:00+09:00'),
          verificationDueAt: DateTime.parse('2026-08-25T20:30:00+09:00'),
          category: PlanCategory.health,
          recurrence: '월·수·금',
          experiencePoint: 10,
          visibility: PlanVisibility.publicChallenge,
          photoProofRequired: true,
        ),
        timezone: 'Asia/Seoul',
      );

      await apiClient.createPlan(request);

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/v1/plans');
      expect(capturedRequest.headers['authorization'], 'Bearer jwt-token');
      expect(
        capturedRequest.headers['content-type'],
        contains('application/json'),
      );
      expect(jsonDecode(capturedRequest.body), {
        'title': '저녁 운동',
        'scheduledAt': '2026-08-25T10:00:00.000Z',
        'verificationDueAt': '2026-08-25T11:30:00.000Z',
        'category': 'HEALTH',
        'recurrence': 'MON_WED_FRI',
        'visibility': 'PUBLIC_CHALLENGE',
        'photoProofRequired': true,
        'experiencePoint': 10,
        'timezone': 'Asia/Seoul',
      });
    });

    test('server field errors become a readable ApiException', () async {
      final client = MockClient((_) async {
        return _jsonResponse({
          'timestamp': '2026-08-25T00:00:00Z',
          'status': 400,
          'code': 'VALIDATION_FAILED',
          'message': '입력값을 다시 확인해 주세요.',
          'path': '/api/v1/plans',
          'fieldErrors': {'title': '계획 제목을 입력해 주세요.'},
        }, statusCode: 400);
      });
      final apiClient = _client(client);

      await expectLater(
        apiClient.fetchPlans(
          from: DateTime.utc(2026, 8, 25),
          to: DateTime.utc(2026, 8, 26),
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having((error) => error.code, 'code', 'VALIDATION_FAILED')
              .having(
                (error) => error.userMessage,
                'userMessage',
                '계획 제목을 입력해 주세요.',
              ),
        ),
      );
    });

    test('401 without JSON uses the login fallback message', () async {
      var unauthorizedCallbacks = 0;
      final apiClient = PlanApiClient(
        client: MockClient((_) async => http.Response('', 401)),
        baseUrl: 'http://127.0.0.1:8080',
        accessTokenReader: () async => 'jwt-token',
        onUnauthorized: () => unauthorizedCallbacks += 1,
      );

      await expectLater(
        apiClient.fetchPlans(
          from: DateTime.utc(2026, 8, 25),
          to: DateTime.utc(2026, 8, 26),
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.isUnauthorized, 'isUnauthorized', isTrue)
              .having(
                (error) => error.userMessage,
                'userMessage',
                '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.',
              ),
        ),
      );
      expect(unauthorizedCallbacks, 1);
    });

    test('a missing stored token prevents an HTTP request', () async {
      var requestCount = 0;
      final apiClient = PlanApiClient(
        client: MockClient((_) async {
          requestCount += 1;
          return _jsonResponse(<Object?>[]);
        }),
        baseUrl: 'http://127.0.0.1:8080',
        accessTokenReader: () async => null,
      );

      await expectLater(
        apiClient.fetchPlans(
          from: DateTime.utc(2026, 8, 25),
          to: DateTime.utc(2026, 8, 26),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.isUnauthorized,
            'isUnauthorized',
            isTrue,
          ),
        ),
      );
      expect(requestCount, 0);
    });

    test('close only owns clients created by its factory', () {
      final ownedClient = TrackingMockClient();
      final ownedApiClient = PlanApiClient(
        clientFactory: () => ownedClient,
        baseUrl: 'http://127.0.0.1:8080',
        accessTokenReader: () async => 'jwt-token',
      );
      final injectedClient = TrackingMockClient();
      final injectedApiClient = PlanApiClient(
        client: injectedClient,
        baseUrl: 'http://127.0.0.1:8080',
        accessTokenReader: () async => 'jwt-token',
      );

      ownedApiClient.close();
      ownedApiClient.close();
      injectedApiClient.close();

      expect(ownedClient.closeCount, 1);
      expect(injectedClient.closeCount, 0);
    });
  });
}

PlanApiClient _client(http.Client client) {
  return PlanApiClient(
    client: client,
    baseUrl: 'http://127.0.0.1:8080/',
    accessTokenReader: () async => 'jwt-token',
  );
}

Map<String, Object?> _occurrenceJson({
  bool photoProofRequired = false,
  String status = 'PENDING',
  Map<String, Object?>? startProof,
  Map<String, Object?>? completionProof,
}) {
  return {
    'planId': 11,
    'occurrenceId': 22,
    'title': '저녁 운동',
    'scheduledAt': '2026-08-25T19:00:00+09:00',
    'verificationDueAt': '2026-08-25T20:30:00+09:00',
    'category': 'HEALTH',
    'recurrence': 'MON_WED_FRI',
    'visibility': 'PUBLIC_CHALLENGE',
    'photoProofRequired': photoProofRequired,
    'experiencePoint': 10,
    'timezone': 'Asia/Seoul',
    'status': status,
    'completedAt': status == 'COMPLETED' ? '2026-08-25T19:45:00+09:00' : null,
    'failureMessage': null,
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

class TrackingMockClient extends MockClient {
  TrackingMockClient() : super((_) async => _jsonResponse(<Object?>[]));

  int closeCount = 0;

  @override
  void close() {
    closeCount += 1;
  }
}
