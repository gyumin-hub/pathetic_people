import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/domain/auth_user.dart';
import '../config/app_environment.dart';
import 'api_error_response.dart';
import 'api_exception.dart';

class AuthApiClient {
  AuthApiClient({
    http.Client? client,
    http.Client Function()? clientFactory,
    String? baseUrl,
    this.requestTimeout = const Duration(seconds: 10),
  }) : assert(client == null || clientFactory == null),
       _client = client ?? (clientFactory?.call() ?? http.Client()),
       _ownsClient = client == null,
       _baseUrl = AppEnvironment.normalizeApiBaseUrl(
         baseUrl ?? AppEnvironment.apiBaseUrl,
       );

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  final Duration requestTimeout;
  bool _isClosed = false;

  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      '/api/auth/signup',
      body: {
        'nickname': nickname.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    _throwIfRequestFailed(response);
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    _throwIfRequestFailed(
      response,
      unauthorizedMessage: '이메일 또는 비밀번호를 다시 확인해 주세요.',
    );

    final json = _decodeJsonObject(response);
    final accessToken = json['accessToken'];
    if (accessToken is! String || accessToken.trim().isEmpty) {
      throw ApiException.invalidResponse();
    }
    return accessToken;
  }

  Future<AuthUser> me({required String accessToken}) async {
    final response = await _get(
      '/api/auth/me',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _throwIfRequestFailed(
      response,
      unauthorizedMessage: '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.',
    );

    try {
      return AuthUser.fromJson(_decodeJsonObject(response));
    } on FormatException {
      throw ApiException.invalidResponse();
    }
  }

  Future<http.Response> _postJson(
    String path, {
    required Map<String, String> body,
  }) {
    return _runRequest(
      _client.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _get(
    String path, {
    required Map<String, String> headers,
  }) {
    return _runRequest(_client.get(_uri(path), headers: headers));
  }

  Future<http.Response> _runRequest(Future<http.Response> request) async {
    try {
      return await request.timeout(requestTimeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      throw ApiException.network();
    }
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return decoded;
    } on FormatException {
      throw ApiException.invalidResponse();
    }
  }

  void _throwIfRequestFailed(
    http.Response response, {
    String? unauthorizedMessage,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final serverError = _tryReadServerError(response);
    if (serverError != null) {
      throw ApiException(
        type: _typeForStatus(response.statusCode),
        userMessage: serverError.userMessage,
        statusCode: response.statusCode,
        code: serverError.code,
      );
    }

    throw ApiException(
      type: _typeForStatus(response.statusCode),
      userMessage: _fallbackMessageForStatus(
        response.statusCode,
        unauthorizedMessage: unauthorizedMessage,
      ),
      statusCode: response.statusCode,
    );
  }

  ApiErrorResponse? _tryReadServerError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ApiErrorResponse.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  ApiExceptionType _typeForStatus(int statusCode) {
    if (statusCode == 401) {
      return ApiExceptionType.unauthorized;
    }
    if (statusCode >= 500) {
      return ApiExceptionType.server;
    }
    return ApiExceptionType.request;
  }

  String _fallbackMessageForStatus(
    int statusCode, {
    String? unauthorizedMessage,
  }) {
    if (statusCode == 400) {
      return '입력한 내용을 다시 확인해 주세요.';
    }
    if (statusCode == 401) {
      return unauthorizedMessage ?? '로그인 정보를 다시 확인해 주세요.';
    }
    if (statusCode == 403) {
      return '이 요청을 실행할 권한이 없습니다.';
    }
    if (statusCode == 404) {
      return '요청한 기능을 서버에서 찾지 못했습니다.';
    }
    if (statusCode == 409) {
      return '이미 사용 중인 정보입니다.';
    }
    if (statusCode == 429) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (statusCode >= 500) {
      return '서버에서 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
    return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }
}
