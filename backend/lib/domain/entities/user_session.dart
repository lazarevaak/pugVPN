class UserSession {
  UserSession({
    required this.token,
    required this.userId,
    required this.expiresAt,
    required this.createdAt,
  });

  final String token;
  final String userId;
  final DateTime expiresAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'token': token,
    'user_id': userId,
    'expires_at': expiresAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}
