import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';

class RevokeDeviceUseCase {
  RevokeDeviceUseCase({required DeviceRepository deviceRepository})
    : _deviceRepository = deviceRepository;

  final DeviceRepository _deviceRepository;

  Future<Map<String, dynamic>> execute({
    required String userId,
    required String deviceId,
    required RequestMeta requestMeta,
  }) {
    return _deviceRepository.revokeDevice(
      userId: userId,
      deviceId: deviceId,
      requestMeta: requestMeta,
    );
  }
}
