import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/features/auth/models/auth_session.dart';
import 'package:organization_app_starter/features/auth/models/user_model.dart';

class SessionService {
  static const _key = 'session';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String _generateToken() {
    final random = Random.secure();
    final input = '${DateTime.now().millisecondsSinceEpoch}'
        '${random.nextInt(1 << 31)}'
        '${random.nextInt(1 << 31)}'
        '${random.nextInt(1 << 31)}';
    return sha256.convert(utf8.encode(input)).toString();
  }

  // Raw token stored on device; hash stored in DB — DB leak doesn't expose usable tokens.
  String _hashToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }

  Future<LocalSession> createSession(AuthUser user) async {
    final token = _generateToken();
    final tokenHash = _hashToken(token);
    final expiresAt = DateTime.now().add(Duration(days: AuthConstants.sessionExpiryDays));

    // Overwrite any previous session for this user — last login wins.
    await AppAmbitDb.execute(
      'UPDATE ${AuthConstants.usersTable} SET token = ?, expires_at = ? WHERE id = ?',
      [tokenHash, expiresAt.toIso8601String(), user.id],
    );

    return LocalSession(
      token: token,
      userId: user.id,
      expiresAt: expiresAt.millisecondsSinceEpoch,
      user: user,
    );
  }

  Future<void> saveSessionLocally(LocalSession session) async {
    final json = jsonEncode(session.toMap());
    await _secure.write(key: _key, value: json);
  }

  Future<LocalSession?> getLocalSession() async {
    try {
      final json = await _secure.read(key: _key);
      if (json == null || json.isEmpty) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return LocalSession.fromMap(map);
    } catch (e) {
      debugPrint('[SessionService] Failed to read local session: $e');
      await clearLocalSession();
      return null;
    }
  }

  Future<void> clearLocalSession() async {
    try {
      await _secure.delete(key: _key);
    } catch (e) {
      debugPrint('[SessionService] Failed to clear local session: $e');
    }
  }

  Future<bool> validateSessionRemote(String token, int userId) async {
    try {
      final tokenHash = _hashToken(token);
      final row = await AppAmbitDb
          .from(AuthConstants.usersTable)
          .where('id', userId)
          .where('token', tokenHash)
          .first();

      if (row == null) return false;

      final expiresAtStr = row['expires_at'] as String?;
      if (expiresAtStr == null) return false;

      final expiresAt = DateTime.parse(expiresAtStr);
      if (expiresAt.isBefore(DateTime.now())) {
        await _clearTokenInDb(userId);
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[SessionService] Remote validation error (optimistic): $e');
      return true;
    }
  }

  Future<void> deleteSession(String token) async {
    try {
      final tokenHash = _hashToken(token);
      await AppAmbitDb.execute(
        'UPDATE ${AuthConstants.usersTable} SET token = NULL, expires_at = NULL WHERE token = ?',
        [tokenHash],
      );
    } catch (e) {
      debugPrint('[SessionService] Delete session error: $e');
    }
  }

  Future<void> deleteAllUserSessions(int userId) async {
    try {
      await _clearTokenInDb(userId);
    } catch (e) {
      debugPrint('[SessionService] Delete all sessions error: $e');
    }
  }

  Future<void> _clearTokenInDb(int userId) async {
    await AppAmbitDb.execute(
      'UPDATE ${AuthConstants.usersTable} SET token = NULL, expires_at = NULL WHERE id = ?',
      [userId],
    );
  }

  Future<void> _clearOnFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installed = prefs.getBool(AuthConstants.sessionInstalledKey);
      if (installed == true) return;
      await _secure.deleteAll();
      await prefs.setBool(AuthConstants.sessionInstalledKey, true);
    } catch (e) {
      debugPrint('[SessionService] Fresh install check error: $e');
    }
  }

  Future<void> _rejuvenateSession(LocalSession session) async {
    try {
      final tokenHash = _hashToken(session.token);
      final newExpiresAt = DateTime.now().add(Duration(days: AuthConstants.sessionExpiryDays));
      await AppAmbitDb.execute(
        'UPDATE ${AuthConstants.usersTable} SET expires_at = ? WHERE token = ?',
        [newExpiresAt.toIso8601String(), tokenHash],
      );
      final rejuvenated = LocalSession(
        token: session.token,
        userId: session.userId,
        expiresAt: newExpiresAt.millisecondsSinceEpoch,
        user: session.user,
      );
      await saveSessionLocally(rejuvenated);
    } catch (e) {
      debugPrint('[SessionService] Rejuvenate error (non-fatal): $e');
    }
  }

  Future<({AuthUser user, Future<bool> onInvalidated})?> restoreSession() async {
    await _clearOnFreshInstall();

    final local = await getLocalSession();
    if (local == null) return null;

    if (local.isExpired) {
      await _clearTokenInDb(local.userId);
      await clearLocalSession();
      return null;
    }

    unawaited(_rejuvenateSession(local));

    final future = validateSessionRemote(local.token, local.userId);
    return (user: local.user, onInvalidated: future);
  }
}
