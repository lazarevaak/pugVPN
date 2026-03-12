import 'package:pug_vpn_backend/domain/entities/server_node.dart';
import 'package:pug_vpn_backend/domain/repositories/server_repository.dart';

class ListServersUseCase {
  ListServersUseCase({required ServerRepository serverRepository})
    : _serverRepository = serverRepository;

  final ServerRepository _serverRepository;

  Future<List<ServerNode>> execute() {
    return _serverRepository.listServers();
  }
}
