import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';

class ListDevicesUseCase {
  ListDevicesUseCase({required DeviceRepository deviceRepository})
    : _deviceRepository = deviceRepository;

  final DeviceRepository _deviceRepository;

  Future<List<Map<String, dynamic>>> execute({
    required String userId,
    bool includeRevoked = false,
  }) {
    return _deviceRepository.listDevices(
      userId: userId,
      includeRevoked: includeRevoked,
    );
  }
}
