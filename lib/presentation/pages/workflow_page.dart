import 'package:flutter/material.dart';

class WorkflowPage extends StatelessWidget {
  const WorkflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工作流')),
      body: const Center(child: Text('Day 3 实现：多智能体工作流编排')),
    );
  }
}