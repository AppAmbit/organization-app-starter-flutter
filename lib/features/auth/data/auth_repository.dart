import 'dart:async';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:organization_app_starter/features/notifications/data/notifications_repository.dart';
import 'package:organization_app_starter/features/auth/models/user_model.dart';
import 'auth_db.dart';
import 'session_service.dart';

class AuthRepository {
  final AuthDB _authDB = AuthDB();
  final SessionService _sessionService = SessionService();

  Future<AuthUser> login(String email, String password) async {
    final user = await _authDB.login(email, password);
    final session = await _sessionService.createSession(user);
    // Run local save + SDK side-effects in parallel — none block the return value.
    await Future.wait([
      _sessionService.saveSessionLocally(session),
      AppAmbitSdk.trackEvent('User Logged In', {'email': user.email}),
      AppAmbitSdk. setUserId(user.id.toString()),
      AppAmbitSdk.setEmail(user.email),
    ]);
    return user;
  }

  Future<AuthUser> register(String name, String email, String password) async {
    final user = await _authDB.register(name, email, password);
    final session = await _sessionService.createSession(user);
    await Future.wait([
      _sessionService.saveSessionLocally(session),
      AppAmbitSdk.trackEvent('User Registered', {'email': user.email}),
      AppAmbitSdk.setUserId(user.id.toString()),
      AppAmbitSdk.setEmail(user.email),
    ]);
    return user;
  }

  Future<void> logout() async {
    final local = await _sessionService.getLocalSession();
    // Run all cleanup in parallel — each is best-effort.
    await Future.wait([
      _sessionService.clearLocalSession(),
      if (local != null)
        _sessionService.deleteSession(local.token).catchError((e) {
          debugPrint('[AuthRepository] logout deleteSession: $e');
        }),
      NotificationsRepository().clear().catchError((e) {
        debugPrint('[AuthRepository] logout notifications: $e');
      }),
      AppAmbitSdk.clearToken().catchError((e) {
        debugPrint('[AuthRepository] logout clearToken: $e');
      }),
      AppAmbitSdk.trackEvent('User Logged Out', {}).catchError((e) {
        debugPrint('[AuthRepository] logout trackEvent: $e');
      }),
    ]);
  }

  Future<void> deleteAccount(AuthUser user) async {
    // DB delete must succeed — propagate on failure.
    await _sessionService.deleteAllUserSessions(user.id);
    await _authDB.deleteUser(user.id);
    // Remaining cleanup runs in parallel — best-effort.
    await Future.wait([
      _sessionService.clearLocalSession(),
      NotificationsRepository().clear().catchError((e) {
        debugPrint('[AuthRepository] deleteAccount notifications: $e');
      }),
      AppAmbitSdk.clearToken().catchError((e) {
        debugPrint('[AuthRepository] deleteAccount clearToken: $e');
      }),
      AppAmbitSdk.trackEvent('User Deleted Account', {'email': user.email})
          .catchError((e) {
        debugPrint('[AuthRepository] deleteAccount trackEvent: $e');
      }),
    ]);
  }

  Future<({AuthUser user, Future<bool> onInvalidated})?> restoreSession() {
    return _sessionService.restoreSession();
  }

  Future<void> clearLocalSessionOnly() => _sessionService.clearLocalSession();

  Future<bool> validateCurrentSession() async {
    final local = await _sessionService.getLocalSession();
    if (local == null) return false;
    return _sessionService.validateSessionRemote(local.token, local.userId);
  }
}
