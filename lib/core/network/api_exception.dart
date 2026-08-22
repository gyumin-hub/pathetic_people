enum ApiExceptionType {
  network,
  timeout,
  invalidResponse,
  unauthorized,
  server,
  request,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.userMessage,
    this.statusCode,
    this.code,
  });

  factory ApiException.network() => const ApiException(
    type: ApiExceptionType.network,
    userMessage: '서버에 연결할 수 없습니다. 서버가 실행 중인지와 주소를 확인해 주세요.',
  );

  factory ApiException.timeout() => const ApiException(
    type: ApiExceptionType.timeout,
    userMessage: '서버 응답이 늦어지고 있습니다. 잠시 후 다시 시도해 주세요.',
  );

  factory ApiException.invalidResponse() => const ApiException(
    type: ApiExceptionType.invalidResponse,
    userMessage: '서버 응답 형식을 이해하지 못했습니다. 앱과 서버 버전을 확인해 주세요.',
  );

  final ApiExceptionType type;
  final String userMessage;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized =>
      type == ApiExceptionType.unauthorized || statusCode == 401;

  @override
  String toString() => 'ApiException($type, $statusCode, $code)';
}
