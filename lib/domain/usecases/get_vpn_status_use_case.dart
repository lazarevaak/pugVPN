import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

class GetVpnStatusUseCase {
  const GetVpnStatusUseCase({
    required NativeVpnRepository nativeVpnRepository,
  }) : _nativeVpnRepository = nativeVpnRepository;

  final NativeVpnRepository _nativeVpnRepository;

  Future<Map<String, dynamic>> execute({required bool useNativeTunnel}) async {
    if (!useNativeTunnel) {
      return const <String, dynamic>{'state': 'down', 'is_connected': false};
    }
    return _nativeVpnRepository.status();
  }
}
