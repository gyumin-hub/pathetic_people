import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_token_store.dart';

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: AuthStorageKeys.accessToken);
  }

  @override
  Future<void> writeAccessToken(String accessToken) {
    return _storage.write(key: AuthStorageKeys.accessToken, value: accessToken);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: AuthStorageKeys.accessToken);
  }
}
