import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/localization/app_strings.dart';

import 'package:pug_vpn/presentation/pages/home/locations_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';

import 'package:pug_vpn/presentation/viewmodels/home_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';
import 'package:pug_vpn/presentation/widgets/location_card.dart';
import 'package:pug_vpn/presentation/widgets/location_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpeningLocations = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final strings = AppStrings.of(context);
    final vm = context.watch<HomeViewModel>();
    final tabVm = context.read<TabViewModel>();

    if (vm.isConnecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1.0;
    }

    final buttonLabel = vm.isConnecting
        ? strings.connecting
        : vm.isConnected
        ? strings.disconnect
        : strings.connect;
    final displayStatusLabel = switch (vm.statusLabel) {
      'Connected' => strings.connected,
      'Connecting...' => strings.connecting,
      'Disconnected' => strings.disconnected,
      'Preparing device...' => strings.connecting,
      'Authorizing...' => strings.connecting,
      'Loading servers...' => strings.connecting,
      'Preparing VPN config...' => strings.connecting,
      'Starting tunnel...' => strings.connecting,
      _ => vm.statusLabel,
    };

    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.2,
              colors: palette.backgroundGradient,
              stops: const <double>[0.0, 0.6, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: palette.isDark ? 0.08 : 0.12,
            child: Image.asset(
              'assets/images/world_map.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final imageSize = (constraints.maxHeight * 0.62).clamp(
                270.0,
                500.0,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 126),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: <Widget>[
                          Image.asset('assets/images/pug_icon.png', height: 54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: palette.primaryText,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: vm.shareApp,
                            icon: Icon(
                              Icons.share_rounded,
                              color: palette.secondaryText,
                              size: 24,
                            ),
                            tooltip: strings.shareApp,
                            visualDensity: VisualDensity.compact,
                            splashRadius: 20,
                          ),
                          IconButton(
                            onPressed: () => tabVm.changeTab(1),
                            icon: Icon(
                              Icons.settings,
                              color: palette.secondaryText,
                              size: 24,
                            ),
                            visualDensity: VisualDensity.compact,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LocationCard(
                        location: vm.displayLocation,
                        details: vm.displayLocationDetails,
                        imageAsset: LocationAsset.fromValue(
                          vm.displayCountryName,
                        ).flagAsset,
                        isOpening: _isOpeningLocations,
                        onTap: () async {
                          if (_isOpeningLocations) return;
                          final navigator = Navigator.of(context);
                          setState(() {
                            _isOpeningLocations = true;
                          });
                          await Future<void>.delayed(
                            const Duration(milliseconds: 180),
                          );
                          if (!mounted) return;
                          await navigator.push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LocationsPage(),
                            ),
                          );
                          if (!mounted) return;
                          setState(() {
                            _isOpeningLocations = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 0),
                    SizedBox(
                      height: imageSize - 132,
                      child: Align(
                        alignment: const Alignment(0, 0.34),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4EFFC5,
                                    ).withValues(
                                      alpha: palette.isDark ? 0.15 : 0.10,
                                    ),
                                    blurRadius: 120,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            ScaleTransition(
                              scale: _controller,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: vm.isConnecting ? 0.25 : 0,
                                  sigmaY: vm.isConnecting ? 0.25 : 0,
                                ),
                                child: Image.asset(
                                  LocationAsset.fromValue(
                                    vm.displayCountryName,
                                  ).countryImageAsset,
                                  width: imageSize + 260,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: vm.isConnecting ? null : vm.toggleConnection,
                      child: Container(
                        width: 360,
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palette.isDark
                                ? const <Color>[
                                    Color(0xFF2C3F55),
                                    Color(0xFF1A2636),
                                  ]
                                : const <Color>[
                                    Color(0xFF7DE0BE),
                                    Color(0xFF32BDA0),
                                  ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: palette.isDark
                                  ? Colors.black.withValues(alpha: 0.8)
                                  : const Color(
                                      0xFF7CD9BF,
                                    ).withValues(alpha: 0.42),
                              blurRadius: 34,
                              offset: const Offset(0, 25),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF4EFFC5,
                              ).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.power_settings_new,
                              color: palette.isDark
                                  ? const Color(0xFF4EFFC5)
                                  : Colors.white,
                              size: 30,
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  buttonLabel,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.tapToSecure,
                      style: TextStyle(
                        color: palette.tertiaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        displayStatusLabel,
                        key: ValueKey<String>(displayStatusLabel),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: vm.isConnected
                              ? const Color(0xFF4EFFC5)
                              : vm.isConnecting
                              ? const Color(0xFFFFE082)
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                    if (vm.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          vm.errorMessage!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
