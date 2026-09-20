import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../models/agent_role.dart';
import '../models/ai_model.dart';
import '../services/openrouter_service.dart';
import '../services/secure_storage_service.dart';

class ModelRepository extends ChangeNotifier {
  final OpenRouterService _api;
  final SecureStorageService _storage;

  List<AiModel> _all = [];
  List<AiModel> _free = [];
  bool _loading = false;
  String? _error;
  Map<AgentRole, String> _roleAssignments = {};

  ModelRepository(this._api, this._storage);

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
      final all = await _api.fetchModels();
      _all = all;
      _free = all.where((m) => m.isFree).toList()..sort((a, b) => b.contextLength.compareTo(a.contextLength));
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
      case AgentRole.commander: return _free.firstWhereOrNull((m) => hit(m, ['gemini', 'r1', 'reason', 'o3'])) ?? _free.firstOrNull;
      case AgentRole.frontend: return _free.firstWhereOrNull((m) => hit(m, ['coder', 'qwen', 'claude'])) ?? _free.firstOrNull;
      case AgentRole.backend: return _free.firstWhereOrNull((m) => hit(m, ['deepseek', 'llama', 'coder'])) ?? _free.firstOrNull;
      case AgentRole.tester: return _free.firstWhereOrNull((m) => hit(m, ['gemini', 'qwen'])) ?? _free.firstOrNull;
      case AgentRole.reviewer: return _free.firstWhereOrNull((m) => hit(m, ['deepseek', 'r1'])) ?? _free.firstOrNull;
      case AgentRole.optimizer: return _free.firstWhereOrNull((m) => hit(m, ['gemini', 'llama'])) ?? _free.firstOrNull;
    }
  }

  Future<void> assignRole(AgentRole role, String modelId) async {
    _roleAssignments[role] = modelId;
    await _storage.saveRoleMap(_roleAssignments.map((k, v) => MapEntry(k.name, v)));
    notifyListeners();
  }
}