# AgentTrace 路线图

路线图以 **MoonBit 基础库价值** 为第一优先级。

## Phase 1 — Public Core

- [x] 顶层 `core` package
- [x] Evidence
- [x] Rule
- [x] Diagnosis
- [x] evaluate_rule
- [x] evaluate_rules
- [x] Core 单元测试
- [x] 与 AI Coding 无关的消费者示例

目标：证明 Core 可以脱离 AgentTrace CLI 独立使用。

## Phase 2 — Reusable Normalization

计划：

- error signature；
- 路径归一化；
- 可配置文本 normalization；
- 重复 Evidence 聚类；
- 通用 fixture。

目标：提供日志/错误分析工具普遍可复用的基础能力。

## Phase 3 — Composable Rules

计划：

- all-of；
- any-of；
- not；
- rule priority；
- rule set；
- conflict resolution。

目标：从简单规则匹配扩展成轻量、确定性的 MoonBit 诊断规则库。

## Phase 4 — Adapter Interfaces

计划把当前：

- Vitest parser；
- TSC parser；
- Git collector；
- environment collector

整理为更明确的适配器层，并定义公共接口。

目标：让社区能扩展其他日志源和工程生态。

## Phase 5 — Stable Reporting

计划：

- Core diagnosis schema；
- JSON serializer；
- schema version；
- redaction hooks；
- formatter interface。

目标：让诊断结果更容易进入 CLI、CI、Web 和 Agent 系统。

## Reference Applications

现有 CLI 与 Visual Report 继续维护，但它们的职责是：

- 验证 Core；
- 提供真实使用案例；
- 防止基础库只停留在抽象设计。

不会把新增 UI 功能放在基础库能力之前。

## 后续候选

- WASM target；
- Python / Rust / MoonBit build adapters；
- GitHub Actions adapter；
- Agent session adapter；
- community rule packs。

判断一个新功能是否进入主路线图的标准：

> **它是否能被 AgentTrace 自己之外的 MoonBit 项目独立复用？**
