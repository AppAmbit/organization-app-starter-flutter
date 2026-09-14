import 'dart:convert';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:crypto/crypto.dart';

import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/features/auth/models/user_model.dart';

class EmailAlreadyExistsError implements Exception {
  final String message;
  const EmailAlreadyExistsError([this.message = 'An account with this email already exists']);
  @override
  String toString() => message;
}

class InvalidCredentialsError implements Exception {
  final String message;
  const InvalidCredentialsError([this.message = 'Invalid email or password']);
  @override
  String toString() => message;
}

// Salt with email to prevent cross-user rainbow table attacks.
String hashPassword(String password, String email) {
  final salted = '${email.trim().toLowerCase()}:$password';
  return sha256.convert(utf8.encode(salted)).toString();
}

class AuthDB {
  Future<AuthUser> register(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final createdAt = DateTime.now().toIso8601String();

    final result = await AppAmbitDb.execute(
      'INSERT INTO ${AuthConstants.usersTable} (name, email, password_hash, created_at) '
      'SELECT ?, ?, ?, ? WHERE NOT EXISTS '
      '(SELECT 1 FROM ${AuthConstants.usersTable} WHERE email = ?)',
      [name.trim(), normalizedEmail, hashPassword(password, normalizedEmail), createdAt, normalizedEmail],
    );

    if (result.rowsWritten == 0) {
      throw const EmailAlreadyExistsError();
    }

    final created = await AppAmbitDb
        .from(AuthConstants.usersTable)
        .where('email', normalizedEmail)
        .first();

    return AuthUser.fromMap(created!);
  }

  Future<AuthUser> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final row = await AppAmbitDb
        .from(AuthConstants.usersTable)
        .where('email', normalizedEmail)
        .first();

    if (row == null) {
      throw const InvalidCredentialsError();
    }

    final storedHash = row['password_hash'] as String? ?? '';
    if (storedHash != hashPassword(password, normalizedEmail)) {
      throw const InvalidCredentialsError();
    }

    return AuthUser.fromMap(row);
  }

  Future<void> deleteUser(int userId) async {
    await AppAmbitDb
        .from(AuthConstants.usersTable)
        .where('id', userId)
        .delete();
  }
}
