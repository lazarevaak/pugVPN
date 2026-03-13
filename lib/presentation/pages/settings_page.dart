import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/pages/select_apps_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/theme_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _killSwitch = true;
  bool _autoConnect = true;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final themeVm = context.watch<ThemeViewModel>();

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 18),
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
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSwitchTile(
                  icon: Icons.shield_rounded,
                  title: 'Kill Switch',
                  value: _killSwitch,
                  palette: palette,
                  onChanged: (bool value) {
                    setState(() {
                      _killSwitch = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _SettingsSwitchTile(
                  icon: Icons.lock_rounded,
                  title: 'Auto Connect',
                  value: _autoConnect,
                  palette: palette,
                  onChanged: (bool value) {
                    setState(() {
                      _autoConnect = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _SettingsSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
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
                  title: 'Account',
                  subtitle: 'demo@pugvpn.app',
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.apps_rounded,
                  title: 'Select Apps',
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
                  icon: Icons.workspace_premium_rounded,
                  title: 'Subscription',
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.info_rounded,
                  title: 'About',
                  palette: palette,
                ),
                const Spacer(),
                const SizedBox(height: 112),
              ],
            ),
          ),
        ),
      ],
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
            activeColor: Colors.white,
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
