import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';

class PushHeartbeatUseCase {
  PushHeartbeatUseCase({required DeviceRepository deviceRepository})
    : _deviceRepository = deviceRepository;

  final DeviceRepository _deviceRepository;

  Future<void> execute({
    required String userId,
    required String deviceId,
    required String serverId,
    required bool isConnected,
    required int latencyMs,
  }) {
    return _deviceRepository.pushHeartbeat(
      userId: userId,
      deviceId: deviceId,
      serverId: serverId,
      isConnected: isConnected,
      latencyMs: latencyMs,
    );
  }
}
