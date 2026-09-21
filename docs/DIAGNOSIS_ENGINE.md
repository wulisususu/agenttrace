# 诊断引擎设计

## 1. 两层诊断体系

AgentTrace 将诊断逻辑拆成两层：

### Core

公共包：

```text
wulisususu/agenttrace/core
```

负责通用：

- Evidence；
- Rule；
- Diagnosis；
- evaluate_rule；
- evaluate_rules。

Core 不知道 Git、Vitest、TypeScript 或 AI Coding。

### Domain Rules

仓库自带的 `src/diagnosis` 提供工程诊断规则 R001–R005。

这些规则只是 Core 的一个领域应用。

## 2. 核心思想

诊断分为三步：

```text
Observation
    ↓
Evidence
    ↓
Diagnosis
```

Observation 是解析器或采集器得到的事实。

Evidence 是可供规则消费的结构化事实。

Diagnosis 是规则根据 Evidence 产生的可解释结论。

## 3. 通用 Rule

当前 Core Rule：

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

首版采用 all-of 策略：

> required_evidence_kinds 中的每一种 Evidence 都存在，规则才命中。

设计目的不是一次实现完整规则语言，而是先提供一个稳定、可预测、容易测试的基础能力。

## 4. 通用评估

```moonbit
pub fn evaluate_rule(
  rule : Rule,
  evidence : Array[Evidence],
) -> Diagnosis?
```

和：

```moonbit
pub fn evaluate_rules(
  rules : Array[Rule],
  evidence : Array[Evidence],
) -> Array[Diagnosis]
```

这两个 API 可以被任何 MoonBit 项目直接使用。

## 5. 内置工程规则

### R001

编译成功，但多个测试 suite 出现同源 missing matcher 错误。

倾向：

`dependency_environment_error`

### R002

编译器非零退出并给出明确源码定位。

倾向：

`build_compile_error`

### R003

测试框架正常运行，出现有限范围明确断言失败。

倾向：

`test_assertion_failure`

### R004

显式要求的 branch / clean worktree 条件与当前仓库状态冲突。

倾向：

`worktree_state_error`

### R005

顶层同时存在多个不同 package manager 的 lockfile。

倾向：

`package_manager_ambiguity`

这些规则不会进入 Core 的类型定义中，避免把基础库绑死到具体工程生态。

## 6. 置信等级

首版使用：

- `low`
- `medium`
- `high`

不使用没有统计意义的百分比。

## 7. Evidence 原则

Diagnosis 必须保留参与判断的 Evidence。

命中结果应能回答：

1. 规则是什么；
2. 哪些事实触发了规则；
3. 结论类别是什么；
4. 后续建议检查什么。

当证据不足时，规则不命中，而不是猜测。

## 8. 扩展方向

Core 后续计划加入：

- any-of / all-of 可组合条件；
- negation；
- rule priority；
- Evidence metadata；
- rule set；
- 更稳定的 schema。

但这些扩展仍必须保持与具体 AI Coding 产品解耦。
