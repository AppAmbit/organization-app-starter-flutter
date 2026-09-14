import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:organization_app_starter/features/auth/data/auth_repository.dart';
import 'package:organization_app_starter/features/auth/models/user_model.dart';

enum AuthSessionEvent { remotelyInvalidated }

// --- Login Form ---

class LoginFormState {
  final String? emailError;
  final String? passwordError;
  final bool loading;

  const LoginFormState({this.emailError, this.passwordError, this.loading = false});

  LoginFormState copyWith({
    String? emailError,
    String? passwordError,
    bool? loading,
  }) {
    return LoginFormState(
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      loading: loading ?? this.loading,
    );
  }
}

class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  void setEmailError(String? error) => state = state.copyWith(emailError: error);
  void setPasswordError(String? error) => state = state.copyWith(passwordError: error);
  void setLoading(bool value) => state = state.copyWith(loading: value);
  void reset() => state = const LoginFormState();
}

final loginFormProvider =
    NotifierProvider<LoginFormNotifier, LoginFormState>(LoginFormNotifier.new);

// --- Register Form ---

class RegisterFormState {
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmError;
  final bool loading;

  const RegisterFormState({
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmError,
    this.loading = false,
  });

  RegisterFormState copyWith({
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmError,
    bool? loading,
  }) {
    return RegisterFormState(
      nameError: nameError ?? this.nameError,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      confirmError: confirmError ?? this.confirmError,
      loading: loading ?? this.loading,
    );
  }
}

class RegisterFormNotifier extends Notifier<RegisterFormState> {
  @override
  RegisterFormState build() => const RegisterFormState();

  void setNameError(String? error) => state = state.copyWith(nameError: error);
  void setEmailError(String? error) => state = state.copyWith(emailError: error);
  void setPasswordError(String? error) => state = state.copyWith(passwordError: error);
  void setConfirmError(String? error) => state = state.copyWith(confirmError: error);
  void setLoading(bool value) => state = state.copyWith(loading: value);
  void reset() => state = const RegisterFormState();
}

final registerFormProvider =
    NotifierProvider<RegisterFormNotifier, RegisterFormState>(RegisterFormNotifier.new);

// --- Shared UI state ---

class _AuthGateIsLoginNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void setValue(bool value) => state = value;
}

final authGateIsLoginProvider =
    NotifierProvider<_AuthGateIsLoginNotifier, bool>(_AuthGateIsLoginNotifier.new);

class _ProfileDeletingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setValue(bool value) => state = value;
}

final profileDeletingProvider =
    NotifierProvider<_ProfileDeletingNotifier, bool>(_ProfileDeletingNotifier.new);

class _AuthSessionEventNotifier extends Notifier<AuthSessionEvent?> {
  @override
  AuthSessionEvent? build() => null;

  void emit(AuthSessionEvent event) => state = event;
  void clear() => state = null;
}

final authSessionEventProvider =
    NotifierProvider<_AuthSessionEventNotifier, AuthSessionEvent?>(
        _AuthSessionEventNotifier.new);

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() async {
    final restored = await _repo.restoreSession();
    if (restored == null) return null;
    restored.onInvalidated.then((valid) {
      if (!valid) {
        _repo.clearLocalSessionOnly().catchError((_) {});
        _clearFormState();
        ref.read(authSessionEventProvider.notifier).emit(
            AuthSessionEvent.remotelyInvalidated);
        state = const AsyncData(null);
      }
    });
    return restored.user;
  }

  Future<void> login(String email, String password) async {
    final user = await _repo.login(email, password);
    state = AsyncData(user);
  }

  Future<void> register(String name, String email, String password) async {
    final user = await _repo.register(name, email, password);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (e, st) {
      debugPrint('[AuthNotifier] logout error (best-effort): $e\n$st');
    }
    _clearFormState();
    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    final current = state.asData?.value;
    if (current == null) return;
    await _repo.deleteAccount(current);
    _clearFormState();
    state = const AsyncData(null);
  }

  void _clearFormState() {
    ref.read(loginFormProvider.notifier).reset();
    ref.read(registerFormProvider.notifier).reset();
    ref.read(profileDeletingProvider.notifier).setValue(false);
    ref.read(authGateIsLoginProvider.notifier).setValue(true);
  }

  /// Called on app resume. Validates the current session against the DB.
  /// If another device logged in and replaced the token, kicks this device out
  /// and emits [AuthSessionEvent.remotelyInvalidated] to show a toast.
  Future<void> checkSessionOnResume() async {
    final current = state.asData?.value;
    if (current == null) return;
    bool shouldLogout = false;
    try {
      final isValid = await _repo.validateCurrentSession();
      if (!isValid) {
        await _repo.logout();
        _clearFormState();
        ref.read(authSessionEventProvider.notifier).emit(
            AuthSessionEvent.remotelyInvalidated);
        shouldLogout = true;
      }
    } catch (e, st) {
      debugPrint('[AuthNotifier] checkSessionOnResume error: $e\n$st');
      // Validation threw — session is lost, don't stay stuck logged in.
      shouldLogout = true;
    } finally {
      if (shouldLogout) state = const AsyncData(null);
    }
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).asData?.value != null;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});
