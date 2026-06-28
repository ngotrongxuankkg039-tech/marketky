import 'package:mysql1/mysql1.dart';

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

class MySqlDatabase {
  const MySqlDatabase(this.config);

  final DatabaseConfig config;

  Future<MySqlConnection> open() {
    return MySqlConnection.connect(
      ConnectionSettings(
        host: config.host,
        port: config.port,
        user: config.user,
        password: config.password,
        db: config.database,
      ),
    );
  }

  Future<T> withConnection<T>(
    Future<T> Function(MySqlConnection connection) action,
  ) async {
    final connection = await open();
    try {
      return await action(connection);
    } finally {
      await connection.close();
    }
  }

  Future<T> transaction<T>(
    Future<T> Function(MySqlConnection connection) action,
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
