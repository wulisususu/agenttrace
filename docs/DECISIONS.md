# Engineering Decisions

本文件记录项目早期关键决策，防止实现过程中反复改变基本方向。

## ADR-001：MoonBit 为主要实现语言

**状态：Accepted**

原因：

- 项目参加 MoonBit 开源开发活动；
- 诊断核心适合用强类型数据模型表达；
- Native CLI 可以处理本地开发环境；
- 核心纯逻辑未来可复用于其他 target。

约束：不能只用 MoonBit 写薄壳，把主要逻辑放到其他语言。

---

## ADR-002：Native CLI 优先

**状态：Accepted**

首版首先解决本地仓库问题，因此需要：

- 文件系统访问；
- Git 状态；
- 日志文件；
- 进程/命令边界。

Web UI 延后。

---

## ADR-003：确定性诊断优先于 LLM

**状态：Accepted**

LLM 输出存在随机性，且不能可靠证明根因。

首版采用：

```text
observations -> evidence -> deterministic rules -> diagnosis
```

LLM 仅作为未来可选解释层。

---

## ADR-004：默认只读

**状态：Accepted**

AgentTrace 首版不会：

- git reset；
- git clean；
- 删除 node_modules；
- 修改 lockfile；
- 自动安装依赖；
- 修改源码。

理由：诊断工具首先要做到可信和安全。

---

## ADR-005：不使用伪精确概率

**状态：Accepted**

首版 confidence 使用：

- low；
- medium；
- high。

在没有标注数据和概率校准前，不显示“91% 置信度”等数值。

---

## ADR-006：证据与结论分离

**状态：Accepted**

Collector 不直接输出“这是环境错误”，只输出事实。

Diagnosis Engine 负责把多个事实组合成结论。

这样：

- 更容易测试；
- 更容易新增规则；
- 更容易解释错误诊断。

---

## ADR-007：新 MoonBit 配置格式

**状态：Accepted**

新项目使用 `moon.mod` 与 `moon.pkg`，不以旧的 `moon.mod.json` / `moon.pkg.json` 作为默认模板。

---

## 后续 ADR 候选

待真实实现验证后决定：

- Git 信息通过子进程还是库实现；
- async IO 边界；
- JSON 库选择；
- parser plugin 机制；
- Windows 进程调用策略。
