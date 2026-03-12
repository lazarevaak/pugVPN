import 'package:pug_vpn/core/exceptions/backend_exception.dart';

class VpnConfigResultDto {
  const VpnConfigResultDto({
    required this.protocol,
    required this.vpnConf,
    required this.deviceId,
  });

  final String protocol;
  final String vpnConf;
  final String deviceId;

  factory VpnConfigResultDto.fromJson(Map<String, dynamic> json) {
    final protocol = json['protocol'] as String?;
    final vpnConf = json['vpn_conf'] as String?;

    final device = json['device'];
    final deviceId = device is Map<String, dynamic>
        ? device['id'] as String? ?? ''
        : '';

    if (protocol == null || protocol.isEmpty) {
      throw const BackendException('Backend не вернул protocol.');
    }
    if (protocol != 'amneziawg') {
      throw BackendException(
        'Unsupported protocol from backend: "$protocol". Expected "amneziawg".',
      );
    }
    if (vpnConf == null || vpnConf.isEmpty) {
      throw const BackendException('Backend не вернул vpn_conf.');
    }

    return VpnConfigResultDto(
      protocol: protocol,
      vpnConf: vpnConf,
      deviceId: deviceId,
    );
  }
}
