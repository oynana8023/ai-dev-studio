import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/orchestrator_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final List<_Msg> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text, true));
      _controller.clear();
    });

    final orch = context.read<OrchestratorService>();
    await orch.analyzeRequirement(text);

    if (orch.error != null) {
      setState(() => _messages.add(_Msg('错误：${orch.error}', false)));
    } else {
      setState(() => _messages.add(_Msg('已拆解为 ${orch.tasks.length} 个任务，请查看下方清单。', false)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orch = context.watch<OrchestratorService>();

    return Scaffold(
      appBar: AppBar(title: const Text('对话式开发')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._messages.map((m) => _buildBubble(m)),
                if (orch.tasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('任务清单', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...orch.tasks.map((t) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.task_alt, color: Colors.greenAccent),
                          title: Text(t.role, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(t.description),
                        ),
                      )),
                ],
                if (orch.isWorking)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '描述你想开发的软件…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: orch.isWorking ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg m) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: m.mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(m.text),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool mine;
  _Msg(this.text, this.mine);
}