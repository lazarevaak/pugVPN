import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/localization/app_strings.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  int _selectedIndex = 0;

  static const List<_LocationItem> _items = <_LocationItem>[
    _LocationItem(
      country: 'Russia',
      subtitle: '',
      imageAsset: 'assets/flags/russia_flag.png',
      accent: Color(0xFFB9EA8B),
      isPremium: false,
    ),
    _LocationItem(
      country: 'Finland',
      subtitle: '',
      imageAsset: 'assets/flags/finland_flag.png',
      accent: Color(0xFF9BCBFF),
      isPremium: false,
    ),
    _LocationItem(
      country: 'Germany',
      subtitle: 'Premium',
      imageAsset: 'assets/flags/germany_flag.png',
      accent: Color(0xFF9BCBFF),
      isPremium: true,
    ),
    _LocationItem(
      country: 'United States',
      subtitle: 'Premium',
      imageAsset: 'assets/flags/usa_flag.png',
      accent: Color(0xFF8EE7A8),
      isPremium: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TabViewModel>();
    final palette = AppPalette.of(context);
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
                      strings.locationsTitle,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ConnectionBanner(
                  isConnected: vm.isConnected,
                  location: vm.connectedLocation,
                  details: vm.connectedDetails,
                  palette: palette,
                  strings: strings,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 112),
                    itemBuilder: (BuildContext context, int index) {
                      final item = _items[index];
                      final isSelected = index == _selectedIndex;
                      final isConnectedTo = vm.isConnected &&
                          _matchesConnectedLocation(
                            item.country,
                            vm.connectedLocation,
                          );
                      return _LocationRow(
                        item: item,
                        isConnectedTo: isConnectedTo,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _items.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _matchesConnectedLocation(String country, String connectedLocation) {
    final current = connectedLocation.trim().toUpperCase();
    final item = country.trim().toUpperCase();
    return item == current ||
        (item == 'RUSSIA' && current == 'RU') ||
        (item == 'FINLAND' && current == 'FI') ||
        (item == 'GERMANY' && current == 'DE') ||
        (item == 'UNITED STATES' && (current == 'US' || current == 'USA'));
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.item,
    required this.isConnectedTo,
    required this.isSelected,
    required this.onTap,
  });

  final _LocationItem item;
  final bool isConnectedTo;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = item.subtitle.isNotEmpty;
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? <Color>[
                        palette.cardGradient.first.withValues(alpha: 0.95),
                        palette.cardGradient.last,
                      ]
                    : palette.cardGradient,
              ),
              border: Border.all(color: palette.border),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: item.accent.withValues(alpha: 0.10),
                        blurRadius: 20,
                        spreadRadius: -8,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.imageAsset,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasSubtitle
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                        item.country,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: <Widget>[
                                if (item.isPremium) ...<Widget>[
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFE4C46A),
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: item.isPremium
                                        ? const Color(0xFFE4C46A)
                                        : palette.tertiaryText,
                                    fontSize: 14,
                                    fontWeight: item.isPremium
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.country,
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                if (isConnectedTo) ...<Widget>[
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/images/connection_board.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationItem {
  const _LocationItem({
    required this.country,
    required this.subtitle,
    required this.imageAsset,
    required this.accent,
    required this.isPremium,
  });

  final String country;
  final String subtitle;
  final String imageAsset;
  final Color accent;
  final bool isPremium;
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.isConnected,
    required this.location,
    required this.details,
    required this.palette,
    required this.strings,
  });

  final bool isConnected;
  final String location;
  final String details;
  final AppPalette palette;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: palette.softFill,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isConnected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 18,
            color: isConnected ? const Color(0xFF56F2C4) : palette.secondaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? strings.connectedTo(location)
                  : strings.notConnected,
              style: TextStyle(
                color: isConnected ? const Color(0xFF56F2C4) : palette.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isConnected)
            Text(
              details,
              style: TextStyle(
                color: palette.tertiaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
