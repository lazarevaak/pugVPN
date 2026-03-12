class Device {
  Device({
    required this.id,
    required this.userId,
    required this.serverId,
    required this.name,
    required this.publicKey,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.revokedAt,
  });

  final String id;
  final String userId;
  final String serverId;
  final String name;
  final String publicKey;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'server_id': serverId,
    'name': name,
    'public_key': publicKey,
    'address': address,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'revoked_at': revokedAt?.toIso8601String(),
  };
}
