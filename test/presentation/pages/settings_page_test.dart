import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
import 'package:pug_vpn/presentation/pages/settings_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/home_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/language_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/theme_viewmodel.dart';

void main() {
  testWidgets('language picker changes language to Russian', (WidgetTester tester) async {
    final languageVm = LanguageViewModel();
    await tester.binding.setSurfaceSize(const Size(430, 1000));

    await tester.pumpWidget(
      _wrapWithProviders(
        languageVm: languageVm,
        child: const SettingsPage(),
      ),
    );

    await tester.ensureVisible(find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(languageVm.language, AppLanguage.russian);
    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
  });

  testWidgets('about dialog opens with app description', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const SettingsPage(),
      ),
    );

    await tester.ensureVisible(find.text('About'));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About PUGVPN'), findsOneWidget);
    expect(
      find.textContaining('simple VPN client'),
      findsOneWidget,
    );
  });

  testWidgets('subscription tile switches current tab to premium', (WidgetTester tester) async {
    final tabVm = TabViewModel();
    await tester.binding.setSurfaceSize(const Size(430, 1000));

    await tester.pumpWidget(
      _wrapWithProviders(
        tabVm: tabVm,
        child: const SettingsPage(),
      ),
    );

    await tester.ensureVisible(find.text('Subscription'));
    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();

    expect(tabVm.index, 3);
  });
}

Widget _wrapWithProviders({
  Widget? child,
  TabViewModel? tabVm,
  ThemeViewModel? themeVm,
  LanguageViewModel? languageVm,
  AppSelectionViewModel? appSelectionVm,
  HomeViewModel? homeVm,
}) {
  final resolvedAppSelectionVm =
      appSelectionVm ??
      AppSelectionViewModel(repository: _AppsOnlyNativeRepository());

  final resolvedHomeVm =
      homeVm ??
      HomeViewModel(
        appSelectionViewModel: resolvedAppSelectionVm,
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

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TabViewModel>(
        create: (_) => tabVm ?? TabViewModel(),
      ),
      ChangeNotifierProvider<ThemeViewModel>(
        create: (_) => themeVm ?? ThemeViewModel(),
      ),
      ChangeNotifierProvider<LanguageViewModel>(
        create: (_) => languageVm ?? LanguageViewModel(),
      ),
      ChangeNotifierProvider<AppSelectionViewModel>(
        create: (_) => resolvedAppSelectionVm,
      ),
      ChangeNotifierProvider<HomeViewModel>(
        create: (_) => resolvedHomeVm,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: child ?? const SettingsPage(),
      ),
    ),
  );
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
    return _session;
  }
}

class _FakeDisconnectVpnUseCase extends DisconnectVpnUseCase {
  _FakeDisconnectVpnUseCase()
    : super(
        nativeVpnRepository: const NativeVpnRepository(dao: NativeVpnDao()),
      );
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

  @override
  Future<void> execute() async {}
}
