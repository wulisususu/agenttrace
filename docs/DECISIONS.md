# Engineering Decisions

## ADR-001：MoonBit 为主要实现语言

**状态：Accepted**

AgentTrace 的公共诊断模型、规则引擎和主要工程实现使用 MoonBit。

---

## ADR-002：Library First

**状态：Accepted**

项目主体定义为可复用 MoonBit 基础库。

公共入口：

```text
wulisususu/agenttrace/core
```

CLI、Git Collector 和 Web Visual Report 均为基础库消费者或参考实现，不再作为项目主体。

理由：

- 允许 MoonBit 生态中的其他工具直接复用；
- 降低具体 AI Coding 场景耦合；
- 让规则和数据模型可以独立测试；
- 明确“基础能力”与“落地应用”的边界。

---

## ADR-003：Core 不做 IO

**状态：Accepted**

Core 不访问：

- 文件系统；
- Git；
- 网络；
- 环境变量；
- LLM。

所有外部事实先由 adapter 转换成 Evidence，再进入 Core。

---

## ADR-004：确定性诊断优先

**状态：Accepted**

基础流程：

```text
evidence -> deterministic rule -> diagnosis
```

LLM 如未来加入，只能作为可选解释层。

---

## ADR-005：证据与结论分离

**状态：Accepted**

Evidence 是事实，Diagnosis 是规则评估后的结论。

每个命中的 Diagnosis 必须保留相关 Evidence 和 rule id。

---

## ADR-006：公共 API 不绑定 AI Coding

**状态：Accepted**

Core 类型和函数不得出现：

- Codex 专属字段；
- Claude Code 专属字段；
- Git 专属字段；
- Vitest 专属字段；
- Node.js 专属字段。

这些内容属于 adapter 或内置规则层。

---

## ADR-007：Native CLI 作为参考应用

**状态：Accepted**

CLI 继续保留，因为它能证明基础库可用于真实本地工程诊断，但 CLI 不定义 Core 的能力边界。

---

## ADR-008：不使用伪精确概率

**状态：Accepted**

首版 confidence 使用：

- low；
- medium；
- high。

没有标注数据和校准前不展示伪精确百分比。

---

## ADR-009：新 MoonBit 配置格式

**状态：Accepted**

项目使用 `moon.mod` 与 `moon.pkg`。

---

## 后续 ADR 候选

- composable condition 表达方式；
- rule priority；
- Evidence metadata 结构；
- adapter interface；
- report schema versioning；
- WASM 目标的公共 API 稳定性。
