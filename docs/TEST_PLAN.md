# AgentTrace 测试计划

## 1. 测试目标

AgentTrace 的价值取决于诊断是否稳定，因此自动化测试不是附加项，而是核心交付。

主要验证：

- parser 能否稳定提取事实；
- rules 能否对相同 evidence 给出相同结果；
- 不同故障是否被错误混淆；
- reporter 是否输出合法 JSON；
- Windows 路径等边界输入是否正常。

## 2. 测试分层

### Unit Tests

覆盖：

- path normalization；
- error signature；
- log statistics；
- rule predicates；
- confidence 合并；
- JSON serialization。

### Fixture Tests

使用固定输入模拟真实故障：

```text
fixtures/
├─ logs/
│  ├─ vitest-missing-matcher/
│  ├─ compile-type-error/
│  ├─ assertion-failure/
│  └─ runner-config-error/
├─ repository/
│  ├─ dirty-worktree/
│  ├─ clean-repo/
│  └─ lockfile-mismatch/
└─ expected/
```

### Integration Tests

验证：

```text
fixture
 -> collector/parser
 -> diagnosis
 -> report
```

能够完整跑通。

## 3. 第一批必测场景

1. 正常项目，无故障；
2. TypeScript 编译失败；
3. 测试断言失败；
4. 测试框架全局依赖缺失；
5. 大量测试共享同一错误签名；
6. dirty worktree；
7. 未知日志格式；
8. 空日志；
9. Windows 路径；
10. 含中文路径。

## 4. Golden Report

对关键 fixtures 保存期望 JSON。

只有在有意修改 schema 或规则行为时更新 golden data，避免重构时无意改变结果。

## 5. 负向测试

必须测试：

- 文件不存在；
- 没有读取权限；
- 输入不是 Git 仓库；
- 非 UTF-8/异常文本策略；
- 超长日志；
- 日志缺少 summary；
- parser 只提取部分数据时。

## 6. 性能边界

MVP 不追求基准排名，但应避免：

- 将整个大型日志复制多份；
- 对每一行使用高复杂度全局扫描；
- 对仓库做无界递归。

后续可添加 benchmark。

## 7. MoonBit 测试命令

项目初始化后使用：

```bash
moon check
moon test
```

提交前至少确保上述命令通过。

## 8. 验收测试

最终 Demo 应包含至少一个“环境问题伪装成代码问题”的完整案例，并展示：

- 输入；
- 提取到的 evidence；
- 诊断；
- 建议；
- 对应自动化测试。

这样可以证明工具不是只展示界面，而是在运行真实的诊断逻辑。
