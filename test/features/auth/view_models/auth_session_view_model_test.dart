import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/core/network/api_exception.dart';
import 'package:pathetic_people/features/auth/domain/auth_repository.dart';
import 'package:pathetic_people/features/auth/domain/auth_user.dart';
import 'package:pathetic_people/features/auth/view_models/auth_session_view_model.dart';

void main() {
  const user = AuthUser(
    id: 7,
    email: 'minsu@example.com',
    nickname: '민수',
    profileImage: null,
    role: 'USER',
  );

  group('AuthSessionViewModel', () {
    test('starts in checking state', () {
      final viewModel = AuthSessionViewModel(FakeAuthRepository());

      expect(viewModel.status, AuthStatus.checking);
      expect(viewModel.user, isNull);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('restoreSession authenticates a saved user', () async {
      final repository = FakeAuthRepository()..restoreResult = user;
      final viewModel = AuthSessionViewModel(repository);

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user, user);
      expect(viewModel.errorMessage, isNull);
    });

    test(
      'restoreSession becomes unauthenticated without a saved user',
      () async {
        final viewModel = AuthSessionViewModel(FakeAuthRepository());

        await viewModel.restoreSession();

        expect(viewModel.status, AuthStatus.unauthenticated);
        expect(viewModel.user, isNull);
      },
    );

    test(
      'login exposes submitting state and authenticates on success',
      () async {
        final repository = FakeAuthRepository()..loginResult = user;
        final viewModel = AuthSessionViewModel(repository);
        final submittingStates = <bool>[];
        viewModel.addListener(() {
          submittingStates.add(viewModel.isSubmitting);
        });

        final success = await viewModel.login(
          email: 'minsu@example.com',
          password: 'password123',
        );

        expect(success, isTrue);
        expect(viewModel.status, AuthStatus.authenticated);
        expect(viewModel.user, user);
        expect(viewModel.isSubmitting, isFalse);
        expect(submittingStates, containsAllInOrder([true, false]));
      },
    );

    test('login maps an API error and returns false', () async {
      final repository = FakeAuthRepository()
        ..loginError = const ApiException(
          type: ApiExceptionType.unauthorized,
          userMessage: '이메일 또는 비밀번호가 올바르지 않습니다.',
          statusCode: 401,
        );
      final viewModel = AuthSessionViewModel(repository);

      final success = await viewModel.login(
        email: 'minsu@example.com',
        password: 'wrong-password',
      );

      expect(success, isFalse);
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, isNull);
      expect(viewModel.errorMessage, '이메일 또는 비밀번호가 올바르지 않습니다.');
    });

    test('signUp creates the account and then logs in automatically', () async {
      final repository = FakeAuthRepository()..loginResult = user;
      final viewModel = AuthSessionViewModel(repository);

      final success = await viewModel.signUp(
        nickname: '민수',
        email: 'minsu@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(repository.calls, ['signUp', 'login']);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user, user);
    });

    test(
      'signUp keeps the created account and asks for login when auto-login fails',
      () async {
        final repository = FakeAuthRepository()
          ..loginError = ApiException.network();
        final viewModel = AuthSessionViewModel(repository);

        final success = await viewModel.signUp(
          nickname: '민수',
          email: 'minsu@example.com',
          password: 'password123',
        );

        expect(success, isFalse);
        expect(repository.calls, ['signUp', 'login']);
        expect(viewModel.status, AuthStatus.unauthenticated);
        expect(viewModel.user, isNull);
        expect(viewModel.accountCreatedButLoginRequired, isTrue);
        expect(
          viewModel.errorMessage,
          '계정은 생성되었습니다. 자동 로그인에 실패했습니다. 다시 로그인해 주세요.',
        );
      },
    );

    test('signUp does not attempt login when account creation fails', () async {
      final repository = FakeAuthRepository()
        ..signUpError = const ApiException(
          type: ApiExceptionType.request,
          userMessage: '이미 사용 중인 이메일입니다.',
          statusCode: 409,
        );
      final viewModel = AuthSessionViewModel(repository);

      final success = await viewModel.signUp(
        nickname: '민수',
        email: 'minsu@example.com',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(repository.calls, ['signUp']);
      expect(viewModel.errorMessage, '이미 사용 중인 이메일입니다.');
    });

    test('clearError removes the current error', () async {
      final repository = FakeAuthRepository()
        ..loginError = StateError('storage failed');
      final viewModel = AuthSessionViewModel(repository);
      await viewModel.login(email: 'a@b.com', password: 'password123');
      expect(viewModel.errorMessage, isNotNull);

      viewModel.clearError();

      expect(viewModel.errorMessage, isNull);
    });

    test('logout clears the in-memory authenticated user', () async {
      final repository = FakeAuthRepository()..loginResult = user;
      final viewModel = AuthSessionViewModel(repository);
      await viewModel.login(
        email: 'minsu@example.com',
        password: 'password123',
      );

      await viewModel.logout();

      expect(repository.calls, ['login', 'logout']);
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, isNull);
    });

    test('slow restore completion after dispose is ignored safely', () async {
      final repository = FakeAuthRepository()..holdRestore();
      final viewModel = AuthSessionViewModel(repository);
      var notificationCount = 0;
      viewModel.addListener(() {
        notificationCount += 1;
      });

      final restore = viewModel.restoreSession();
      expect(notificationCount, 1);
      viewModel.dispose();
      repository.completeRestore(user);

      await expectLater(restore, completes);
      expect(notificationCount, 1);
      expect(repository.disposeCount, 1);
    });
  });
}

class FakeAuthRepository implements AuthRepository, DisposableAuthRepository {
  AuthUser? restoreResult;
  AuthUser? loginResult;
  Object? restoreError;
  Object? signUpError;
  Object? loginError;
  Object? logoutError;
  Completer<AuthUser?>? _restoreCompleter;
  int disposeCount = 0;
  final List<String> calls = [];

  @override
  Future<AuthUser?> restoreSession() async {
    calls.add('restoreSession');
    final restoreCompleter = _restoreCompleter;
    if (restoreCompleter != null) {
      return restoreCompleter.future;
    }
    if (restoreError case final error?) {
      throw error;
    }
    return restoreResult;
  }

  @override
  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    calls.add('signUp');
    if (signUpError case final error?) {
      throw error;
    }
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    calls.add('login');
    if (loginError case final error?) {
      throw error;
    }
    return loginResult!;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    if (logoutError case final error?) {
      throw error;
    }
  }

  void holdRestore() {
    _restoreCompleter = Completer<AuthUser?>();
  }

  void completeRestore(AuthUser? user) {
    _restoreCompleter?.complete(user);
  }

  @override
  void dispose() {
    disposeCount += 1;
  }
}
