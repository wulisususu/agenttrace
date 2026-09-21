# AgentTrace

> 基于 MoonBit 的 AI Coding 工程诊断工具，分析仓库、环境与测试日志，定位代码和环境故障。

AgentTrace 面向使用 Codex、Claude Code、Copilot CLI 等 AI Coding 工具的开发者。它计划通过结构化分析 Git/Worktree 状态、依赖环境、构建结果与测试日志，帮助开发者回答一个常见问题：

> **这次失败究竟是代码写坏了，还是开发环境出了问题？**

## 项目状态

当前处于 **MVP 设计与实现阶段**。仓库中的功能说明以“计划 / 目标”为主，未标记为已完成的能力均不代表当前已经实现。

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
- **范围克制**：MVP 不做 IDE、不做完整多 Agent 调度平台、不自动修改用户源码。

## 初步使用形态

计划中的 CLI 形式：

```bash
agenttrace inspect .
agenttrace inspect . --format json
agenttrace analyze-log ./test-output.txt
agenttrace doctor .
```

示例输出目标：

```text
AgentTrace

Repository
  Branch: feat/ui-settings
  Dirty files: 3

Build
  TypeScript: PASS

Tests
  Test files: 27 failed
  Cases: 155 failed

Diagnosis
  Category: environment_dependency_error
  Confidence: high

Evidence
  - compilation succeeds
  - test suites share the same missing matcher
  - dependency signal is consistent across failures

Suggested action
  1. verify dependency installation
  2. restore dependencies
  3. rerun tests before reverting source changes
```

> 上述内容是目标输出格式示意，不代表当前版本已实现。

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
- [贡献指南](CONTRIBUTING.md)

## 许可证

计划采用 Apache License 2.0，详见 [LICENSE](LICENSE)。

## 项目定位

AgentTrace 不是通用日志查看器，也不是“让 LLM 阅读错误信息”的薄封装。它希望形成一套 **可测试、可解释、可扩展的 AI Coding 工程诊断模型**，让开发者在 Agent 自动修改代码后能够更快判断故障来源，并减少因错误归因导致的无效回滚和重复调试。
