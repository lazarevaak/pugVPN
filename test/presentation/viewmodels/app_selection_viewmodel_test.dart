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

  test('ensureLoaded selects all apps when there is no persisted selection', () async {
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
  });

  test('ensureLoaded restores persisted selection and filters missing packages', () async {
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
  });

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
    expect(
      prefs.getStringList('selected_app_packages'),
      <String>['app.two'],
    );
  });
}

class _FakeNativeVpnRepository extends NativeVpnRepository {
  _FakeNativeVpnRepository({required this.apps}) : super(dao: const NativeVpnDao());

  final List<DeviceApp> apps;

  @override
  Future<List<DeviceApp>> listInstalledApps() async => apps;
}
