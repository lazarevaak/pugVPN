import 'dart:io';

import 'package:postgres/postgres.dart';

class MigrationRunner {
  MigrationRunner({String? migrationsPath})
    : _migrationsPath = migrationsPath ?? 'migrations';

  final String _migrationsPath;

  Future<void> migrate(Connection connection) async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    ''');

    final dir = Directory(_migrationsPath);
    if (!dir.existsSync()) {
      throw StateError('Migrations directory not found: $_migrationsPath');
    }

    final applied = await _appliedVersions(connection);
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final version = file.uri.pathSegments.last;
      if (applied.contains(version)) continue;

      final sql = file.readAsStringSync();
      final statements = _splitStatements(sql);
      if (statements.isEmpty) continue;

      await connection.runTx((tx) async {
        for (final statement in statements) {
          await tx.execute(statement);
        }
        await tx.execute(
          Sql.named('''
            INSERT INTO schema_migrations (version)
            VALUES (@version)
          '''),
          parameters: <String, Object?>{'version': version},
        );
      });
    }
  }

  Future<Set<String>> _appliedVersions(Connection connection) async {
    final rows = await connection.execute(
      'SELECT version FROM schema_migrations',
    );
    return rows.map((row) => row.toColumnMap()['version'] as String).toSet();
  }

  List<String> _splitStatements(String sql) {
    final statements = <String>[];
    final buffer = StringBuffer();
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      }

      if (char == ';' && !inSingleQuote && !inDoubleQuote) {
        final statement = buffer.toString().trim();
        if (statement.isNotEmpty) {
          statements.add(statement);
        }
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    final tail = buffer.toString().trim();
    if (tail.isNotEmpty) {
      statements.add(tail);
    }
    return statements;
  }
}
