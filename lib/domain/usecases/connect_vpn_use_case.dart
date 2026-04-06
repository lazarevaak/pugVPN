import 'package:pug_vpn/core/config/app_env.dart';
import 'package:pug_vpn/domain/entities/connected_vpn_session.dart';
import 'package:pug_vpn/domain/entities/device_key_pair.dart';
import 'package:pug_vpn/domain/entities/vpn_server.dart';
import 'package:pug_vpn/domain/repositories/backend_repository.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

class ConnectVpnUseCase {
  ConnectVpnUseCase({
    required BackendRepository backendRepository,
    required NativeVpnRepository nativeVpnRepository,
  }) : _backendRepository = backendRepository,
       _nativeVpnRepository = nativeVpnRepository;

  final BackendRepository _backendRepository;
  final NativeVpnRepository _nativeVpnRepository;

  Future<ConnectedVpnSession> execute({
    required String deviceName,
    required bool useNativeTunnel,
    required List<String> selectedPackages,
    required List<String> allPackages,
    String? preferredLocation,
    void Function(String status)? onProgress,
  }) async {
    await _ensureTunnelStoppedBeforeConnect(useNativeTunnel: useNativeTunnel);
    onProgress?.call('Preparing device...');

    final keyPair = await _loadOrCreateDeviceKeyPair();

    onProgress?.call('Authorizing...');
    final token = await _backendRepository.login(
      email: AppEnv.backendEmail,
      password: AppEnv.backendPassword,
    );

    onProgress?.call('Loading servers...');
    final servers = await _backendRepository.fetchServers(accessToken: token);
    if (servers.isEmpty) {
      throw Exception('Backend returned no VPN servers.');
    }

    final server = _selectServer(
      servers: servers,
      preferredLocation: preferredLocation,
    );
    onProgress?.call('Preparing VPN config...');
    final configResult = await _backendRepository.buildConfig(
      accessToken: token,
      serverId: server.id,
      deviceName: deviceName,
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
    final configForConnection = useNativeTunnel
        ? _applySelectedAppsToConfig(
            config: preparedConfig,
            allPackages: allPackages,
            selectedPackages: selectedPackages,
          )
        : preparedConfig;

    if (useNativeTunnel) {
      onProgress?.call('Starting tunnel...');
      final granted = await _nativeVpnRepository.prepare();
      if (!granted) {
        throw Exception('VPN permission not granted.');
      }

      final connected = await _nativeVpnRepository.connect(
        config: configForConnection,
        tunnelName: 'pugvpn',
      );
      if (!connected) {
        throw Exception('Native VPN backend returned isUp=false.');
      }
    }

    return ConnectedVpnSession(
      location: server.location,
      details: server.name,
    );
  }

  VpnServer _selectServer({
    required List<VpnServer> servers,
    required String? preferredLocation,
  }) {
    if (preferredLocation == null || preferredLocation.trim().isEmpty) {
      return servers.first;
    }

    final normalizedPreferred = _normalizeLocation(preferredLocation);
    for (final server in servers) {
      if (_normalizeLocation(server.location) == normalizedPreferred) {
        return server;
      }
    }

    return servers.first;
  }

  String _normalizeLocation(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'FI' || 'FINLAND' => 'FINLAND',
      'DE' || 'GERMANY' => 'GERMANY',
      'US' || 'USA' || 'UNITED STATES' => 'UNITED STATES',
      _ => normalized,
    };
  }

  Future<DeviceKeyPair> _loadOrCreateDeviceKeyPair() async {
    final existing = await _nativeVpnRepository.loadDeviceKeyPair();
    if (existing != null) {
      return existing;
    }

    final keyPair = await DeviceKeyPair.generate();
    await _nativeVpnRepository.saveDeviceKeyPair(keyPair);
    return keyPair;
  }

  Future<void> _ensureTunnelStoppedBeforeConnect({
    required bool useNativeTunnel,
  }) async {
    if (!useNativeTunnel) {
      return;
    }

    final status = await _nativeVpnRepository.status();
    final state = (status['state'] as String? ?? 'down').toLowerCase();
    final isConnected = status['is_connected'] as bool? ?? false;
    if (!isConnected &&
        state != 'up' &&
        state != 'connecting' &&
        state != 'reasserting' &&
        state != 'disconnecting') {
      return;
    }

    await _nativeVpnRepository.disconnect();
    for (var attempt = 0; attempt < 10; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final currentStatus = await _nativeVpnRepository.status();
      final currentState = (currentStatus['state'] as String? ?? 'down')
          .toLowerCase();
      final currentConnected =
          currentStatus['is_connected'] as bool? ?? false;
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

  String _applySelectedAppsToConfig({
    required String config,
    required List<String> allPackages,
    required List<String> selectedPackages,
  }) {
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
}
