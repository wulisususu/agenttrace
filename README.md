# AgentTrace

> 基于 MoonBit 的 AI Coding 工程诊断工具，分析仓库、环境与测试日志，定位代码和环境故障。

AgentTrace 面向使用 Codex、Claude Code、Copilot CLI 等 AI Coding 工具的开发者。它计划通过结构化分析 Git/Worktree 状态、依赖环境、构建结果与测试日志，帮助开发者回答一个常见问题：

> **这次失败究竟是代码写坏了，还是开发环境出了问题？**

## 为什么 AI Coding 还需要 AgentTrace

Codex、Claude Code 等 AI Coding Agent 已经能够读取报错、运行命令并尝试修复代码。AgentTrace 不重复这些能力，也不试图成为另一个负责“写代码”的 Agent。

两者关注的问题不同：

- **AI Agent 负责推理和修复**：根据已有上下文判断下一步怎么改；
- **AgentTrace 负责工程现场取证和故障归因**：稳定采集仓库、Worktree、依赖、构建和测试信号，回答“到底坏在哪一层，以及依据是什么”。

AI Agent 很擅长在获得上下文后进行推理，但它每次是否收集到了完整、正确、可比较的工程状态，并没有天然保证。尤其在多个 Agent、多个 Worktree、长时间自动执行或中断恢复的场景中，测试失败可能来自：

- 当前验收目录并不是发生修改的 Worktree；
- 当前 HEAD 或目标分支与预期不一致；
- 工作区残留未提交修改；
- 某个 Worktree 的依赖安装不完整；
- lockfile 与实际依赖目录不一致；
- 大量测试失败实际上只是同一个环境根因的重复表现。

AgentTrace 的目标是在 Agent 修改更多代码之前，先提供一份确定性、可复现、可解释的工程诊断结果。

可以把两者的关系理解为：

```text
Codex / Claude Code / other Agent
              │
              │ reasoning / repair
              ▼
          AgentTrace
              │
      structured evidence
              ▼
 Git / Worktree / Env / Build / Test
```

一句话概括：

> **AI 负责“怎么修”，AgentTrace 负责先判断“哪里坏了、证据是什么、当前工程现场是否可信”。**

### 一个典型场景

例如测试阶段出现：

```text
27 test files failed
155 tests failed
Invalid Chai property: toBeInTheDocument
```

仅根据错误文本，Agent 可能直接修改测试代码、配置或回滚最近改动。

AgentTrace 则会把多个工程信号关联起来：

```text
Build
  TypeScript: PASS

Tests
  27 files failed
  155 cases failed
  repeated signature: missing matcher

Environment
  dependency state: inconsistent

Diagnosis
  dependency_environment_error
  confidence: high
```

此时建议优先验证依赖环境，而不是先修改或回滚源码。

在多 Agent 开发中也是同样的逻辑：AgentTrace 不负责调度多个 Agent，而是帮助确认当前 Branch、HEAD、Worktree、dirty files、依赖和测试状态是否与预期一致，减少因为错误归因造成的无效修复。

## 项目状态

当前处于 **MVP 实现与验证阶段**。Repository/Worktree 采集、环境快照、Vitest/TypeScript 构建日志解析、R001–R005 确定性诊断、Text/JSON Reporter、默认 Home 路径脱敏，以及 `version`、`analyze-log`、`inspect` CLI 已有可运行实现；`doctor`、更多日志适配器与更广泛的 secret scanner 仍在后续范围。

## MVP 目标

首个可验收版本聚焦 5 个能力：

1. **Repository Scanner**：读取 Git 分支、Worktree、工作区变更等状态。
2. **Test Log Parser**：解析常见构建/测试输出并提取失败特征。
3. **Environment Inspector**：检查依赖、锁文件及常见环境异常信号。
4. **Diagnosis Engine**：基于可解释规则区分代码故障、环境故障与仓库状态异常。
5. **Report Generator**：输出终端报告及结构化 JSON 报告。

## 设计原则

- **MoonBit 为主要实现语言**。
- **确定性诊断优先**：核心结论由可测试规则产生，而不是直接把全部日志交给大模型猜测。
- **AI 为可选增强层**：未来可根据结构化诊断结果生成自然语言解释，但不能成为基础诊断唯一依赖。
- **证据驱动**：每条诊断结论应能指出对应证据。
- **可复现**：通过 fixtures 和自动化测试复现典型故障。
- **默认最小暴露**：报告不回显原始日志，对常见用户 Home 绝对路径在 Reporter 边界折叠为 `$HOME`。
- **范围克制**：MVP 不做 IDE、不做完整多 Agent 调度平台、不自动修改用户源码。

## 当前 CLI

目前已实现并由 Linux / Windows CI 验证：

```bash
agenttrace version
agenttrace inspect .
agenttrace inspect . --format json
agenttrace inspect . --log ./test-output.txt --format json
agenttrace inspect . --log ./test-output.txt --build-exit-code 0 --format json
agenttrace inspect . --build-log ./tsc-output.txt --build-exit-code 2 --format json
agenttrace analyze-log ./test-output.txt
agenttrace analyze-log ./test-output.txt --format json
```

## 可复现核心 Demo

仓库源码态可以直接运行：

```bash
moon run cmd/main inspect . \
  --log fixtures/logs/vitest-missing-matcher.txt \
  --build-exit-code 0 \
  --format json
```

这条命令显式告诉 AgentTrace “编译退出码为 0”，同时提供 27 个 suite / 155 个 case 共享 missing matcher 的测试日志。Linux 与 Windows CI 都会执行这一场景，并验证退出码为 `1`、规则为 `R001`。

实际 JSON 中的关键诊断片段为：

```json
{
  "category": "dependency_environment_error",
  "severity": "error",
  "confidence": "high",
  "rule_ids": ["R001"]
}
```

同一份测试日志如果只执行：

```bash
moon run cmd/main analyze-log fixtures/logs/vitest-missing-matcher.txt
```

由于缺少 compile-pass 事实，AgentTrace 会保持 `unknown`，不会为了得出环境结论而补造证据。

完整的正常、编译故障和环境伪装案例见 [Demo 文档](docs/DEMO.md)。

## 默认报告脱敏

Reporter 默认对常见用户 Home 路径做最小化脱敏：

```text
C:\Users\Alice\work\repo  -> $HOME/work/repo
/home/alice/work/repo       -> $HOME/work/repo
/Users/alice/work/repo      -> $HOME/work/repo
```

脱敏只影响输出视图，不改变 RepositorySnapshot / BuildObservation 原始事实。AgentTrace 默认也不回显整份测试或构建日志。MVP 不把这一能力描述成通用 secret scanner。

## 计划中的目录结构

```text
agenttrace/
├─ cmd/
│  └─ main/
├─ src/
│  ├─ git/
│  ├─ environment/
│  ├─ testlog/
│  ├─ diagnosis/
│  └─ report/
├─ fixtures/
├─ docs/
├─ README.md
├─ CONTRIBUTING.md
├─ LICENSE
└─ moon.mod
```

MoonBit 官方当前推荐新项目使用 `moon.mod` 和 `moon.pkg`，CLI 项目将业务逻辑放在库包中，并让 `cmd/main` 保持轻量。本项目会按这一结构实现。

## 文档

- [项目范围](docs/PROJECT_SCOPE.md)
- [系统架构](docs/ARCHITECTURE.md)
- [CLI 规范](docs/CLI_SPEC.md)
- [诊断引擎设计](docs/DIAGNOSIS_ENGINE.md)
- [数据模型](docs/DATA_MODEL.md)
- [测试计划](docs/TEST_PLAN.md)
- [开发指南](docs/DEVELOPMENT.md)
- [路线图](docs/ROADMAP.md)
- [Visual Report 规范](docs/VISUAL_REPORT.md)
- [贡献指南](CONTRIBUTING.md)

## 许可证

采用 Apache License 2.0，详见 [LICENSE](LICENSE)。

## 项目定位

AgentTrace 不是通用日志查看器，也不是“让 LLM 阅读错误信息”的薄封装。它希望形成一套 **可测试、可解释、可扩展的 AI Coding 工程诊断模型**，让开发者在 Agent 自动修改代码后能够更快判断故障来源，并减少因错误归因导致的无效回滚和重复调试。
