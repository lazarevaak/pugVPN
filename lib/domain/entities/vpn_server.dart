class VpnServer {
  const VpnServer({
    required this.id,
    required this.name,
    required this.protocol,
    required this.location,
  });

  final String id;
  final String name;
  final String protocol;
  final String location;
}
