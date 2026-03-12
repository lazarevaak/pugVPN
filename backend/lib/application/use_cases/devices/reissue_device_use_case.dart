import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';

class ReissueDeviceUseCase {
  ReissueDeviceUseCase({required DeviceRepository deviceRepository})
    : _deviceRepository = deviceRepository;

  final DeviceRepository _deviceRepository;

  Future<Map<String, dynamic>> execute({
    required String userId,
    required String deviceId,
    required String devicePublicKey,
    String? deviceName,
    required RequestMeta requestMeta,
  }) {
    return _deviceRepository.reissueDevice(
      userId: userId,
      deviceId: deviceId,
      devicePublicKey: devicePublicKey,
      deviceName: deviceName,
      requestMeta: requestMeta,
    );
  }
}
