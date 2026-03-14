part of 'backend_store_dao.dart';

class _DatabaseConnectionConfig {
  const _DatabaseConnectionConfig({
    required this.databaseName,
    required this.openPrimary,
    required this.openAdmin,
  });

  final String databaseName;
  final Future<Connection> Function() openPrimary;
  final Future<Connection> Function() openAdmin;
}

extension BackendStoreDaoSupport on BackendStoreDao {
  Future<void> _ensureInitialized() async {
    if (_initializing != null) {
      return _initializing!;
    }

    final future = _initialize();
    _initializing = future;
    try {
      await future;
    } catch (_) {
      if (identical(_initializing, future)) {
        _initializing = null;
      }
      rethrow;
    }
  }

  Future<void> _initialize() async {
    final connection = await _db();
    await BackendStoreDao._migrationRunner.migrate(connection);
    await _ensureLegacySchemaCompat(connection);
    await _seedDefaults(connection);
  }

  Future<void> _ensureLegacySchemaCompat(Connection connection) async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
        request_id TEXT,
        client_ip TEXT,
        target_type TEXT,
        target_id TEXT,
        details TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    ''');

    await connection.execute('''
      CREATE INDEX IF NOT EXISTS audit_logs_event_created_idx
        ON audit_logs (event_type, created_at DESC)
    ''');
    await connection.execute('''
      CREATE INDEX IF NOT EXISTS audit_logs_target_idx
        ON audit_logs (target_type, target_id, created_at DESC)
    ''');
    await connection.execute('''
      CREATE INDEX IF NOT EXISTS audit_logs_client_ip_idx
        ON audit_logs (client_ip, created_at DESC)
    ''');
  }

  Future<Connection> _db() async {
    final cached = _connection;
    if (cached != null && cached.isOpen) {
      return cached;
    }

    if (_openingConnection != null) {
      return _openingConnection!;
    }

    final future = _openConnection();
    _openingConnection = future;

    try {
      final connection = await future;
      _connection = connection;
      if (identical(_openingConnection, future)) {
        _openingConnection = null;
      }
      return connection;
    } catch (_) {
      if (identical(_openingConnection, future)) {
        _openingConnection = null;
      }
      rethrow;
    }
  }

  Future<Connection> _openConnection() async {
    final config = _databaseConnectionConfig();
    try {
      return await config.openPrimary();
    } on ServerException catch (error) {
      if (error.code != '3D000' || config.databaseName == 'postgres') {
        rethrow;
      }

      await _createMissingDatabase(config);
      return config.openPrimary();
    }
  }

  _DatabaseConnectionConfig _databaseConnectionConfig() {
    final databaseUrl = Platform.environment['PUGVPN_DATABASE_URL']?.trim();
    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      final primaryUrl = databaseUrl;
      final primaryUri = Uri.parse(primaryUrl);
      final queryParameters = Map<String, String>.from(
        primaryUri.queryParameters,
      );
      final databaseName =
          queryParameters['database'] ??
          (primaryUri.pathSegments.isNotEmpty
              ? primaryUri.pathSegments.first
              : 'postgres');
      final adminUri = primaryUri.replace(
        path: '/postgres',
        queryParameters: <String, String>{
          ...queryParameters,
          'database': 'postgres',
        },
      );
      return _DatabaseConnectionConfig(
        databaseName: databaseName,
        openPrimary: () => Connection.openFromUrl(primaryUrl),
        openAdmin: () => Connection.openFromUrl(adminUri.toString()),
      );
    }

    final host = Platform.environment['PUGVPN_DB_HOST']?.trim() ?? '127.0.0.1';
    final port = _envInt('PUGVPN_DB_PORT', 5432);
    final databaseName =
        Platform.environment['PUGVPN_DB_NAME']?.trim() ?? 'pugvpn';
    final username =
        Platform.environment['PUGVPN_DB_USER']?.trim() ?? 'postgres';
    final password =
        Platform.environment['PUGVPN_DB_PASSWORD']?.trim() ?? 'postgres';
    final settings = ConnectionSettings(
      applicationName: 'pug_vpn_backend',
      sslMode: _sslModeFromEnv(),
    );

    return _DatabaseConnectionConfig(
      databaseName: databaseName,
      openPrimary: () => Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: settings,
      ),
      openAdmin: () => Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: 'postgres',
          username: username,
          password: password,
        ),
        settings: settings,
      ),
    );
  }

  Future<void> _createMissingDatabase(_DatabaseConnectionConfig config) async {
    final adminConnection = await config.openAdmin();
    try {
      final escapedDatabaseName = config.databaseName.replaceAll('"', '""');
      await adminConnection.execute('CREATE DATABASE "$escapedDatabaseName"');
    } on ServerException catch (error) {
      if (error.code != '42P04') {
        rethrow;
      }
    } finally {
      await adminConnection.close();
    }
  }

  Future<void> _seedDefaults(Connection connection) async {
    final demoEmail =
        Platform.environment['PUGVPN_DEMO_EMAIL']?.trim().toLowerCase() ??
        'demo@pugvpn.app';
    final demoPassword =
        Platform.environment['PUGVPN_DEMO_PASSWORD']?.trim() ?? 'demo1234';
    final demoUserId =
        Platform.environment['PUGVPN_DEMO_USER_ID']?.trim() ?? 'user_demo';

    await connection.execute(
      Sql.named('''
        INSERT INTO users (
          id,
          email,
          password_hash
        )
        VALUES (
          @id,
          @email,
          @password_hash
        )
        ON CONFLICT (email) DO UPDATE SET
          password_hash = EXCLUDED.password_hash,
          is_active = TRUE,
          updated_at = NOW()
      '''),
      parameters: <String, Object?>{
        'id': demoUserId,
        'email': demoEmail,
        'password_hash': _hashPassword(demoPassword),
      },
    );

    final dnsServers = _parseCsv(
      Platform.environment['PUGVPN_SERVER_DNS'] ?? '1.1.1.1,8.8.8.8',
    );

    await connection.execute(
      Sql.named('''
        INSERT INTO servers (
          id,
          name,
          location,
          endpoint,
          public_key,
          subnet,
          dns_servers,
          mtu,
          awg_jc,
          awg_jmin,
          awg_jmax,
          awg_s1,
          awg_s2,
          awg_s3,
          awg_s4,
          awg_h1,
          awg_h2,
          awg_h3,
          awg_h4
        )
        VALUES (
          @id,
          @name,
          @location,
          @endpoint,
          @public_key,
          @subnet,
          @dns_servers,
          @mtu,
          @awg_jc,
          @awg_jmin,
          @awg_jmax,
          @awg_s1,
          @awg_s2,
          @awg_s3,
          @awg_s4,
          @awg_h1,
          @awg_h2,
          @awg_h3,
          @awg_h4
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          location = EXCLUDED.location,
          endpoint = EXCLUDED.endpoint,
          public_key = EXCLUDED.public_key,
          subnet = EXCLUDED.subnet,
          dns_servers = EXCLUDED.dns_servers,
          mtu = EXCLUDED.mtu,
          awg_jc = EXCLUDED.awg_jc,
          awg_jmin = EXCLUDED.awg_jmin,
          awg_jmax = EXCLUDED.awg_jmax,
          awg_s1 = EXCLUDED.awg_s1,
          awg_s2 = EXCLUDED.awg_s2,
          awg_s3 = EXCLUDED.awg_s3,
          awg_s4 = EXCLUDED.awg_s4,
          awg_h1 = EXCLUDED.awg_h1,
          awg_h2 = EXCLUDED.awg_h2,
          awg_h3 = EXCLUDED.awg_h3,
          awg_h4 = EXCLUDED.awg_h4,
          updated_at = NOW()
      '''),
      parameters: <String, Object?>{
        'id': Platform.environment['PUGVPN_SERVER_ID'] ?? 'srv_fi_1',
        'name': Platform.environment['PUGVPN_SERVER_NAME'] ?? 'Finland #1',
        'location': Platform.environment['PUGVPN_SERVER_LOCATION'] ?? 'FI',
        'endpoint': _envOrSecret(
          envKey: 'PUGVPN_SERVER_ENDPOINT',
          secretKey: 'server_endpoint',
          fallback: 'CHANGE_ME_SERVER_ENDPOINT:443',
        ),
        'public_key': _envOrSecret(
          envKey: 'PUGVPN_SERVER_PUBLIC_KEY',
          secretKey: 'server_public_key',
          fallback: 'CHANGE_ME_SERVER_PUBLIC_KEY',
        ),
        'subnet': Platform.environment['PUGVPN_SERVER_SUBNET'] ?? '10.77.77',
        'dns_servers': dnsServers.isEmpty
            ? '1.1.1.1,8.8.8.8'
            : dnsServers.join(','),
        'mtu': _envInt('PUGVPN_SERVER_MTU', 1200),
        'awg_jc': _envInt('PUGVPN_AWG_JC', 4),
        'awg_jmin': _envInt('PUGVPN_AWG_JMIN', 64),
        'awg_jmax': _envInt('PUGVPN_AWG_JMAX', 512),
        'awg_s1': _envInt('PUGVPN_AWG_S1', 32),
        'awg_s2': _envInt('PUGVPN_AWG_S2', 40),
        'awg_s3': _envInt('PUGVPN_AWG_S3', 24),
        'awg_s4': _envInt('PUGVPN_AWG_S4', 16),
        'awg_h1': _envInt('PUGVPN_AWG_H1', 11111111),
        'awg_h2': _envInt('PUGVPN_AWG_H2', 22222222),
        'awg_h3': _envInt('PUGVPN_AWG_H3', 33333333),
        'awg_h4': _envInt('PUGVPN_AWG_H4', 44444444),
      },
    );

    await connection.execute('''
      DELETE FROM sessions
      WHERE expires_at <= NOW()
    ''');
  }

  SslMode _sslModeFromEnv() {
    final raw = Platform.environment['PUGVPN_DB_SSLMODE']?.trim().toLowerCase();
    switch (raw) {
      case 'disable':
      case null:
      case '':
        return SslMode.disable;
      case 'require':
        return SslMode.require;
      case 'verify-full':
      case 'verify_full':
        return SslMode.verifyFull;
      default:
        throw StorageException(
          'Unsupported PUGVPN_DB_SSLMODE="$raw". Use disable, require, or verify-full.',
        );
    }
  }

  ServerNode _serverFromRow(Map<String, dynamic> row) {
    return ServerNode(
      id: row['id'] as String,
      name: row['name'] as String,
      location: row['location'] as String,
      endpoint: row['endpoint'] as String,
      publicKey: row['public_key'] as String,
      subnet: row['subnet'] as String,
      dnsServers: _parseCsv(row['dns_servers'] as String),
      mtu: _asInt(row['mtu']),
      amneziaSettings: AmneziaSettings(
        jc: _asInt(row['awg_jc']),
        jmin: _asInt(row['awg_jmin']),
        jmax: _asInt(row['awg_jmax']),
        s1: _asInt(row['awg_s1']),
        s2: _asInt(row['awg_s2']),
        s3: _asInt(row['awg_s3']),
        s4: _asInt(row['awg_s4']),
        h1: _asInt(row['awg_h1']),
        h2: _asInt(row['awg_h2']),
        h3: _asInt(row['awg_h3']),
        h4: _asInt(row['awg_h4']),
      ),
    );
  }

  UserAccount _userFromRow(Map<String, dynamic> row) {
    return UserAccount(
      id: row['id'] as String,
      email: row['email'] as String,
      isActive: row['is_active'] as bool,
      createdAt: (row['created_at'] as DateTime).toUtc(),
      updatedAt: (row['updated_at'] as DateTime).toUtc(),
    );
  }

  UserSession _sessionFromRow(Map<String, dynamic> row) {
    return UserSession(
      token: row['token'] as String,
      userId: row['user_id'] as String,
      expiresAt: (row['expires_at'] as DateTime).toUtc(),
      createdAt: (row['created_at'] as DateTime).toUtc(),
    );
  }

  Device _deviceFromRow(Map<String, dynamic> row) {
    return Device(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      serverId: row['server_id'] as String,
      name: row['name'] as String,
      publicKey: row['public_key'] as String,
      address: row['address'] as String,
      createdAt: (row['created_at'] as DateTime).toUtc(),
      updatedAt: (row['updated_at'] as DateTime).toUtc(),
      revokedAt: (row['revoked_at'] as DateTime?)?.toUtc(),
    );
  }

  Map<String, dynamic> _deviceSummaryFromRow(Map<String, dynamic> row) {
    final device = _deviceFromRow(row);
    return {
      ...device.toJson(),
      'provisioning_state': row['provisioning_state'] as String?,
      'last_heartbeat_at': (row['last_heartbeat_at'] as DateTime?)
          ?.toUtc()
          .toIso8601String(),
      'last_error': row['last_error'] as String?,
    };
  }

  String _newId(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = _random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    return '${prefix}_$ts$rnd';
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is num) return value.toInt();
    throw StorageException('Expected integer value, got: $value');
  }
}

int _envInt(String key, int fallback) {
  final raw = Platform.environment[key];
  if (raw == null) return fallback;
  return int.tryParse(raw.trim()) ?? fallback;
}

List<String> _parseCsv(String raw) {
  return raw
      .split(',')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();
}

String _envOrSecret({
  required String envKey,
  required String secretKey,
  required String fallback,
}) {
  final envValue = Platform.environment[envKey]?.trim();
  if (envValue != null && envValue.isNotEmpty) return envValue;
  final secretValue = BackendStoreDao._secrets[secretKey]?.trim();
  if (secretValue != null && secretValue.isNotEmpty) return secretValue;
  return fallback;
}

Map<String, String> _loadSecrets() {
  final result = <String, String>{};

  final inlineJson = Platform.environment['PUGVPN_SECRETS_JSON']?.trim();
  if (inlineJson != null && inlineJson.isNotEmpty) {
    result.addAll(_decodeSecretMap(inlineJson));
  }

  final command = Platform.environment['PUGVPN_SECRETS_COMMAND']?.trim();
  if (command != null && command.isNotEmpty) {
    final response = Process.runSync('/bin/bash', ['-lc', command]);
    if (response.exitCode != 0) {
      throw StorageException(
        'PUGVPN_SECRETS_COMMAND failed with exit code ${response.exitCode}: ${response.stderr}',
      );
    }
    result.addAll(_decodeSecretMap(response.stdout.toString()));
  }

  final filePath =
      (Platform.environment['PUGVPN_SECRETS_FILE'] ?? 'secrets.json').trim();
  if (filePath.isNotEmpty) {
    final file = File(filePath);
    if (file.existsSync()) {
      result.addAll(_decodeSecretMap(file.readAsStringSync()));
    }
  }

  return result;
}

Map<String, String> _decodeSecretMap(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return const {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  } catch (_) {
    throw StorageException('Unable to decode secrets JSON payload.');
  }
}
