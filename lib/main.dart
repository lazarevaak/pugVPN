import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/pages/onboarding_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';
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
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<TabViewModel>(create: (_) => TabViewModel()),
        ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider<LanguageViewModel>(
          create: (_) => LanguageViewModel(),
        ),
        ChangeNotifierProvider<AppSelectionViewModel>(
          create: (_) => AppSelectionViewModel(),
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
