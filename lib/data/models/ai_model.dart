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

  const AiModel({
    required this.id,
    required this.name,
    this.description,
    this.contextLength = 0,
    this.isFree = true,
    this.capability = ModelCapability.unknown,
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
    );
  }
}