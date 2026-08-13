import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:organization_app_starter/features/auth/data/auth_db.dart';
import 'package:organization_app_starter/features/auth/utils/auth_validation.dart';
import 'package:organization_app_starter/features/auth/widgets/auth_button.dart';
import 'package:organization_app_starter/features/auth/widgets/auth_card.dart';
import 'package:organization_app_starter/features/auth/widgets/auth_input.dart';
import 'package:organization_app_starter/features/auth/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginScreen({super.key, required this.onSwitchToRegister});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text;
    final password = _passwordCtrl.text;
    final form = ref.read(loginFormProvider.notifier);

    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    form
      ..setEmailError(emailError)
      ..setPasswordError(passwordError);

    if (emailError != null || passwordError != null) return;

    form.setLoading(true);
    try {
      await ref.read(authStateProvider.notifier).login(email, password);
    } catch (e) {
      if (!mounted) return;
      if (e is InvalidCredentialsError) {
        form.setPasswordError(e.message);
      } else {
        form.setPasswordError('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) form.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);
    return AuthCard(
      icon: Icons.login_rounded,
      title: 'Welcome back',
      subtitle: 'Log in to access your profile',
      children: [
        AuthInput(
          label: 'Email',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          errorText: formState.emailError,
          focusNode: _emailFocus,
          textInputAction: TextInputAction.next,
          maxLength: maxEmailLength,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
        ),
        AuthInput(
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outlined,
          controller: _passwordCtrl,
          obscureText: true,
          errorText: formState.passwordError,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          maxLength: maxPasswordLength,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        AuthButton(
          label: 'Log In',
          onPressed: _submit,
          loading: formState.loading,
        ),
        AuthButton(
          label: "Don't have an account? Register",
          onPressed: widget.onSwitchToRegister,
          variant: AuthButtonVariant.ghost,
        ),
      ],
    );
  }
}
