enum ModelCapability {
  reasoning, coding, frontend, backend, testing, reviewing, fast, unknown;

  static ModelCapability infer(String id, String name) {
    final s = '$id $name'.toLowerCase();
    if (s.contains('gemini') || s.contains('o1') || s.contains('o3') || s.contains('r1') || s.contains('reason')) {
      return ModelCapability.reasoning;
    }
    if (s.contains('coder') || s.contains('codestral') || s.contains('deepseek')) {
      return ModelCapability.coding;
    }
    if (s.contains('qwen') || s.contains('llama')) {
      return ModelCapability.fast;
    }
    return ModelCapability.unknown;
  }

  String get label {
    switch (this) {
      case ModelCapability.reasoning: return '推理';
      case ModelCapability.coding: return '编码';
      case ModelCapability.frontend: return '前端';
      case ModelCapability.backend: return '后端';
      case ModelCapability.testing: return '测试';
      case ModelCapability.reviewing: return '审查';
      case ModelCapability.fast: return '快速';
      case ModelCapability.unknown: return '通用';
    }
  }
}

class AiModel {
  final String id;
  final String name;
  final String? description;
  final int contextLength;
  final bool isFree;
  final ModelCapability capability;
  final String providerId; // 新增，用于区分模型来源

  const AiModel({
    required this.id,
    required this.name,
    this.description,
    this.contextLength = 0,
    this.isFree = true,
    this.capability = ModelCapability.unknown,
    this.providerId = 'unknown',
  });

  factory AiModel.fromOpenRouter(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>? ?? {};
    final prompt = double.tryParse(pricing['prompt']?.toString() ?? '0') ?? 0;
    final completion = double.tryParse(pricing['completion']?.toString() ?? '0') ?? 0;
    final id = json['id'] as String;
    final name = json['name'] as String? ?? id;
    return AiModel(
      id: id,
      name: name,
      description: json['description'] as String?,
      contextLength: json['context_length'] as int? ?? 0,
      isFree: prompt == 0 && completion == 0,
      capability: ModelCapability.infer(id, name),
      providerId: 'openrouter',
    );
  }

  factory AiModel.fromDomestic(Map<String, dynamic> json, String platformId) {
    final id = json['id'] as String;
    final name = json['name'] as String? ?? json['id'] as String;

    // 国内各大平台免费模型库（可根据各平台最新政策持续补充）
    final freeModels = {
      'zhipu': ['glm-4.7-flash', 'glm-4-flash', 'glm-4v-flash'],
      'deepseek': ['deepseek-flash'],
      'qwen': ['qwen-turbo', 'qwen-plus', 'qwen-vl-plus'],
      'ernie': ['ernie-3.5-turbo', 'ernie-speed', 'ernie-speed-128k', 'ernie-lite'],
      'doubao': ['doubao-1-5-lite', 'doubao-lite-4k'],
      'hunyuan': ['hunyuan-lite'],
      'spark': ['spark-lite'],
      'nvidia': ['meta/llama3-70b-instruct', 'mistralai/mistral-7b-instruct-v0.3', 'google/gemma-2-9b-it'],
    };

    final isFree = freeModels[platformId]?.contains(id) ?? false;

    return AiModel(
      id: id,
      name: name,
      description: json['description'] as String?,
      contextLength: json['context_length'] as int? ?? 0,
      isFree: isFree,
      capability: ModelCapability.infer(id, name),
      providerId: platformId,
    );
  }
}