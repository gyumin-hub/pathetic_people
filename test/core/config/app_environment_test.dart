import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('Android emulator uses the host loopback bridge by default', () {
      expect(
        AppEnvironment.resolveApiBaseUrl(dartDefineValue: '', isAndroid: true),
        'http://10.0.2.2:8080',
      );
    });

    test('non-Android platforms use local loopback by default', () {
      expect(
        AppEnvironment.resolveApiBaseUrl(dartDefineValue: '', isAndroid: false),
        'http://127.0.0.1:8080',
      );
    });

    test('dart-define value wins and trailing slashes are removed', () {
      expect(
        AppEnvironment.resolveApiBaseUrl(
          dartDefineValue: '  http://192.168.0.7:8080/// ',
          isAndroid: true,
        ),
        'http://192.168.0.7:8080',
      );
    });

    test('blank dart-define value falls back to the platform default', () {
      expect(
        AppEnvironment.resolveApiBaseUrl(
          dartDefineValue: '   ',
          isAndroid: false,
        ),
        'http://127.0.0.1:8080',
      );
    });
  });
}
