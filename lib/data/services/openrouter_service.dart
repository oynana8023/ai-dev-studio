import 'package:dio/dio.dart';
import '../models/ai_model.dart';
import 'secure_storage_service.dart';

class OpenRouterService {
  static const _base = 'https://openrouter.ai/api/v1';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _base,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  final SecureStorageService _storage;
  OpenRouterService(this._storage);

  Future<List<AiModel>> fetchModels() async {
    final key = await _storage.getOpenRouterKey();
    final res = await _dio.get(
      '/models',
      options: Options(
        headers: { if (key != null && key.isNotEmpty) 'Authorization': 'Bearer $key' },
      ),
    );
    final data = res.data['data'] as List;
    return data.map((e) => AiModel.fromOpenRouter(e as Map<String, dynamic>)).toList();
  }

  Future<String> chat({
    required String modelId,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    final key = await _storage.getOpenRouterKey();
    if (key == null || key.isEmpty) throw Exception('未配置 OpenRouter API Key');
    final res = await _dio.post(
      '/chat/completions',
      data: { 'model': modelId, 'messages': messages, 'temperature': temperature },
      options: Options(
        headers: {
          'Authorization': 'Bearer $key',
          'HTTP-Referer': 'https://github.com/ai-dev-studio',
          'X-Title': 'AI Dev Studio',
        },
      ),
    );
    final choices = res.data['choices'] as List;
    return choices.first['message']['content'] as String;
  }
}