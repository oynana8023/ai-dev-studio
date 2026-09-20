import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/model_repository.dart';
import 'data/services/openrouter_service.dart';
import 'data/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final openRouter = OpenRouterService(secureStorage);
  final modelRepo = ModelRepository(openRouter, secureStorage);
  await modelRepo.restore();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: secureStorage),
        Provider.value(value: openRouter),
        ChangeNotifierProvider.value(value: modelRepo),
      ],
      child: const AiDevStudioApp(),
    ),
  );
}