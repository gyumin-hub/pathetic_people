import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_token_store.dart';

class AuthRepositoryImpl implements AuthRepository, DisposableAuthRepository {
  const AuthRepositoryImpl({required this.apiClient, required this.tokenStore});

  final AuthApiClient apiClient;
  final AuthTokenStore tokenStore;

  @override
  Future<AuthUser?> restoreSession() async {
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      if (accessToken != null) {
        await tokenStore.deleteAccessToken();
      }
      return null;
    }

    try {
      return await apiClient.me(accessToken: accessToken);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await tokenStore.deleteAccessToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) {
    return apiClient.signUp(
      nickname: nickname,
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final accessToken = await apiClient.login(email: email, password: password);
    await tokenStore.writeAccessToken(accessToken);

    try {
      return await apiClient.me(accessToken: accessToken);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _deleteTokenWithoutMaskingOriginalError();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() {
    return tokenStore.deleteAccessToken();
  }

  @override
  void dispose() {
    apiClient.close();
  }

  Future<void> _deleteTokenWithoutMaskingOriginalError() async {
    try {
      await tokenStore.deleteAccessToken();
    } catch (_) {
      // The request error is more useful than a secondary cleanup error.
    }
  }
}
