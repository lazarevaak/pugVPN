import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/core/providers.dart';

import 'package:pug_vpn/presentation/pages/entrance/onboarding_page.dart';

import 'package:pug_vpn/presentation/theme/app_theme.dart';

import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/home_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/language_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/theme_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TabViewModel>(create: (_) => TabViewModel()),
        ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider<LanguageViewModel>(
          create: (_) => LanguageViewModel(),
        ),
        ChangeNotifierProvider<AppSelectionViewModel>(
          create: (_) => AppSelectionViewModel(),
        ),
        ChangeNotifierProxyProvider<AppSelectionViewModel, HomeViewModel>(
          create: (BuildContext context) => HomeViewModel(
            appSelectionViewModel: context.read<AppSelectionViewModel>(),
            connectVpnUseCase: createConnectVpnUseCase(),
            disconnectVpnUseCase: createDisconnectVpnUseCase(),
            getVpnStatusUseCase: createGetVpnStatusUseCase(),
            shareAppUseCase: createShareAppUseCase(),
          )..initialize(),
          update: (_, appSelectionVm, homeVm) =>
              homeVm ??
              HomeViewModel(
                appSelectionViewModel: appSelectionVm,
                connectVpnUseCase: createConnectVpnUseCase(),
                disconnectVpnUseCase: createDisconnectVpnUseCase(),
                getVpnStatusUseCase: createGetVpnStatusUseCase(),
                shareAppUseCase: createShareAppUseCase(),
              )..initialize(),
        ),
      ],
      child: Consumer2<ThemeViewModel, LanguageViewModel>(
        builder: (
          BuildContext context,
          ThemeViewModel themeVm,
          LanguageViewModel languageVm,
          _,
        ) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeVm.themeMode,
            locale: languageVm.locale,
            home: const OnboardingPage(),
          );
        },
      ),
    );
  }
}
