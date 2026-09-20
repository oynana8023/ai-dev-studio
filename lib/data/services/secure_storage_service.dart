import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kOpenRouterKey = 'openrouter_api_key';
  static const _kGithubToken = 'github_token';
  static const _kRoleMap = 'role_model_map';
  static const _kPlatformKeys = 'platform_api_keys';
  static const _kCustomProviders = 'custom_providers'; // 自定义平台

  Future<void> saveOpenRouterKey(String key) => _storage.write(key: _kOpenRouterKey, value: key);
  Future<String?> getOpenRouterKey() => _storage.read(key: _kOpenRouterKey);
  Future<void> clearOpenRouterKey() => _storage.delete(key: _kOpenRouterKey);

  Future<void> saveGithubToken(String token) => _storage.write(key: _kGithubToken, value: token);
  Future<String?> getGithubToken() => _storage.read(key: _kGithubToken);

  // 各平台 Key 存储
  Future<void> savePlatformKey(String platformId, String key) async {
    final raw = await _storage.read(key: _kPlatformKeys);
    final map = raw == null || raw.isEmpty
        ? <String, String>{}
        : Map<String, String>.from(jsonDecode(raw) as Map);
    map[platformId] = key;
    await _storage.write(key: _kPlatformKeys, value: jsonEncode(map));
  }

  Future<Map<String, String>> loadPlatformKeys() async {
    final raw = await _storage.read(key: _kPlatformKeys);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  // 自定义平台存储
  Future<void> saveCustomProviders(List<Map<String, String>> providers) =>
      _storage.write(key: _kCustomProviders, value: jsonEncode(providers));

  Future<List<Map<String, String>>> loadCustomProviders() async {
    final raw = await _storage.read(key: _kCustomProviders);
    if (raw == null || raw.isEmpty) return [];
    return List<Map<String, String>>.from(jsonDecode(raw) as List);
  }

  Future<void> saveRoleMap(Map<String, String> map) => _storage.write(key: _kRoleMap, value: jsonEncode(map));
  Future<Map<String, String>> loadRoleMap() async {
    final raw = await _storage.read(key: _kRoleMap);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }
}