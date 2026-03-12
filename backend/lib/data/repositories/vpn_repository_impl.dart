import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/data/dao/backend_store_dao.dart';
import 'package:pug_vpn_backend/domain/repositories/vpn_repository.dart';

class VpnRepositoryImpl implements VpnRepository {
  VpnRepositoryImpl({required BackendStoreDao storeDao}) : _storeDao = storeDao;

  final BackendStoreDao _storeDao;

  @override
  Future<Map<String, dynamic>> buildConfig({
    required String userId,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
    required RequestMeta requestMeta,
  }) {
    return _storeDao.buildConfig(
      userId: userId,
      serverId: serverId,
      deviceName: deviceName,
      devicePublicKey: devicePublicKey,
      requestMeta: requestMeta,
    );
  }
}
