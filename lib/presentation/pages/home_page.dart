import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pug_vpn/core/config/app_env.dart';
import 'package:pug_vpn/core/providers.dart';
import 'package:pug_vpn/domain/entities/device_key_pair.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
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
  }

  @override
  void dispose() {
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
      _statusLabel = 'Connecting...';
    });
    _controller.repeat(reverse: true);

    try {
      final keyPair = await DeviceKeyPair.generate();
      final token = await _backend.login(
        email: AppEnv.backendEmail,
        password: AppEnv.backendPassword,
      );
      final servers = await _backend.fetchServers(accessToken: token);
      if (servers.isEmpty) {
        throw Exception('Backend returned no VPN servers.');
      }

      final server = servers.first;
      final configResult = await _backend.buildConfig(
        accessToken: token,
        serverId: server.id,
        deviceName: _buildDeviceName(),
        devicePublicKey: keyPair.publicKeyBase64,
      );

      if (configResult.protocol != 'amneziawg') {
        throw Exception(
          'Unsupported protocol "${configResult.protocol}", expected amneziawg.',
        );
      }

      final preparedConfig = configResult.vpnConf.replaceFirst(
        '<CLIENT_PRIVATE_KEY_FROM_DEVICE>',
        keyPair.privateKeyBase64,
      );
      await Clipboard.setData(ClipboardData(text: preparedConfig));

      if (_isAndroidRuntime || _isIosRuntime) {
        final granted = await _nativeVpn.prepare();
        if (!granted) {
          throw Exception('VPN permission not granted.');
        }

        final connected = await _nativeVpn.connect(
          config: preparedConfig,
          tunnelName: 'pugvpn',
        );
        if (!connected) {
          throw Exception('Native VPN backend returned isUp=false.');
        }
      }

      if (!mounted) return;
      setState(() {
        _location = server.location;
        _locationDetails = server.name;
        _isConnected = true;
        _statusLabel = 'Connected';
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _statusLabel = 'Disconnected';
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

  Future<void> _disconnect() async {
    try {
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
        setState(() {
          _isConnected = false;
          _isConnecting = false;
          _statusLabel = 'Disconnected';
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final buttonLabel = _isConnecting
        ? 'CONNECTING...'
        : _isConnected
        ? 'DISCONNECT'
        : 'CONNECT';

    return Scaffold(
      backgroundColor: const Color(0xFF050D18),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: <Color>[
                  Color(0xFF1E2C3F),
                  Color(0xFF0A1625),
                  Color(0xFF050D18),
                ],
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
            child: Column(
              children: <Widget>[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: <Widget>[
                      Image.asset('assets/images/pug_icon.png', height: 38),
                      const SizedBox(width: 12),
                      const Text(
                        'PugVPN',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.settings,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LocationCard(
                    location: _location,
                    details: _locationDetails,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Container(
                          width: 260,
                          height: 260,
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
                              'assets/images/pug_vpn.png',
                              width: 380,
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF2C3F55), Color(0xFF1A2636)],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 40,
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
                        const Icon(
                          Icons.power_settings_new,
                          color: Color(0xFF4EFFC5),
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap to secure your connection',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusLabel,
                    key: ValueKey<String>(_statusLabel),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
