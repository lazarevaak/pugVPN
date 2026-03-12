import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/repositories/vpn_repository.dart';

class BuildVpnConfigUseCase {
  BuildVpnConfigUseCase({required VpnRepository vpnRepository})
    : _vpnRepository = vpnRepository;

  final VpnRepository _vpnRepository;

  Future<Map<String, dynamic>> execute({
    required String userId,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
    required RequestMeta requestMeta,
  }) {
    return _vpnRepository.buildConfig(
      userId: userId,
      serverId: serverId,
      deviceName: deviceName,
      devicePublicKey: devicePublicKey,
      requestMeta: requestMeta,
    );
  }
}
