import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/localization/app_strings.dart';
import 'package:pug_vpn/presentation/pages/home_page.dart';
import 'package:pug_vpn/presentation/pages/locations_page.dart';
import 'package:pug_vpn/presentation/pages/premium_page.dart';
import 'package:pug_vpn/presentation/pages/settings_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TabViewModel>();
    final palette = AppPalette.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IndexedStack(
              index: vm.index,
              children: <Widget>[
                const HomePage(),
                const LocationsPage(),
                const SettingsPage(),
                const PremiumPage(),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _GlassTabBar(
              selectedIndex: vm.index,
              onSelected: vm.changeTab,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final strings = AppStrings.of(context);
    final items = <({IconData icon, String label})>[
      (icon: Icons.home_rounded, label: strings.homeTab),
      (icon: Icons.location_on_rounded, label: strings.locationsTab),
      (icon: Icons.settings_rounded, label: strings.settingsTab),
      (icon: Icons.workspace_premium_rounded, label: strings.premiumTab),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.tabShadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[palette.tabTop, palette.tabBottom],
              ),
              border: Border.all(color: palette.border),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 18,
                  right: 18,
                  top: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(items.length, (int index) {
                    final item = items[index];
                    return Expanded(
                      child: Row(
                        children: <Widget>[
                          if (index > 0)
                            Container(
                              width: 1,
                              height: 32,
                              color: palette.border,
                            ),
                          Expanded(
                            child: _NavItem(
                              icon: item.icon,
                              label: item.label,
                              active: selectedIndex == index,
                              palette: palette,
                              onTap: () => onSelected(index),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? palette.activeTab : palette.inactiveTab;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: active
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF8FBEFF).withValues(alpha: 0.20),
                          blurRadius: 16,
                          spreadRadius: -6,
                        ),
                      ],
                    )
                  : null,
              child: Icon(icon, color: color, size: 24),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
