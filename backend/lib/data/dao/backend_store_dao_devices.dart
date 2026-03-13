part of 'backend_store_dao.dart';

extension BackendStoreDaoDevices on BackendStoreDao {
  Future<Device> registerDevice({
    required String userId,
    required String serverId,
    required String deviceName,
    required String publicKey,
    required String subnet,
    required RequestMeta requestMeta,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final device = await connection.runTx<Device>((tx) async {
      return _registerOrReuseDevice(
        tx,
        userId: userId,
        serverId: serverId,
        deviceName: deviceName,
        publicKey: publicKey,
        subnet: subnet,
      );
    });

    await _upsertPeerRecord(
      connection,
      device: device,
      provisioningMode: _provisioningMode,
      provisioningState: 'registered',
    );
    await _logAuditEvent(
      connection,
      eventType: 'device.registered',
      requestMeta: requestMeta,
      userId: userId,
      targetType: 'device',
      targetId: device.id,
      details: {'server_id': device.serverId},
    );
    return device;
  }

  Future<List<Map<String, dynamic>>> listDevices({
    required String userId,
    bool includeRevoked = false,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final rows = await connection.execute(
      Sql.named('''
        SELECT
          d.*,
          p.provisioning_state,
          p.last_heartbeat_at,
          p.last_error
        FROM devices d
        LEFT JOIN peers p ON p.device_id = d.id
        WHERE d.user_id = @user_id
          AND (@include_revoked = TRUE OR d.revoked_at IS NULL)
        ORDER BY d.created_at DESC
      '''),
      parameters: <String, Object?>{
        'user_id': userId,
        'include_revoked': includeRevoked,
      },
    );
    return rows.map((row) => _deviceSummaryFromRow(row.toColumnMap())).toList();
  }

  Future<Map<String, dynamic>> revokeDevice({
    required String userId,
    required String deviceId,
    required RequestMeta requestMeta,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final device = await _getDeviceForUser(
      connection,
      userId: userId,
      deviceId: deviceId,
    );
    final server = await resolveServer(serverId: device.serverId);

    if (device.isRevoked) {
      return {'ok': true, 'already_revoked': true, 'device': device.toJson()};
    }

    try {
      _deprovisionPeer(server: server, devicePublicKey: device.publicKey);
    } on PeerProvisionException catch (error) {
      await _upsertPeerRecord(
        connection,
        device: device,
        provisioningMode: _provisioningMode,
        provisioningState: 'failed',
        lastError: error.message,
      );
      await _logAuditEvent(
        connection,
        eventType: 'device.revoke.failed',
        severity: 'error',
        requestMeta: requestMeta,
        userId: userId,
        targetType: 'device',
        targetId: device.id,
        details: {'reason': error.message},
      );
      rethrow;
    }

    final updatedRows = await connection.execute(
      Sql.named('''
        UPDATE devices
        SET
          revoked_at = NOW(),
          updated_at = NOW()
        WHERE id = @device_id
          AND user_id = @user_id
        RETURNING *
      '''),
      parameters: <String, Object?>{'device_id': deviceId, 'user_id': userId},
    );
    final revokedDevice = _deviceFromRow(updatedRows.first.toColumnMap());

    await _upsertPeerRecord(
      connection,
      device: revokedDevice,
      provisioningMode: _provisioningMode,
      provisioningState: 'revoked',
    );
    await _logAuditEvent(
      connection,
      eventType: 'device.revoked',
      requestMeta: requestMeta,
      userId: userId,
      targetType: 'device',
      targetId: revokedDevice.id,
      details: {'server_id': revokedDevice.serverId},
    );

    return {'ok': true, 'device': revokedDevice.toJson()};
  }

  Future<Map<String, dynamic>> reissueDevice({
    required String userId,
    required String deviceId,
    required String devicePublicKey,
    String? deviceName,
    required RequestMeta requestMeta,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final currentDevice = await _getDeviceForUser(
      connection,
      userId: userId,
      deviceId: deviceId,
    );
    if (currentDevice.isRevoked) {
      throw DeviceRevokedException();
    }

    final server = await resolveServer(serverId: currentDevice.serverId);
    final preflight = await _performServerPreflight(connection, server);
    final normalizedPublicKey = devicePublicKey.trim();
    final normalizedName = deviceName?.trim();

    if (normalizedPublicKey != currentDevice.publicKey) {
      await _ensurePublicKeyAvailable(
        connection,
        userId: userId,
        serverId: currentDevice.serverId,
        publicKey: normalizedPublicKey,
        currentDeviceId: currentDevice.id,
      );
      _replacePeer(
        server: server,
        oldDevicePublicKey: currentDevice.publicKey,
        newDevicePublicKey: normalizedPublicKey,
        deviceAddress: currentDevice.address,
      );
    } else {
      _provisionPeer(
        server: server,
        devicePublicKey: currentDevice.publicKey,
        deviceAddress: currentDevice.address,
      );
    }

    final updatedRows = await connection.execute(
      Sql.named('''
        UPDATE devices
        SET
          public_key = @public_key,
          name = @name,
          updated_at = NOW()
        WHERE id = @device_id
          AND user_id = @user_id
        RETURNING *
      '''),
      parameters: <String, Object?>{
        'public_key': normalizedPublicKey,
        'name': normalizedName != null && normalizedName.isNotEmpty
            ? normalizedName
            : currentDevice.name,
        'device_id': deviceId,
        'user_id': userId,
      },
    );
    final updatedDevice = _deviceFromRow(updatedRows.first.toColumnMap());

    await _upsertPeerRecord(
      connection,
      device: updatedDevice,
      provisioningMode: _provisioningMode,
      provisioningState: _provisioningMode == 'off'
          ? 'config_only'
          : 'provisioned',
    );
    await _logAuditEvent(
      connection,
      eventType: 'device.reissued',
      requestMeta: requestMeta,
      userId: userId,
      targetType: 'device',
      targetId: updatedDevice.id,
      details: {
        'server_id': updatedDevice.serverId,
        'preflight': preflight.toJson(),
      },
    );

    final config = _buildClientConfig(
      server: server,
      deviceAddress: updatedDevice.address,
    );

    return {
      'server': server.toJson(),
      'server_preflight': preflight.toJson(),
      'device': updatedDevice.toJson(),
      'protocol': 'amneziawg',
      'vpn_conf': config,
      'amneziawg_conf': config,
      'note': _buildConfigNote(),
    };
  }

  Future<void> pushHeartbeat({
    required String userId,
    required String deviceId,
    required String serverId,
    required bool isConnected,
    required int latencyMs,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    await connection.execute(
      Sql.named('''
        INSERT INTO heartbeats (
          id,
          user_id,
          device_id,
          server_id,
          is_connected,
          latency_ms
        )
        VALUES (
          @id,
          @user_id,
          @device_id,
          @server_id,
          @is_connected,
          @latency_ms
        )
      '''),
      parameters: <String, Object?>{
        'id': _newId('hb'),
        'user_id': userId,
        'device_id': deviceId,
        'server_id': serverId,
        'is_connected': isConnected,
        'latency_ms': latencyMs,
      },
    );

    await connection.execute(
      Sql.named('''
        UPDATE peers
        SET
          last_heartbeat_at = NOW(),
          updated_at = NOW()
        WHERE device_id = @device_id
      '''),
      parameters: <String, Object?>{'device_id': deviceId},
    );
  }

  Future<Device> _registerOrReuseDevice(
    TxSession tx, {
    required String userId,
    required String serverId,
    required String deviceName,
    required String publicKey,
    required String subnet,
  }) async {
    await tx.execute(
      Sql.named('''
        SELECT id
        FROM servers
        WHERE id = @server_id
        FOR UPDATE
      '''),
      parameters: <String, Object?>{'server_id': serverId},
    );

    final existingRows = await tx.execute(
      Sql.named('''
        SELECT *
        FROM devices
        WHERE user_id = @user_id
          AND server_id = @server_id
          AND public_key = @public_key
          AND revoked_at IS NULL
        LIMIT 1
      '''),
      parameters: <String, Object?>{
        'user_id': userId,
        'server_id': serverId,
        'public_key': publicKey.trim(),
      },
    );

    if (existingRows.isNotEmpty) {
      final existing = _deviceFromRow(existingRows.first.toColumnMap());
      final normalizedName = deviceName.trim();
      if (existing.name == normalizedName) {
        return existing;
      }

      final updatedRows = await tx.execute(
        Sql.named('''
          UPDATE devices
          SET
            name = @name,
            updated_at = NOW()
          WHERE id = @device_id
          RETURNING *
        '''),
        parameters: <String, Object?>{
          'device_id': existing.id,
          'name': normalizedName,
        },
      );
      return _deviceFromRow(updatedRows.first.toColumnMap());
    }

    await _ensurePublicKeyAvailable(
      tx,
      userId: userId,
      serverId: serverId,
      publicKey: publicKey.trim(),
    );

    final countRows = await tx.execute(
      Sql.named('''
        SELECT COUNT(*) AS cnt
        FROM devices
        WHERE user_id = @user_id
          AND server_id = @server_id
          AND revoked_at IS NULL
      '''),
      parameters: <String, Object?>{'user_id': userId, 'server_id': serverId},
    );

    final count = _asInt(countRows.first.toColumnMap()['cnt']);
    if (count >= 250) {
      throw TooManyClientsException();
    }

    final allocatedAddress = await _allocateNextAddress(
      tx,
      serverId: serverId,
      subnet: subnet,
    );
    final now = DateTime.now().toUtc();
    final deviceId = _newId('dev');

    final insertedRows = await tx.execute(
      Sql.named('''
        INSERT INTO devices (
          id,
          user_id,
          server_id,
          name,
          public_key,
          address,
          created_at,
          updated_at
        )
        VALUES (
          @id,
          @user_id,
          @server_id,
          @name,
          @public_key,
          @address,
          @created_at,
          @updated_at
        )
        RETURNING *
      '''),
      parameters: <String, Object?>{
        'id': deviceId,
        'user_id': userId,
        'server_id': serverId,
        'name': deviceName.trim(),
        'public_key': publicKey.trim(),
        'address': allocatedAddress,
        'created_at': now,
        'updated_at': now,
      },
    );

    return _deviceFromRow(insertedRows.first.toColumnMap());
  }

  Future<void> _ensurePublicKeyAvailable(
    Session session, {
    required String userId,
    required String serverId,
    required String publicKey,
    String? currentDeviceId,
  }) async {
    final rows = currentDeviceId == null
        ? await session.execute(
            Sql.named('''
              SELECT id, user_id
              FROM devices
              WHERE server_id = @server_id
                AND public_key = @public_key
                AND revoked_at IS NULL
              LIMIT 1
            '''),
            parameters: <String, Object?>{
              'server_id': serverId,
              'public_key': publicKey,
            },
          )
        : await session.execute(
            Sql.named('''
              SELECT id, user_id
              FROM devices
              WHERE server_id = @server_id
                AND public_key = @public_key
                AND revoked_at IS NULL
                AND id != @current_device_id
              LIMIT 1
            '''),
            parameters: <String, Object?>{
              'server_id': serverId,
              'public_key': publicKey,
              'current_device_id': currentDeviceId,
            },
          );
    if (rows.isEmpty) return;

    final row = rows.first.toColumnMap();
    if (row['user_id'] == userId) {
      throw DuplicateDeviceKeyException(
        'This public key is already registered for another active device.',
      );
    }
    throw DuplicateDeviceKeyException(
      'This public key is already registered on the server.',
    );
  }

  Future<String> _allocateNextAddress(
    TxSession tx, {
    required String serverId,
    required String subnet,
  }) async {
    final rows = await tx.execute(
      Sql.named('''
        SELECT address
        FROM devices
        WHERE server_id = @server_id
          AND revoked_at IS NULL
      '''),
      parameters: <String, Object?>{'server_id': serverId},
    );

    final used = <int>{};
    for (final row in rows) {
      final address = row.toColumnMap()['address'] as String;
      final host = _extractIpv4Host(address);
      if (host != null) {
        used.add(host);
      }
    }

    for (var host = 2; host <= 254; host++) {
      if (!used.contains(host)) {
        return '$subnet.$host/32';
      }
    }

    throw TooManyClientsException();
  }

  Future<Device> _getDeviceForUser(
    Session session, {
    required String userId,
    required String deviceId,
  }) async {
    final rows = await session.execute(
      Sql.named('''
        SELECT *
        FROM devices
        WHERE id = @device_id
          AND user_id = @user_id
        LIMIT 1
      '''),
      parameters: <String, Object?>{'device_id': deviceId, 'user_id': userId},
    );
    if (rows.isEmpty) {
      throw DeviceNotFoundException();
    }
    return _deviceFromRow(rows.first.toColumnMap());
  }

  Future<void> _upsertPeerRecord(
    Session session, {
    required Device device,
    required String provisioningMode,
    required String provisioningState,
    String? lastError,
  }) async {
    await session.execute(
      Sql.named('''
        INSERT INTO peers (
          id,
          device_id,
          server_id,
          public_key,
          allowed_ip,
          provisioning_mode,
          provisioning_state,
          last_error,
          provisioned_at,
          last_heartbeat_at
        )
        VALUES (
          @id,
          @device_id,
          @server_id,
          @public_key,
          @allowed_ip,
          @provisioning_mode,
          @provisioning_state,
          @last_error,
          @provisioned_at,
          NULL
        )
        ON CONFLICT (device_id) DO UPDATE SET
          server_id = EXCLUDED.server_id,
          public_key = EXCLUDED.public_key,
          allowed_ip = EXCLUDED.allowed_ip,
          provisioning_mode = EXCLUDED.provisioning_mode,
          provisioning_state = EXCLUDED.provisioning_state,
          last_error = EXCLUDED.last_error,
          provisioned_at = EXCLUDED.provisioned_at,
          updated_at = NOW()
      '''),
      parameters: <String, Object?>{
        'id': _newId('peer'),
        'device_id': device.id,
        'server_id': device.serverId,
        'public_key': device.publicKey,
        'allowed_ip': device.address.split('/').first,
        'provisioning_mode': provisioningMode,
        'provisioning_state': provisioningState,
        'last_error': lastError,
        'provisioned_at': provisioningState == 'provisioned'
            ? DateTime.now().toUtc()
            : null,
      },
    );
  }

  int? _extractIpv4Host(String cidrAddress) {
    final address = cidrAddress.split('/').first;
    final octets = address.split('.');
    if (octets.length != 4) return null;
    return int.tryParse(octets.last);
  }
}
