enum AgentRole {
  commander('总指挥', '拆解需求、分配任务、汇总审核'),
  frontend('前端工程师', 'UI 布局与交互代码生成'),
  backend('后端工程师', 'API、数据模型与业务逻辑'),
  tester('测试工程师', '单元测试与边界用例生成'),
  reviewer('代码审查员', '质量、安全与规范检查'),
  optimizer('优化顾问', '性能优化与重构建议');

  final String label;
  final String description;
  const AgentRole(this.label, this.description);
}