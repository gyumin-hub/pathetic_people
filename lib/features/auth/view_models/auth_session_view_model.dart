import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthSessionViewModel extends ChangeNotifier {
  AuthSessionViewModel(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.checking;
  AuthUser? _user;
  bool _isSubmitting = false;
  bool _accountCreatedButLoginRequired = false;
  bool _isDisposed = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isSubmitting => _isSubmitting;
  bool get accountCreatedButLoginRequired => _accountCreatedButLoginRequired;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    if (_isDisposed) {
      return;
    }
    _status = AuthStatus.checking;
    _accountCreatedButLoginRequired = false;
    _errorMessage = null;
    _notifyListeners();

    try {
      final restoredUser = await _repository.restoreSession();
      if (_isDisposed) {
        return;
      }
      _user = restoredUser;
      _status = restoredUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = _messageFor(
        error,
        fallback: '로그인 상태를 확인하지 못했습니다. 다시 시도해 주세요.',
      );
    }

    _notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (_isDisposed || _isSubmitting) {
      return false;
    }

    _accountCreatedButLoginRequired = false;
    _beginSubmitting();
    try {
      final authenticatedUser = await _repository.login(
        email: email,
        password: password,
      );
      if (_isDisposed) {
        return false;
      }
      _user = authenticatedUser;
      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      if (_isDisposed) {
        return false;
      }
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = _messageFor(
        error,
        fallback: '로그인 처리 중 문제가 발생했습니다. 다시 시도해 주세요.',
      );
      return false;
    } finally {
      _endSubmitting();
    }
  }

  Future<bool> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    if (_isDisposed || _isSubmitting) {
      return false;
    }

    _accountCreatedButLoginRequired = false;
    _beginSubmitting();
    var accountCreated = false;
    try {
      await _repository.signUp(
        nickname: nickname,
        email: email,
        password: password,
      );
      accountCreated = true;
      if (_isDisposed) {
        return false;
      }

      final authenticatedUser = await _repository.login(
        email: email,
        password: password,
      );
      if (_isDisposed) {
        return false;
      }
      _user = authenticatedUser;
      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      if (_isDisposed) {
        return false;
      }
      _user = null;
      _status = AuthStatus.unauthenticated;
      if (accountCreated) {
        _accountCreatedButLoginRequired = true;
        _errorMessage = '계정은 생성되었습니다. 자동 로그인에 실패했습니다. 다시 로그인해 주세요.';
      } else {
        _errorMessage = _messageFor(
          error,
          fallback: '회원가입 처리 중 문제가 발생했습니다. 다시 시도해 주세요.',
        );
      }
      return false;
    } finally {
      _endSubmitting();
    }
  }

  Future<void> logout() async {
    if (_isDisposed) {
      return;
    }
    _accountCreatedButLoginRequired = false;
    _errorMessage = null;
    try {
      await _repository.logout();
    } catch (error) {
      if (!_isDisposed) {
        _errorMessage = _messageFor(
          error,
          fallback: '기기의 로그인 정보를 삭제하지 못했습니다. 앱을 다시 실행하면 로그인이 복원될 수 있습니다.',
        );
      }
    } finally {
      if (!_isDisposed) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        _notifyListeners();
      }
    }
  }

  void clearError() {
    if (_isDisposed || _errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _notifyListeners();
  }

  void _beginSubmitting() {
    _isSubmitting = true;
    _errorMessage = null;
    _notifyListeners();
  }

  void _endSubmitting() {
    _isSubmitting = false;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String _messageFor(Object error, {required String fallback}) {
    return error is ApiException ? error.userMessage : fallback;
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    if (_repository case final DisposableAuthRepository disposableRepository) {
      disposableRepository.dispose();
    }
    super.dispose();
  }
}
