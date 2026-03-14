import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/localization/app_strings.dart';
import 'package:pug_vpn/presentation/pages/select_apps_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/home_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/language_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/theme_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final themeVm = context.watch<ThemeViewModel>();
    final languageVm = context.watch<LanguageViewModel>();
    final strings = AppStrings.of(context);

    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.2,
              colors: palette.backgroundGradient,
              stops: <double>[0.0, 0.6, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 146),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.read<TabViewModel>().changeTab(0),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: palette.secondaryText,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.settingsTitle,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SettingsSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  title: strings.darkMode,
                  value: themeVm.isDarkMode,
                  palette: palette,
                  activeColor: const Color(0xFF8CABFF),
                  onChanged: (bool value) {
                    context.read<ThemeViewModel>().setDarkMode(value);
                  },
                ),
                const SizedBox(height: 18),
                _SettingsActionTile(
                  icon: Icons.person_rounded,
                  title: strings.account,
                  subtitle: 'demo@pugvpn.app',
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.language_rounded,
                  title: strings.language,
                  subtitle: languageVm.displayName,
                  palette: palette,
                  onTap: () => _showLanguagePicker(context),
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.apps_rounded,
                  title: strings.selectApps,
                  palette: palette,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SelectAppsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.share_rounded,
                  title: strings.shareApp,
                  palette: palette,
                  onTap: () => _shareApp(context),
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.workspace_premium_rounded,
                  title: strings.subscription,
                  palette: palette,
                  onTap: () => context.read<TabViewModel>().changeTab(3),
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.info_rounded,
                  title: strings.about,
                  palette: palette,
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final palette = AppPalette.of(context);
    final languageVm = context.read<LanguageViewModel>();
    final strings = AppStrings.fromLanguage(languageVm.isRussian);

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: palette.cardGradient.last,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.languageChoice,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LanguageTile(
                  label: strings.english,
                  selected: languageVm.language == AppLanguage.english,
                  onTap: () {
                    languageVm.setLanguage(AppLanguage.english);
                    Navigator.of(dialogContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                _LanguageTile(
                  label: strings.russian,
                  selected: languageVm.language == AppLanguage.russian,
                  onTap: () {
                    languageVm.setLanguage(AppLanguage.russian);
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    await context.read<HomeViewModel>().shareApp();
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final palette = AppPalette.of(context);
    final strings = AppStrings.fromLanguage(
      context.read<LanguageViewModel>().isRussian,
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: palette.cardGradient.last,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            strings.aboutTitle,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            strings.aboutBody,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.close),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? palette.softFill : Colors.transparent,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF56F2C4),
              ),
          ],
        ),
      ),
    );
  }
}


class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.palette,
    this.activeColor = const Color(0xFF9FD6B7),
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppPalette palette;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      palette: palette,
      child: Row(
        children: <Widget>[
          _LeadingIcon(icon: icon, palette: palette),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: activeColor,
            inactiveThumbColor:
                palette.isDark ? Colors.white54 : const Color(0xFFFDFEFF),
            inactiveTrackColor:
                palette.isDark ? Colors.white24 : const Color(0xFFD7E0ED),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.palette,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final AppPalette palette;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      palette: palette,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: <Widget>[
              _LeadingIcon(icon: icon, palette: palette),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.secondaryText,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, required this.palette});

  final Widget child;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.cardGradient,
            ),
            border: Border.all(color: palette.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.palette});

  final IconData icon;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: palette.softFill,
      ),
      child: Icon(icon, color: palette.secondaryText, size: 20),
    );
  }
}
