import 'package:pug_vpn/data/dto/vpn_server_dto.dart';
import 'package:pug_vpn/domain/entities/vpn_server.dart';

class VpnServerMapper {
  const VpnServerMapper._();

  static VpnServer toEntity(VpnServerDto dto) {
    return VpnServer(
      id: dto.id,
      name: dto.name,
      protocol: dto.protocol,
      location: dto.location,
    );
  }
}
