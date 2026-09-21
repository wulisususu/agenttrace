# AgentTrace Core 公共 API

AgentTrace Core 是一个纯 MoonBit 的结构化诊断规则基础库。它只负责：

```text
Evidence[] + PolicyRule[] -> Diagnosis[]
```

它不采集文件、不执行命令、不调用网络，也不依赖具体开发工具。

公共包：

```text
wulisususu/agenttrace/core
```

## Evidence

```moonbit
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}
```

Evidence 表示已经由调用方确认的结构化事实。

Core 只关心 `kind` 如何参与规则判断，同时保留 `id/message/source` 供诊断解释使用。

查询 API：

```moonbit
evidence_has_kind(evidence, kind)
evidence_count_kind(evidence, kind)
evidence_by_kind(evidence, kind)
```

## Condition

```moonbit
pub(all) struct Condition {
  all_of : Array[String]
  any_of : Array[String]
  none_of : Array[String]
}
```

语义：

- `all_of`：每一种 kind 都必须存在；
- `any_of`：非空时，至少一种 kind 必须存在；
- `none_of`：这些 kind 必须全部不存在；
- 全空 Condition 永远不匹配，避免误配置成全局 catch-all。

核心 API：

```moonbit
condition_is_empty(condition)
condition_matches(condition, evidence)
condition_evidence(condition, evidence)
```

## PolicyRule

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

与首版 `Rule` 相比，PolicyRule 支持：

- all / any / none 条件；
- priority；
- 静态规则校验；
- 最高优先级选择。

## 规则评估

### 单规则

```moonbit
evaluate_policy_rule(rule, evidence)
```

返回：

```text
Diagnosis?
```

### 多规则

```moonbit
evaluate_policy_rules(rules, evidence)
```

返回全部命中规则，保持调用方传入顺序。

### 最高优先级

```moonbit
evaluate_highest_priority(rules, evidence)
```

返回 priority 最大的命中规则。

priority 相同时保留输入顺序，保证结果稳定。

## Diagnosis

```moonbit
pub(all) struct Diagnosis {
  category : String
  severity : String
  confidence : String
  rule_ids : Array[String]
  evidence : Array[Evidence]
  suggested_checks : Array[String]
}
```

Diagnosis 不只是结论字符串。

它会保留：

- 产生结论的 rule id；
- 实际参与判断的 Evidence；
- severity；
- confidence；
- 后续建议。

因此调用方可以自行：

- 渲染 CLI；
- 输出 JSON；
- 写入 CI；
- 生成 Web UI；
- 保存为审计记录。

## Rule Validation

```moonbit
pub(all) struct ValidationIssue {
  field : String
  message : String
}
```

API：

```moonbit
validate_policy_rule(rule)
validate_policy_rules(rules)
```

当前校验：

- 空 rule id；
- 空 category；
- 非法 severity；
- 非法 confidence；
- 空 Condition；
- 空 evidence kind；
- duplicate rule id。

设计上采用“返回问题列表”而不是抛异常，方便调用方在配置加载阶段一次显示所有错误。

## 完整示例

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

let issues = @core.validate_policy_rule(rule)

if issues.length() == 0 {
  match @core.evaluate_policy_rule(rule, evidence) {
    Some(diagnosis) => {
      // diagnosis.category == "service_degraded"
      // diagnosis.evidence.length() == 2
    }
    None => ()
  }
}
```

## 兼容 API

首版简单规则继续保留：

```moonbit
Rule
evaluate_rule
evaluate_rules
```

它等价于只有 `all_of` 的轻量场景。

这使已有消费者不需要因为 PolicyRule 的加入立即迁移。

## 示例与契约测试

仓库中有三种独立验证方式：

```text
examples/custom_rules/
examples/config_guard/
tests/core_contract/
```

它们都只导入：

```text
wulisususu/agenttrace/core
```

其中：

- `custom_rules`：服务健康策略；
- `config_guard`：配置检查策略；
- `core_contract`：从外部 package 视角验证公共 API。

## Core 的设计边界

Core 保持纯逻辑层，不负责：

- IO；
- 日志格式；
- Git；
- 网络；
- 命令执行；
- 自动修复；
- 展示层。

这样同一套规则基础能力可以被不同 MoonBit 工具复用，而不会被某个具体产品架构绑死。
