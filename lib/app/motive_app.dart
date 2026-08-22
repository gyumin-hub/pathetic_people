import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/auth_api_client.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/mock_app_repository.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/data/secure_auth_token_store.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/auth_splash_page.dart';
import '../features/auth/view_models/auth_session_view_model.dart';
import 'app_content_session.dart';
import 'motive_shell.dart';

class MotiveApp extends StatefulWidget {
  const MotiveApp({
    this.authRepository,
    this.contentRepositoryFactory,
    super.key,
  });

  final AuthRepository? authRepository;
  final ContentRepositoryFactory? contentRepositoryFactory;

  @override
  State<MotiveApp> createState() => _MotiveAppState();
}

class _MotiveAppState extends State<MotiveApp> {
  late final AuthSessionViewModel _authViewModel;
  AppContentSession? _contentSession;

  @override
  void initState() {
    super.initState();
    final authRepository =
        widget.authRepository ??
        AuthRepositoryImpl(
          apiClient: AuthApiClient(),
          tokenStore: SecureAuthTokenStore(),
        );
    _authViewModel = AuthSessionViewModel(authRepository)
      ..addListener(_handleAuthSessionChanged);
    unawaited(_authViewModel.restoreSession());
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_handleAuthSessionChanged);
    _disposeContentSession();
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'motive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: _authViewModel,
        builder: (context, _) {
          return switch (_authViewModel.status) {
            AuthStatus.checking => const AuthSplashPage(),
            AuthStatus.unauthenticated => AuthPage(viewModel: _authViewModel),
            AuthStatus.authenticated => _buildAuthenticatedContent(),
          };
        },
      ),
    );
  }

  Widget _buildAuthenticatedContent() {
    final authUser = _authViewModel.user;
    final contentSession = _contentSession;
    if (authUser == null ||
        contentSession == null ||
        contentSession.userId != authUser.id) {
      return const AuthSplashPage();
    }

    return MotiveShell(
      key: ValueKey<int>(contentSession.userId),
      feedViewModel: contentSession.feedViewModel,
      exploreViewModel: contentSession.exploreViewModel,
      plannerViewModel: contentSession.plannerViewModel,
      chatViewModel: contentSession.chatViewModel,
      profileViewModel: contentSession.profileViewModel,
      onLogout: _authViewModel.logout,
    );
  }

  void _handleAuthSessionChanged() {
    final authUser = _authViewModel.user;
    if (_authViewModel.status != AuthStatus.authenticated || authUser == null) {
      _disposeContentSession();
      return;
    }

    if (_contentSession?.userId != authUser.id) {
      _disposeContentSession();
      final repository =
          widget.contentRepositoryFactory?.call(authUser.id) ??
          MockAppRepository();
      _contentSession = AppContentSession(
        userId: authUser.id,
        repository: repository,
      );
    }
    _contentSession?.syncAuthenticatedUser(authUser);
  }

  void _disposeContentSession() {
    final contentSession = _contentSession;
    _contentSession = null;
    contentSession?.dispose();
  }
}
