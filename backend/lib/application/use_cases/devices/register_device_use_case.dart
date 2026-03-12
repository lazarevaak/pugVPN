import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/entities/device.dart';
import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';
import 'package:pug_vpn_backend/domain/repositories/server_repository.dart';

class RegisterDeviceUseCase {
  RegisterDeviceUseCase({
    required DeviceRepository deviceRepository,
    required ServerRepository serverRepository,
  }) : _deviceRepository = deviceRepository,
       _serverRepository = serverRepository;

  final DeviceRepository _deviceRepository;
  final ServerRepository _serverRepository;

  Future<Device> execute({
    required String userId,
    required String deviceName,
    required String publicKey,
    String? serverId,
    required RequestMeta requestMeta,
  }) async {
    final server = await _serverRepository.resolveServer(serverId: serverId);
    return _deviceRepository.registerDevice(
      userId: userId,
      serverId: server.id,
      deviceName: deviceName,
      publicKey: publicKey,
      subnet: server.subnet,
      requestMeta: requestMeta,
    );
  }
}
