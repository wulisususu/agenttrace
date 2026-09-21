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

## ADR-008：Git 通过无 Shell 子进程采集

**状态：Accepted**

MVP 使用 Git CLI 自身提供的机器可读接口采集仓库事实，而不是直接解析 `.git` 内部文件：

- `git status --porcelain=v2 -z`；
- `git worktree list --porcelain`；
- `git rev-parse`；
- `git branch --show-current`。

实现使用 `moonbitlang/async/process` 直接执行 `git`，命令与参数分离，不通过 Bash、PowerShell 或 `cmd /c` 拼接用户输入。

原因：

- Git 自己处理主仓库、linked worktree 和平台差异；
- porcelain 接口比面向人的本地化文本稳定；
- 参数数组避免路径空格、中文和 shell 注入问题；
- Collector 仍然保持只读，不执行 reset/clean/checkout 等修改命令。

`moonbitlang/async` 在 MVP 中固定版本，升级时必须经过 Linux/Windows CI 验证。

---

## 后续 ADR 候选

待真实实现验证后决定：

- parser plugin 机制；
- Windows 本地代码页兼容策略。
