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

MVP 不采集或保存环境变量秘密值、token、cookies、SSH key 或带凭据的 remote URL。

## 3. TestObservation

```text
runner
status
failed_suites
failed_tests
error_signatures[]
raw_source
```

默认报告只输出结构化摘要，不回显整个原始测试日志。

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

BuildObservation 只保存编译事实；是否属于源码故障由 Diagnosis Engine 决定。报告层会对源码文件绝对路径执行与仓库路径相同的 Home 路径脱敏。

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

## 9. 默认敏感信息处理

脱敏发生在 **Reporter 边界**，而不是采集层。这样规则引擎仍能看到完整、真实的工程事实，同时默认对外输出不会直接暴露常见用户 Home 路径。

MVP 当前保证：

- Windows `C:\Users\<name>\...` 与 `C:/Users/<name>/...` 折叠为 `$HOME/...`；
- Linux `/home/<name>/...` 折叠为 `$HOME/...`；
- macOS `/Users/<name>/...` 折叠为 `$HOME/...`；
- Repository root、Worktree path、TypeScript BuildError.file 在 JSON 报告中使用同一策略；
- Text 聚合报告中的 Repository root 使用同一策略；
- 原始测试日志和原始构建日志不会被默认报告回显；
- EnvironmentSnapshot 不读取环境变量秘密值，RepositorySnapshot 不采集 remote URL。

这不是通用 secret scanner。MVP 不声称能识别任意自由文本中的所有 token/密钥；后续如果增加原始日志输出或更自由的 metadata 字段，必须在进入 Reporter 前扩展专门的 secret redaction。

## 10. 时间模型

如果后续加入 Agent timeline，时间字段统一使用带时区的 ISO 8601 表示；MVP 不为了时间线需求提前复杂化核心模型。
