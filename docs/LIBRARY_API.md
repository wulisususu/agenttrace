# AgentTrace Core 公共 API

AgentTrace 的项目主体是 **MoonBit 结构化诊断基础库**。CLI、Git/Worktree 扫描和 Visual Report 是建立在该基础库之上的参考应用。

## 1. 导入

外部 MoonBit 项目可以直接导入：

```text
wulisususu/agenttrace/core
```

`core` 包不依赖 AgentTrace CLI、Git、Vitest、TypeScript 或 Web 页面。

## 2. Evidence

```moonbit
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}
```

Evidence 表示已经被采集或解析出来的结构化事实。它不包含“根因”判断。

例如：

```moonbit
let evidence : Array[@core.Evidence] = [
  {
    id: "E1",
    kind: "timeout",
    message: "request timed out",
    source: "http",
  },
  {
    id: "E2",
    kind: "retry_exhausted",
    message: "retry budget exhausted",
    source: "runtime",
  },
]
```

## 3. Rule

```moonbit
pub(all) struct Rule {
  id : String
  category : String
  severity : String
  confidence : String
  required_evidence_kinds : Array[String]
  suggested_checks : Array[String]
}
```

当前基础引擎实现一个确定性的 **all-of evidence rule**：只有所需 evidence kind 全部存在时，规则才命中。

这是一层通用能力，不限定故障领域。

可以用于：

- CI / 构建诊断；
- 配置检查；
- 服务健康判断；
- 网络故障归因；
- 测试结果分析；
- Agent 执行状态分析；
- 其他需要“结构化事实 → 可解释结论”的工具。

## 4. evaluate_rule

```moonbit
pub fn evaluate_rule(
  rule : Rule,
  evidence : Array[Evidence],
) -> Diagnosis?
```

示例：

```moonbit
let rule : @core.Rule = {
  id: "SERVICE001",
  category: "service_unavailable",
  severity: "error",
  confidence: "high",
  required_evidence_kinds: ["timeout", "retry_exhausted"],
  suggested_checks: ["verify upstream service availability"],
}

match @core.evaluate_rule(rule, evidence) {
  Some(diagnosis) => ...
  None => ...
}
```

完整可编译示例位于：

`examples/custom_rules/`

## 5. evaluate_rules

```moonbit
pub fn evaluate_rules(
  rules : Array[Rule],
  evidence : Array[Evidence],
) -> Array[Diagnosis]
```

允许上层工具维护自己的规则集，并一次评估多个独立规则。

## 6. Diagnosis

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

Diagnosis 保留：

- 结论类别；
- 严重级别；
- 置信级别；
- 命中的规则；
- 参与判断的 Evidence；
- 后续验证建议。

因此消费者不仅得到“结果”，还能知道该结果由什么证据产生。

## 7. AgentTrace 自带适配器

仓库当前同时提供若干建立在 Core 之上的参考实现：

- `src/testlog`：Vitest 日志解析；
- `src/buildlog`：TypeScript 编译日志解析；
- `src/git`：Git/Worktree 状态采集；
- `src/environment`：Node.js 项目环境信号；
- `src/diagnosis`：R001–R005 内置工程诊断规则；
- `src/report`：Text / JSON Reporter；
- `src/cli`：完整 CLI 示例应用。

这些模块用于证明基础模型能够落地到真实工程诊断场景，但不是 Core 的前置依赖。

## 8. 设计边界

Core 当前刻意保持简单：

- 不执行系统命令；
- 不读取文件；
- 不依赖网络；
- 不调用 LLM；
- 不限定编程语言；
- 不自动修复。

外部项目可以只引入 Core，并自行实现采集器、领域规则和展示层。

## 9. 后续基础库方向

计划继续扩充的仍然是可复用能力：

- error signature / normalization；
- composable conditions；
- rule priority；
- evidence metadata；
- stable report schema；
- adapter interface；
- WASM 可复用核心。

新增能力应优先考虑是否能被 AgentTrace 之外的 MoonBit 项目独立使用。
