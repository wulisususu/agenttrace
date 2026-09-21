# AgentTrace Core Examples

本目录中的示例只依赖：

```text
wulisususu/agenttrace/core
```

它们不依赖仓库采集、测试日志解析、命令行程序或网页展示。

## custom_rules

演示服务健康诊断：

- `all_of`：服务已经启动；
- `any_of`：超时或连接拒绝至少出现一种；
- `none_of`：维护模式不存在。

它展示了可组合 Condition 的基本语义。

## config_guard

演示配置策略：

- 缺失必需配置产生 error；
- 旧配置仍存在产生 warning；
- 完成迁移后通过 `none_of` 抑制旧配置告警。

它展示了同一组 Evidence 上运行多个相互独立的 PolicyRule。

## tests/core_contract

虽然不在 examples 目录中，但这个测试 package 很重要：它从**外部 package 视角**只导入公共 `core`，用于防止基础库在重构时意外依赖内部实现。
