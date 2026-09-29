import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_error_response.dart';
import '../../../core/network/api_exception.dart';
import 'plan_api_dto.dart';

typedef AccessTokenReader = Future<String?> Function();
typedef UnauthorizedCallback = void Function();

class PlanApiClient {
  PlanApiClient({
    required AccessTokenReader accessTokenReader,
    http.Client? client,
    http.Client Function()? clientFactory,
    String? baseUrl,
    this.onUnauthorized,
    this.requestTimeout = const Duration(seconds: 10),
  }) : assert(client == null || clientFactory == null),
       _readAccessToken = accessTokenReader,
       _client = client ?? (clientFactory?.call() ?? http.Client()),
       _ownsClient = client == null,
       _baseUrl = AppEnvironment.normalizeApiBaseUrl(
         baseUrl ?? AppEnvironment.apiBaseUrl,
       );

  final AccessTokenReader _readAccessToken;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  final UnauthorizedCallback? onUnauthorized;
  final Duration requestTimeout;
  bool _isClosed = false;

  Future<List<PlanOccurrenceDto>> fetchPlans({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!to.isAfter(from)) {
      throw ArgumentError.value(to, 'to', '조회 종료 시각은 시작 시각보다 뒤여야 합니다.');
    }
    if (to.toUtc().difference(from.toUtc()) > const Duration(days: 93)) {
      throw ArgumentError.value(to, 'to', '계획은 한 번에 최대 93일까지 조회할 수 있습니다.');
    }

    final uri = _uri('/api/v1/plans').replace(
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    final response = await _get(uri);
    _throwIfRequestFailed(response);

    try {
      final json = _decodeJsonList(response);
      return json.map(PlanOccurrenceDto.fromJson).toList(growable: false);
    } on FormatException {
      throw ApiException.invalidResponse();
    }
  }

  Future<PlanOccurrenceDto> fetchPlan(String occurrenceId) async {
    final response = await _get(
      _uri('/api/v1/plans/${Uri.encodeComponent(occurrenceId)}'),
    );
    _throwIfRequestFailed(response);
    return _decodeOccurrence(response);
  }

  Future<PlanOccurrenceDto> createPlan(PlanCreateRequestDto request) async {
    final response = await _postJson(
      _uri('/api/v1/plans'),
      body: request.toJson(),
    );
    _throwIfRequestFailed(response);
    return _decodeOccurrence(response);
  }

  Future<PlanOccurrenceDto> recordStartProof(
    String occurrenceId,
    ProofCreateRequestDto request,
  ) {
    return _recordProof(occurrenceId, 'start', request);
  }

  Future<PlanOccurrenceDto> recordCompletionProof(
    String occurrenceId,
    ProofCreateRequestDto request,
  ) {
    return _recordProof(occurrenceId, 'completion', request);
  }

  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<PlanOccurrenceDto> _recordProof(
    String occurrenceId,
    String proofPath,
    ProofCreateRequestDto request,
  ) async {
    final uri = _uri(
      '/api/v1/plans/${Uri.encodeComponent(occurrenceId)}/proofs/$proofPath',
    );
    final response = request.mediaBytes == null
        ? await _postJson(uri, body: request.toJson())
        : await _postMultipart(uri, request);
    _throwIfRequestFailed(response);
    return _decodeOccurrence(response);
  }

  Future<http.Response> _postMultipart(
    Uri uri,
    ProofCreateRequestDto request,
  ) async {
    final multipart = http.MultipartRequest('POST', uri);
    multipart.headers.addAll(await _authorizedHeaders());
    if (request.note != null) {
      multipart.fields['note'] = request.note!;
    }
    multipart.fields['shareToFeed'] = request.shareToFeed.toString();
    multipart.files.add(
      http.MultipartFile.fromBytes(
        'media',
        request.mediaBytes!,
        filename: request.mediaName ?? 'proof-image',
      ),
    );

    try {
      final streamed = await _client.send(multipart).timeout(requestTimeout);
      return await http.Response.fromStream(streamed).timeout(requestTimeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      throw ApiException.network();
    }
  }

  Future<http.Response> _get(Uri uri) async {
    final headers = await _authorizedHeaders();
    return _runRequest(_client.get(uri, headers: headers));
  }

  Future<http.Response> _postJson(
    Uri uri, {
    required Map<String, Object?> body,
  }) async {
    final headers = await _authorizedHeaders(includeJsonContentType: true);
    return _runRequest(
      _client.post(uri, headers: headers, body: jsonEncode(body)),
    );
  }

  Future<Map<String, String>> _authorizedHeaders({
    bool includeJsonContentType = false,
  }) async {
    final accessToken = (await _readAccessToken())?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.unauthorized,
        userMessage: '로그인 정보가 없습니다. 다시 로그인해 주세요.',
        statusCode: 401,
      );
    }
    return {
      'Authorization': 'Bearer $accessToken',
      if (includeJsonContentType)
        'Content-Type': 'application/json; charset=UTF-8',
    };
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

  PlanOccurrenceDto _decodeOccurrence(http.Response response) {
    try {
      return PlanOccurrenceDto.fromJson(_decodeJsonObject(response));
    } on FormatException {
      throw ApiException.invalidResponse();
    }
  }

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

  List<Map<String, dynamic>> _decodeJsonList(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('Expected a JSON list.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Expected a JSON object in the list.');
          }
          return item;
        })
        .toList(growable: false);
  }

  void _throwIfRequestFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 401) {
      try {
        onUnauthorized?.call();
      } catch (_) {
        // Keep the API failure authoritative even if session cleanup fails.
      }
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
      userMessage: _fallbackMessageForStatus(response.statusCode),
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

  String _fallbackMessageForStatus(int statusCode) {
    if (statusCode == 400) {
      return '계획 내용을 다시 확인해 주세요.';
    }
    if (statusCode == 401) {
      return '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (statusCode == 403) {
      return '이 계획을 변경할 권한이 없습니다.';
    }
    if (statusCode == 404) {
      return '계획을 찾을 수 없습니다. 목록을 새로고침해 주세요.';
    }
    if (statusCode == 409) {
      return '이미 처리된 계획입니다. 목록을 새로고침해 주세요.';
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
