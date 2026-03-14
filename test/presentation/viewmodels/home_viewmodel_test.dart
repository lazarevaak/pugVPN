import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pug_vpn/data/dao/backend_api_dao.dart';
import 'package:pug_vpn/data/dao/native_vpn_dao.dart';
import 'package:pug_vpn/domain/entities/connected_vpn_session.dart';
import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
import 'package:pug_vpn/domain/usecases/connect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/disconnect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/get_vpn_status_use_case.dart';
import 'package:pug_vpn/domain/usecases/share_app_use_case.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/home_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('connect updates state from connected session', () async {
    final selectionVm = AppSelectionViewModel(
      repository: _AppsOnlyNativeRepository(),
    );
    await selectionVm.ensureLoaded();
    final homeVm = HomeViewModel(
      appSelectionViewModel: selectionVm,
      connectVpnUseCase: _FakeConnectVpnUseCase(
        session: const ConnectedVpnSession(
          location: 'FI',
          details: 'Finland_1',
        ),
      ),
      disconnectVpnUseCase: _FakeDisconnectVpnUseCase(),
      getVpnStatusUseCase: _FakeGetVpnStatusUseCase(),
      shareAppUseCase: _FakeShareAppUseCase(),
    );

    await homeVm.connect();

    expect(homeVm.isConnected, isTrue);
    expect(homeVm.isConnecting, isFalse);
    expect(homeVm.location, 'FI');
    expect(homeVm.locationDetails, 'Finland_1');
    expect(homeVm.displayLocation, 'FI');
  });

  test('handleAppSelectionChanged disconnects active vpn and resets state', () async {
    final selectionVm = AppSelectionViewModel(
      repository: _AppsOnlyNativeRepository(),
    );
    await selectionVm.ensureLoaded();
    final disconnectUseCase = _FakeDisconnectVpnUseCase();
    final homeVm = HomeViewModel(
      appSelectionViewModel: selectionVm,
      connectVpnUseCase: _FakeConnectVpnUseCase(
        session: const ConnectedVpnSession(
          location: 'US',
          details: 'United States',
        ),
      ),
      disconnectVpnUseCase: disconnectUseCase,
      getVpnStatusUseCase: _FakeGetVpnStatusUseCase(),
      shareAppUseCase: _FakeShareAppUseCase(),
    );

    await homeVm.connect();
    await homeVm.handleAppSelectionChanged();

    expect(disconnectUseCase.calledWithNativeTunnel, isTrue);
    expect(homeVm.isConnected, isFalse);
    expect(homeVm.statusLabel, 'Disconnected');
    expect(homeVm.displayLocation, 'RU');
  });

  test('shareApp delegates to use case', () async {
    final selectionVm = AppSelectionViewModel(
      repository: _AppsOnlyNativeRepository(),
    );
    final shareUseCase = _FakeShareAppUseCase();
    final homeVm = HomeViewModel(
      appSelectionViewModel: selectionVm,
      connectVpnUseCase: _FakeConnectVpnUseCase(
        session: const ConnectedVpnSession(
          location: 'FI',
          details: 'Finland_1',
        ),
      ),
      disconnectVpnUseCase: _FakeDisconnectVpnUseCase(),
      getVpnStatusUseCase: _FakeGetVpnStatusUseCase(),
      shareAppUseCase: shareUseCase,
    );

    await homeVm.shareApp();

    expect(shareUseCase.wasCalled, isTrue);
  });
}

class _AppsOnlyNativeRepository extends NativeVpnRepository {
  _AppsOnlyNativeRepository() : super(dao: const NativeVpnDao());

  @override
  Future<List<DeviceApp>> listInstalledApps() async {
    return const <DeviceApp>[
      DeviceApp(packageName: 'app.one', label: 'App One'),
      DeviceApp(packageName: 'app.two', label: 'App Two'),
    ];
  }
}

class _FakeConnectVpnUseCase extends ConnectVpnUseCase {
  _FakeConnectVpnUseCase({required ConnectedVpnSession session})
    : _session = session,
      super(
        backendRepository: BackendRepository(
          apiDao: BackendApiDao(baseUrl: 'http://localhost'),
        ),
        nativeVpnRepository: const NativeVpnRepository(dao: NativeVpnDao()),
      );

  final ConnectedVpnSession _session;

  @override
  Future<ConnectedVpnSession> execute({
    required String deviceName,
    required bool useNativeTunnel,
    required List<String> selectedPackages,
    required List<String> allPackages,
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('Preparing device...');
    onProgress?.call('Starting tunnel...');
    return _session;
  }
}

class _FakeDisconnectVpnUseCase extends DisconnectVpnUseCase {
  _FakeDisconnectVpnUseCase()
    : super(
        nativeVpnRepository: const NativeVpnRepository(dao: NativeVpnDao()),
      );

  bool calledWithNativeTunnel = false;

  @override
  Future<void> execute({required bool useNativeTunnel}) async {
    calledWithNativeTunnel = useNativeTunnel;
  }
}

class _FakeGetVpnStatusUseCase extends GetVpnStatusUseCase {
  _FakeGetVpnStatusUseCase()
    : super(
        nativeVpnRepository: const NativeVpnRepository(dao: NativeVpnDao()),
      );

  @override
  Future<Map<String, dynamic>> execute({required bool useNativeTunnel}) async {
    return const <String, dynamic>{'state': 'down', 'is_connected': false};
  }
}

class _FakeShareAppUseCase extends ShareAppUseCase {
  _FakeShareAppUseCase()
    : super(
        nativeVpnRepository: const NativeVpnRepository(dao: NativeVpnDao()),
      );

  bool wasCalled = false;

  @override
  Future<void> execute() async {
    wasCalled = true;
  }
}
