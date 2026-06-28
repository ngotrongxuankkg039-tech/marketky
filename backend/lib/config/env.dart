import 'dart:io';

import '../db/mysql_database.dart';

class AppEnv {
  static DatabaseConfig databaseConfig() {
    return DatabaseConfig(
      host: _get('MYSQL_HOST', '127.0.0.1'),
      port: int.parse(_get('MYSQL_PORT', '3306')),
      user: _get('MYSQL_USER', 'root'),
      password: _get('MYSQL_PASSWORD', 'root'),
      database: _get('MYSQL_DATABASE', 'marketky_shop'),
    );
  }

  static String get jwtSecret =>
      _get('JWT_SECRET', 'change-me-marketky-course-design-secret');

  static String _get(String key, String fallback) {
    final value = Platform.environment[key];
    return value == null || value.isEmpty ? fallback : value;
  }
}
