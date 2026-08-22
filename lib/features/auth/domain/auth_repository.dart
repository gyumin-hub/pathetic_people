import 'auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();

  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  });

  Future<AuthUser> login({required String email, required String password});

  Future<void> logout();
}

abstract interface class DisposableAuthRepository {
  void dispose();
}
