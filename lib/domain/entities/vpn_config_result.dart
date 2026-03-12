class VpnConfigResult {
  const VpnConfigResult({
    required this.protocol,
    required this.vpnConf,
    required this.deviceId,
  });

  final String protocol;
  final String vpnConf;
  final String deviceId;
}
