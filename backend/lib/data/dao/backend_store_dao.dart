import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:pug_vpn_backend/core/exceptions/backend_exception.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/data/dao/migration_runner_dao.dart';
import 'package:pug_vpn_backend/domain/entities/amnezia_settings.dart';
import 'package:pug_vpn_backend/domain/entities/device.dart';
import 'package:pug_vpn_backend/domain/entities/server_node.dart';
import 'package:pug_vpn_backend/domain/entities/server_preflight.dart';
import 'package:pug_vpn_backend/domain/entities/user_account.dart';
import 'package:pug_vpn_backend/domain/entities/user_session.dart';

part 'backend_store_dao_auth.dart';
part 'backend_store_dao_devices.dart';
part 'backend_store_dao_servers.dart';
part 'backend_store_dao_support.dart';
part 'backend_store_dao_vpn.dart';

class _PasswordVerification {
  _PasswordVerification({required this.isValid, required this.needsUpgrade});

  final bool isValid;
  final bool needsUpgrade;
}

class BackendStoreDao {
  BackendStoreDao();

  static final Map<String, String> _secrets = _loadSecrets();
  static final MigrationRunner _migrationRunner = MigrationRunner();

  final _random = Random.secure();

  Connection? _connection;
  Future<Connection>? _openingConnection;
  Future<void>? _initializing;
}
