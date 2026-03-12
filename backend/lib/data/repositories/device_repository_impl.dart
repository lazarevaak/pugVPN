import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/data/dao/backend_store_dao.dart';
import 'package:pug_vpn_backend/domain/entities/device.dart';
import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required BackendStoreDao storeDao})
    : _storeDao = storeDao;

  final BackendStoreDao _storeDao;

  @override
  Future<Device> registerDevice({
    required String userId,
    required String serverId,
    required String deviceName,
    required String publicKey,
    required String subnet,
    required RequestMeta requestMeta,
  }) {
    return _storeDao.registerDevice(
      userId: userId,
      serverId: serverId,
      deviceName: deviceName,
      publicKey: publicKey,
      subnet: subnet,
      requestMeta: requestMeta,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listDevices({
    required String userId,
    bool includeRevoked = false,
  }) {
    return _storeDao.listDevices(
      userId: userId,
      includeRevoked: includeRevoked,
    );
  }

  @override
  Future<Map<String, dynamic>> revokeDevice({
    required String userId,
    required String deviceId,
    required RequestMeta requestMeta,
  }) {
    return _storeDao.revokeDevice(
      userId: userId,
      deviceId: deviceId,
      requestMeta: requestMeta,
    );
  }

  @override
  Future<Map<String, dynamic>> reissueDevice({
    required String userId,
    required String deviceId,
    required String devicePublicKey,
    String? deviceName,
    required RequestMeta requestMeta,
  }) {
    return _storeDao.reissueDevice(
      userId: userId,
      deviceId: deviceId,
      devicePublicKey: devicePublicKey,
      deviceName: deviceName,
      requestMeta: requestMeta,
    );
  }

  @override
  Future<void> pushHeartbeat({
    required String userId,
    required String deviceId,
    required String serverId,
    required bool isConnected,
    required int latencyMs,
  }) {
    return _storeDao.pushHeartbeat(
      userId: userId,
      deviceId: deviceId,
      serverId: serverId,
      isConnected: isConnected,
      latencyMs: latencyMs,
    );
  }
}
