import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/entities/device.dart';

abstract interface class DeviceRepository {
  Future<Device> registerDevice({
    required String userId,
    required String serverId,
    required String deviceName,
    required String publicKey,
    required String subnet,
    required RequestMeta requestMeta,
  });

  Future<List<Map<String, dynamic>>> listDevices({
    required String userId,
    bool includeRevoked = false,
  });

  Future<Map<String, dynamic>> revokeDevice({
    required String userId,
    required String deviceId,
    required RequestMeta requestMeta,
  });

  Future<Map<String, dynamic>> reissueDevice({
    required String userId,
    required String deviceId,
    required String devicePublicKey,
    String? deviceName,
    required RequestMeta requestMeta,
  });

  Future<void> pushHeartbeat({
    required String userId,
    required String deviceId,
    required String serverId,
    required bool isConnected,
    required int latencyMs,
  });
}
