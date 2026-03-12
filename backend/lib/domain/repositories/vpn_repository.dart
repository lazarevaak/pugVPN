import 'package:pug_vpn_backend/core/request_meta.dart';

abstract interface class VpnRepository {
  Future<Map<String, dynamic>> buildConfig({
    required String userId,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
    required RequestMeta requestMeta,
  });
}
