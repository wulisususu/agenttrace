# AgentTrace 数据模型

本文定义逻辑模型，不代表最终 MoonBit 类型名称已经冻结。

## 1. RepositorySnapshot

描述仓库在采集时刻的状态。

字段草案：

```text
path
branch
head
is_dirty
changed_files[]
worktree[]
```

原则：Snapshot 是事实快照，不保存诊断结论。

## 2. EnvironmentSnapshot

```text
platform
lockfiles[]
dependency_markers[]
config_files[]
observations[]
```

MVP 不保存机器敏感信息，例如：

- 用户名；
- Home 目录完整路径（报告时可脱敏）；
- token；
- 环境变量秘密值。

## 3. TestObservation

```text
runner
status
failed_suites
failed_tests
error_signatures[]
raw_source
```

其中 `raw_source` 建议只保存来源标识，不在默认 JSON 报告里回显整个日志。

## 4. BuildObservation

```text
compiler
status
exit_code
errors[]
```

首版 TypeScript 编译错误元素保存：

```text
file
line
column
code
message
```

BuildObservation 只保存编译事实；是否属于源码故障由 Diagnosis Engine 决定。

## 5. Evidence

```text
id
kind
message
source
weight
metadata
```

Evidence 应能独立解释“为什么它与诊断有关”。

## 6. Diagnosis

```text
category
severity
confidence
rule_ids[]
evidence_ids[]
suggested_checks[]
```

### category

见 PROJECT_SCOPE 中的初始故障分类。

### severity

建议：

- `info`
- `warning`
- `error`
- `blocking`

### confidence

- `low`
- `medium`
- `high`

## 7. DiagnosticReport

聚合结构：

```text
schema_version
tool_version
repository?
environment?
build?
tests?
diagnoses[]
summary
```

## 8. JSON 兼容

JSON 输出必须包含 `schema_version`。

新增字段优先保持向后兼容；删除或改变字段语义时提高 schema version。

## 9. 敏感信息处理

默认报告应避免直接包含：

- access token；
- cookies；
- 完整环境变量；
- SSH key；
- 私有仓库远端 URL 中的凭据；
- 日志中的明显密钥。

未来如果实现日志脱敏，应在 reporter 之前完成，避免不同输出格式出现安全差异。

## 10. 时间模型

如果后续加入 Agent timeline，时间字段统一使用带时区的 ISO 8601 表示；MVP 不为了时间线需求提前复杂化核心模型。
