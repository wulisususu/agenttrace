# AgentTrace 数据模型

## 1. 公共 Core 模型

真正稳定、面向外部消费者的模型位于 `core/`。

### Evidence

```text
id
kind
message
source
```

Evidence 表示一条已经结构化的事实。

它不包含：

- Git 专属字段；
- 测试框架专属字段；
- Node.js 专属字段；
- Agent 专属字段。

### Rule

```text
id
category
severity
confidence
required_evidence_kinds[]
suggested_checks[]
```

Rule 是确定性规则声明。

### Diagnosis

```text
category
severity
confidence
rule_ids[]
evidence[]
suggested_checks[]
```

Diagnosis 直接携带命中的证据，保证可解释性。

## 2. Adapter 模型

以下模型属于参考适配器，不是 Core API。

### RepositorySnapshot

```text
root
branch
head
is_dirty
changed_files[]
worktrees[]
```

### EnvironmentSnapshot

```text
package_managers[]
lockfiles[]
dependency_markers[]
config_files[]
```

### TestObservation

```text
runner
status
failed_suites
failed_tests
assertion_failures
error_signatures[]
```

### BuildObservation

```text
compiler
status
exit_code
errors[]
```

这些结构可以被替换。外部项目使用 AgentTrace Core 时不需要采用它们。

## 3. 为什么分层

如果把 RepositorySnapshot 或 Vitest 字段放进 Core：

- 非 Git 工具无法自然复用；
- 非 Node.js 生态被迫携带无关字段；
- Core 会逐渐变成某个产品的内部模型。

所以公共层只保留“事实、规则、诊断”三个抽象。

## 4. Reporter

Reporter 可以消费 Core Diagnosis。

完整 AgentTrace CLI 还会将：

- RepositorySnapshot；
- EnvironmentSnapshot；
- BuildObservation；
- TestObservation

组成聚合报告。

这属于上层应用 schema，不等同于 Core schema。

## 5. 敏感信息

Core 本身不访问本地环境，因此不会主动采集敏感信息。

具体 collector / reporter 需要处理：

- Home 路径；
- token；
- cookie；
- credentials；
- 私有 URL。

现有 Reporter 已对常见用户 Home 路径做最小化脱敏。

## 6. API 稳定性

优先稳定：

- Evidence；
- Rule；
- Diagnosis；
- evaluate_rule；
- evaluate_rules。

Adapter 数据结构允许更快演进。

这一策略让外部消费者可以依赖 Core，而不必跟随 AgentTrace CLI 每次变化。
