import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/entities/device_key_pair.dart';
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

  Future<Map<String, dynamic>> status() => _dao.status();

  Future<DeviceKeyPair?> loadDeviceKeyPair() => _dao.loadDeviceKeyPair();

  Future<void> saveDeviceKeyPair(DeviceKeyPair keyPair) =>
      _dao.saveDeviceKeyPair(keyPair);

  Future<List<DeviceApp>> listInstalledApps() => _dao.listInstalledApps();
}
