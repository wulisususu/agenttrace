# AgentTrace Core

AgentTrace Core 是一个纯 MoonBit 的**结构化诊断规则基础库**。

它解决的是一个通用问题：

> 已经有了一组结构化事实，如何用确定、可解释、可测试的规则，把它们转换成诊断结果？

Core 不负责采集事实，也不要求特定日志格式。调用方只需要提供 `Evidence[]`。

## 设计目标

- **纯逻辑**：不访问文件系统、网络、进程或环境变量；
- **领域无关**：不绑定 Git、测试框架、编程语言或某类应用；
- **确定性**：相同 Evidence 与 Rule 永远得到相同结果；
- **可解释**：Diagnosis 保留 rule id 和参与判断的 Evidence；
- **可验证**：规则在进入运行阶段前可以进行静态校验；
- **向后兼容**：保留首版简单 `Rule` API，同时提供更强的 `PolicyRule`。

## 核心模型

### Evidence

```moonbit
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}
```

Evidence 是事实，不是结论。

### Condition

```moonbit
pub(all) struct Condition {
  all_of : Array[String]
  any_of : Array[String]
  none_of : Array[String]
}
```

语义：

- `all_of`：全部存在；
- `any_of`：非空时至少存在一个；
- `none_of`：全部不存在；
- 三组都为空时不匹配，防止意外 catch-all。

### PolicyRule

```moonbit
pub(all) struct PolicyRule {
  id : String
  category : String
  severity : String
  confidence : String
  priority : Int
  condition : Condition
  suggested_checks : Array[String]
}
```

### Diagnosis

诊断结果包含：

- category；
- severity；
- confidence；
- rule_ids；
- 参与判断的 Evidence；
- suggested_checks。

## 主要 API

### 条件判断

```moonbit
condition_matches(condition, evidence)
condition_evidence(condition, evidence)
```

### Evidence 查询

```moonbit
evidence_has_kind(evidence, kind)
evidence_count_kind(evidence, kind)
evidence_by_kind(evidence, kind)
```

### 规则评估

```moonbit
evaluate_policy_rule(rule, evidence)
evaluate_policy_rules(rules, evidence)
evaluate_highest_priority(rules, evidence)
```

`evaluate_policy_rules` 保留调用方提供的顺序。

`evaluate_highest_priority` 选择 priority 最大的命中规则；priority 相同时，较早出现的规则获胜，因此行为稳定。

### 规则校验

```moonbit
validate_policy_rule(rule)
validate_policy_rules(rules)
```

校验不会抛异常，而是返回 `ValidationIssue[]`，当前覆盖：

- 空 rule id；
- 空 category；
- 非法 severity；
- 非法 confidence；
- 空 Condition；
- 空 evidence kind；
- 重复 rule id。

## 最小示例

```moonbit
let evidence : Array[@core.Evidence] = [
  {
    id: "E1",
    kind: "latency_high",
    message: "p95 latency exceeded threshold",
    source: "metrics",
  },
  {
    id: "E2",
    kind: "error_rate_high",
    message: "error rate exceeded threshold",
    source: "metrics",
  },
]

let rule : @core.PolicyRule = {
  id: "SLO001",
  category: "service_degraded",
  severity: "warning",
  confidence: "high",
  priority: 50,
  condition: {
    all_of: ["latency_high", "error_rate_high"],
    any_of: [],
    none_of: ["planned_load_test"],
  },
  suggested_checks: ["inspect recent deployment"],
}

match @core.evaluate_policy_rule(rule, evidence) {
  Some(diagnosis) => {
    // deterministic, explainable result
  }
  None => ()
}
```

## 兼容 API

首版的简单规则仍然保留：

```moonbit
Rule
evaluate_rule
evaluate_rules
```

它适合只有 `all_of` 需求的调用方。复杂策略建议使用 `PolicyRule`。

## 测试覆盖

Core 自己包含以下测试层次：

- 基础 Rule 兼容性；
- all/any/none Condition；
- Evidence 查询；
- PolicyRule 评估；
- priority 决策；
- 稳定 tie-break；
- Rule validation；
- duplicate rule id；
- 外部 package contract test。

仓库中的 `examples/` 另外提供多个与 Core 实现无关的消费场景。

## 边界

Core 刻意不做：

- IO；
- 日志解析；
- 命令执行；
- 自动修复；
- UI；
- 远程服务。

这些能力属于调用方或 adapter。Core 只负责把**事实转换成可解释规则结果**。
