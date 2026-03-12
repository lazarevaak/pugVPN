import 'package:pug_vpn_backend/domain/entities/server_node.dart';

abstract interface class ServerRepository {
  Future<ServerNode> resolveServer({String? serverId});

  Future<List<ServerNode>> listServers();

  Future<bool> healthCheck();
}
