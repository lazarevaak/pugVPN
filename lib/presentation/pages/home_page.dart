import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/core/config/app_env.dart';
import 'package:pug_vpn/core/providers.dart';
import 'package:pug_vpn/domain/entities/device_key_pair.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/localization/app_strings.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';
import 'package:pug_vpn/presentation/widgets/location_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final BackendRepository _backend;
  late final NativeVpnRepository _nativeVpn;
  Timer? _vpnStatusTimer;

  bool _isConnecting = false;
  bool _isConnected = false;
  String _location = 'Auto';
  String _locationDetails = 'Fastest location';
  String _statusLabel = 'Disconnected';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _backend = createBackendRepository();
    _nativeVpn = createNativeVpnRepository();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
      value: 1.0,
    );
    _startVpnStatusPolling();
    unawaited(_syncVpnStatusOnce());
  }

  @override
  void dispose() {
    _vpnStatusTimer?.cancel();
    _backend.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_isConnecting) return;

    if (_isConnected) {
      await _disconnect();
      return;
    }

    await _connect();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    _controller.repeat(reverse: true);

    try {
      debugPrint('[VPN] connect: start');
      await _ensureTunnelStoppedBeforeConnect();
      setState(() {
        _statusLabel = 'Preparing device...';
      });
      debugPrint('[VPN] connect: load or create device key pair');
      final keyPair = await _loadOrCreateDeviceKeyPair();
      debugPrint('[VPN] connect: device key pair ready');
      if (!mounted) return;
      setState(() {
        _statusLabel = 'Authorizing...';
      });
      debugPrint('[VPN] connect: login request');
      final token = await _backend.login(
        email: AppEnv.backendEmail,
        password: AppEnv.backendPassword,
      );
      debugPrint('[VPN] connect: login success');
      if (!mounted) return;
      setState(() {
        _statusLabel = 'Loading servers...';
      });
      debugPrint('[VPN] connect: fetchServers request');
      final servers = await _backend.fetchServers(accessToken: token);
      debugPrint(
        '[VPN] connect: fetchServers success (${servers.length} servers)',
      );
      if (servers.isEmpty) {
        throw Exception('Backend returned no VPN servers.');
      }

      final server = servers.first;
      if (!mounted) return;
      setState(() {
        _statusLabel = 'Preparing VPN config...';
      });
      debugPrint('[VPN] connect: buildConfig request for ${server.id}');
      final configResult = await _backend.buildConfig(
        accessToken: token,
        serverId: server.id,
        deviceName: _buildDeviceName(),
        devicePublicKey: keyPair.publicKeyBase64,
      );
      debugPrint('[VPN] connect: buildConfig success');

      if (configResult.protocol != 'amneziawg') {
        throw Exception(
          'Unsupported protocol "${configResult.protocol}", expected amneziawg.',
        );
      }

      final preparedConfig = configResult.vpnConf.replaceFirst(
        '<CLIENT_PRIVATE_KEY_FROM_DEVICE>',
        keyPair.privateKeyBase64,
      );
      debugPrint('[VPN] connect: private key injected');
      final configForConnection = _isAndroidRuntime
          ? await _applySelectedAppsToConfig(preparedConfig)
          : preparedConfig;
      debugPrint('[VPN] connect: native config prepared');

      if (_isAndroidRuntime || _isIosRuntime) {
        if (!mounted) return;
        setState(() {
          _statusLabel = 'Starting tunnel...';
        });
        debugPrint('[VPN] connect: prepare native tunnel');
        final granted = await _nativeVpn.prepare();
        debugPrint('[VPN] connect: prepare native tunnel result=$granted');
        if (!granted) {
          throw Exception('VPN permission not granted.');
        }

        debugPrint('[VPN] connect: native connect request');
        final connected = await _nativeVpn.connect(
          config: configForConnection,
          tunnelName: 'pugvpn',
        );
        debugPrint('[VPN] connect: native connect result=$connected');
        if (!connected) {
          throw Exception('Native VPN backend returned isUp=false.');
        }
      }

      if (!mounted) return;
      debugPrint('[VPN] connect: success, start status polling');
      _startVpnStatusPolling();
      context.read<TabViewModel>().setConnection(
        isConnected: true,
        location: server.location,
        details: server.name,
      );
      setState(() {
        _location = server.location;
        _locationDetails = server.name;
        _isConnected = true;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint('[VPN] connect: error=$error');
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        _controller
          ..stop()
          ..value = 1.0;
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<DeviceKeyPair> _loadOrCreateDeviceKeyPair() async {
    final existing = await _nativeVpn.loadDeviceKeyPair();
    if (existing != null) {
      return existing;
    }

    final keyPair = await DeviceKeyPair.generate();
    await _nativeVpn.saveDeviceKeyPair(keyPair);
    return keyPair;
  }

  Future<void> _disconnect() async {
    try {
      _vpnStatusTimer?.cancel();
      _vpnStatusTimer = null;
      if (_isAndroidRuntime || _isIosRuntime) {
        await _nativeVpn.disconnect();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        context.read<TabViewModel>().setConnection(
          isConnected: false,
          location: 'RU',
          details: 'Russia',
        );
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _shareApp() async {
    const shareText =
        'PugVPN\nSecure. Fast. Private.\nDownload and try the app.';
    await _nativeVpn.shareText(shareText);
  }

  Future<void> _ensureTunnelStoppedBeforeConnect() async {
    if (!_isAndroidRuntime && !_isIosRuntime) {
      return;
    }

    final status = await _nativeVpn.status();
    final state = (status['state'] as String? ?? 'down').toLowerCase();
    final isConnected = status['is_connected'] as bool? ?? false;
    if (!isConnected &&
        state != 'up' &&
        state != 'connecting' &&
        state != 'reasserting' &&
        state != 'disconnecting') {
      return;
    }

    debugPrint('[VPN] connect: stale tunnel state=$state, forcing disconnect');
    await _nativeVpn.disconnect();
    for (var attempt = 0; attempt < 10; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final currentStatus = await _nativeVpn.status();
      final currentState = (currentStatus['state'] as String? ?? 'down')
          .toLowerCase();
      final currentConnected = currentStatus['is_connected'] as bool? ?? false;
      if (!currentConnected &&
          currentState != 'up' &&
          currentState != 'connecting' &&
          currentState != 'reasserting' &&
          currentState != 'disconnecting') {
        return;
      }
    }

    throw Exception('Previous VPN tunnel is still shutting down.');
  }

  Future<void> _syncVpnStatusOnce() async {
    if (!_isAndroidRuntime && !_isIosRuntime) {
      return;
    }

    try {
      final status = await _nativeVpn.status();
      if (!mounted) return;
      _applyNativeVpnStatus(status);
    } catch (_) {
      // Ignore initial status sync errors.
    }
  }

  void _startVpnStatusPolling() {
    _vpnStatusTimer?.cancel();
    if (!_isAndroidRuntime && !_isIosRuntime) {
      return;
    }

    _vpnStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;

      try {
        final status = await _nativeVpn.status();
        if (!mounted) return;
        _applyNativeVpnStatus(status);
      } catch (_) {
        // Ignore transient native status errors and keep existing UI state.
      }
    });
  }

  void _applyNativeVpnStatus(Map<String, dynamic> status) {
    final state = (status['state'] as String? ?? 'down').toLowerCase();
    final isConnected = status['is_connected'] as bool? ?? false;

    if (isConnected || state == 'up') {
      if (!_isConnected || _isConnecting || _statusLabel != 'Connected') {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _statusLabel = 'Connected';
          _errorMessage = null;
        });
      }
      return;
    }

    if (state == 'connecting' || state == 'reasserting') {
      if (!_isConnecting || _statusLabel != 'Connecting...') {
        setState(() {
          _isConnecting = true;
          _statusLabel = 'Connecting...';
        });
      }
      return;
    }

    if (_isConnected || _isConnecting || _statusLabel != 'Disconnected') {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _statusLabel = 'Disconnected';
      });
    }
  }

  Future<String> _applySelectedAppsToConfig(String config) async {
    final appSelectionVm = context.read<AppSelectionViewModel>();
    await appSelectionVm.ensureLoaded();
    final allPackages = appSelectionVm.allPackages;
    final selectedPackages = appSelectionVm.selectedPackages.toList(
      growable: false,
    );

    if (allPackages.isEmpty || selectedPackages.length == allPackages.length) {
      return _stripApplicationRules(config);
    }

    final rules = <String>[
      if (selectedPackages.isEmpty)
        'ExcludedApplications = ${allPackages.join(", ")}'
      else
        'IncludedApplications = ${selectedPackages.join(", ")}',
    ];
    return _insertApplicationRules(config, rules);
  }

  String _stripApplicationRules(String config) {
    final lines = config.split('\n');
    return lines
        .where(
          (String line) =>
              !line.trimLeft().startsWith('IncludedApplications =') &&
              !line.trimLeft().startsWith('ExcludedApplications ='),
        )
        .join('\n');
  }

  String _insertApplicationRules(String config, List<String> rules) {
    final lines = _stripApplicationRules(config).split('\n');
    final interfaceIndex = lines.indexWhere(
      (String line) => line.trim() == '[Interface]',
    );
    if (interfaceIndex == -1) {
      return config;
    }

    lines.insertAll(interfaceIndex + 1, rules);
    return lines.join('\n');
  }

  String _buildDeviceName() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
    return 'pug-$platform-$ts';
  }

  bool get _isAndroidRuntime =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIosRuntime =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String get _displayLocation => _isConnected ? _location : 'RU';

  String get _displayLocationDetails =>
      _isConnected ? _locationDetails : 'Russia';

  String get _selectedCountryImageAsset => _countryImageAsset(_displayLocation);
  String get _selectedFlagAsset => _flagAsset(_displayLocation);

  String _countryImageAsset(String value) {
    final normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'FI':
      case 'FINLAND':
        return 'assets/pug_countries/pug_finland.png';
      case 'DE':
      case 'GERMANY':
        return 'assets/pug_countries/pug_germany.png';
      case 'US':
      case 'USA':
      case 'UNITED STATES':
        return 'assets/pug_countries/pug_usa.png';
      case 'RU':
      case 'RUSSIA':
        return 'assets/pug_countries/pug_russia.png';
      default:
        return 'assets/images/pug_vpn.png';
    }
  }

  String _flagAsset(String value) {
    final normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'FI':
      case 'FINLAND':
        return 'assets/flags/finland_flag.png';
      case 'DE':
      case 'GERMANY':
        return 'assets/flags/germany_flag.png';
      case 'US':
      case 'USA':
      case 'UNITED STATES':
        return 'assets/flags/usa_flag.png';
      case 'RU':
      case 'RUSSIA':
      default:
        return 'assets/flags/russia_flag.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final strings = AppStrings.of(context);
    final buttonLabel = _isConnecting
        ? strings.connecting
        : _isConnected
        ? strings.disconnect
        : strings.connect;
    final displayStatusLabel = switch (_statusLabel) {
      'Connected' => strings.connected,
      'Connecting...' => strings.connecting,
      'Disconnected' => strings.disconnected,
      'Preparing device...' => strings.connecting,
      'Authorizing...' => strings.connecting,
      'Loading servers...' => strings.connecting,
      'Preparing VPN config...' => strings.connecting,
      'Starting tunnel...' => strings.connecting,
      _ => _statusLabel,
    };

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
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/images/world_map.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final imageSize = (constraints.maxHeight * 0.34).clamp(180.0, 260.0);

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 126),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: <Widget>[
                          Image.asset('assets/images/pug_icon.png', height: 38),
                          const SizedBox(width: 12),
                          Text(
                            strings.appName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: palette.primaryText,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _shareApp,
                            icon: Icon(
                              Icons.share_rounded,
                              color: palette.secondaryText,
                              size: 26,
                            ),
                            tooltip: strings.shareApp,
                            splashRadius: 22,
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<TabViewModel>().changeTab(2),
                            icon: Icon(
                              Icons.settings,
                              color: palette.secondaryText,
                              size: 28,
                            ),
                            splashRadius: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LocationCard(
                        location: _displayLocation,
                        details: _displayLocationDetails,
                        imageAsset: _selectedFlagAsset,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: imageSize + 28,
                      child: Align(
                        alignment: const Alignment(0, -0.15),
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
                                    ).withValues(alpha: 0.15),
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
                                  sigmaX: _isConnecting ? 0.25 : 0,
                                  sigmaY: _isConnecting ? 0.25 : 0,
                                ),
                                child: Image.asset(
                                  _selectedCountryImageAsset,
                                  width: imageSize + 120,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isConnecting ? null : _toggleConnection,
                      child: Container(
                        width: 300,
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palette.isDark
                                ? const <Color>[Color(0xFF2C3F55), Color(0xFF1A2636)]
                                : const <Color>[Color(0xFF7DE0BE), Color(0xFF32BDA0)],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: palette.isDark
                                  ? Colors.black.withValues(alpha: 0.8)
                                  : const Color(0xFF7CD9BF).withValues(alpha: 0.42),
                              blurRadius: 34,
                              offset: const Offset(0, 25),
                            ),
                            BoxShadow(
                              color: const Color(0xFF4EFFC5).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.power_settings_new,
                              color: Color(0xFF4EFFC5),
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
                      style: TextStyle(color: palette.tertiaryText, fontSize: 14),
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
                          color: _isConnected
                              ? const Color(0xFF4EFFC5)
                              : _isConnecting
                              ? const Color(0xFFFFE082)
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
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
