import 'package:pug_vpn_backend/domain/repositories/server_repository.dart';

class HealthCheckUseCase {
  HealthCheckUseCase({required ServerRepository serverRepository})
    : _serverRepository = serverRepository;

  final ServerRepository _serverRepository;

  Future<bool> execute() {
    return _serverRepository.healthCheck();
  }
}
