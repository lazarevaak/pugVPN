class ServerPreflight {
  ServerPreflight({
    required this.serverReachable,
    required this.interfaceUp,
    required this.provisioningReady,
    required this.hasFreeIps,
    required this.availableIpSlots,
    required this.mode,
    required this.checkedAt,
    required this.details,
  });

  final bool serverReachable;
  final bool? interfaceUp;
  final bool? provisioningReady;
  final bool hasFreeIps;
  final int availableIpSlots;
  final String mode;
  final DateTime checkedAt;
  final String details;

  Map<String, dynamic> toJson() => {
    'server_reachable': serverReachable,
    'interface_up': interfaceUp,
    'provisioning_ready': provisioningReady,
    'has_free_ips': hasFreeIps,
    'available_ip_slots': availableIpSlots,
    'mode': mode,
    'checked_at': checkedAt.toIso8601String(),
    'details': details,
  };
}
