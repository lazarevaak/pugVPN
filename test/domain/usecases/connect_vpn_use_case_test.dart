import 'package:flutter_test/flutter_test.dart';

import 'package:pug_vpn/data/dao/backend_api_dao.dart';
import 'package:pug_vpn/data/dao/native_vpn_dao.dart';
import 'package:pug_vpn/domain/entities/device_key_pair.dart';
import 'package:pug_vpn/domain/entities/vpn_config_result.dart';
import 'package:pug_vpn/domain/entities/vpn_server.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
import 'package:pug_vpn/domain/usecases/connect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/disconnect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/get_vpn_status_use_case.dart';
import 'package:pug_vpn/domain/usecases/share_app_use_case.dart';

void main() {
  group('ConnectVpnUseCase', () {
    test('injects IncludedApplications and connects native tunnel', () async {
      final backend = _FakeBackendRepository();
      final native = _FakeNativeVpnRepository(
        deviceKeyPair: const DeviceKeyPair(
          privateKeyBase64: 'private-key',
          publicKeyBase64: 'public-key',
        ),
      );
      final useCase = ConnectVpnUseCase(
        backendRepository: backend,
        nativeVpnRepository: native,
      );

      final session = await useCase.execute(
        deviceName: 'pixel-test',
        useNativeTunnel: true,
        allPackages: const <String>['app.one', 'app.two'],
        selectedPackages: const <String>['app.one'],
      );

      expect(session.location, 'FI');
      expect(session.details, 'Finland_1');
      expect(native.prepareCalled, isTrue);
      expect(native.connectCalled, isTrue);
      expect(native.lastTunnelName, 'pugvpn');
      expect(native.lastConfig, contains('IncludedApplications = app.one'));
      expect(native.lastConfig, isNot(contains('<CLIENT_PRIVATE_KEY_FROM_DEVICE>')));
      expect(native.lastConfig, contains('PrivateKey = private-key'));
    });

    test('skips native tunnel when disabled', () async {
      final backend = _FakeBackendRepository();
      final native = _FakeNativeVpnRepository(
        deviceKeyPair: const DeviceKeyPair(
          privateKeyBase64: 'private-key',
          publicKeyBase64: 'public-key',
        ),
      );
      final useCase = ConnectVpnUseCase(
        backendRepository: backend,
        nativeVpnRepository: native,
      );

      await useCase.execute(
        deviceName: 'macos-test',
        useNativeTunnel: false,
        allPackages: const <String>['app.one', 'app.two'],
        selectedPackages: const <String>['app.one'],
      );

      expect(native.prepareCalled, isFalse);
      expect(native.connectCalled, isFalse);
    });

    test('throws when backend returns no servers', () async {
      final backend = _FakeBackendRepository(servers: const <VpnServer>[]);
      final native = _FakeNativeVpnRepository(
        deviceKeyPair: const DeviceKeyPair(
          privateKeyBase64: 'private-key',
          publicKeyBase64: 'public-key',
        ),
      );
      final useCase = ConnectVpnUseCase(
        backendRepository: backend,
        nativeVpnRepository: native,
      );

      expect(
        () => useCase.execute(
          deviceName: 'pixel-test',
          useNativeTunnel: true,
          allPackages: const <String>[],
          selectedPackages: const <String>[],
        ),
        throwsA(
          isA<Exception>().having(
            (Exception error) => error.toString(),
            'message',
            contains('no VPN servers'),
          ),
        ),
      );
    });
  });

  group('Simple use cases', () {
    test('DisconnectVpnUseCase disconnects only for native tunnel', () async {
      final native = _FakeNativeVpnRepository();
      final useCase = DisconnectVpnUseCase(nativeVpnRepository: native);

      await useCase.execute(useNativeTunnel: false);
      expect(native.disconnectCalled, isFalse);

      await useCase.execute(useNativeTunnel: true);
      expect(native.disconnectCalled, isTrue);
    });

    test('GetVpnStatusUseCase returns fallback status when native disabled', () async {
      final native = _FakeNativeVpnRepository();
      final useCase = GetVpnStatusUseCase(nativeVpnRepository: native);

      final status = await useCase.execute(useNativeTunnel: false);

      expect(status['state'], 'down');
      expect(status['is_connected'], isFalse);
    });

    test('ShareAppUseCase sends expected share text', () async {
      final native = _FakeNativeVpnRepository();
      final useCase = ShareAppUseCase(nativeVpnRepository: native);

      await useCase.execute();

      expect(
        native.sharedText,
        'PugVPN\nSecure. Fast. Private.\nDownload and try the app.',
      );
    });
  });
}

class _FakeBackendRepository extends BackendRepository {
  _FakeBackendRepository({
    List<VpnServer>? servers,
    VpnConfigResult? configResult,
  }) : _servers =
           servers ??
           const <VpnServer>[
             VpnServer(
               id: 'srv_fi_1',
               name: 'Finland_1',
               protocol: 'amneziawg',
               location: 'FI',
             ),
           ],
       _configResult =
           configResult ??
           const VpnConfigResult(
             protocol: 'amneziawg',
             vpnConf: '[Interface]\nPrivateKey = <CLIENT_PRIVATE_KEY_FROM_DEVICE>\n[Peer]\nAllowedIPs = 0.0.0.0/0',
             deviceId: 'device-id',
           ),
       super(apiDao: BackendApiDao(baseUrl: 'http://localhost'));

  final List<VpnServer> _servers;
  final VpnConfigResult _configResult;

  @override
  Future<String> login({required String email, required String password}) async {
    return 'token';
  }

  @override
  Future<List<VpnServer>> fetchServers({required String accessToken}) async {
    return _servers;
  }

  @override
  Future<VpnConfigResult> buildConfig({
    required String accessToken,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
  }) async {
    return _configResult;
  }
}

class _FakeNativeVpnRepository extends NativeVpnRepository {
  _FakeNativeVpnRepository({
    this.deviceKeyPair,
    this.statusValue = const <String, dynamic>{
      'state': 'down',
      'is_connected': false,
    },
    this.prepareResult = true,
    this.connectResult = true,
  }) : super(dao: const NativeVpnDao());

  final DeviceKeyPair? deviceKeyPair;
  final Map<String, dynamic> statusValue;
  final bool prepareResult;
  final bool connectResult;

  bool prepareCalled = false;
  bool connectCalled = false;
  bool disconnectCalled = false;
  String? lastConfig;
  String? lastTunnelName;
  String? sharedText;

  @override
  Future<bool> prepare() async {
    prepareCalled = true;
    return prepareResult;
  }

  @override
  Future<bool> connect({required String config, required String tunnelName}) async {
    connectCalled = true;
    lastConfig = config;
    lastTunnelName = tunnelName;
    return connectResult;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }

  @override
  Future<Map<String, dynamic>> status() async => statusValue;

  @override
  Future<DeviceKeyPair?> loadDeviceKeyPair() async => deviceKeyPair;

  @override
  Future<bool> shareText(String text) async {
    sharedText = text;
    return true;
  }
}
