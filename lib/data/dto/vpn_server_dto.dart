class VpnServerDto {
  const VpnServerDto({
    required this.id,
    required this.name,
    required this.protocol,
    required this.location,
  });

  final String id;
  final String name;
  final String protocol;
  final String location;

  factory VpnServerDto.fromJson(Map<String, dynamic> json) {
    return VpnServerDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      protocol: json['protocol'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}
