import 'package:pug_vpn/data/dao/native_vpn_dao.dart';

class NativeVpnRepository {
  const NativeVpnRepository({required NativeVpnDao dao}) : _dao = dao;

  final NativeVpnDao _dao;

  Future<bool> prepare() => _dao.prepare();

  Future<bool> connect({required String config, required String tunnelName}) =>
      _dao.connect(config: config, tunnelName: tunnelName);

  Future<bool> importConfig({
    required String config,
    required String tunnelName,
  }) => _dao.importConfig(config: config, tunnelName: tunnelName);

  Future<void> disconnect() => _dao.disconnect();
}
