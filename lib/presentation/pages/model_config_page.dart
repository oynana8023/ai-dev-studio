import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/agent_role.dart';
import '../../data/repositories/model_repository.dart';
import '../../data/services/domestic_ai_service.dart';
import '../../data/services/secure_storage_service.dart';

class ModelConfigPage extends StatefulWidget {
  const ModelConfigPage({super.key});
  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  final _openRouterController = TextEditingController();
  final Map<String, TextEditingController> _platformControllers = {};
  bool _showKeys = false;

  @override
  void initState() {
    super.initState();
    for (final p in DomesticAiService.platforms) {
      _platformControllers[p.id] = TextEditingController();
    }
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final orKey = await context.read<SecureStorageService>().getOpenRouterKey();
    if (orKey != null && mounted) _openRouterController.text = orKey;

    final platformKeys = await context.read<SecureStorageService>().loadPlatformKeys();
    platformKeys.forEach((id, key) {
      _platformControllers[id]?.text = key;
    });
  }

  @override
  void dispose() {
    _openRouterController.dispose();
    for (final c in _platformControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _saveAndFetch() async {
    final storage = context.read<SecureStorageService>();
    final repo = context.read<ModelRepository>();

    if (_openRouterController.text.trim().isNotEmpty) {
      await storage.saveOpenRouterKey(_openRouterController.text.trim());
    }

    for (final entry in _platformControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        await storage.savePlatformKey(entry.key, entry.value.text.trim());
      }
    }

    if (!mounted) return;
    await repo.loadModels();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ModelRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('模型与角色')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 国内平台配置
          Text('1. 配置国内 AI 平台 Key', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('点击对应平台的控制台链接申请 Key（大部分有免费额度）', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),

          ...DomesticAiService.platforms.map((p) => _buildPlatformCard(p)),

          const SizedBox(height: 20),
          // OpenRouter 配置
          Text('2. 配置 OpenRouter（可选）', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _openRouterController,
                  obscureText: !_showKeys,
                  decoration: const InputDecoration(
                    hintText: 'sk-or-v1-...', border: OutlineInputBorder(), labelText: 'OpenRouter API Key',
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 20),
          Text('3. 自定义添加模型', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('支持任何 OpenAI 兼容接口（如 OneAPI、Ollama、本地大模型）', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showCustomDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加自定义平台/模型'),
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: repo.isLoading ? null : _saveAndFetch,
            icon: repo.isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_download_outlined),
            label: Text(repo.isLoading ? '拉取中…' : '保存并拉取全部模型'),
          ),

          if (repo.error != null) ...[
            const SizedBox(height: 8),
            Text(repo.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],

          const SizedBox(height: 20),
          Text('4. 角色分配', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('免费模型 ${repo.freeModels.length} 个 · 可点开重新指定', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          ...AgentRole.values.map((role) => _RoleCard(role: role)),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(DomesticAiPlatform p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (p.id == 'nvidia')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('免费额度大', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
              ),
          ]),
          const SizedBox(height: 2),
          Text(p.consoleUrl, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          TextField(
            controller: _platformControllers[p.id],
            obscureText: !_showKeys,
            decoration: InputDecoration(
              hintText: '粘贴 ${p.name} 的 API Key',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('添加自定义平台'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '平台名称', hintText: '如：本地Ollama')),
            const SizedBox(height: 8),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'http://.../v1')),
            const SizedBox(height: 8),
            TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key', hintText: '没有可填 none')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              final storage = context.read<SecureStorageService>();
              final custom = await storage.loadCustomProviders();
              custom.add({
                'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
                'name': nameCtrl.text,
                'baseUrl': urlCtrl.text.replaceAll(RegExp(r'/+$'), ''),
                'apiKey': keyCtrl.text,
              });
              await storage.saveCustomProviders(custom);
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已添加，请点击“保存并拉取全部模型”')));
            },
            child: const Text('保存'),
          ),
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
          Text(
            model == null ? '未分配' : '${model.providerId} · ${model.name}',
            style: TextStyle(fontSize: 12, color: model == null ? Colors.orangeAccent : Colors.greenAccent),
          ),
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
              subtitle: Text('${m.providerId} · ${m.capability.label} · 上下文 ${m.contextLength}', style: const TextStyle(fontSize: 11)),
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