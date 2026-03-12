import 'package:pug_vpn_backend/data/dao/backend_store_dao.dart';
import 'package:pug_vpn_backend/domain/entities/server_node.dart';
import 'package:pug_vpn_backend/domain/repositories/server_repository.dart';

class ServerRepositoryImpl implements ServerRepository {
  ServerRepositoryImpl({required BackendStoreDao storeDao})
    : _storeDao = storeDao;

  final BackendStoreDao _storeDao;

  @override
  Future<ServerNode> resolveServer({String? serverId}) {
    return _storeDao.resolveServer(serverId: serverId);
  }

  @override
  Future<List<ServerNode>> listServers() {
    return _storeDao.listServers();
  }

  @override
  Future<bool> healthCheck() {
    return _storeDao.healthCheck();
  }
}
