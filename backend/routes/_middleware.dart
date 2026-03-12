import 'package:dart_frog/dart_frog.dart';
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
import 'package:pug_vpn_backend/core/providers.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/repositories/auth_repository.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(
        provider<RequestMeta>(
          (context) => RequestMeta.fromRequest(context.request),
        ),
      )
      .use(provider<AuthRepository>((_) => createAuthRepository()))
      .use(provider<LoginUseCase>((_) => createLoginUseCase()))
      .use(provider<LogoutUseCase>((_) => createLogoutUseCase()))
      .use(
        provider<GetCurrentUserUseCase>((_) => createGetCurrentUserUseCase()),
      )
      .use(provider<ListDevicesUseCase>((_) => createListDevicesUseCase()))
      .use(
        provider<RegisterDeviceUseCase>((_) => createRegisterDeviceUseCase()),
      )
      .use(provider<RevokeDeviceUseCase>((_) => createRevokeDeviceUseCase()))
      .use(provider<ReissueDeviceUseCase>((_) => createReissueDeviceUseCase()))
      .use(provider<PushHeartbeatUseCase>((_) => createPushHeartbeatUseCase()))
      .use(provider<RevokeSessionUseCase>((_) => createRevokeSessionUseCase()))
      .use(provider<ListServersUseCase>((_) => createListServersUseCase()))
      .use(
        provider<BuildVpnConfigUseCase>((_) => createBuildVpnConfigUseCase()),
      )
      .use(provider<HealthCheckUseCase>((_) => createHealthCheckUseCase()));
}
