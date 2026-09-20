import 'package:go_router/go_router.dart';

import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/model_config_page.dart';
import '../../presentation/pages/preview_page.dart';
import '../../presentation/pages/settings_page.dart';
import '../../presentation/pages/workflow_page.dart';
import '../../presentation/widgets/main_shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/workflow', builder: (_, __) => const WorkflowPage()),
          GoRoute(path: '/preview', builder: (_, __) => const PreviewPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
      GoRoute(path: '/models', builder: (_, __) => const ModelConfigPage()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
    ],
  );
}