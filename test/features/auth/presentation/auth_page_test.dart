import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/core/theme/app_theme.dart';
import 'package:pathetic_people/features/auth/presentation/auth_page.dart';
import 'package:pathetic_people/features/auth/presentation/auth_splash_page.dart';
import 'package:pathetic_people/features/auth/view_models/auth_session_view_model.dart';

void main() {
  group('AuthPage', () {
    testWidgets('빈 로그인 폼을 제출하면 입력값 오류를 보여준다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pump();

      expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
      expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
      expect(viewModel.loginCalls, 0);
    });

    testWidgets('이메일 형식과 8자 비밀번호 규칙을 검증한다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.enterText(_editableText('emailField'), 'wrong-email');
      await tester.enterText(_editableText('passwordField'), '1234567');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pump();

      expect(find.text('올바른 이메일 형식으로 입력해 주세요.'), findsOneWidget);
      expect(find.text('비밀번호는 8자 이상 입력해 주세요.'), findsOneWidget);
      expect(viewModel.loginCalls, 0);
    });

    testWidgets('100자를 넘는 이메일을 거절한다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);
      final overlongEmail = '${List.filled(89, 'a').join()}@example.com';
      expect(overlongEmail.length, 101);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.enterText(_editableText('emailField'), overlongEmail);
      await tester.enterText(_editableText('passwordField'), 'password123');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pump();

      expect(find.text('이메일은 100자 이하로 입력해 주세요.'), findsOneWidget);
      expect(viewModel.loginCalls, 0);
    });

    testWidgets('올바른 이메일과 비밀번호를 ViewModel에 전달한다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.enterText(
        _editableText('emailField'),
        '  user@example.com  ',
      );
      await tester.enterText(_editableText('passwordField'), 'password123');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pumpAndSettle();

      expect(viewModel.loginCalls, 1);
      expect(viewModel.loginEmail, 'user@example.com');
      expect(viewModel.loginPassword, 'password123');
    });

    testWidgets('회원가입에서는 닉네임을 검증하고 세 입력값을 전달한다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.tap(find.byKey(const ValueKey('authSignUpTab')));
      await tester.pump();

      expect(_editableText('nicknameField'), findsOneWidget);
      await tester.enterText(_editableText('nicknameField'), 'a');
      await tester.enterText(_editableText('emailField'), 'new@example.com');
      await tester.enterText(_editableText('passwordField'), 'password123');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pump();

      expect(find.text('닉네임은 2자 이상 입력해 주세요.'), findsOneWidget);
      expect(viewModel.signUpCalls, 0);

      await tester.enterText(_editableText('nicknameField'), '  민수  ');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pumpAndSettle();

      expect(viewModel.signUpCalls, 1);
      expect(viewModel.signUpNickname, '민수');
      expect(viewModel.signUpEmail, 'new@example.com');
      expect(viewModel.signUpPassword, 'password123');
    });

    testWidgets('계정 생성 후 자동 로그인이 실패하면 로그인으로 전환한다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel()
        ..failAutoLoginAfterAccountCreation();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.tap(find.byKey(const ValueKey('authSignUpTab')));
      await tester.pump();
      await tester.enterText(_editableText('nicknameField'), '민수');
      await tester.enterText(_editableText('emailField'), 'new@example.com');
      await tester.enterText(_editableText('passwordField'), 'password123');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pumpAndSettle();

      expect(viewModel.signUpCalls, 1);
      expect(_editableText('nicknameField'), findsNothing);
      expect(find.text('다시 만나서 반가워요'), findsOneWidget);
      expect(
        find.text('계정은 생성되었습니다. 자동 로그인에 실패했습니다. 다시 로그인해 주세요.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pumpAndSettle();
      expect(viewModel.signUpCalls, 1);
      expect(viewModel.loginCalls, 1);
    });

    testWidgets('비밀번호 표시 버튼으로 숨김 상태를 바꿀 수 있다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));

      EditableText passwordField = tester.widget(
        _editableText('passwordField'),
      );
      expect(passwordField.obscureText, isTrue);

      await tester.tap(find.byTooltip('비밀번호 표시'));
      await tester.pump();

      passwordField = tester.widget(_editableText('passwordField'));
      expect(passwordField.obscureText, isFalse);
      expect(find.byTooltip('비밀번호 숨기기'), findsOneWidget);
    });

    testWidgets('요청 중에는 로딩을 표시하고 중복 제출을 막는다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel()..holdNextLogin();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.enterText(_editableText('emailField'), 'user@example.com');
      await tester.enterText(_editableText('passwordField'), 'password123');
      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pump();

      expect(viewModel.loginCalls, 1);
      expect(find.text('로그인 중...'), findsOneWidget);
      final submitButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('authSubmitButton')),
      );
      expect(submitButton.onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
      await tester.pump();
      expect(viewModel.loginCalls, 1);

      viewModel.completeLogin();
      await tester.pumpAndSettle();
      expect(find.text('로그인'), findsWidgets);
    });

    testWidgets('서버 오류를 알림 영역에 표시하고 입력하면 지운다', (tester) async {
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      viewModel.showError('이메일 또는 비밀번호가 올바르지 않아요.');
      await tester.pump();

      expect(find.text('이메일 또는 비밀번호가 올바르지 않아요.'), findsOneWidget);
      expect(find.byKey(const ValueKey('authServerError')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('로그인 오류: 이메일 또는 비밀번호가 올바르지 않아요.')),
        findsOneWidget,
      );

      await tester.enterText(_editableText('emailField'), 'u');
      await tester.pump();
      expect(find.byKey(const ValueKey('authServerError')), findsNothing);
      semantics.dispose();
    });

    testWidgets('360px 화면에서 키보드가 열려도 레이아웃 오류가 없다', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final viewModel = _FakeAuthSessionViewModel();
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_testApp(AuthPage(viewModel: viewModel)));
      await tester.tap(find.byKey(const ValueKey('authSignUpTab')));
      await tester.pump();
      await tester.showKeyboard(_editableText('passwordField'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  testWidgets('AuthSplashPage는 로그인 확인 진행 상태를 알린다', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_testApp(const AuthSplashPage()));

    expect(find.text('motive'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('motive, 로그인 상태 확인 중'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(theme: AppTheme.light, home: home);
}

Finder _editableText(String fieldKey) {
  return find.descendant(
    of: find.byKey(ValueKey(fieldKey)),
    matching: find.byType(EditableText),
  );
}

class _FakeAuthSessionViewModel extends ChangeNotifier
    implements AuthSessionViewModel {
  bool _isSubmitting = false;
  bool _accountCreatedButLoginRequired = false;
  bool _failAutoLoginAfterAccountCreation = false;
  String? _errorMessage;
  Completer<bool>? _loginCompleter;

  int loginCalls = 0;
  int signUpCalls = 0;
  String? loginEmail;
  String? loginPassword;
  String? signUpNickname;
  String? signUpEmail;
  String? signUpPassword;

  @override
  bool get isSubmitting => _isSubmitting;

  @override
  bool get accountCreatedButLoginRequired => _accountCreatedButLoginRequired;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> login({required String email, required String password}) async {
    _accountCreatedButLoginRequired = false;
    loginCalls++;
    loginEmail = email;
    loginPassword = password;
    final completer = _loginCompleter;
    if (completer == null) return true;

    _isSubmitting = true;
    notifyListeners();
    final result = await completer.future;
    _isSubmitting = false;
    _loginCompleter = null;
    notifyListeners();
    return result;
  }

  @override
  Future<bool> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    signUpNickname = nickname;
    signUpEmail = email;
    signUpPassword = password;
    if (_failAutoLoginAfterAccountCreation) {
      _accountCreatedButLoginRequired = true;
      _errorMessage = '계정은 생성되었습니다. 자동 로그인에 실패했습니다. 다시 로그인해 주세요.';
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void holdNextLogin() {
    _loginCompleter = Completer<bool>();
  }

  void completeLogin() {
    _loginCompleter?.complete(true);
  }

  void failAutoLoginAfterAccountCreation() {
    _failAutoLoginAfterAccountCreation = true;
  }

  void showError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
