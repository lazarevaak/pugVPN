part of 'backend_store_dao.dart';

extension BackendStoreDaoVpn on BackendStoreDao {
  Future<Map<String, dynamic>> buildConfig({
    required String userId,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
    required RequestMeta requestMeta,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final server = await resolveServer(serverId: serverId);
    final preflight = await _performServerPreflight(connection, server);

    final device = await connection.runTx<Device>((tx) async {
      return _registerOrReuseDevice(
        tx,
        userId: userId,
        serverId: server.id,
        deviceName: deviceName,
        publicKey: devicePublicKey,
        subnet: server.subnet,
      );
    });

    final mode = _provisioningMode;
    try {
      _provisionPeer(
        server: server,
        devicePublicKey: device.publicKey,
        deviceAddress: device.address,
      );
      await _upsertPeerRecord(
        connection,
        device: device,
        provisioningMode: mode,
        provisioningState: mode == 'off' ? 'config_only' : 'provisioned',
      );
    } on PeerProvisionException catch (error) {
      await _upsertPeerRecord(
        connection,
        device: device,
        provisioningMode: mode,
        provisioningState: 'failed',
        lastError: error.message,
      );
      await _logAuditEvent(
        connection,
        eventType: 'vpn.config.failed',
        severity: 'error',
        requestMeta: requestMeta,
        userId: userId,
        targetType: 'device',
        targetId: device.id,
        details: {'reason': error.message, 'server_id': server.id},
      );
      rethrow;
    }

    final config = _buildClientConfig(
      server: server,
      deviceAddress: device.address,
    );

    await _logAuditEvent(
      connection,
      eventType: 'vpn.config.issued',
      requestMeta: requestMeta,
      userId: userId,
      targetType: 'device',
      targetId: device.id,
      details: {'server_id': server.id, 'preflight': preflight.toJson()},
    );

    return {
      'server': server.toJson(),
      'server_preflight': preflight.toJson(),
      'device': device.toJson(),
      'protocol': 'amneziawg',
      'vpn_conf': config,
      'amneziawg_conf': config,
      'note': _buildConfigNote(),
    };
  }

  Future<ServerPreflight> _performServerPreflight(
    Connection connection,
    ServerNode server,
  ) async {
    final availableIpSlots = await _remainingIpSlots(connection, server.id);
    final hasFreeIps = availableIpSlots > 0;
    final mode = _provisioningMode;
    final endpointTcpReachable = await _isEndpointReachable(server.endpoint);

    var interfaceUp = mode == 'off' ? null : false;
    var provisioningReady = mode == 'off' ? null : false;
    var details = endpointTcpReachable
        ? 'endpoint tcp probe reachable'
        : 'endpoint tcp probe unreachable';

    if (mode != 'off') {
      final result = _runProvisioningScript(
        _buildPreflightScript(),
        context: 'VPN server preflight',
      );
      interfaceUp = result.exitCode == 0;
      provisioningReady = result.exitCode == 0;
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      details = stderr.isNotEmpty
          ? stderr
          : stdout.isNotEmpty
          ? stdout
          : details;
      if (!endpointTcpReachable) {
        details =
            '$details; endpoint tcp probe failed, but provisioning host is reachable';
      }
    }

    final serverReachable = mode == 'off'
        ? endpointTcpReachable
        : (provisioningReady == true || endpointTcpReachable);

    final preflight = ServerPreflight(
      serverReachable: serverReachable,
      interfaceUp: interfaceUp,
      provisioningReady: provisioningReady,
      hasFreeIps: hasFreeIps,
      availableIpSlots: availableIpSlots,
      mode: mode,
      checkedAt: DateTime.now().toUtc(),
      details: details,
    );

    if (mode == 'off' && !endpointTcpReachable) {
      throw ServerPreflightException(
        message: 'VPN endpoint is not reachable from backend.',
        preflight: preflight,
      );
    }
    if (!hasFreeIps) {
      throw ServerPreflightException(
        message: 'No free IP addresses remain on the server subnet.',
        preflight: preflight,
      );
    }
    if (mode != 'off' && provisioningReady != true) {
      throw ServerPreflightException(
        message: 'VPN server preflight failed: $details',
        preflight: preflight,
      );
    }

    return preflight;
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
      ..writeln('AllowedIPs = 0.0.0.0/0, ::/0')
      ..writeln('PersistentKeepalive = 25');

    return '${interface.toString().trimRight()}\n\n${peer.toString().trimRight()}\n';
  }

  String _buildConfigNote() {
    final mode = _provisioningMode;
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
    final mode = _provisioningMode;
    if (mode == 'off') return;

    final script = _buildProvisionScript(
      peerPublicKey: devicePublicKey,
      peerAllowedIp: '${deviceAddress.split('/').first}/32',
    );
    final result = _runProvisioningScript(script, context: 'Peer provisioning');
    _ensureSuccess(result, context: 'Peer provisioning');
  }

  void _deprovisionPeer({
    required ServerNode server,
    required String devicePublicKey,
  }) {
    final mode = _provisioningMode;
    if (mode == 'off') return;

    final result = _runProvisioningScript(
      _buildRemovePeerScript(peerPublicKey: devicePublicKey),
      context: 'Peer revocation',
    );
    _ensureSuccess(result, context: 'Peer revocation');
  }

  void _replacePeer({
    required ServerNode server,
    required String oldDevicePublicKey,
    required String newDevicePublicKey,
    required String deviceAddress,
  }) {
    final mode = _provisioningMode;
    if (mode == 'off') return;

    final result = _runProvisioningScript(
      _buildReplacePeerScript(
        oldPeerPublicKey: oldDevicePublicKey,
        newPeerPublicKey: newDevicePublicKey,
        peerAllowedIp: '${deviceAddress.split('/').first}/32',
      ),
      context: 'Peer reissue',
    );
    _ensureSuccess(result, context: 'Peer reissue');
  }

  String _buildPreflightScript() {
    final interface = _provisionInterface;
    final configPath = _provisionConfigPath(interface);
    return '''
set -euo pipefail
CONFIG_PATH=${_shellEscape(configPath)}
INTERFACE=${_shellEscape(interface)}
SERVICE=${_shellEscape('awg-quick@$interface')}

if [ ! -f "\$CONFIG_PATH" ]; then
  echo "Config file not found: \$CONFIG_PATH" >&2
  exit 1
fi

if ! command -v ip >/dev/null 2>&1; then
  echo "ip command not found" >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl not found" >&2
  exit 1
fi

if ! ip link show dev "\$INTERFACE" >/dev/null 2>&1; then
  echo "Interface \$INTERFACE not found" >&2
  exit 1
fi

if ! ip link show dev "\$INTERFACE" | grep -q "<.*UP.*>"; then
  echo "Interface \$INTERFACE is not UP" >&2
  exit 1
fi

if [ ! -w "\$CONFIG_PATH" ]; then
  echo "Config file not writable: \$CONFIG_PATH" >&2
  exit 1
fi

echo "interface_up=1"
echo "provisioning_ready=1"
''';
  }

  String _buildProvisionScript({
    required String peerPublicKey,
    required String peerAllowedIp,
  }) {
    final interface = _provisionInterface;
    final configPath = _provisionConfigPath(interface);
    final restartCommand = _restartCommand(interface);

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

  String _buildRemovePeerScript({required String peerPublicKey}) {
    final interface = _provisionInterface;
    final configPath = _provisionConfigPath(interface);
    final restartCommand = _restartCommand(interface);

    return '''
set -euo pipefail
CONFIG_PATH=${_shellEscape(configPath)}
PUBLIC_KEY=${_shellEscape(peerPublicKey)}
TMP_FILE="\${CONFIG_PATH}.tmp.\$\$"

if [ ! -f "\$CONFIG_PATH" ]; then
  echo "Config file not found: \$CONFIG_PATH" >&2
  exit 1
fi

awk -v key="\$PUBLIC_KEY" '
BEGIN { RS=""; ORS="\\n\\n" }
{
  if (\$0 ~ /^\\[Peer\\]/ && \$0 ~ ("PublicKey = " key)) next
  print \$0
}
' "\$CONFIG_PATH" > "\$TMP_FILE"
mv "\$TMP_FILE" "\$CONFIG_PATH"

$restartCommand
''';
  }

  String _buildReplacePeerScript({
    required String oldPeerPublicKey,
    required String newPeerPublicKey,
    required String peerAllowedIp,
  }) {
    final interface = _provisionInterface;
    final configPath = _provisionConfigPath(interface);
    final restartCommand = _restartCommand(interface);

    return '''
set -euo pipefail
CONFIG_PATH=${_shellEscape(configPath)}
OLD_PUBLIC_KEY=${_shellEscape(oldPeerPublicKey)}
NEW_PUBLIC_KEY=${_shellEscape(newPeerPublicKey)}
ALLOWED_IP=${_shellEscape(peerAllowedIp)}
TMP_FILE="\${CONFIG_PATH}.tmp.\$\$"

if [ ! -f "\$CONFIG_PATH" ]; then
  echo "Config file not found: \$CONFIG_PATH" >&2
  exit 1
fi

awk -v key="\$OLD_PUBLIC_KEY" '
BEGIN { RS=""; ORS="\\n\\n" }
{
  if (\$0 ~ /^\\[Peer\\]/ && \$0 ~ ("PublicKey = " key)) next
  print \$0
}
' "\$CONFIG_PATH" > "\$TMP_FILE"
mv "\$TMP_FILE" "\$CONFIG_PATH"

if ! grep -q "PublicKey = \$NEW_PUBLIC_KEY" "\$CONFIG_PATH"; then
  printf '\\n[Peer]\\nPublicKey = %s\\nAllowedIPs = %s\\n' "\$NEW_PUBLIC_KEY" "\$ALLOWED_IP" >> "\$CONFIG_PATH"
fi

$restartCommand
''';
  }

  ProcessResult _runProvisioningScript(
    String script, {
    required String context,
  }) {
    final mode = _provisioningMode;
    switch (mode) {
      case 'local':
        return _runLocalScript(script, context: context);
      case 'ssh':
        return _runRemoteScriptViaSsh(script, context: context);
      case 'off':
        return ProcessResult(0, 0, '', '');
      default:
        throw PeerProvisionException(
          'Unknown PUGVPN_PROVISION_MODE="$mode". Use one of: off, local, ssh.',
        );
    }
  }

  ProcessResult _runLocalScript(String script, {required String context}) {
    return Process.runSync('/bin/bash', ['-lc', script]);
  }

  ProcessResult _runRemoteScriptViaSsh(
    String script, {
    required String context,
  }) {
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
    final knownHostsPath =
        (Platform.environment['PUGVPN_PROVISION_SSH_KNOWN_HOSTS_FILE'] ??
                '/tmp/pugvpn_known_hosts')
            .trim();

    final args = <String>[
      '-o',
      'BatchMode=yes',
      '-o',
      'ConnectTimeout=10',
      '-o',
      'StrictHostKeyChecking=accept-new',
      '-o',
      'UserKnownHostsFile=$knownHostsPath',
      if (port != 22) ...['-p', '$port'],
      if (keyPath.isNotEmpty) ...['-i', keyPath],
      '$user@$host',
      'bash -lc ${_shellEscape(script)}',
    ];

    return Process.runSync('ssh', args);
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

  String get _provisioningMode {
    return (Platform.environment['PUGVPN_PROVISION_MODE'] ?? 'off')
        .trim()
        .toLowerCase();
  }

  String get _provisionInterface {
    final raw = (Platform.environment['PUGVPN_PROVISION_INTERFACE'] ?? 'awg0')
        .trim();
    return raw.isEmpty ? 'awg0' : raw;
  }

  String _provisionConfigPath(String interface) {
    return '/etc/amnezia/amneziawg/$interface.conf';
  }

  String _restartCommand(String interface) {
    return 'systemctl restart awg-quick@$interface';
  }
}
