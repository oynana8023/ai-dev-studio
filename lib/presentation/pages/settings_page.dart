import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('模型与角色'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/models'),
          ),
          const ListTile(leading: Icon(Icons.code), title: Text('GitHub 仓库'), subtitle: Text('Day 4 接入')),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('关于'), subtitle: Text('AI Dev Studio v0.1.0')),
        ],
      ),
    );
  }
}