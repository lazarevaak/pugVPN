import 'package:pug_vpn/data/dto/vpn_config_result_dto.dart';
import 'package:pug_vpn/domain/entities/vpn_config_result.dart';

class VpnConfigResultMapper {
  const VpnConfigResultMapper._();

  static VpnConfigResult toEntity(VpnConfigResultDto dto) {
    return VpnConfigResult(
      protocol: dto.protocol,
      vpnConf: dto.vpnConf,
      deviceId: dto.deviceId,
    );
  }
}
