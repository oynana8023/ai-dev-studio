import '../models/agent_role.dart';
import '../models/ai_model.dart';
import 'domestic_ai_service.dart';
import 'openrouter_service.dart';
import 'secure_storage_service.dart';

class AiChatService {
  final OpenRouterService _openRouter;
  final DomesticAiService _domestic;
  final SecureStorageService _storage;

  AiChatService(this._openRouter, this._domestic, this._storage);

  Future<String> chatWithRole({
    required AgentRole role,
    required String modelId,
    required String providerId,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    if (providerId == 'openrouter') {
      return await _openRouter.chat(
        modelId: modelId,
        messages: messages,
        temperature: temperature,
      );
    } else {
      final platformKeys = await _storage.loadPlatformKeys();
      final key = platformKeys[providerId];
      if (key == null || key.isEmpty) {
        throw Exception('未配置该平台的 API Key');
      }

      String baseUrl;
      final customProviders = await _storage.loadCustomProviders();
      final custom = customProviders.firstWhere(
        (p) => p['id'] == providerId,
        orElse: () => {},
      );

      if (custom.isNotEmpty) {
        baseUrl = custom['baseUrl']!;
      } else {
        final platform = DomesticAiService.platforms
            .firstWhere((p) => p.id == providerId);
        baseUrl = platform.baseUrl;
      }

      return await _domestic.chat(
        baseUrl: baseUrl,
        apiKey: key,
        modelId: modelId,
        messages: messages,
        temperature: temperature,
      );
    }
  }
}