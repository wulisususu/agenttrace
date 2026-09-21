# Fixture 编写规范

## 1. 为什么需要 Fixture

AgentTrace 的诊断规则必须能够被重复验证。

真实工程日志往往包含：

- 用户路径；
- 临时时间戳；
- 隐私信息；
- 巨量无关输出。

因此项目使用最小化、匿名化 fixture 复现故障，而不是直接提交真实完整日志。

## 2. 目录建议

```text
fixtures/
├─ logs/
│  ├─ vitest-missing-matcher/
│  │  ├─ input.txt
│  │  └─ expected.json
│  └─ typescript-compile-error/
├─ repository/
│  ├─ dirty-worktree/
│  └─ lockfile-mismatch/
└─ README.md
```

## 3. Fixture 必须包含

每个故障案例应说明：

- 场景名称；
- 故障类别；
- 最小输入；
- 期望 evidence；
- 期望 diagnosis；
- 为什么这个案例具有代表性。

## 4. 匿名化

必须替换：

- 用户名；
- 私有域名；
- token；
- 内网 IP；
- 私有仓库 URL；
- 真实业务名称。

允许保留：

- 错误类型；
- runner 名称；
- 非敏感版本信息；
- 对诊断有意义的路径结构。

## 5. 最小化

Fixture 不应只是把 10MB 日志原样放进仓库。

应保留能够触发同样解析和诊断的最小信息。

## 6. Positive / Negative Pair

重要规则尽量准备成对案例。

例如 R001：

Positive：

- compile pass；
- 大量 suite 同一 matcher 错误。

Negative：

- compile pass；
- 单个断言 expected != actual。

这样可以证明规则不是“看到 test failed 就判断环境坏了”。

## 7. 预期结果

建议 expected.json 只描述稳定字段：

```json
{
  "category": "dependency_environment_error",
  "confidence": "high",
  "required_evidence_kinds": [
    "compile_passed",
    "repeated_error_signature"
  ]
}
```

不要把不稳定文本格式全部做 snapshot。

## 8. 新增规则时

新增诊断规则的 PR 至少包含：

- 一个正例 fixture；
- 一个反例或边界测试；
- 对规则证据的说明。
