# Diagnostic Report Schema

## 1. 目标

AgentTrace 同时面向人类和自动化工具，因此诊断结果必须有稳定的结构化表示。

MVP 使用 JSON 作为机器可读输出格式。

## 2. 顶层结构草案

```json
{
  "schema_version": "0.1",
  "tool_version": "0.1.0",
  "summary": {
    "status": "problem_detected"
  },
  "repository": {},
  "environment": {},
  "tests": {},
  "diagnoses": []
}
```

## 3. Diagnosis

```json
{
  "id": "D001",
  "category": "dependency_environment_error",
  "severity": "error",
  "confidence": "high",
  "rule_ids": ["R001"],
  "evidence_ids": ["E001", "E002"],
  "suggested_checks": [
    "verify installed test dependencies",
    "rerun the affected test suite"
  ]
}
```

## 4. Evidence

```json
{
  "id": "E001",
  "kind": "repeated_error_signature",
  "message": "Multiple test suites share the same missing matcher error",
  "source": "testlog",
  "metadata": {
    "occurrences": 27
  }
}
```

## 5. 空值规则

- 不知道的事实不要编造；
- 可选字段可以省略；
- 不用空字符串表示 unknown；
- category 无法确定时使用 `unknown`。

## 6. 稳定性

`schema_version` 用于区分不兼容变化。

兼容修改：

- 新增可选字段；
- 新增 category；
- 新增 metadata。

潜在不兼容修改：

- 删除字段；
- 改字段类型；
- 改字段语义。

## 7. 脱敏

JSON reporter 在输出前应经过统一脱敏层。

默认不输出：

- token；
- secret；
- password；
- cookie；
- 私钥；
- 带认证信息的 URL。

## 8. 原始日志

默认报告不嵌入完整原始日志。

可以保存：

- source path（必要时脱敏）；
- hash；
- parser name；
- error signature；
- 必要的短摘要。

这样可以减少隐私风险和报告体积。
