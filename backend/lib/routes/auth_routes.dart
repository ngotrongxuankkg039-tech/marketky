import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../middleware/auth_middleware.dart';
import '../utils/json_response.dart';
import '../utils/password_hash.dart';
import '../utils/request_body.dart';

class AuthRoutes {
  AuthRoutes(this._database, this._authService);

  final MySqlDatabase _database;
  final AuthService _authService;

  Router get router => Router()
    ..post('/register', _register)
    ..post('/login', _login);

  Future<Response> _register(Request request) async {
    final body = await readJsonObject(request);
    final name = body['name']?.toString().trim() ?? '';
    final email = body['email']?.toString().trim().toLowerCase() ?? '';
    final password = body['password']?.toString() ?? '';
    if (name.isEmpty || email.isEmpty || password.length < 8) {
      return jsonResponse({
        'message': 'Name, email and an 8-character password are required',
      }, statusCode: 400);
    }

    return _database.transaction((connection) async {
      final exists = await connection.query(
        'SELECT id FROM users WHERE email = ?',
        [email],
      );
      if (exists.isNotEmpty) {
        return jsonResponse({
          'message': 'Email already registered',
        }, statusCode: 409);
      }
      final userResult = await connection.query(
        'INSERT INTO users(name, email, password_hash, status) VALUES (?, ?, ?, "ACTIVE")',
        [name, email, PasswordHash.create(password)],
      );
      final userId = userResult.insertId!;
      await _grantRole(connection, userId, 'BUYER');
      await connection.query('INSERT INTO carts(user_id) VALUES (?)', [userId]);
      return _sessionResponse(connection, userId);
    });
  }

  Future<Response> _login(Request request) async {
    final body = await readJsonObject(request);
    final email = body['email']?.toString().trim().toLowerCase() ?? '';
    final password = body['password']?.toString() ?? '';
    return _database.withConnection((connection) async {
      final users = await connection.query(
        'SELECT id, password_hash, status FROM users WHERE email = ?',
        [email],
      );
      if (users.isEmpty || users.first.fields['status'] != 'ACTIVE') {
        return jsonResponse({
          'message': 'Invalid email or password',
        }, statusCode: 401);
      }
      final row = users.first.fields;
      if (!PasswordHash.verify(password, row['password_hash'].toString())) {
        return jsonResponse({
          'message': 'Invalid email or password',
        }, statusCode: 401);
      }
      return _sessionResponse(connection, row['id'] as int);
    });
  }

  Future<void> _grantRole(
    DbConnection connection,
    int userId,
    String roleCode,
  ) async {
    final roles = await connection.query(
      'SELECT id FROM roles WHERE code = ?',
      [roleCode],
    );
    if (roles.isEmpty) {
      throw StateError(
        'Role $roleCode is missing. Run database/schema.sql first.',
      );
    }
    await connection.query(
      'INSERT INTO user_roles(user_id, role_id) VALUES (?, ?)',
      [userId, roles.first.fields['id']],
    );
  }

  Future<Response> _sessionResponse(DbConnection connection, int userId) async {
    final results = await connection.query(
      '''
      SELECT u.id, u.name, u.email, r.code AS role_code
      FROM users u
      JOIN user_roles ur ON ur.user_id = u.id
      JOIN roles r ON r.id = ur.role_id
      WHERE u.id = ?
      ''',
      [userId],
    );
    final first = results.first.fields;
    final roles = results
        .map((row) => row.fields['role_code'].toString())
        .toList();
    final token = _authService.sign(
      userId: userId,
      email: first['email'].toString(),
      roles: roles,
    );
    return jsonResponse({
      'token': token,
      'user': {
        'id': userId,
        'name': first['name'],
        'email': first['email'],
        'roles': roles,
      },
    });
  }
}
