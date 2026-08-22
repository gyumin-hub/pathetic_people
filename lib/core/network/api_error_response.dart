class ApiErrorResponse {
  const ApiErrorResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.fieldErrors,
    this.timestamp,
    this.path,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final code = json['code'];
    final message = json['message'];

    if (status is! int || code is! String || message is! String) {
      throw const FormatException('Invalid API error response.');
    }

    final rawFieldErrors = json['fieldErrors'];
    final fieldErrors = <String, String>{};
    if (rawFieldErrors != null) {
      if (rawFieldErrors is! Map) {
        throw const FormatException('Invalid API field errors.');
      }
      for (final entry in rawFieldErrors.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const FormatException('Invalid API field error.');
        }
        fieldErrors[entry.key as String] = entry.value as String;
      }
    }

    return ApiErrorResponse(
      timestamp: json['timestamp'] is String
          ? json['timestamp'] as String
          : null,
      status: status,
      code: code,
      message: message,
      path: json['path'] is String ? json['path'] as String : null,
      fieldErrors: fieldErrors,
    );
  }

  final String? timestamp;
  final int status;
  final String code;
  final String message;
  final String? path;
  final Map<String, String> fieldErrors;

  String get userMessage {
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.values.first;
    }

    final trimmedMessage = message.trim();
    return trimmedMessage.isEmpty
        ? '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.'
        : trimmedMessage;
  }
}
