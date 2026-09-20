import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kOpenRouterKey = 'openrouter_api_key';
  static const _kGithubToken = 'github_token';
  static const _kRoleMap = 'role_model_map';

  Future<void> saveOpenRouterKey(String key) => _storage.write(key: _kOpenRouterKey, value: key);
  Future<String?> getOpenRouterKey() => _storage.read(key: _kOpenRouterKey);
  Future<void> clearOpenRouterKey() => _storage.delete(key: _kOpenRouterKey);

  Future<void> saveGithubToken(String token) => _storage.write(key: _kGithubToken, value: token);
  Future<String?> getGithubToken() => _storage.read(key: _kGithubToken);

  Future<void> saveRoleMap(Map<String, String> map) => _storage.write(key: _kRoleMap, value: jsonEncode(map));
  Future<Map<String, String>> loadRoleMap() async {
    final raw = await _storage.read(key: _kRoleMap);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }
}