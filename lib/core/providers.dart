import 'package:pug_vpn/core/config/app_env.dart';
import 'package:pug_vpn/data/dao/backend_api_dao.dart';
import 'package:pug_vpn/data/dao/native_vpn_dao.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
import 'package:pug_vpn/domain/usecases/connect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/disconnect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/get_vpn_status_use_case.dart';
import 'package:pug_vpn/domain/usecases/share_app_use_case.dart';

BackendRepository createBackendRepository() =>
    BackendRepository(apiDao: BackendApiDao(baseUrl: AppEnv.backendBaseUrl));

NativeVpnRepository createNativeVpnRepository() =>
    const NativeVpnRepository(dao: NativeVpnDao());

ConnectVpnUseCase createConnectVpnUseCase() => ConnectVpnUseCase(
  backendRepository: createBackendRepository(),
  nativeVpnRepository: createNativeVpnRepository(),
);

DisconnectVpnUseCase createDisconnectVpnUseCase() => DisconnectVpnUseCase(
  nativeVpnRepository: createNativeVpnRepository(),
);

GetVpnStatusUseCase createGetVpnStatusUseCase() => GetVpnStatusUseCase(
  nativeVpnRepository: createNativeVpnRepository(),
);

ShareAppUseCase createShareAppUseCase() =>
    ShareAppUseCase(nativeVpnRepository: createNativeVpnRepository());
