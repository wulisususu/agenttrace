# AgentTrace 可复现 Demo

这些 Demo 使用仓库中受版本控制的 fixtures，并在 Linux / Windows CI 中验证。

## 1. 正常场景

```bash
moon run cmd/main inspect . \
  --log fixtures/logs/vitest-pass.txt \
  --build-exit-code 0 \
  --format json
```

预期：

- exit code = `0`
- build.status = `pass`
- tests.status = `pass`
- diagnoses = `[]`

## 2. 编译故障

```bash
moon run cmd/main inspect . \
  --build-log fixtures/logs/tsc-type-error.txt \
  --build-exit-code 2 \
  --format json
```

关键结果：

```json
{
  "category": "build_compile_error",
  "confidence": "high",
  "rule_ids": ["R002"]
}
```

这里的结论由两个事实共同支持：编译器非零退出，以及 tsc 日志包含明确源码位置/错误码。

## 3. 环境问题伪装成代码问题

```bash
moon run cmd/main inspect . \
  --log fixtures/logs/vitest-missing-matcher.txt \
  --build-exit-code 0 \
  --format json
```

fixture 中包含：

```text
Test Files 27 failed (27)
Tests 155 failed (155)
Error: Invalid Chai property: toBeInTheDocument
...
```

但编译退出码被显式提供为 `0`。

关键结果：

```json
{
  "category": "dependency_environment_error",
  "confidence": "high",
  "rule_ids": ["R001"]
}
```

这正是 AgentTrace 的核心场景：测试大量失败不自动等于源码坏了。编译层健康且失败高度重复时，应先验证测试依赖/setup 环境。

### 反向验证

只分析同一测试日志：

```bash
moon run cmd/main analyze-log fixtures/logs/vitest-missing-matcher.txt
```

因为没有提供 compile-pass 证据，结果保持 `unknown`。这证明 AgentTrace 不会为了匹配案例而虚构上下文。

## 4. 断言失败

```bash
moon run cmd/main analyze-log \
  fixtures/logs/vitest-assertion-failure.txt \
  --format json
```

预期规则：`R003`，category 为 `test_assertion_failure`。

## 验证命令

```bash
moon check --target native --deny-warn
moon test --target native
moon build --target native
```

CI 会在 Ubuntu 与 Windows 上额外执行 CLI smoke tests。
