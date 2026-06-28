import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/api_client.dart';
import '../common/app_constants.dart';
import '../model/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._apiClient) {
    _apiClient.onUnauthorized = expireSession;
  }

  final ApiClient _apiClient;
  AppUser? user;
  String? token;
  bool isRestoring = true;
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => user != null && token != null;

  bool hasRole(String role) => user?.hasRole(role) ?? false;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (token != null && userJson != null) {
      user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _apiClient.setToken(token);
    }
    isRestoring = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authenticate('/auth/login', {'email': email, 'password': password});
  }

  Future<void> register(String name, String email, String password) async {
    await _authenticate('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> registerMerchant({
    required String name,
    required String email,
    required String password,
    required String shopName,
    required String description,
    required String licenseNo,
  }) async {
    await _authenticate('/auth/merchant-register', {
      'name': name,
      'email': email,
      'password': password,
      'shopName': shopName,
      'description': description,
      'licenseNo': licenseNo,
    });
  }

  Future<void> useDemoRole(String role) async {
    final email = switch (role) {
      AppRoles.admin => 'admin@marketky.local',
      AppRoles.merchant => 'merchant@marketky.local',
      _ => 'buyer@marketky.local',
    };
    await login(email, 'Password@123');
  }

  Future<void> _authenticate(String path, Map<String, String> body) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data =
          await _apiClient.post(path, body: body) as Map<String, dynamic>;
      final nextToken = data['token']?.toString();
      final nextUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      if (nextToken == null || nextToken.isEmpty) {
        throw ApiException('后端未返回登录令牌');
      }
      await _saveSession(nextToken, nextUser);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String nextToken, AppUser nextUser) async {
    token = nextToken;
    user = nextUser;
    _apiClient.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token!);
    await prefs.setString('auth_user', jsonEncode(user!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> expireSession() async {
    if (token == null && user == null) return;
    await _clearSession();
    errorMessage = '登录已过期，请重新登录';
    notifyListeners();
  }

  Future<void> _clearSession() async {
    token = null;
    user = null;
    _apiClient.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}
