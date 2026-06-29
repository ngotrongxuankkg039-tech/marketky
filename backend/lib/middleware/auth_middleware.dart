import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../models/auth_user.dart';
import '../utils/json_response.dart';

class AuthService {
  AuthService(this.secret);

  final String secret;

  String sign({
    required int userId,
    required String email,
    required Iterable<String> roles,
  }) {
    final jwt = JWT({'sub': userId, 'email': email, 'roles': roles.toList()});
    return jwt.sign(SecretKey(secret), expiresIn: const Duration(hours: 24));
  }

  AuthUser verify(String token) {
    final jwt = JWT.verify(token, SecretKey(secret));
    final payload = Map<String, dynamic>.from(jwt.payload as Map);
    final roles = (payload['roles'] as List? ?? const [])
        .map((role) => role.toString())
        .toSet();
    return AuthUser(
      id: int.parse(payload['sub'].toString()),
      email: payload['email']?.toString() ?? '',
      roles: roles,
    );
  }
}

Middleware requireAuth(AuthService authService) {
  return (innerHandler) {
    return (request) async {
      final header =
          request.headers['authorization'] ?? request.headers['Authorization'];
      if (header == null || !header.startsWith('Bearer ')) {
        return jsonResponse({
          'message': 'Missing Authorization bearer token',
        }, statusCode: 401);
      }
      try {
        final user = authService.verify(header.substring(7));
        return await innerHandler(request.change(context: {'authUser': user}));
      } catch (_) {
        return jsonResponse({
          'message': 'Invalid or expired token',
        }, statusCode: 401);
      }
    };
  };
}

Middleware requireRoles(Set<String> roles) {
  return (innerHandler) {
    return (request) async {
      final user = authUser(request);
      if (!user.hasAnyRole(roles)) {
        return jsonResponse({'message': 'Permission denied'}, statusCode: 403);
      }
      return innerHandler(request);
    };
  };
}

AuthUser authUser(Request request) => request.context['authUser'] as AuthUser;
