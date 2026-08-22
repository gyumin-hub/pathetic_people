import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathetic_people/core/network/api_exception.dart';
import 'package:pathetic_people/core/network/auth_api_client.dart';
import 'package:pathetic_people/features/auth/data/auth_repository_impl.dart';
import 'package:pathetic_people/features/auth/data/auth_token_store.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test('login stores the token and returns /me user data', () async {
      final requestedPaths = <String>[];
      final client = MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path == '/api/auth/login') {
          return _jsonResponse({'accessToken': 'new-token'});
        }
        expect(request.headers['authorization'], 'Bearer new-token');
        return _meResponse();
      });
      final tokenStore = MemoryAuthTokenStore();
      final repository = _repository(client: client, tokenStore: tokenStore);

      final user = await repository.login(
        email: 'minsu@example.com',
        password: 'password123',
      );

      expect(requestedPaths, ['/api/auth/login', '/api/auth/me']);
      expect(tokenStore.accessToken, 'new-token');
      expect(user.nickname, '민수');
    });

    test(
      'unauthorized /me after login removes the newly stored token',
      () async {
        final client = MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return _jsonResponse({'accessToken': 'new-token'});
          }
          return http.Response('', 401);
        });
        final tokenStore = MemoryAuthTokenStore();
        final repository = _repository(client: client, tokenStore: tokenStore);

        await expectLater(
          repository.login(email: 'minsu@example.com', password: 'password123'),
          throwsA(isA<ApiException>()),
        );
        expect(tokenStore.accessToken, isNull);
        expect(tokenStore.deleteCount, 1);
      },
    );

    test('temporary /me server error after login keeps the token', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return _jsonResponse({'accessToken': 'new-token'});
        }
        return http.Response('', 500);
      });
      final tokenStore = MemoryAuthTokenStore();
      final repository = _repository(client: client, tokenStore: tokenStore);

      await expectLater(
        repository.login(email: 'minsu@example.com', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.server,
          ),
        ),
      );
      expect(tokenStore.accessToken, 'new-token');
      expect(tokenStore.deleteCount, 0);
    });

    test('temporary /me network error after login keeps the token', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return _jsonResponse({'accessToken': 'new-token'});
        }
        throw http.ClientException('Connection lost', request.url);
      });
      final tokenStore = MemoryAuthTokenStore();
      final repository = _repository(client: client, tokenStore: tokenStore);

      await expectLater(
        repository.login(email: 'minsu@example.com', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.network,
          ),
        ),
      );
      expect(tokenStore.accessToken, 'new-token');
      expect(tokenStore.deleteCount, 0);
    });

    test('invalid /me response after login keeps the token', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return _jsonResponse({'accessToken': 'new-token'});
        }
        return http.Response('broken-json', 200);
      });
      final tokenStore = MemoryAuthTokenStore();
      final repository = _repository(client: client, tokenStore: tokenStore);

      await expectLater(
        repository.login(email: 'minsu@example.com', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiExceptionType.invalidResponse,
          ),
        ),
      );
      expect(tokenStore.accessToken, 'new-token');
      expect(tokenStore.deleteCount, 0);
    });

    test('restoreSession does not call the server without a token', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount += 1;
        return _meResponse();
      });
      final tokenStore = MemoryAuthTokenStore();
      final repository = _repository(client: client, tokenStore: tokenStore);

      final user = await repository.restoreSession();

      expect(user, isNull);
      expect(requestCount, 0);
    });

    test('restoreSession returns the user for a valid saved token', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer saved-token');
        return _meResponse();
      });
      final tokenStore = MemoryAuthTokenStore('saved-token');
      final repository = _repository(client: client, tokenStore: tokenStore);

      final user = await repository.restoreSession();

      expect(user?.email, 'minsu@example.com');
      expect(tokenStore.accessToken, 'saved-token');
    });

    test('restoreSession removes an unauthorized token', () async {
      final client = MockClient((_) async {
        return _jsonResponse({
          'timestamp': '2026-08-23T00:00:00Z',
          'status': 401,
          'code': 'USER_NOT_FOUND',
          'message': '로그인 정보를 다시 확인해 주세요.',
          'path': '/api/auth/me',
          'fieldErrors': <String, String>{},
        }, statusCode: 401);
      });
      final tokenStore = MemoryAuthTokenStore('expired-token');
      final repository = _repository(client: client, tokenStore: tokenStore);

      final user = await repository.restoreSession();

      expect(user, isNull);
      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.deleteCount, 1);
    });

    test(
      'restoreSession keeps the token for a temporary server error',
      () async {
        final client = MockClient((_) async => http.Response('', 500));
        final tokenStore = MemoryAuthTokenStore('saved-token');
        final repository = _repository(client: client, tokenStore: tokenStore);

        await expectLater(
          repository.restoreSession(),
          throwsA(isA<ApiException>()),
        );
        expect(tokenStore.accessToken, 'saved-token');
        expect(tokenStore.deleteCount, 0);
      },
    );

    test('logout removes the saved token', () async {
      final client = MockClient((_) async => _meResponse());
      final tokenStore = MemoryAuthTokenStore('saved-token');
      final repository = _repository(client: client, tokenStore: tokenStore);

      await repository.logout();

      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.deleteCount, 1);
    });

    test('dispose closes the API client owned by the repository', () {
      final client = TrackingMockClient();
      final repository = AuthRepositoryImpl(
        apiClient: AuthApiClient(
          clientFactory: () => client,
          baseUrl: 'http://127.0.0.1:8080',
        ),
        tokenStore: MemoryAuthTokenStore(),
      );

      repository.dispose();
      repository.dispose();

      expect(client.closeCount, 1);
    });
  });
}

AuthRepositoryImpl _repository({
  required http.Client client,
  required MemoryAuthTokenStore tokenStore,
}) {
  return AuthRepositoryImpl(
    apiClient: AuthApiClient(client: client, baseUrl: 'http://127.0.0.1:8080'),
    tokenStore: tokenStore,
  );
}

http.Response _meResponse() => _jsonResponse({
  'id': 7,
  'email': 'minsu@example.com',
  'nickname': '민수',
  'profileImage': null,
  'role': 'USER',
});

http.Response _jsonResponse(Map<String, Object?> body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

class MemoryAuthTokenStore implements AuthTokenStore {
  MemoryAuthTokenStore([this.accessToken]);

  String? accessToken;
  int deleteCount = 0;

  @override
  Future<void> deleteAccessToken() async {
    deleteCount += 1;
    accessToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> writeAccessToken(String accessToken) async {
    this.accessToken = accessToken;
  }
}

class TrackingMockClient extends MockClient {
  TrackingMockClient() : super((_) async => http.Response('{}', 200));

  int closeCount = 0;

  @override
  void close() {
    closeCount += 1;
  }
}
