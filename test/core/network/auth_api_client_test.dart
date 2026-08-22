import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathetic_people/core/network/api_exception.dart';
import 'package:pathetic_people/core/network/auth_api_client.dart';

void main() {
  group('AuthApiClient', () {
    test('signUp sends the server contract and trims text fields', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response('ok', 200);
      });
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080/',
      );

      await apiClient.signUp(
        nickname: '  민수  ',
        email: '  minsu@example.com ',
        password: 'password123',
      );

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'http://127.0.0.1:8080/api/auth/signup',
      );
      expect(
        capturedRequest.headers['content-type'],
        contains('application/json'),
      );
      expect(jsonDecode(capturedRequest.body), {
        'nickname': '민수',
        'email': 'minsu@example.com',
        'password': 'password123',
      });
    });

    test('login returns the access token', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        return _jsonResponse({
          'accessToken': 'jwt-token',
          'tokenType': 'Bearer',
          'userId': 7,
          'nickname': '민수',
        });
      });
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080',
      );

      final token = await apiClient.login(
        email: 'minsu@example.com',
        password: 'password123',
      );

      expect(token, 'jwt-token');
    });

    test(
      'me sends the bearer token and parses the authenticated user',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/auth/me');
          expect(request.headers['authorization'], 'Bearer jwt-token');
          return _jsonResponse({
            'id': 7,
            'email': 'minsu@example.com',
            'nickname': '민수',
            'profileImage': null,
            'role': 'USER',
          });
        });
        final apiClient = AuthApiClient(
          client: client,
          baseUrl: 'http://127.0.0.1:8080',
        );

        final user = await apiClient.me(accessToken: 'jwt-token');

        expect(user.id, 7);
        expect(user.email, 'minsu@example.com');
        expect(user.nickname, '민수');
        expect(user.profileImage, isNull);
        expect(user.role, 'USER');
      },
    );

    test('server field error becomes a Korean user message', () async {
      final client = MockClient((_) async {
        return _jsonResponse({
          'timestamp': '2026-08-23T00:00:00Z',
          'status': 400,
          'code': 'VALIDATION_FAILED',
          'message': '입력값을 다시 확인해 주세요.',
          'path': '/api/auth/signup',
          'fieldErrors': {'password': '비밀번호는 8자 이상이어야 합니다.'},
        }, statusCode: 400);
      });
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080',
      );

      await expectLater(
        apiClient.signUp(
          nickname: '민수',
          email: 'minsu@example.com',
          password: 'short',
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having((error) => error.code, 'code', 'VALIDATION_FAILED')
              .having(
                (error) => error.userMessage,
                'userMessage',
                '비밀번호는 8자 이상이어야 합니다.',
              ),
        ),
      );
    });

    test(
      '401 without an API error body gets a login-specific message',
      () async {
        final client = MockClient((_) async => http.Response('', 401));
        final apiClient = AuthApiClient(
          client: client,
          baseUrl: 'http://127.0.0.1:8080',
        );

        await expectLater(
          apiClient.login(
            email: 'minsu@example.com',
            password: 'wrong-password',
          ),
          throwsA(
            isA<ApiException>()
                .having(
                  (error) => error.isUnauthorized,
                  'isUnauthorized',
                  isTrue,
                )
                .having(
                  (error) => error.userMessage,
                  'userMessage',
                  '이메일 또는 비밀번호를 다시 확인해 주세요.',
                ),
          ),
        );
      },
    );

    test('invalid success JSON is mapped to a readable error', () async {
      final client = MockClient((_) async => http.Response('not-json', 200));
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080',
      );

      await expectLater(
        apiClient.login(email: 'a@b.com', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.invalidResponse,
          ),
        ),
      );
    });

    test('request timeout is mapped to a readable error', () async {
      final completer = Completer<http.Response>();
      final client = MockClient((_) => completer.future);
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080',
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        apiClient.login(email: 'a@b.com', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.timeout,
          ),
        ),
      );
    });

    test('client connection failure is mapped to a readable error', () async {
      final client = MockClient((request) {
        throw http.ClientException('Connection refused', request.url);
      });
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080',
      );

      await expectLater(
        apiClient.login(email: 'a@b.com', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.network,
          ),
        ),
      );
    });

    test('close closes a client created by the client factory once', () {
      final client = TrackingMockClient();
      final apiClient = AuthApiClient(
        clientFactory: () => client,
        baseUrl: 'http://127.0.0.1:8080',
      );

      apiClient.close();
      apiClient.close();

      expect(client.closeCount, 1);
    });

    test('close does not close an injected client', () {
      final client = TrackingMockClient();
      final apiClient = AuthApiClient(
        client: client,
        baseUrl: 'http://127.0.0.1:8080',
      );

      apiClient.close();

      expect(client.closeCount, 0);
    });
  });
}

http.Response _jsonResponse(Map<String, Object?> body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

class TrackingMockClient extends MockClient {
  TrackingMockClient() : super((_) async => http.Response('{}', 200));

  int closeCount = 0;

  @override
  void close() {
    closeCount += 1;
  }
}
