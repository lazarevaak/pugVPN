import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/localization/app_strings.dart';
import 'package:pug_vpn/presentation/pages/premium/premium_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/home_viewmodel.dart';
import 'package:pug_vpn/presentation/widgets/location_item.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  int _selectedIndex = 0;
  static const List<LocationItem> _baseItems = <LocationItem>[
    LocationItem(country: 'Auto'),
    LocationItem(country: 'Finland'),
    LocationItem(country: 'Germany'),
    LocationItem(country: 'United States'),
  ];

  @override
  void initState() {
    super.initState();
    final homeVm = context.read<HomeViewModel>();
    final currentLocation = homeVm.isConnected ? homeVm.location : 'Auto';
    final index = _baseItems.indexWhere(
      (LocationItem item) => _matchesConnectedLocation(item.country, currentLocation),
    );
    if (index >= 0) {
      _selectedIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final items = _baseItems;
    final palette = AppPalette.of(context);
    final strings = AppStrings.of(context);
    final topInset = defaultTargetPlatform == TargetPlatform.macOS ? 28.0 : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          _LocationsBackground(palette: palette),
          SafeArea(
            minimum: EdgeInsets.only(top: topInset),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: <Widget>[
                  _PageHeader(
                    palette: palette,
                    title: strings.locationsTitle,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 28),
                      children: <Widget>[
                        _ConnectionSummary(
                          isConnected: homeVm.isConnected,
                          location: homeVm.location,
                          details: homeVm.locationDetails,
                          palette: palette,
                          strings: strings,
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel(
                          palette: palette,
                          title: 'Available regions',
                          subtitle: '${items.length} locations ready',
                        ),
                        const SizedBox(height: 12),
                        ...List<Widget>.generate(items.length, (int index) {
                          final item = items[index];
                          final isSelected = index == _selectedIndex;
                          final isConnectedTo = homeVm.isConnected &&
                              _matchesConnectedLocation(
                                item.country,
                                homeVm.location,
                              );
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == items.length - 1 ? 0 : 12,
                            ),
                            child: _LocationCard(
                              item: item,
                              isSelected: isSelected,
                              isConnectedTo: isConnectedTo,
                              isLoading:
                                  homeVm.isConnecting && isSelected,
                              onTap: () {
                                if (item.isPremium) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const PremiumPage(),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _selectedIndex = index;
                                });
                                final viewModel = context.read<HomeViewModel>();
                                Navigator.of(context).pop();
                                if (item.country == 'Auto') {
                                  viewModel.connect();
                                  return;
                                }
                                viewModel.connect(preferredLocation: item.country);
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 18),
                        _LocationsPromoBanner(palette: palette),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesConnectedLocation(String country, String connectedLocation) {
    final current = connectedLocation.trim().toUpperCase();
    final item = country.trim().toUpperCase();
    return item == current ||
        (item == 'AUTO' && current == 'AUTO') ||
        (item == 'FINLAND' && current == 'FI') ||
        (item == 'GERMANY' && current == 'DE') ||
        (item == 'UNITED STATES' && (current == 'US' || current == 'USA'));
  }
}

class _LocationsBackground extends StatelessWidget {
  const _LocationsBackground({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.24,
          colors: <Color>[
            palette.backgroundGradient.first,
            palette.backgroundGradient[1],
            palette.backgroundGradient.last,
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: -80,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF56F2C4).withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Positioned(
            left: -100,
            bottom: 120,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6D8DFF).withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.palette,
    required this.title,
    required this.onBack,
  });

  final AppPalette palette;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: palette.primaryText,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your fastest exit point',
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({
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
    final accent = isConnected
        ? const Color(0xFF56F2C4)
        : const Color(0xFFFF8A7A);

    return _GlassCard(
      palette: palette,
      borderRadius: 28,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Icon(
                isConnected
                    ? Icons.shield_rounded
                    : Icons.wifi_tethering_error_rounded,
                color: accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isConnected ? 'Protected now' : 'Connection status',
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isConnected
                        ? strings.connectedTo(location)
                        : strings.notConnected,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isConnected && details.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        color: palette.tertiaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Pick a region below and start a secure route.',
                      style: TextStyle(
                        color: palette.tertiaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.palette,
    required this.title,
    required this.subtitle,
  });

  final AppPalette palette;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.item,
    required this.isSelected,
    required this.isConnectedTo,
    required this.isLoading,
    required this.onTap,
  });

  final LocationItem item;
  final bool isSelected;
  final bool isConnectedTo;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: _GlassCard(
          palette: palette,
          borderRadius: 28,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(color: palette.border),
                  ),
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      item.imageAsset,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.country,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          if (isConnectedTo) ...<Widget>[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF56F2C4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Connected',
                              style: TextStyle(
                                color: const Color(0xFF56F2C4),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else if (item.isPremium) ...<Widget>[
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFE8C86B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Color(0xFFE8C86B),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else ...<Widget>[
                            Text(
                              'Available',
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? item.accent.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isSelected
                          ? item.accent.withValues(alpha: 0.45)
                          : palette.border,
                    ),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              item.accent,
                            ),
                          ),
                        )
                      : Icon(
                          isSelected
                              ? Icons.check_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: isSelected ? item.accent : palette.secondaryText,
                          size: isSelected ? 16 : 14,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationsPromoBanner extends StatelessWidget {
  const _LocationsPromoBanner({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      palette: palette,
      borderRadius: 28,
      gradient: <Color>[
        const Color(0xFF5E7EFF).withValues(alpha: 0.28),
        const Color(0xFF152133).withValues(alpha: 0.96),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Color(0xFFFFDE8A),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Watch one ad, unlock premium route',
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Open sponsored access and try a faster region for free.',
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFFFDE8A).withValues(alpha: 0.16),
                border: Border.all(
                  color: const Color(0xFFFFDE8A).withValues(alpha: 0.28),
                ),
              ),
              child: const Text(
                'Watch',
                style: TextStyle(
                  color: Color(0xFFFFEFC3),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.palette,
    required this.borderRadius,
    required this.child,
    this.gradient,
  });

  final AppPalette palette;
  final double borderRadius;
  final Widget child;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient ?? palette.cardGradient,
            ),
            border: Border.all(color: palette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -18,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
