import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/agent_role.dart';
import '../../data/repositories/model_repository.dart';
import '../../data/services/secure_storage_service.dart';

class ModelConfigPage extends StatefulWidget {
  const ModelConfigPage({super.key});
  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  final _keyController = TextEditingController();
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final key = await context.read<SecureStorageService>().getOpenRouterKey();
    if (key != null && mounted) _keyController.text = key;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveAndFetch() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请粘贴 OpenRouter API Key')));
      return;
    }
    await context.read<SecureStorageService>().saveOpenRouterKey(key);
    if (!mounted) return;
    await context.read<ModelRepository>().loadModels();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ModelRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('模型与角色')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('1. 配置 OpenRouter Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('访问 openrouter.ai → Keys → 新建 Key（免费，无需绑卡）', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: !_showKey,
                  decoration: InputDecoration(
                    hintText: 'sk-or-v1-...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showKey = !_showKey)),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: repo.isLoading ? null : _saveAndFetch,
                  icon: repo.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_download_outlined),
                  label: Text(repo.isLoading ? '拉取中…' : '保存并拉取模型'),
                ),
                if (repo.error != null) ...[
                  const SizedBox(height: 8),
                  Text(repo.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('2. 角色分配（已自动打标）', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('免费模型 ${repo.freeModels.length} 个 · 可点开重新指定', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          ...AgentRole.values.map((role) => _RoleCard(role: role)),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final AgentRole role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ModelRepository>();
    final modelId = repo.roleAssignments[role];
    final model = modelId == null ? null : repo.modelById(modelId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(role.description, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          Text(model == null ? '未分配' : model.name, style: TextStyle(fontSize: 12, color: model == null ? Colors.orangeAccent : Colors.greenAccent)),
        ]),
        trailing: const Icon(Icons.swap_horiz),
        onTap: repo.freeModels.isEmpty ? null : () => _pickModel(context, role),
      ),
    );
  }

  void _pickModel(BuildContext context, AgentRole role) {
    final repo = context.read<ModelRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => ListView.builder(
          controller: controller,
          itemCount: repo.freeModels.length,
          itemBuilder: (_, i) {
            final m = repo.freeModels[i];
            return ListTile(
              title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${m.capability.label} · 上下文 ${m.contextLength}', style: const TextStyle(fontSize: 11)),
              onTap: () {
                repo.assignRole(role, m.id);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}