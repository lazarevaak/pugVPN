class UserAccount {
  UserAccount({
    required this.id,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
