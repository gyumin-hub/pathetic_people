abstract final class AuthStorageKeys {
  static const String accessToken = 'auth_access_token';
}

abstract interface class AuthTokenStore {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String accessToken);

  Future<void> deleteAccessToken();
}
