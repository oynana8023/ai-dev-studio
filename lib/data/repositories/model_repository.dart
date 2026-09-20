import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../models/agent_role.dart';
import '../models/ai_model.dart';
import '../services/domestic_ai_service.dart';
import '../services/openrouter_service.dart';
import '../services/secure_storage_service.dart';

class ModelRepository extends ChangeNotifier {
  final OpenRouterService _openRouter;
  final DomesticAiService _domestic;
  final SecureStorageService _storage;

  List<AiModel> _all = [];
  List<AiModel> _free = [];
  bool _loading = false;
  String? _error;
  Map<AgentRole, String> _roleAssignments = {};

  ModelRepository(this._openRouter, this._domestic, this._storage);

  List<AiModel> get allModels => _all;
  List<AiModel> get freeModels => _free;
  bool get isLoading => _loading;
  String? get error => _error;
  Map<AgentRole, String> get roleAssignments => _roleAssignments;

  AiModel? modelById(String id) => _all.firstWhereOrNull((m) => m.id == id) ?? null;

  Future<void> restore() async {
    final saved = await _storage.loadRoleMap();
    _roleAssignments = saved.map((k, v) => MapEntry(
      AgentRole.values.firstWhere((r) => r.name == k, orElse: () => AgentRole.commander), v,
    ));
    notifyListeners();
  }

  Future<void> loadModels() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final List<AiModel> all = [];

      // 1. 拉取 OpenRouter（如果有配置）
      final orKey = await _storage.getOpenRouterKey();
      if (orKey != null && orKey.isNotEmpty) {
        all.addAll(await _openRouter.fetchModels());
      }

      // 2. 拉取国内预置平台
      final platformKeys = await _storage.loadPlatformKeys();
      for (final platform in DomesticAiService.platforms) {
        final key = platformKeys[platform.id];
        if (key != null && key.isNotEmpty) {
          try {
            final models = await _domestic.fetchModels(
              baseUrl: platform.baseUrl, apiKey: key, platformId: platform.id,
            );
            all.addAll(models);
          } catch (_) { /* 单个平台失败不影响其它 */ }
        }
      }

      // 3. 拉取自定义平台
      final customProviders = await _storage.loadCustomProviders();
      for (final cp in customProviders) {
        final key = cp['apiKey'];
        if (key != null && key.isNotEmpty) {
          try {
            final models = await _domestic.fetchModels(
              baseUrl: cp['baseUrl']!, apiKey: key, platformId: cp['id']!,
            );
            all.addAll(models);
          } catch (_) {}
        }
      }

      _all = all;
      _free = all.where((m) => m.isFree).toList()
        ..sort((a, b) => b.contextLength.compareTo(a.contextLength));
      await _autoAssignRoles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _autoAssignRoles() async {
    final map = <AgentRole, String>{};
    for (final role in AgentRole.values) {
      final picked = _pickForRole(role);
      if (picked != null) map[role] = picked.id;
    }
    _roleAssignments = map;
    await _storage.saveRoleMap(map.map((k, v) => MapEntry(k.name, v)));
    notifyListeners();
  }

  AiModel? _pickForRole(AgentRole role) {
    bool hit(AiModel m, List<String> keys) {
      final s = '${m.id} ${m.name}'.toLowerCase();
      return keys.any(s.contains);
    }

    switch (role) {
      case AgentRole.commander:
        return _free.firstWhereOrNull((m) => hit(m, ['glm-4.7', 'deepseek-v4-pro', 'qwen-max', 'ernie-4.0', 'llama3-70b'])) ?? _free.firstOrNull;
      case AgentRole.frontend:
        return _free.firstWhereOrNull((m) => hit(m, ['deepseek-coder', 'glm-4', 'qwen-coder', 'codegeex', 'mistral'])) ?? _free.firstOrNull;
      case AgentRole.backend:
        return _free.firstWhereOrNull((m) => hit(m, ['deepseek', 'glm-4', 'qwen-plus', 'ernie-4.0'])) ?? _free.firstOrNull;
      case AgentRole.tester:
        return _free.firstWhereOrNull((m) => hit(m, ['glm-4.7-flash', 'qwen-turbo', 'deepseek-flash'])) ?? _free.firstOrNull;
      case AgentRole.reviewer:
        return _free.firstWhereOrNull((m) => hit(m, ['deepseek-v4-pro', 'glm-5', 'ernie-4.0', 'llama3-70b'])) ?? _free.firstOrNull;
      case AgentRole.optimizer:
        return _free.firstWhereOrNull((m) => hit(m, ['glm-4', 'qwen-plus', 'hunyuan-standard'])) ?? _free.firstOrNull;
    }
  }

  Future<void> assignRole(AgentRole role, String modelId) async {
    _roleAssignments[role] = modelId;
    await _storage.saveRoleMap(_roleAssignments.map((k, v) => MapEntry(k.name, v)));
    notifyListeners();
  }
}