part of 'backend_store_dao.dart';

extension BackendStoreDaoServers on BackendStoreDao {
  Future<ServerNode> resolveServer({String? serverId}) async {
    await _ensureInitialized();
    final connection = await _db();
    final normalized = serverId?.trim() ?? '';

    final rows = normalized.isEmpty
        ? await connection.execute('''
            SELECT *
            FROM servers
            ORDER BY id
            LIMIT 1
          ''')
        : await connection.execute(
            Sql.named('''
              SELECT *
              FROM servers
              WHERE id = @server_id
              LIMIT 1
            '''),
            parameters: <String, Object?>{'server_id': normalized},
          );

    if (rows.isEmpty) {
      throw ServerNotFoundException();
    }

    return _serverFromRow(rows.first.toColumnMap());
  }

  Future<List<ServerNode>> listServers() async {
    await _ensureInitialized();
    final connection = await _db();
    final rows = await connection.execute('''
      SELECT *
      FROM servers
      ORDER BY id
    ''');
    return rows.map((row) => _serverFromRow(row.toColumnMap())).toList();
  }

  Future<bool> healthCheck() async {
    await _ensureInitialized();
    final connection = await _db();
    await connection.execute('SELECT 1');
    return true;
  }

  Future<int> _remainingIpSlots(Connection connection, String serverId) async {
    final rows = await connection.execute(
      Sql.named('''
        SELECT COUNT(*) AS cnt
        FROM devices
        WHERE server_id = @server_id
          AND revoked_at IS NULL
      '''),
      parameters: <String, Object?>{'server_id': serverId},
    );
    final used = _asInt(rows.first.toColumnMap()['cnt']);
    return max(0, 253 - used);
  }

  Future<bool> _isEndpointReachable(String endpoint) async {
    final hostPort = _parseEndpoint(endpoint);
    if (hostPort == null) return false;
    final timeoutMs = _envInt('PUGVPN_PREFLIGHT_TCP_TIMEOUT_MS', 3000);

    try {
      final socket = await Socket.connect(
        hostPort.$1,
        hostPort.$2,
        timeout: Duration(milliseconds: timeoutMs),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  (String, int)? _parseEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('[')) {
      final end = trimmed.indexOf(']');
      final colon = trimmed.lastIndexOf(':');
      if (end <= 0 || colon <= end) return null;
      final port = int.tryParse(trimmed.substring(colon + 1));
      if (port == null) return null;
      return (trimmed.substring(1, end), port);
    }

    final colon = trimmed.lastIndexOf(':');
    if (colon <= 0 || colon == trimmed.length - 1) return null;
    final host = trimmed.substring(0, colon);
    final port = int.tryParse(trimmed.substring(colon + 1));
    if (port == null) return null;
    return (host, port);
  }
}
