import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/app/motive_app.dart';
import 'package:pathetic_people/data/repositories/mock_app_repository.dart';
import 'package:pathetic_people/features/auth/domain/auth_repository.dart';
import 'package:pathetic_people/features/auth/domain/auth_user.dart';

void main() {
  testWidgets('5개 탭을 전환할 수 있다', (tester) async {
    await tester.pumpWidget(
      MotiveApp(authRepository: _FakeAuthRepository.authenticated()),
    );
    await tester.pumpAndSettle();

    expect(find.text('motive'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('탐색'), findsWidgets);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('PLANNER'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('메시지'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('pathetic_me'), findsOneWidget);
  });

  testWidgets('360px 화면에서도 주요 탭에 레이아웃 오류가 없다', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MotiveApp(authRepository: _FakeAuthRepository.authenticated()),
    );
    await tester.pumpAndSettle();

    for (final icon in [
      Icons.search_rounded,
      Icons.calendar_today_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.person_outline_rounded,
    ]) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('저장된 로그인 정보가 없으면 로그인 화면을 보여준다', (tester) async {
    await tester.pumpWidget(
      MotiveApp(authRepository: _FakeAuthRepository.unauthenticated()),
    );
    await tester.pumpAndSettle();

    expect(find.text('다시 만나서 반가워요'), findsOneWidget);
    expect(find.byKey(const ValueKey('authSubmitButton')), findsOneWidget);
  });

  testWidgets('A 로그아웃 후 B 로그인 시 콘텐츠 상태를 새로 만든다', (tester) async {
    final authRepository = _FakeAuthRepository.switchingAccounts();
    final repositories = <int, _TrackingMockAppRepository>{};

    await tester.pumpWidget(
      MotiveApp(
        authRepository: authRepository,
        contentRepositoryFactory: (userId) {
          final repository = _TrackingMockAppRepository();
          repositories[userId] = repository;
          return repository;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(repositories.keys, [1]);
    final firstRepository = repositories[1]!;
    firstRepository.updateCurrentUser(
      displayName: 'A만의 이름',
      username: 'only_account_a',
      bio: 'A만의 소개',
    );
    firstRepository.updatePreferences(pushEnabled: false);

    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('로그아웃'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();

    expect(firstRepository.disposeCount, 1);
    expect(find.text('다시 만나서 반가워요'), findsOneWidget);

    await tester.enterText(
      _editableText('emailField'),
      'account-b@example.com',
    );
    await tester.enterText(_editableText('passwordField'), 'password123');
    await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(repositories.keys, [1, 2]);
    final secondRepository = repositories[2]!;
    expect(secondRepository, isNot(same(firstRepository)));
    expect(secondRepository.currentUser.displayName, '사용자 B');
    expect(secondRepository.currentUser.username, 'pathetic_me');
    expect(secondRepository.preferences.pushEnabled, isTrue);
    expect(secondRepository.disposeCount, 0);

    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('사용자 B'), findsOneWidget);
    expect(find.text('only_account_a'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(secondRepository.disposeCount, 1);
  });
}

Finder _editableText(String fieldKey) {
  return find.descendant(
    of: find.byKey(ValueKey(fieldKey)),
    matching: find.byType(EditableText),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository.authenticated()
    : _restoredUser = _user,
      _loginUser = _user;

  _FakeAuthRepository.unauthenticated()
    : _restoredUser = null,
      _loginUser = _user;

  _FakeAuthRepository.switchingAccounts()
    : _restoredUser = _user,
      _loginUser = _secondUser;

  static const _user = AuthUser(
    id: 1,
    email: 'tester@example.com',
    nickname: '테스터',
    profileImage: null,
    role: 'USER',
  );

  static const _secondUser = AuthUser(
    id: 2,
    email: 'account-b@example.com',
    nickname: '사용자 B',
    profileImage: null,
    role: 'USER',
  );

  final AuthUser? _restoredUser;
  final AuthUser _loginUser;

  @override
  Future<AuthUser?> restoreSession() async => _restoredUser;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async => _loginUser;

  @override
  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

class _TrackingMockAppRepository extends MockAppRepository {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount += 1;
    super.dispose();
  }
}
