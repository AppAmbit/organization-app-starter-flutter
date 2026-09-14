import 'user_model.dart';

class LocalSession {
  final String token;
  final int userId;
  final int expiresAt;
  final AuthUser user;

  const LocalSession({
    required this.token,
    required this.userId,
    required this.expiresAt,
    required this.user,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toMap() => {
        'token': token,
        'userId': userId,
        'expiresAt': expiresAt,
        'user': user.toMap(),
      };

  factory LocalSession.fromMap(Map<String, dynamic> map) {
    return LocalSession(
      token: map['token'] as String,
      userId: (map['userId'] as num).toInt(),
      expiresAt: (map['expiresAt'] as num).toInt(),
      user: AuthUser.fromMap(map['user'] as Map<String, dynamic>),
    );
  }
}
