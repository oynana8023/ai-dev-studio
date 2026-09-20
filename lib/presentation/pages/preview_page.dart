import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('实时预览')),
      body: const Center(child: Text('Day 4 实现：WebView 代码预览')),
    );
  }
}