import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/agent_role.dart';
import 'ai_chat_service.dart';
import '../repositories/model_repository.dart';

class DevTask {
  final String role;
  final String description;
  DevTask(this.role, this.description);
}

class OrchestratorService extends ChangeNotifier {
  final AiChatService _chat;
  final ModelRepository _modelRepo;

  bool _isWorking = false;
  String? _error;
  List<DevTask> _tasks = [];
  String _rawResponse = '';

  OrchestratorService(this._chat, this._modelRepo);

  bool get isWorking => _isWorking;
  String? get error => _error;
  List<DevTask> get tasks => _tasks;
  String get rawResponse => _rawResponse;

  Future<void> analyzeRequirement(String requirement) async {
    _isWorking = true;
    _error = null;
    _tasks = [];
    _rawResponse = '';
    notifyListeners();

    try {
      final commanderModelId = _modelRepo.roleAssignments[AgentRole.commander];
      if (commanderModelId == null) {
        throw Exception('未分配总指挥模型，请先在“模型与角色”页面配置');
      }
      final model = _modelRepo.modelById(commanderModelId);
      if (model == null) throw Exception('找不到总指挥模型信息');

      final systemPrompt = '''你是一个软件开发团队的总指挥。请分析用户的需求，将其拆解为开发任务清单。
必须严格按以下 JSON 数组格式输出，不要包含任何多余的文字或 Markdown 标记：
[{"role": "前端工程师", "description": "具体的任务描述"}, {"role": "后端工程师", "description": "具体的任务描述"}]
角色只允许使用以下 6 个之一：总指挥、前端工程师、后端工程师、测试工程师、代码审查员、优化顾问。''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': requirement},
      ];

      final response = await _chat.chatWithRole(
        role: AgentRole.commander,
        modelId: commanderModelId,
        providerId: model.providerId,
        messages: messages,
      );

      _rawResponse = response;
      _parseTasks(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  void _parseTasks(String raw) {
    try {
      // 尝试提取 JSON 部分
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) {
        throw FormatException('AI 未返回有效的 JSON 数组');
      }
      final jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> list = jsonDecode(jsonStr) as List;
      _tasks = list.map((e) => DevTask(
            e['role'] as String? ?? '未知角色',
            e['description'] as String? ?? '无描述',
          )).toList();
    } catch (e) {
      _tasks = [DevTask('解析失败', 'AI 返回格式不规范，请重试。原始回复：\n$raw')];
    }
  }
}