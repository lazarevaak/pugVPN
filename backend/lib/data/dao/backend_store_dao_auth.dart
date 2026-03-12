part of 'backend_store_dao.dart';

extension BackendStoreDaoAuth on BackendStoreDao {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required RequestMeta requestMeta,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final normalizedEmail = email.trim().toLowerCase();

    await _enforceLoginRateLimit(
      connection,
      email: normalizedEmail,
      requestMeta: requestMeta,
    );

    final rows = await connection.execute(
      Sql.named('''
        SELECT id, email, password_hash
        FROM users
        WHERE email = @email
          AND is_active = TRUE
        LIMIT 1
      '''),
      parameters: <String, Object?>{'email': normalizedEmail},
    );

    if (rows.isEmpty) {
      await _logAuditEvent(
        connection,
        eventType: 'auth.login.failed',
        severity: 'warn',
        requestMeta: requestMeta,
        targetType: 'email',
        targetId: normalizedEmail,
        details: {'reason': 'user_not_found'},
      );
      throw InvalidCredentialsException();
    }

    final row = rows.first.toColumnMap();
    final userId = row['id'] as String;
    final verification = _verifyPassword(
      password: password,
      storedHash: row['password_hash'] as String,
    );
    if (!verification.isValid) {
      await _logAuditEvent(
        connection,
        eventType: 'auth.login.failed',
        severity: 'warn',
        requestMeta: requestMeta,
        userId: userId,
        targetType: 'email',
        targetId: normalizedEmail,
        details: {'reason': 'bad_password'},
      );
      throw InvalidCredentialsException();
    }

    if (verification.needsUpgrade) {
      await connection.execute(
        Sql.named('''
          UPDATE users
          SET
            password_hash = @password_hash,
            updated_at = NOW()
          WHERE id = @user_id
        '''),
        parameters: <String, Object?>{
          'password_hash': _hashPassword(password),
          'user_id': userId,
        },
      );
    }

    final token = _issueToken(userId);
    final expiresInSeconds = 3600;
    final expiresAt = DateTime.now().toUtc().add(
      Duration(seconds: expiresInSeconds),
    );

    await connection.execute(
      Sql.named('''
        INSERT INTO sessions (
          token,
          user_id,
          expires_at
        )
        VALUES (
          @token,
          @user_id,
          @expires_at
        )
      '''),
      parameters: <String, Object?>{
        'token': token,
        'user_id': userId,
        'expires_at': expiresAt,
      },
    );

    await _clearFailedLoginAttempts(
      connection,
      email: normalizedEmail,
      clientIp: requestMeta.clientIp,
    );
    await _logAuditEvent(
      connection,
      eventType: 'auth.login.succeeded',
      requestMeta: requestMeta,
      userId: userId,
      targetType: 'email',
      targetId: normalizedEmail,
    );

    return {
      'access_token': token,
      'token_type': 'Bearer',
      'expires_in': expiresInSeconds,
      'user': {'id': userId, 'email': normalizedEmail},
    };
  }

  Future<String?> resolveUserIdByToken(String token) async {
    await _ensureInitialized();
    final connection = await _db();
    final rows = await connection.execute(
      Sql.named('''
        SELECT s.user_id
        FROM sessions s
        INNER JOIN users u ON u.id = s.user_id
        WHERE s.token = @token
          AND s.expires_at > NOW()
          AND u.is_active = TRUE
        LIMIT 1
      '''),
      parameters: <String, Object?>{'token': token},
    );

    if (rows.isEmpty) return null;
    return rows.first.toColumnMap()['user_id'] as String;
  }

  Future<UserAccount?> getUserByToken(String token) async {
    await _ensureInitialized();
    final connection = await _db();
    final rows = await connection.execute(
      Sql.named('''
        SELECT
          u.id,
          u.email,
          u.is_active,
          u.created_at,
          u.updated_at
        FROM sessions s
        INNER JOIN users u ON u.id = s.user_id
        WHERE s.token = @token
          AND s.expires_at > NOW()
          AND u.is_active = TRUE
        LIMIT 1
      '''),
      parameters: <String, Object?>{'token': token},
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first.toColumnMap());
  }

  Future<List<UserSession>> listSessions({required String userId}) async {
    await _ensureInitialized();
    final connection = await _db();
    final rows = await connection.execute(
      Sql.named('''
        SELECT token, user_id, expires_at, created_at
        FROM sessions
        WHERE user_id = @user_id
          AND expires_at > NOW()
        ORDER BY created_at DESC
      '''),
      parameters: <String, Object?>{'user_id': userId},
    );
    return rows.map((row) => _sessionFromRow(row.toColumnMap())).toList();
  }

  Future<bool> revokeSessionByToken({
    required String userId,
    required String token,
    required RequestMeta requestMeta,
  }) async {
    await _ensureInitialized();
    final connection = await _db();
    final rows = await connection.execute(
      Sql.named('''
        DELETE FROM sessions
        WHERE token = @token
          AND user_id = @user_id
        RETURNING token
      '''),
      parameters: <String, Object?>{'token': token, 'user_id': userId},
    );
    final revoked = rows.isNotEmpty;
    await _logAuditEvent(
      connection,
      eventType: revoked ? 'auth.session.revoked' : 'auth.session.revoke_miss',
      severity: revoked ? 'info' : 'warn',
      requestMeta: requestMeta,
      userId: userId,
      targetType: 'session',
      targetId: token,
    );
    return revoked;
  }

  Future<void> _enforceLoginRateLimit(
    Connection connection, {
    required String email,
    required RequestMeta requestMeta,
  }) async {
    final windowMinutes = _envInt('PUGVPN_AUTH_RATE_LIMIT_WINDOW_MINUTES', 15);
    final maxAttempts = _envInt('PUGVPN_AUTH_RATE_LIMIT_MAX_ATTEMPTS', 8);
    final since = DateTime.now().toUtc().subtract(
      Duration(minutes: windowMinutes),
    );

    final rows = await connection.execute(
      Sql.named('''
        SELECT
          COUNT(*) AS cnt,
          MIN(created_at) AS oldest
        FROM audit_logs
        WHERE event_type = @event_type
          AND created_at >= @since
          AND (
            target_id = @email
            OR client_ip = @client_ip
          )
      '''),
      parameters: <String, Object?>{
        'event_type': 'auth.login.failed',
        'since': since,
        'email': email,
        'client_ip': requestMeta.clientIp,
      },
    );

    final row = rows.first.toColumnMap();
    final count = _asInt(row['cnt']);
    if (count < maxAttempts) return;

    final oldest = row['oldest'] as DateTime?;
    final retryAfterSeconds = oldest == null
        ? windowMinutes * 60
        : max(
            1,
            Duration(minutes: windowMinutes).inSeconds -
                DateTime.now().toUtc().difference(oldest.toUtc()).inSeconds,
          );

    await _logAuditEvent(
      connection,
      eventType: 'auth.login.rate_limited',
      severity: 'warn',
      requestMeta: requestMeta,
      targetType: 'email',
      targetId: email,
      details: {'retry_after_seconds': retryAfterSeconds},
    );
    throw RateLimitExceededException(retryAfterSeconds);
  }

  Future<void> _clearFailedLoginAttempts(
    Connection connection, {
    required String email,
    required String clientIp,
  }) async {
    await connection.execute(
      Sql.named('''
        DELETE FROM audit_logs
        WHERE event_type = @event_type
          AND (
            target_id = @email
            OR client_ip = @client_ip
          )
      '''),
      parameters: <String, Object?>{
        'event_type': 'auth.login.failed',
        'email': email,
        'client_ip': clientIp,
      },
    );
  }

  Future<void> _logAuditEvent(
    Session session, {
    required String eventType,
    required RequestMeta requestMeta,
    String severity = 'info',
    String? userId,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    await session.execute(
      Sql.named('''
        INSERT INTO audit_logs (
          id,
          event_type,
          severity,
          user_id,
          request_id,
          client_ip,
          target_type,
          target_id,
          details
        )
        VALUES (
          @id,
          @event_type,
          @severity,
          @user_id,
          @request_id,
          @client_ip,
          @target_type,
          @target_id,
          @details
        )
      '''),
      parameters: <String, Object?>{
        'id': _newId('audit'),
        'event_type': eventType,
        'severity': severity,
        'user_id': userId,
        'request_id': requestMeta.requestId,
        'client_ip': requestMeta.clientIp,
        'target_type': targetType,
        'target_id': targetId,
        'details': jsonEncode(<String, dynamic>{
          'user_agent': requestMeta.userAgent,
          ...?details,
        }),
      },
    );
  }

  String _hashPassword(String password) {
    final iterations = _envInt('PUGVPN_PASSWORD_HASH_ITERATIONS', 150000);
    final salt = _randomBytes(16);
    final derived = _pbkdf2(
      passwordBytes: utf8.encode(password),
      salt: salt,
      iterations: iterations,
      keyLength: 32,
    );
    return 'pbkdf2_sha256'
        '\$$iterations'
        '\$${base64Url.encode(salt)}'
        '\$${base64Url.encode(derived)}';
  }

  _PasswordVerification _verifyPassword({
    required String password,
    required String storedHash,
  }) {
    if (storedHash.startsWith('pbkdf2_sha256\$')) {
      final parts = storedHash.split('\$');
      if (parts.length != 4) {
        return _PasswordVerification(isValid: false, needsUpgrade: false);
      }

      final iterations = int.tryParse(parts[1]);
      if (iterations == null) {
        return _PasswordVerification(isValid: false, needsUpgrade: false);
      }

      try {
        final salt = base64Url.decode(parts[2]);
        final expected = base64Url.decode(parts[3]);
        final actual = _pbkdf2(
          passwordBytes: utf8.encode(password),
          salt: salt,
          iterations: iterations,
          keyLength: expected.length,
        );
        return _PasswordVerification(
          isValid: _constantTimeEquals(actual, expected),
          needsUpgrade: false,
        );
      } catch (_) {
        return _PasswordVerification(isValid: false, needsUpgrade: false);
      }
    }

    final legacy = sha256
        .convert(utf8.encode('$_legacyPasswordSalt:$password'))
        .toString();
    return _PasswordVerification(
      isValid: legacy == storedHash,
      needsUpgrade: legacy == storedHash,
    );
  }

  List<int> _pbkdf2({
    required List<int> passwordBytes,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, passwordBytes);
    const hashLength = 32;
    final blockCount = (keyLength / hashLength).ceil();
    final output = BytesBuilder(copy: false);

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final firstInput = <int>[...salt, ..._int32be(blockIndex)];
      var u = hmac.convert(firstInput).bytes;
      final t = List<int>.from(u);
      for (var iteration = 1; iteration < iterations; iteration++) {
        u = hmac.convert(u).bytes;
        for (var i = 0; i < t.length; i++) {
          t[i] ^= u[i];
        }
      }
      output.add(t);
    }

    final bytes = output.takeBytes();
    return bytes.sublist(0, keyLength);
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  List<int> _int32be(int value) {
    return <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }

  String get _legacyPasswordSalt {
    return Platform.environment['PUGVPN_PASSWORD_SALT']?.trim() ??
        'pugvpn-dev-salt';
  }

  String _issueToken(String userId) {
    final raw =
        '$userId:${DateTime.now().millisecondsSinceEpoch}:${_random.nextInt(1 << 32)}';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }
}
