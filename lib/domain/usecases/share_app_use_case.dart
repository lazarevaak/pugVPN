import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

class ShareAppUseCase {
  const ShareAppUseCase({
    required NativeVpnRepository nativeVpnRepository,
  }) : _nativeVpnRepository = nativeVpnRepository;

  final NativeVpnRepository _nativeVpnRepository;

  Future<void> execute() async {
    await _nativeVpnRepository.shareText(
      'PugVPN\nSecure. Fast. Private.\nDownload and try the app.',
    );
  }
}
