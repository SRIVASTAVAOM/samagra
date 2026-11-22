import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              webOptions: WebOptions.defaultOptions,
            );

  static const String _tokenKey = 'jwt_auth_token';
  static const String _userRoleKey = 'active_user_role';
  static const String _userIdKey = 'active_user_id';
  static const String _userDataKey = 'cached_user_model';

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserInfo({required String userId, required String role}) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _userRoleKey, value: role);
    } catch (_) {}
  }

  Future<String?> getActiveRole() async {
    try {
      return await _storage.read(key: _userRoleKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _userDataKey, value: jsonEncode(userData));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final raw = await _storage.read(key: _userDataKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}
