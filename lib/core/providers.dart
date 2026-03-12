import 'package:pug_vpn/core/config/app_env.dart';
import 'package:pug_vpn/data/dao/backend_api_dao.dart';
import 'package:pug_vpn/data/dao/native_vpn_dao.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

BackendRepository createBackendRepository() =>
    BackendRepository(apiDao: BackendApiDao(baseUrl: AppEnv.backendBaseUrl));

NativeVpnRepository createNativeVpnRepository() =>
    const NativeVpnRepository(dao: NativeVpnDao());
