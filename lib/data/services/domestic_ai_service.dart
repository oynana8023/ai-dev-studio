import 'package:dio/dio.dart';
import '../models/ai_model.dart';

class DomesticAiPlatform {
  final String id;
  final String name;
  final String baseUrl;
  final String consoleUrl;
  final bool isCustom;

  const DomesticAiPlatform({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.consoleUrl,
    this.isCustom = false,
  });
}

class DomesticAiService {
  static const platforms = <DomesticAiPlatform>[
    DomesticAiPlatform(
      id: 'zhipu',
      name: '智谱 GLM',
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      consoleUrl: 'https://open.bigmodel.cn',
    ),
    DomesticAiPlatform(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      consoleUrl: 'https://platform.deepseek.com',
    ),
    DomesticAiPlatform(
      id: 'qwen',
      name: '通义千问',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      consoleUrl: 'https://bailian.console.aliyun.com',
    ),
    DomesticAiPlatform(
      id: 'ernie',
      name: '百度文心',
      baseUrl: 'https://aistudio.baidu.com/llm/lmapi/v3',
      consoleUrl: 'https://aistudio.baidu.com',
    ),
    DomesticAiPlatform(
      id: 'doubao',
      name: '字节豆包',
      baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      consoleUrl: 'https://console.volcengine.com/ark',
    ),
    DomesticAiPlatform(
      id: 'hunyuan',
      name: '腾讯混元',
      baseUrl: 'https://api.hunyuan.cloud.tencent.com/v1',
      consoleUrl: 'https://console.cloud.tencent.com/hunyuan',
    ),
    DomesticAiPlatform(
      id: 'spark',
      name: '讯飞星火',
      baseUrl: 'https://spark-api-open.xf-yun.com/v1',
      consoleUrl: 'https://console.xfyun.cn',
    ),
    DomesticAiPlatform(
      id: 'nvidia',
      name: '英伟达 NIM',
      baseUrl: 'https://integrate.api.nvidia.com/v1',
      consoleUrl: 'https://build.nvidia.com',
    ),
  ];

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 120),
  ));

  Future<List<AiModel>> fetchModels({
    required String baseUrl,
    required String apiKey,
    required String platformId,
  }) async {
    final res = await _dio.get(
      '$baseUrl/models',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      }),
    );
    final data = res.data['data'] as List;
    return data.map((e) => AiModel.fromDomestic(
      e as Map<String, dynamic>, platformId,
    )).toList();
  }

  Future<String> chat({
    required String baseUrl,
    required String apiKey,
    required String modelId,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    final res = await _dio.post(
      '$baseUrl/chat/completions',
      data: {
        'model': modelId,
        'messages': messages,
        'temperature': temperature,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
    );
    final choices = res.data['choices'] as List;
    return choices.first['message']['content'] as String;
  }
}