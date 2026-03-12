import 'package:pug_vpn_backend/application/use_cases/auth/get_current_user_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/auth/login_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/auth/logout_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/list_devices_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/push_heartbeat_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/register_device_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/reissue_device_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/revoke_device_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/servers/list_servers_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/sessions/revoke_session_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/system/health_check_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/vpn/build_vpn_config_use_case.dart';
import 'package:pug_vpn_backend/data/dao/backend_store_dao.dart';
import 'package:pug_vpn_backend/data/repositories/auth_repository_impl.dart';
import 'package:pug_vpn_backend/data/repositories/device_repository_impl.dart';
import 'package:pug_vpn_backend/data/repositories/server_repository_impl.dart';
import 'package:pug_vpn_backend/data/repositories/session_repository_impl.dart';
import 'package:pug_vpn_backend/data/repositories/vpn_repository_impl.dart';
import 'package:pug_vpn_backend/domain/repositories/auth_repository.dart';
import 'package:pug_vpn_backend/domain/repositories/device_repository.dart';
import 'package:pug_vpn_backend/domain/repositories/server_repository.dart';
import 'package:pug_vpn_backend/domain/repositories/session_repository.dart';
import 'package:pug_vpn_backend/domain/repositories/vpn_repository.dart';

final BackendStoreDao _backendStoreDao = BackendStoreDao();
final AuthRepository _authRepository = AuthRepositoryImpl(
  storeDao: _backendStoreDao,
);
final DeviceRepository _deviceRepository = DeviceRepositoryImpl(
  storeDao: _backendStoreDao,
);
final ServerRepository _serverRepository = ServerRepositoryImpl(
  storeDao: _backendStoreDao,
);
final SessionRepository _sessionRepository = SessionRepositoryImpl(
  storeDao: _backendStoreDao,
);
final VpnRepository _vpnRepository = VpnRepositoryImpl(
  storeDao: _backendStoreDao,
);
final LoginUseCase _loginUseCase = LoginUseCase(
  authRepository: _authRepository,
);
final LogoutUseCase _logoutUseCase = LogoutUseCase(
  sessionRepository: _sessionRepository,
);
final GetCurrentUserUseCase _getCurrentUserUseCase = GetCurrentUserUseCase(
  authRepository: _authRepository,
  sessionRepository: _sessionRepository,
);
final ListDevicesUseCase _listDevicesUseCase = ListDevicesUseCase(
  deviceRepository: _deviceRepository,
);
final RegisterDeviceUseCase _registerDeviceUseCase = RegisterDeviceUseCase(
  deviceRepository: _deviceRepository,
  serverRepository: _serverRepository,
);
final RevokeDeviceUseCase _revokeDeviceUseCase = RevokeDeviceUseCase(
  deviceRepository: _deviceRepository,
);
final ReissueDeviceUseCase _reissueDeviceUseCase = ReissueDeviceUseCase(
  deviceRepository: _deviceRepository,
);
final PushHeartbeatUseCase _pushHeartbeatUseCase = PushHeartbeatUseCase(
  deviceRepository: _deviceRepository,
);
final RevokeSessionUseCase _revokeSessionUseCase = RevokeSessionUseCase(
  sessionRepository: _sessionRepository,
);
final ListServersUseCase _listServersUseCase = ListServersUseCase(
  serverRepository: _serverRepository,
);
final BuildVpnConfigUseCase _buildVpnConfigUseCase = BuildVpnConfigUseCase(
  vpnRepository: _vpnRepository,
);
final HealthCheckUseCase _healthCheckUseCase = HealthCheckUseCase(
  serverRepository: _serverRepository,
);

AuthRepository createAuthRepository() => _authRepository;
LoginUseCase createLoginUseCase() => _loginUseCase;
LogoutUseCase createLogoutUseCase() => _logoutUseCase;
GetCurrentUserUseCase createGetCurrentUserUseCase() => _getCurrentUserUseCase;
ListDevicesUseCase createListDevicesUseCase() => _listDevicesUseCase;
RegisterDeviceUseCase createRegisterDeviceUseCase() => _registerDeviceUseCase;
RevokeDeviceUseCase createRevokeDeviceUseCase() => _revokeDeviceUseCase;
ReissueDeviceUseCase createReissueDeviceUseCase() => _reissueDeviceUseCase;
PushHeartbeatUseCase createPushHeartbeatUseCase() => _pushHeartbeatUseCase;
RevokeSessionUseCase createRevokeSessionUseCase() => _revokeSessionUseCase;
ListServersUseCase createListServersUseCase() => _listServersUseCase;
BuildVpnConfigUseCase createBuildVpnConfigUseCase() => _buildVpnConfigUseCase;
HealthCheckUseCase createHealthCheckUseCase() => _healthCheckUseCase;
