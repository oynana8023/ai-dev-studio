import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/model_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ModelRepository>();
    final ready = repo.roleAssignments.length == 6;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Dev Studio'), actions: [
        IconButton(icon: const Icon(Icons.tune), onPressed: () => context.push('/models')),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(ready: ready, freeCount: repo.freeModels.length),
          const SizedBox(height: 16),
          _ActionTile(icon: Icons.chat_bubble_outline, title: '开始开发', subtitle: '用自然语言描述你想做的软件', onTap: () => context.push('/chat')),
          _ActionTile(icon: Icons.account_tree_outlined, title: '工作流', subtitle: '查看 / 自定义多智能体协作流程', onTap: () => context.go('/workflow')),
          _ActionTile(icon: Icons.phone_iphone_outlined, title: '实时预览', subtitle: '查看当前生成的界面效果', onTap: () => context.go('/preview')),
          _ActionTile(icon: Icons.smart_toy_outlined, title: '模型与角色', subtitle: '配置 API Key、拉取免费模型、分配角色', onTap: () => context.push('/models')),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool ready;
  final int freeCount;
  const _StatusCard({required this.ready, required this.freeCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(ready ? Icons.check_circle : Icons.warning_amber_rounded, color: ready ? Colors.greenAccent : Colors.orangeAccent),
              const SizedBox(width: 8),
              Text(ready ? '系统就绪' : '待配置', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 8),
            Text(ready ? '已分配 6 个角色，可用免费模型 $freeCount 个' : '请先配置 OpenRouter Key 并拉取模型', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}