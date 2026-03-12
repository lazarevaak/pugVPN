import 'package:pug_vpn/data/dao/backend_api_dao.dart';
import 'package:pug_vpn/domain/entities/vpn_config_result.dart';
import 'package:pug_vpn/domain/entities/vpn_server.dart';
import 'package:pug_vpn/domain/mappers/vpn_config_result_mapper.dart';
import 'package:pug_vpn/domain/mappers/vpn_server_mapper.dart';

class BackendRepository {
  BackendRepository({required BackendApiDao apiDao}) : _apiDao = apiDao;

  final BackendApiDao _apiDao;

  void dispose() {
    _apiDao.dispose();
  }

  Future<String> login({required String email, required String password}) {
    return _apiDao.login(email: email, password: password);
  }

  Future<List<VpnServer>> fetchServers({required String accessToken}) async {
    final dtos = await _apiDao.fetchServers(accessToken: accessToken);
    return dtos.map(VpnServerMapper.toEntity).toList(growable: false);
  }

  Future<VpnConfigResult> buildConfig({
    required String accessToken,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
  }) async {
    final dto = await _apiDao.buildConfig(
      accessToken: accessToken,
      serverId: serverId,
      deviceName: deviceName,
      devicePublicKey: devicePublicKey,
    );
    return VpnConfigResultMapper.toEntity(dto);
  }
}
