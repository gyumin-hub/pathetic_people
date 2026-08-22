import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const String _definedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl => resolveApiBaseUrl(
    dartDefineValue: _definedApiBaseUrl,
    isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  );

  @visibleForTesting
  static String resolveApiBaseUrl({
    required String dartDefineValue,
    required bool isAndroid,
  }) {
    final override = dartDefineValue.trim();
    final defaultUrl = isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://127.0.0.1:8080';

    return normalizeApiBaseUrl(override.isEmpty ? defaultUrl : override);
  }

  static String normalizeApiBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
