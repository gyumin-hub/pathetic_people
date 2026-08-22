import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../view_models/auth_session_view_model.dart';

enum _AuthMode { login, signUp }

class AuthPage extends StatefulWidget {
  const AuthPage({required this.viewModel, super.key});

  final AuthSessionViewModel viewModel;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.viewModel,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 60
                          ? constraints.maxHeight - 60
                          : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _BrandHeader(),
                                const SizedBox(height: 34),
                                _ModeSelector(
                                  mode: _mode,
                                  isEnabled: !widget.viewModel.isSubmitting,
                                  onChanged: _changeMode,
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  _isSignUp
                                      ? '나만의 동기를 만들어 볼까요?'
                                      : '다시 만나서 반가워요',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isSignUp
                                      ? '계정을 만들고 오늘의 계획을 시작해 보세요.'
                                      : '계속하려면 계정으로 로그인해 주세요.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppPalette.muted),
                                ),
                                const SizedBox(height: 24),
                                if (_isSignUp) ...[
                                  _AuthTextField(
                                    key: const ValueKey('nicknameField'),
                                    controller: _nicknameController,
                                    label: '닉네임',
                                    hintText: '앱에서 사용할 이름',
                                    prefixIcon: Icons.person_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newUsername,
                                    ],
                                    enabled: !widget.viewModel.isSubmitting,
                                    maxLength: 20,
                                    validator: _validateNickname,
                                    onChanged: (_) => _clearServerError(),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _AuthTextField(
                                  key: const ValueKey('emailField'),
                                  controller: _emailController,
                                  label: '이메일',
                                  hintText: 'name@example.com',
                                  prefixIcon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: [
                                    _isSignUp
                                        ? AutofillHints.newUsername
                                        : AutofillHints.username,
                                  ],
                                  enabled: !widget.viewModel.isSubmitting,
                                  validator: _validateEmail,
                                  onChanged: (_) => _clearServerError(),
                                ),
                                const SizedBox(height: 14),
                                _AuthTextField(
                                  key: const ValueKey('passwordField'),
                                  controller: _passwordController,
                                  label: '비밀번호',
                                  hintText: '8자 이상 입력',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: [
                                    _isSignUp
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  enabled: !widget.viewModel.isSubmitting,
                                  validator: _validatePassword,
                                  onChanged: (_) => _clearServerError(),
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? '비밀번호 표시'
                                        : '비밀번호 숨기기',
                                    onPressed: widget.viewModel.isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 21,
                                    ),
                                  ),
                                ),
                                _ServerErrorMessage(
                                  message: widget.viewModel.errorMessage,
                                ),
                                const SizedBox(height: 24),
                                Semantics(
                                  button: true,
                                  label: _isSignUp ? '회원가입 제출' : '로그인 제출',
                                  child: FilledButton(
                                    key: const ValueKey('authSubmitButton'),
                                    onPressed: widget.viewModel.isSubmitting
                                        ? null
                                        : _submit,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(54),
                                      backgroundColor: AppPalette.blue,
                                      disabledBackgroundColor: AppPalette.blue
                                          .withValues(alpha: 0.45),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _SubmitButtonContent(
                                      isSubmitting:
                                          widget.viewModel.isSubmitting,
                                      label: _isSignUp ? '회원가입' : '로그인',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _ModeHint(
                                  mode: _mode,
                                  isEnabled: !widget.viewModel.isSubmitting,
                                  onChanged: _changeMode,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _changeMode(_AuthMode mode) {
    if (_mode == mode || widget.viewModel.isSubmitting) return;
    widget.viewModel.clearError();
    setState(() {
      _mode = mode;
      _formKey = GlobalKey<FormState>();
      _obscurePassword = true;
    });
  }

  void _clearServerError() {
    if (widget.viewModel.errorMessage != null) {
      widget.viewModel.clearError();
    }
  }

  Future<void> _submit() async {
    if (widget.viewModel.isSubmitting) return;
    FocusScope.of(context).unfocus();
    widget.viewModel.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isSignUp) {
      final authenticated = await widget.viewModel.signUp(
        nickname: _nicknameController.text.trim(),
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (!authenticated && widget.viewModel.accountCreatedButLoginRequired) {
        setState(() {
          _mode = _AuthMode.login;
          _formKey = GlobalKey<FormState>();
          _obscurePassword = true;
        });
      }
      return;
    }
    await widget.viewModel.login(email: email, password: password);
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
    if (nickname.length < 2) return '닉네임은 2자 이상 입력해 주세요.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해 주세요.';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      return '올바른 이메일 형식으로 입력해 주세요.';
    }
    if (email.length > 100) {
      return '이메일은 100자 이하로 입력해 주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해 주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상 입력해 주세요.';
    return null;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'motive, 계획을 행동으로 바꾸는 공간',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppPalette.ink,
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'motive',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 32,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '계획을 행동으로 바꾸는 공간',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.isEnabled,
    required this.onChanged,
  });

  final _AuthMode mode;
  final bool isEnabled;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '인증 방식 선택',
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppPalette.surfaceStrong,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _ModeButton(
              buttonKey: const ValueKey('authLoginTab'),
              label: '로그인',
              isSelected: mode == _AuthMode.login,
              onPressed: isEnabled ? () => onChanged(_AuthMode.login) : null,
            ),
            _ModeButton(
              buttonKey: const ValueKey('authSignUpTab'),
              label: '회원가입',
              isSelected: mode == _AuthMode.signUp,
              onPressed: isEnabled ? () => onChanged(_AuthMode.signUp) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.buttonKey,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextButton(
            key: buttonKey,
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: isSelected ? AppPalette.ink : AppPalette.muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.textInputAction,
    required this.autofillHints,
    required this.enabled,
    required this.validator,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.suffixIcon,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final bool enabled;
  final bool obscureText;
  final int? maxLength;
  final Widget? suffixIcon;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        obscureText: obscureText,
        maxLength: maxLength,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        autocorrect: false,
        enableSuggestions: !obscureText,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          counterText: '',
          prefixIcon: Icon(prefixIcon, size: 21),
          suffixIcon: suffixIcon,
          errorMaxLines: 2,
          filled: true,
          fillColor: AppPalette.surface,
        ),
      ),
    );
  }
}

class _ServerErrorMessage extends StatelessWidget {
  const _ServerErrorMessage({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final errorMessage = message?.trim();
    if (errorMessage == null || errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      label: '로그인 오류: $errorMessage',
      child: Container(
        key: const ValueKey('authServerError'),
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppPalette.redSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 19,
              color: AppPalette.red,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: AppPalette.red,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButtonContent extends StatelessWidget {
  const _SubmitButtonContent({required this.isSubmitting, required this.label});

  final bool isSubmitting;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isSubmitting) return Text(label);
    return Semantics(
      liveRegion: true,
      label: '$label 처리 중',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text('$label 중...'),
          ],
        ),
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  const _ModeHint({
    required this.mode,
    required this.isEnabled,
    required this.onChanged,
  });

  final _AuthMode mode;
  final bool isEnabled;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSignUp = mode == _AuthMode.signUp;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isSignUp ? '이미 계정이 있나요?' : '아직 계정이 없나요?',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
        ),
        TextButton(
          onPressed: isEnabled
              ? () => onChanged(isSignUp ? _AuthMode.login : _AuthMode.signUp)
              : null,
          child: Text(isSignUp ? '로그인' : '회원가입'),
        ),
      ],
    );
  }
}
