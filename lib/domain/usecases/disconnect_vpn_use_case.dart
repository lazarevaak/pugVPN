import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

class DisconnectVpnUseCase {
  const DisconnectVpnUseCase({
    required NativeVpnRepository nativeVpnRepository,
  }) : _nativeVpnRepository = nativeVpnRepository;

  final NativeVpnRepository _nativeVpnRepository;

  Future<void> execute({required bool useNativeTunnel}) async {
    if (!useNativeTunnel) {
      return;
    }
    await _nativeVpnRepository.disconnect();
  }
}
