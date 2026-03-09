import 'dart:convert';
import 'dart:io';
import 'dart:math';

class InvalidCredentialsException implements Exception {}

class ServerNotFoundException implements Exception {}

class TooManyClientsException implements Exception {}

class PeerProvisionException implements Exception {
  PeerProvisionException(this.message);

  final String message;

  @override
  String toString() => 'PeerProvisionException: $message';
}

class AmneziaSettings {
  AmneziaSettings({
    required this.jc,
    required this.jmin,
    required this.jmax,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
  });

  final int jc;
  final int jmin;
  final int jmax;
  final int s1;
  final int s2;
  final int s3;
  final int s4;
  final int h1;
  final int h2;
  final int h3;
  final int h4;

  Map<String, dynamic> toJson() => {
    'jc': jc,
    'jmin': jmin,
    'jmax': jmax,
    's1': s1,
    's2': s2,
    's3': s3,
    's4': s4,
    'h1': h1,
    'h2': h2,
    'h3': h3,
    'h4': h4,
  };
}

class ServerNode {
  ServerNode({
    required this.id,
    required this.name,
    required this.location,
    required this.endpoint,
    required this.publicKey,
    required this.subnet,
    required this.dnsServers,
    required this.mtu,
    required this.amneziaSettings,
  });

  final String id;
  final String name;
  final String location;
  final String endpoint;
  final String publicKey;
  final String subnet;
  final List<String> dnsServers;
  final int mtu;
  final AmneziaSettings amneziaSettings;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'endpoint': endpoint,
    'public_key': publicKey,
    'protocol': 'amneziawg',
    'subnet': subnet,
    'dns_servers': dnsServers,
    'mtu': mtu,
    'amnezia': amneziaSettings.toJson(),
  };
}

class Device {
  Device({
    required this.id,
    required this.userId,
    required this.serverId,
    required this.name,
    required this.publicKey,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String serverId;
  final String name;
  final String publicKey;
  final String address;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'server_id': serverId,
    'name': name,
    'public_key': publicKey,
    'address': address,
    'created_at': createdAt.toIso8601String(),
  };
}

class AppStore {
  AppStore._() : _servers = _buildServers();

  static final AppStore instance = AppStore._();
  static final Map<String, String> _fileSecrets = _loadFileSecrets();

  final _random = Random.secure();

  final Map<String, String> _passwordByEmail = {'demo@pugvpn.app': 'demo1234'};

  final Map<String, String> _userIdByEmail = {'demo@pugvpn.app': 'user_demo'};

  final Map<String, String> _userIdByToken = {};
  final Map<String, String> _tokenByUserId = {};
  final List<Device> _devices = [];
  final List<Map<String, dynamic>> _heartbeats = [];

  final List<ServerNode> _servers;

  Map<String, dynamic> login({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final validPassword = _passwordByEmail[normalizedEmail];
    if (validPassword == null || validPassword != password) {
      throw InvalidCredentialsException();
    }

    final userId = _userIdByEmail[normalizedEmail]!;
    final token = _issueToken(userId);
    _userIdByToken[token] = userId;
    _tokenByUserId[userId] = token;

    return {
      'access_token': token,
      'token_type': 'Bearer',
      'expires_in': 3600,
      'user': {'id': userId, 'email': normalizedEmail},
    };
  }

  String? resolveUserIdByToken(String token) => _userIdByToken[token];

  ServerNode resolveServer({String? serverId}) {
    final normalized = serverId?.trim() ?? '';
    if (normalized.isEmpty) {
      return _servers.first;
    }

    for (final server in _servers) {
      if (server.id == normalized) {
        return server;
      }
    }

    throw ServerNotFoundException();
  }

  Device registerDevice({
    required String userId,
    required String serverId,
    required String deviceName,
    required String publicKey,
    required String subnet,
  }) {
    final existing = _devices
        .where((d) => d.userId == userId && d.serverId == serverId)
        .length;
    if (existing >= 250) {
      throw TooManyClientsException();
    }

    final address = '$subnet.${existing + 2}/32';
    final device = Device(
      id: _newId('dev'),
      userId: userId,
      serverId: serverId,
      name: deviceName.trim(),
      publicKey: publicKey.trim(),
      address: address,
      createdAt: DateTime.now().toUtc(),
    );
    _devices.add(device);
    return device;
  }

  List<ServerNode> listServers() => List.unmodifiable(_servers);

  Map<String, dynamic> buildConfig({
    required String userId,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
  }) {
    final server = resolveServer(serverId: serverId);

    final device = registerDevice(
      userId: userId,
      serverId: server.id,
      deviceName: deviceName,
      publicKey: devicePublicKey,
      subnet: server.subnet,
    );

    _provisionPeer(
      server: server,
      devicePublicKey: devicePublicKey,
      deviceAddress: device.address,
    );
    final config = _buildClientConfig(
      server: server,
      deviceAddress: device.address,
    );

    return {
      'server': server.toJson(),
      'device': device.toJson(),
      'protocol': 'amneziawg',
      'vpn_conf': config,
      'amneziawg_conf': config,
      'note': _buildConfigNote(),
    };
  }

  void pushHeartbeat({
    required String userId,
    required String deviceId,
    required String serverId,
    required bool isConnected,
    required int latencyMs,
  }) {
    _heartbeats.add({
      'id': _newId('hb'),
      'user_id': userId,
      'device_id': deviceId,
      'server_id': serverId,
      'is_connected': isConnected,
      'latency_ms': latencyMs,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String _issueToken(String userId) {
    final raw =
        '$userId:${DateTime.now().millisecondsSinceEpoch}:${_random.nextInt(1 << 32)}';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  String _newId(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = _random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    return '${prefix}_$ts$rnd';
  }

  static List<ServerNode> _buildServers() {
    final dnsServers = _parseCsv(
      Platform.environment['PUGVPN_SERVER_DNS'] ?? '1.1.1.1,8.8.8.8',
    );

    return [
      ServerNode(
        id: Platform.environment['PUGVPN_SERVER_ID'] ?? 'srv_fi_1',
        name: Platform.environment['PUGVPN_SERVER_NAME'] ?? 'Finland #1',
        location: Platform.environment['PUGVPN_SERVER_LOCATION'] ?? 'FI',
        endpoint: _envOrSecret(
          envKey: 'PUGVPN_SERVER_ENDPOINT',
          secretKey: 'server_endpoint',
          fallback: 'CHANGE_ME_SERVER_ENDPOINT:443',
        ),
        publicKey: _envOrSecret(
          envKey: 'PUGVPN_SERVER_PUBLIC_KEY',
          secretKey: 'server_public_key',
          fallback: 'CHANGE_ME_SERVER_PUBLIC_KEY',
        ),
        subnet: Platform.environment['PUGVPN_SERVER_SUBNET'] ?? '10.77.77',
        dnsServers: dnsServers.isEmpty
            ? const ['1.1.1.1', '8.8.8.8']
            : dnsServers,
        mtu: _envInt('PUGVPN_SERVER_MTU', 1200),
        amneziaSettings: AmneziaSettings(
          jc: _envInt('PUGVPN_AWG_JC', 4),
          jmin: _envInt('PUGVPN_AWG_JMIN', 64),
          jmax: _envInt('PUGVPN_AWG_JMAX', 512),
          s1: _envInt('PUGVPN_AWG_S1', 32),
          s2: _envInt('PUGVPN_AWG_S2', 40),
          s3: _envInt('PUGVPN_AWG_S3', 24),
          s4: _envInt('PUGVPN_AWG_S4', 16),
          h1: _envInt('PUGVPN_AWG_H1', 11111111),
          h2: _envInt('PUGVPN_AWG_H2', 22222222),
          h3: _envInt('PUGVPN_AWG_H3', 33333333),
          h4: _envInt('PUGVPN_AWG_H4', 44444444),
        ),
      ),
    ];
  }

  static int _envInt(String key, int fallback) {
    final raw = Platform.environment[key];
    if (raw == null) return fallback;
    return int.tryParse(raw.trim()) ?? fallback;
  }

  static List<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  static String _envOrSecret({
    required String envKey,
    required String secretKey,
    required String fallback,
  }) {
    final envValue = Platform.environment[envKey]?.trim();
    if (envValue != null && envValue.isNotEmpty) return envValue;
    final secretValue = _fileSecrets[secretKey]?.trim();
    if (secretValue != null && secretValue.isNotEmpty) return secretValue;
    return fallback;
  }

  static Map<String, String> _loadFileSecrets() {
    final filePath =
        (Platform.environment['PUGVPN_SECRETS_FILE'] ?? 'secrets.json').trim();
    if (filePath.isEmpty) return const {};
    final file = File(filePath);
    if (!file.existsSync()) return const {};
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return const {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    } catch (_) {
      return const {};
    }
  }

  String _buildClientConfig({
    required ServerNode server,
    required String deviceAddress,
  }) {
    final awg = server.amneziaSettings;
    final interface = StringBuffer()
      ..writeln('[Interface]')
      ..writeln('PrivateKey = <CLIENT_PRIVATE_KEY_FROM_DEVICE>')
      ..writeln('Address = $deviceAddress')
      ..writeln('DNS = ${server.dnsServers.join(', ')}')
      ..writeln('MTU = ${server.mtu}')
      ..writeln('Jc = ${awg.jc}')
      ..writeln('Jmin = ${awg.jmin}')
      ..writeln('Jmax = ${awg.jmax}')
      ..writeln('S1 = ${awg.s1}')
      ..writeln('S2 = ${awg.s2}')
      ..writeln('S3 = ${awg.s3}')
      ..writeln('S4 = ${awg.s4}')
      ..writeln('H1 = ${awg.h1}')
      ..writeln('H2 = ${awg.h2}')
      ..writeln('H3 = ${awg.h3}')
      ..writeln('H4 = ${awg.h4}');

    final peer = StringBuffer()
      ..writeln('[Peer]')
      ..writeln('PublicKey = ${server.publicKey}')
      ..writeln('Endpoint = ${server.endpoint}')
      // Keep IPv4-only default route until full IPv6 forwarding/NAT is configured server-side.
      ..writeln('AllowedIPs = 0.0.0.0/0')
      ..writeln('PersistentKeepalive = 25');

    return '${interface.toString().trimRight()}\n\n${peer.toString().trimRight()}\n';
  }

  String _buildConfigNote() {
    final mode = (Platform.environment['PUGVPN_PROVISION_MODE'] ?? 'off')
        .trim()
        .toLowerCase();
    if (mode == 'off') {
      return 'Client must inject real private key generated on-device. '
          'Server peer provisioning is disabled (PUGVPN_PROVISION_MODE=off).';
    }
    return 'Client must inject real private key generated on-device. '
        'Server peer provisioning is enabled via mode=$mode.';
  }

  void _provisionPeer({
    required ServerNode server,
    required String devicePublicKey,
    required String deviceAddress,
  }) {
    final mode = (Platform.environment['PUGVPN_PROVISION_MODE'] ?? 'off')
        .trim()
        .toLowerCase();
    if (mode == 'off') return;

    final peerIp = deviceAddress.split('/').first;
    final interface =
        (Platform.environment['PUGVPN_PROVISION_INTERFACE'] ?? '')
            .trim()
            .isNotEmpty
        ? Platform.environment['PUGVPN_PROVISION_INTERFACE']!.trim()
        : 'awg0';

    final configPath = '/etc/amnezia/amneziawg/$interface.conf';
    final restartCommand = 'systemctl restart awg-quick@$interface';

    final script = _buildProvisionScript(
      configPath: configPath,
      peerPublicKey: devicePublicKey,
      peerAllowedIp: '$peerIp/32',
      restartCommand: restartCommand,
    );

    switch (mode) {
      case 'local':
        _runLocalScript(script);
        return;
      case 'ssh':
        _runRemoteScriptViaSsh(script);
        return;
      default:
        throw PeerProvisionException(
          'Unknown PUGVPN_PROVISION_MODE="$mode". Use one of: off, local, ssh.',
        );
    }
  }

  String _buildProvisionScript({
    required String configPath,
    required String peerPublicKey,
    required String peerAllowedIp,
    required String restartCommand,
  }) {
    return '''
set -euo pipefail
CONFIG_PATH=${_shellEscape(configPath)}
PUBLIC_KEY=${_shellEscape(peerPublicKey)}
ALLOWED_IP=${_shellEscape(peerAllowedIp)}

if [ ! -f "\$CONFIG_PATH" ]; then
  echo "Config file not found: \$CONFIG_PATH" >&2
  exit 1
fi

if ! grep -q "PublicKey = \$PUBLIC_KEY" "\$CONFIG_PATH"; then
  printf '\\n[Peer]\\nPublicKey = %s\\nAllowedIPs = %s\\n' "\$PUBLIC_KEY" "\$ALLOWED_IP" >> "\$CONFIG_PATH"
fi

$restartCommand
''';
  }

  void _runLocalScript(String script) {
    final result = Process.runSync('/bin/bash', ['-lc', script]);
    _ensureSuccess(result, context: 'Local peer provisioning');
  }

  void _runRemoteScriptViaSsh(String script) {
    final host = _envOrSecret(
      envKey: 'PUGVPN_PROVISION_SSH_HOST',
      secretKey: 'provision_ssh_host',
      fallback: '',
    ).trim();
    if (host.isEmpty) {
      throw PeerProvisionException(
        'PUGVPN_PROVISION_SSH_HOST is required when PUGVPN_PROVISION_MODE=ssh.',
      );
    }

    final user = (Platform.environment['PUGVPN_PROVISION_SSH_USER'] ?? 'root')
        .trim();
    final port = _envInt('PUGVPN_PROVISION_SSH_PORT', 22);
    final keyPath =
        (Platform.environment['PUGVPN_PROVISION_SSH_KEY_PATH'] ?? '').trim();

    final args = <String>[
      '-o',
      'BatchMode=yes',
      '-o',
      'ConnectTimeout=10',
      '-o',
      'StrictHostKeyChecking=accept-new',
      if (port != 22) ...['-p', '$port'],
      if (keyPath.isNotEmpty) ...['-i', keyPath],
      '$user@$host',
      'bash -lc ${_shellEscape(script)}',
    ];

    final result = Process.runSync('ssh', args);
    _ensureSuccess(result, context: 'SSH peer provisioning');
  }

  void _ensureSuccess(ProcessResult result, {required String context}) {
    if (result.exitCode == 0) return;
    final stderr = result.stderr.toString().trim();
    final stdout = result.stdout.toString().trim();
    final details = stderr.isNotEmpty ? stderr : stdout;
    throw PeerProvisionException(
      '$context failed with exit code ${result.exitCode}${details.isEmpty ? '' : ': $details'}',
    );
  }

  String _shellEscape(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }
}
