import 'package:pug_vpn_backend/domain/entities/amnezia_settings.dart';

class ServerNode {
  ServerNode({
    required this.id,
    required this.name,
    required this.location,
    required this.endpoint,
    required this.publicKey,
    required this.subnet,
    required this.dnsServers,
    required this.mtu,
    required this.amneziaSettings,
  });

  final String id;
  final String name;
  final String location;
  final String endpoint;
  final String publicKey;
  final String subnet;
  final List<String> dnsServers;
  final int mtu;
  final AmneziaSettings amneziaSettings;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'endpoint': endpoint,
    'public_key': publicKey,
    'protocol': 'amneziawg',
    'subnet': subnet,
    'dns_servers': dnsServers,
    'mtu': mtu,
    'amnezia': amneziaSettings.toJson(),
  };
}
