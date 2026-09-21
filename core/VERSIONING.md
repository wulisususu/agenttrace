# AgentTrace Core API Compatibility

AgentTrace Core 当前处于 `0.x` 阶段，但仍采用明确的公共 API 边界。

## Public API

以下位于 `wulisususu/agenttrace/core` 的 `pub` / `pub(all)` 符号视为公共 API。

当前主要公共模型：

- `Evidence`
- `Diagnosis`
- `Rule`
- `Condition`
- `ConditionReport`
- `PolicyRule`
- `RuleEvaluation`
- `ValidationIssue`

主要函数：

- `evaluate_rule`
- `evaluate_rules`
- `condition_matches`
- `inspect_condition`
- `evaluate_policy_rule`
- `evaluate_policy_rules`
- `inspect_policy_rule`
- `inspect_policy_rules`
- `evaluate_highest_priority`
- `validate_policy_rule`
- `validate_policy_rules`

## Compatibility Principle

优先采用 additive evolution：

- 新增函数；
- 新增独立模型；
- 新增不改变现有语义的能力。

避免在无迁移路径时：

- 删除公共函数；
- 修改已有字段语义；
- 改变 tie-break 行为；
- 将原本确定性的 API 改成依赖 IO 或随机状态。

## Legacy Rule

首版 `Rule + evaluate_rule/evaluate_rules` 继续保留。

新的复杂规则使用 `PolicyRule`，避免为了增加能力直接破坏已有消费者。

## Determinism Contract

以下行为视为 API 契约的一部分：

- `evaluate_policy_rules` 保持输入规则顺序；
- `evaluate_highest_priority` 在 priority 相同时选择更早的规则；
- 空 Condition 不匹配；
- Diagnosis 只携带参与正向条件的 Evidence；
- validation 返回问题而不是抛出运行时异常。

## Contract Test

`tests/core_contract/` 从外部 package 视角验证公共 API。

任何公共 API 重构都应首先保证该测试继续通过。
