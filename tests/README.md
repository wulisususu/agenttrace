# Core Contract Tests

本目录验证的是 **AgentTrace Core 作为外部基础库是否真的可用**，而不是测试仓库内部实现细节。

## 为什么单独存在

`core/*_test.mbt` 与 Core 位于同一个 package，适合验证内部语义。

`tests/core_contract/` 则处于独立 package，只允许：

```text
import wulisususu/agenttrace/core
```

因此它可以发现：

- 公共类型忘记导出；
- 公共函数依赖内部 package；
- 重构后示例只能在 Core 包内部编译；
- 文档宣称的 API 实际无法被消费者调用。

## 当前契约

外部消费者应能够：

1. 构造 `Evidence`；
2. 构造 `Condition`；
3. 构造 `PolicyRule`；
4. 调用 `validate_policy_rule`；
5. 调用 `evaluate_policy_rule`；
6. 获得包含参与 Evidence 的 `Diagnosis`。

Contract test 不导入：

- repository collector；
- environment collector；
- parser；
- reporter；
- CLI；
- Web 代码。

这保证 Core 的可复用性是通过编译与测试证明的，而不仅是文档声明。
