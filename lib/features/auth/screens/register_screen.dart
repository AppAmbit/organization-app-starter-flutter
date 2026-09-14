import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:organization_app_starter/features/auth/data/auth_db.dart';
import 'package:organization_app_starter/features/auth/providers/auth_providers.dart';
import 'package:organization_app_starter/features/auth/utils/auth_validation.dart';
import 'package:organization_app_starter/features/auth/widgets/auth_button.dart';
import 'package:organization_app_starter/features/auth/widgets/auth_card.dart';
import 'package:organization_app_starter/features/auth/widgets/auth_input.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterScreen({super.key, required this.onSwitchToLogin});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text;
    final email = _emailCtrl.text;
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    final form = ref.read(registerFormProvider.notifier);

    final nameError = validateName(name);
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    final confirmError = validateConfirmPassword(password, confirm);
    form
      ..setNameError(nameError)
      ..setEmailError(emailError)
      ..setPasswordError(passwordError)
      ..setConfirmError(confirmError);

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null) {
      return;
    }

    form.setLoading(true);
    try {
      await ref.read(authStateProvider.notifier).register(name, email, password);
    } catch (e) {
      if (!mounted) return;
      if (e is EmailAlreadyExistsError) {
        form.setEmailError(e.message);
      } else {
        form.setPasswordError('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) form.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registerFormProvider);
    return AuthCard(
      icon: Icons.person_add_rounded,
      title: 'Create account',
      subtitle: 'Sign up to set up your profile',
      children: [
        AuthInput(
          label: 'Name',
          hint: 'Your name',
          icon: Icons.person_outlined,
          controller: _nameCtrl,
          errorText: formState.nameError,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.next,
          maxLength: maxNameLength,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
        ),
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
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_passwordFocus),
        ),
        AuthInput(
          label: 'Password',
          hint: 'At least 6 characters',
          icon: Icons.lock_outlined,
          controller: _passwordCtrl,
          obscureText: true,
          errorText: formState.passwordError,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.next,
          maxLength: maxPasswordLength,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_confirmFocus),
        ),
        AuthInput(
          label: 'Confirm password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outlined,
          controller: _confirmCtrl,
          obscureText: true,
          errorText: formState.confirmError,
          focusNode: _confirmFocus,
          textInputAction: TextInputAction.done,
          maxLength: maxPasswordLength,
          onSubmitted: (_) => _submit(),
        ),
        AuthButton(
          label: 'Register',
          onPressed: _submit,
          loading: formState.loading,
        ),
        AuthButton(
          label: 'Already have an account? Log in',
          onPressed: widget.onSwitchToLogin,
          variant: AuthButtonVariant.ghost,
        ),
      ],
    );
  }
}
