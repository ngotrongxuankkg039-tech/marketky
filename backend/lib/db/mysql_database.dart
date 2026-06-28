import 'dart:collection';

import 'package:mysql_client/mysql_client.dart';

class DatabaseConfig {
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
}

class DbRow {
  DbRow(this.fields);

  final Map<String, dynamic> fields;
}

class DbResult extends IterableBase<DbRow> {
  DbResult({required this.rows, this.insertId, this.affectedRows = 0});

  final List<DbRow> rows;
  final int? insertId;
  final int affectedRows;

  @override
  Iterator<DbRow> get iterator => rows.iterator;
}

class DbConnection {
  DbConnection(this._connection);

  final MySQLConnection _connection;

  Future<DbResult> query(String sql, [List<Object?> params = const []]) async {
    final prepared = _prepareNamedParams(sql, params);
    final result = await _connection.execute(prepared.sql, prepared.params);
    return DbResult(
      rows: [
        for (final row in result.rows) DbRow(_normalizeRow(row.typedAssoc())),
      ],
      insertId: result.lastInsertID.toInt(),
      affectedRows: result.affectedRows.toInt(),
    );
  }

  Future<void> close() => _connection.close();

  _PreparedSql _prepareNamedParams(String sql, List<Object?> params) {
    if (params.isEmpty) {
      return _PreparedSql(sql, const {});
    }
    final values = <String, Object?>{};
    var index = 0;
    final buffer = StringBuffer();
    for (var i = 0; i < sql.length; i++) {
      if (sql.codeUnitAt(i) == 63) {
        final name = 'p$index';
        buffer.write(':$name');
        values[name] = params[index];
        index++;
      } else {
        buffer.write(sql[i]);
      }
    }
    if (index != params.length) {
      throw ArgumentError(
        'SQL placeholder count does not match parameter count',
      );
    }
    return _PreparedSql(buffer.toString(), values);
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    return row.map((key, value) => MapEntry(key, _normalizeValue(value)));
  }

  Object? _normalizeValue(Object? value) {
    if (value is BigInt) {
      return value.toInt();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }
}

class _PreparedSql {
  const _PreparedSql(this.sql, this.params);

  final String sql;
  final Map<String, Object?> params;
}

class MySqlDatabase {
  const MySqlDatabase(this.config);

  final DatabaseConfig config;

  Future<DbConnection> open() async {
    final connection = await MySQLConnection.createConnection(
      host: config.host,
      port: config.port,
      userName: config.user,
      password: config.password,
      databaseName: config.database,
    );
    await connection.connect();
    return DbConnection(connection);
  }

  Future<T> withConnection<T>(
    Future<T> Function(DbConnection connection) action,
  ) async {
    final connection = await open();
    try {
      return await action(connection);
    } finally {
      await connection.close();
    }
  }

  Future<T> transaction<T>(
    Future<T> Function(DbConnection connection) action,
  ) async {
    return withConnection((connection) async {
      await connection.query('START TRANSACTION');
      try {
        final result = await action(connection);
        await connection.query('COMMIT');
        return result;
      } catch (_) {
        await connection.query('ROLLBACK');
        rethrow;
      }
    });
  }
}
