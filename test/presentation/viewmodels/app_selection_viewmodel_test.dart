import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pug_vpn/data/dao/native_vpn_dao.dart';
import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'ensureLoaded selects all apps when there is no persisted selection',
    () async {
      final viewModel = AppSelectionViewModel(
        repository: _FakeNativeVpnRepository(
          apps: const <DeviceApp>[
            DeviceApp(packageName: 'app.one', label: 'App One'),
            DeviceApp(packageName: 'app.two', label: 'App Two'),
          ],
        ),
      );

      await viewModel.ensureLoaded();

      expect(viewModel.isLoaded, isTrue);
      expect(viewModel.apps.length, 2);
      expect(viewModel.selectedPackages, <String>{'app.one', 'app.two'});
      expect(viewModel.hasCustomSelection, isFalse);
    },
  );

  test(
    'ensureLoaded restores persisted selection and filters missing packages',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_app_packages': <String>['app.two', 'missing.app'],
      });
      final viewModel = AppSelectionViewModel(
        repository: _FakeNativeVpnRepository(
          apps: const <DeviceApp>[
            DeviceApp(packageName: 'app.one', label: 'App One'),
            DeviceApp(packageName: 'app.two', label: 'App Two'),
          ],
        ),
      );

      await viewModel.ensureLoaded();

      expect(viewModel.selectedPackages, <String>{'app.two'});
      expect(viewModel.hasCustomSelection, isTrue);
    },
  );

  test('saveSelection persists only available packages', () async {
    final viewModel = AppSelectionViewModel(
      repository: _FakeNativeVpnRepository(
        apps: const <DeviceApp>[
          DeviceApp(packageName: 'app.one', label: 'App One'),
          DeviceApp(packageName: 'app.two', label: 'App Two'),
        ],
      ),
    );
    await viewModel.ensureLoaded();

    await viewModel.saveSelection(<String>{'app.two', 'ghost.app'});

    expect(viewModel.selectedPackages, <String>{'app.two'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('selected_app_packages'), <String>['app.two']);
  });

  test('ensureLoaded on macOS uses installed apps and persisted selection', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'selected_app_packages': <String>['com.apple.Safari'],
    });
    final viewModel = AppSelectionViewModel(
      repository: _FakeNativeVpnRepository(
        apps: const <DeviceApp>[
          DeviceApp(packageName: 'com.apple.Safari', label: 'Safari'),
          DeviceApp(packageName: 'com.apple.TextEdit', label: 'TextEdit'),
        ],
      ),
    );

    await viewModel.ensureLoaded();

    expect(viewModel.isLoaded, isTrue);
    expect(viewModel.apps.length, 2);
    expect(viewModel.apps.first.packageName, 'com.apple.Safari');
    expect(viewModel.selectedPackages, <String>{'com.apple.Safari'});
  });

  test('pickApps persists selected packages on macOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final viewModel = AppSelectionViewModel(
      repository: _FakeNativeVpnRepository(
        apps: const <DeviceApp>[],
        pickedApps: <DeviceApp>[
          const DeviceApp(packageName: 'com.apple.TextEdit', label: 'TextEdit'),
          const DeviceApp(packageName: 'com.apple.Safari', label: 'Safari'),
          const DeviceApp(packageName: 'com.apple.Safari', label: 'Safari'),
        ],
      ),
    );

    await viewModel.pickApps();

    expect(viewModel.allPackages, <String>[
      'com.apple.Safari',
      'com.apple.TextEdit',
    ]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('selected_app_packages'), <String>[
      'com.apple.Safari',
      'com.apple.TextEdit',
    ]);
  });
}

class _FakeNativeVpnRepository extends NativeVpnRepository {
  _FakeNativeVpnRepository({required this.apps, List<DeviceApp>? pickedApps})
    : pickedApps = pickedApps ?? apps,
      super(dao: const NativeVpnDao());

  final List<DeviceApp> apps;
  final List<DeviceApp> pickedApps;

  @override
  Future<List<DeviceApp>> listInstalledApps() async => apps;

  @override
  Future<List<DeviceApp>> pickInstalledApps() async => pickedApps;
}
