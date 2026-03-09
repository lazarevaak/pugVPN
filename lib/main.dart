import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const _backendBaseUrlFromEnv = String.fromEnvironment(
  'PUGVPN_BACKEND_URL',
  defaultValue: '',
);
final _backendBaseUrl = _backendBaseUrlFromEnv.isNotEmpty
    ? _backendBaseUrlFromEnv
    : _defaultBackendUrl();

String _defaultBackendUrl() {
  if (!kDebugMode) return 'http://178.17.60.48:8080';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulator reaches host machine via 10.0.2.2.
      return 'http://10.0.2.2:8080';
    default:
      return 'http://127.0.0.1:8080';
  }
}

const _backendEmail = String.fromEnvironment(
  'PUGVPN_BACKEND_EMAIL',
  defaultValue: 'demo@pugvpn.app',
);
const _backendPassword = String.fromEnvironment(
  'PUGVPN_BACKEND_PASSWORD',
  defaultValue: 'demo1234',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConnectScreen(),
    );
  }
}

enum ConnectionStage { idle, connecting, readyToImport, connected, error }

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final BackendClient _backend;
  late final NativeVpnBridge _nativeVpn;

  ConnectionStage _stage = ConnectionStage.idle;
  String _status = 'Нажми Connect';
  String? _errorMessage;
  String? _protocol;
  String? _serverName;
  String? _deviceId;
  String? _preparedConfig;
  bool _showConfig = false;
  final List<String> _steps = <String>[];

  bool get _isBusy => _stage == ConnectionStage.connecting;

  @override
  void initState() {
    super.initState();
    _backend = BackendClient(baseUrl: _backendBaseUrl);
    _nativeVpn = const NativeVpnBridge();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  @override
  void dispose() {
    _backend.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onConnectPressed() async {
    if (_isBusy) return;

    setState(() {
      _stage = ConnectionStage.connecting;
      _status = 'Подключение...';
      _errorMessage = null;
      _protocol = null;
      _serverName = null;
      _deviceId = null;
      _preparedConfig = null;
      _showConfig = false;
      _steps.clear();
    });

    _controller.repeat(reverse: true);

    try {
      _pushStep('1/5 Генерируем ключ устройства локально');
      final keyPair = await DeviceKeyPair.generate();

      _pushStep('2/5 Логин в backend');
      final token = await _backend.login(
        email: _backendEmail,
        password: _backendPassword,
      );

      _pushStep('3/5 Получаем список серверов');
      final servers = await _backend.fetchServers(accessToken: token);
      if (servers.isEmpty) {
        throw const BackendException('Серверов в ответе нет.');
      }
      final server = servers.first;

      _pushStep('4/5 Регистрируем peer и запрашиваем vpn_conf');
      final configResult = await _backend.buildConfig(
        accessToken: token,
        serverId: server.id,
        deviceName: _buildDeviceName(),
        devicePublicKey: keyPair.publicKeyBase64,
      );

      _pushStep('5/5 Собираем итоговый конфиг (вставляем private key)');
      final finalConfig = configResult.vpnConf.replaceFirst(
        '<CLIENT_PRIVATE_KEY_FROM_DEVICE>',
        keyPair.privateKeyBase64,
      );

      await Clipboard.setData(ClipboardData(text: finalConfig));

      if (!mounted) return;
      setState(() {
        _protocol = configResult.protocol;
        _serverName = server.name;
        _deviceId = configResult.deviceId;
        _preparedConfig = finalConfig;
      });

      if (configResult.protocol != 'amneziawg') {
        throw BackendException(
          'Backend вернул неподдерживаемый protocol="${configResult.protocol}". Ожидается amneziawg.',
        );
      }

      if (_isAndroidRuntime || _isIosRuntime) {
        final osName = _isAndroidRuntime ? 'Android' : 'iOS';
        _pushStep('6/7 Запрашиваем разрешение $osName VPN');
        final granted = await _nativeVpn.prepare();
        if (!granted) {
          throw const BackendException(
            'Системное разрешение VPN не выдано. Разреши VPN и повтори.',
          );
        }

        _pushStep('7/7 Поднимаем AmneziaWG внутри приложения ($osName)');
        final isUp = await _nativeVpn.connect(
          config: finalConfig,
          tunnelName: 'pugvpn',
        );
        if (!isUp) {
          throw const BackendException(
            'Native backend не поднял туннель (isUp=false).',
          );
        }

        if (!mounted) return;
        setState(() {
          _stage = ConnectionStage.connected;
          _status = 'Connected (AmneziaWG one-tap внутри приложения, $osName)';
        });
      } else {
        if (!mounted) return;
        setState(() {
          _stage = ConnectionStage.readyToImport;
          _status =
              'Профиль готов и скопирован в буфер. '
              'На этой платформе пока импортируй его в AmneziaVPN.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = ConnectionStage.error;
        _errorMessage = error.toString();
        _status = 'Не удалось подключиться';
      });
    } finally {
      _controller
        ..stop()
        ..value = 1.0;
    }
  }

  Future<void> _copyConfig() async {
    final config = _preparedConfig;
    if (config == null) return;
    await Clipboard.setData(ClipboardData(text: config));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Конфиг скопирован')));
  }

  Future<void> _openInAmneziaIos() async {
    final config = _preparedConfig;
    if (config == null || !_isIosRuntime) return;

    try {
      final imported = await _nativeVpn.importConfig(
        config: config,
        tunnelName: 'pugvpn',
      );
      if (!mounted) return;
      final text = imported
          ? 'Открыло меню импорта. Выбери AmneziaVPN.'
          : 'Импорт отменен.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _onDisconnectPressed() async {
    if (_isBusy) return;
    if (_isAndroidRuntime || _isIosRuntime) {
      await _nativeVpn.disconnect();
    }
    if (!mounted) return;
    setState(() {
      _stage = ConnectionStage.idle;
      _status = 'Отключено';
    });
  }

  void _pushStep(String step) {
    if (!mounted) return;
    setState(() {
      _steps.insert(0, step);
      if (_steps.length > 8) _steps.removeLast();
    });
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
    final statusColor = switch (_stage) {
      ConnectionStage.idle => const Color(0xFF6B6E7A),
      ConnectionStage.connecting => const Color(0xFF5C63F2),
      ConnectionStage.readyToImport => const Color(0xFFDD8A00),
      ConnectionStage.connected => Colors.green,
      ConnectionStage.error => Colors.red,
    };

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF6F7FB), Color(0xFFEDEBFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 24),
                const Text(
                  'PugVPN',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E3140),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Backend: $_backendBaseUrl',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6E7A),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: _onConnectPressed,
                    child: ScaleTransition(
                      scale: _controller,
                      child: Image.asset(
                        'assets/images/pug_vpn.png',
                        height: 190,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: FilledButton(
                    onPressed: _isBusy ? null : _onConnectPressed,
                    child: Text(_isBusy ? 'Connecting...' : 'Connect'),
                  ),
                ),
                if (_stage == ConnectionStage.connected) ...<Widget>[
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton(
                      onPressed: _onDisconnectPressed,
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (_preparedConfig != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      if (_isIosRuntime && _stage != ConnectionStage.connected)
                        OutlinedButton(
                          onPressed: _openInAmneziaIos,
                          child: const Text('Open in Amnezia'),
                        ),
                      OutlinedButton(
                        onPressed: _copyConfig,
                        child: const Text('Copy config'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _showConfig = !_showConfig);
                        },
                        child: Text(
                          _showConfig ? 'Hide config' : 'Show config',
                        ),
                      ),
                    ],
                  ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                if (_protocol != null ||
                    _serverName != null ||
                    _deviceId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Server: ${_serverName ?? '-'} | Protocol: ${_protocol ?? '-'} | Device: ${_deviceId ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6E7A),
                      ),
                    ),
                  ),
                if (_showConfig && _preparedConfig != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDADCF0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _preparedConfig!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    'Последние шаги:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _steps.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _steps[index],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A4D5A),
                          ),
                        ),
                      ),
                    ),
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

class DeviceKeyPair {
  const DeviceKeyPair({
    required this.privateKeyBase64,
    required this.publicKeyBase64,
  });

  final String privateKeyBase64;
  final String publicKeyBase64;

  static Future<DeviceKeyPair> generate() async {
    final keyPair = await X25519().newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = (await keyPair.extractPublicKey()).bytes;
    return DeviceKeyPair(
      privateKeyBase64: base64Encode(privateKey),
      publicKeyBase64: base64Encode(publicKey),
    );
  }
}

class NativeVpnBridge {
  const NativeVpnBridge();

  static const MethodChannel _channel = MethodChannel('pug_vpn/awg');

  Future<bool> prepare() async {
    try {
      final result = await _channel.invokeMethod<bool>('prepare');
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'Native VPN bridge не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<bool> connect({
    required String config,
    required String tunnelName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'connect',
        <String, dynamic>{'config': config, 'tunnelName': tunnelName},
      );
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'Native VPN bridge не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<bool> importConfig({
    required String config,
    required String tunnelName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'importConfig',
        <String, dynamic>{'config': config, 'tunnelName': tunnelName},
      );
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'iOS import bridge не найден. Проверь сборку iOS.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<bool>('disconnect');
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }
}

class BackendClient {
  BackendClient({required String baseUrl})
    : _baseUri = Uri.parse(baseUrl),
      _http = http.Client();

  final Uri _baseUri;
  final http.Client _http;

  void dispose() {
    _http.close();
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final jsonMap = await _requestJson(
      method: 'POST',
      path: '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    final token = jsonMap['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const BackendException('Backend не вернул access_token.');
    }
    return token;
  }

  Future<List<VpnServer>> fetchServers({required String accessToken}) async {
    final jsonMap = await _requestJson(
      method: 'GET',
      path: '/vpn/servers',
      accessToken: accessToken,
    );
    final rawList = jsonMap['servers'];
    if (rawList is! List) {
      throw const BackendException(
        'Backend вернул некорректный список servers.',
      );
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(VpnServer.fromJson)
        .toList(growable: false);
  }

  Future<VpnConfigResult> buildConfig({
    required String accessToken,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
  }) async {
    final jsonMap = await _requestJson(
      method: 'POST',
      path: '/vpn/config',
      accessToken: accessToken,
      body: <String, dynamic>{
        'server_id': serverId,
        'device_name': deviceName,
        'device_public_key': devicePublicKey,
      },
    );
    return VpnConfigResult.fromJson(jsonMap);
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required String path,
    String? accessToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = _baseUri.resolve(path);
    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (accessToken != null) 'authorization': 'Bearer $accessToken',
    };

    final response = switch (method) {
      'GET' => await _http.get(uri, headers: headers),
      'POST' => await _http.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      _ => throw BackendException('Unsupported method: $method'),
    };

    final decoded = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded['error'] as String? ?? 'HTTP ${response.statusCode}';
      throw BackendException(message);
    }
    return decoded;
  }

  Map<String, dynamic> _decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const BackendException('Backend вернул некорректный JSON.');
    }
    return decoded;
  }
}

class VpnServer {
  const VpnServer({
    required this.id,
    required this.name,
    required this.protocol,
    required this.location,
  });

  final String id;
  final String name;
  final String protocol;
  final String location;

  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      protocol: json['protocol'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}

class VpnConfigResult {
  const VpnConfigResult({
    required this.protocol,
    required this.vpnConf,
    required this.deviceId,
  });

  final String protocol;
  final String vpnConf;
  final String deviceId;

  factory VpnConfigResult.fromJson(Map<String, dynamic> json) {
    final protocol = json['protocol'] as String?;
    final vpnConf = json['vpn_conf'] as String?;

    final device = json['device'];
    final deviceId = device is Map<String, dynamic>
        ? device['id'] as String? ?? ''
        : '';

    if (protocol == null || protocol.isEmpty) {
      throw const BackendException('Backend не вернул protocol.');
    }
    if (protocol != 'amneziawg') {
      throw BackendException(
        'Unsupported protocol from backend: "$protocol". Expected "amneziawg".',
      );
    }
    if (vpnConf == null || vpnConf.isEmpty) {
      throw const BackendException('Backend не вернул vpn_conf.');
    }

    return VpnConfigResult(
      protocol: protocol,
      vpnConf: vpnConf,
      deviceId: deviceId,
    );
  }
}

class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}
