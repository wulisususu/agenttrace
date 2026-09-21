# AgentTrace 开发指南

## 1. 技术基线

- 主实现语言：MoonBit
- 首选运行形态：Native CLI
- 版本控制：Git
- 自动化测试：MoonBit test
- 文档：Markdown

新项目使用当前 MoonBit 配置格式：

- `moon.mod`
- `moon.pkg`

不主动使用已经弃用的新项目 JSON 配置格式。

## 2. 本地环境

安装 MoonBit 工具链后确认：

```bash
moon version
```

项目初始化后常用命令：

```bash
moon check
moon test
moon fmt
moon build --target native
```

## 2.1 Fresh-install 验证

普通 CI checkout 用于持续测试；另外的 `fresh-install` workflow 用于验证文档里的源码安装路径。

它不复用工作区产物，而是在 GitHub hosted runner 上：

1. 显式安装固定 MoonBit 工具链；
2. 在新的目录重新 `git clone` 仓库；
3. checkout 当前 push 的精确 commit；
4. 执行 `moon update`、check、test、native build；
5. 实际运行 `version` 与 `inspect`。

因此 README 的“从零安装与验证”不是只靠开发者本机经验维护，而有独立的 Ubuntu / Windows 自动化回归。

## 3. CLI 架构约定

Native CLI 按以下原则组织：

- 参数解析与核心逻辑放在可测试库 package；
- `cmd/main` 只做入口接线；
- 文件系统和进程 IO 集中在边界模块；
- 纯诊断逻辑不得依赖终端输出。

## 4. 开发顺序

推荐按照纵向切片开发，而不是一次建立大量空模块。

### Slice 1：Log Parser

- 定义 TestObservation；
- 解析一个固定 fixture；
- 添加测试；
- 输出文本。

### Slice 2：Diagnosis Rule

- 定义 Evidence；
- 实现一条规则；
- 加入 positive/negative tests。

### Slice 3：Repository Snapshot

- Git 状态采集；
- 统一路径模型；
- Windows fixture。

### Slice 4：Report

- 文本；
- JSON；
- schema version。

### Slice 5：整合

- `inspect` 命令；
- 完整 demo fixture；
- README 实际运行结果。

## 5. Commit 规范

建议使用 Conventional Commits 风格：

```text
feat: add vitest log parser
test: cover repeated error signatures
fix: normalize Windows worktree paths
docs: explain diagnosis evidence model
refactor: isolate report serialization
```

一次提交尽量只表达一个完整意图。

禁止为了增加 commit 数量进行：

- 同一内容无意义拆分；
- 空提交；
- 反复删除再恢复；
- 仅修改空格来制造提交。

## 6. 分支建议

项目早期可以直接在 main 保持小步提交。

功能变大后：

```text
feat/log-parser
feat/git-snapshot
feat/json-report
fix/windows-paths
```

## 7. Definition of Done

一个功能完成至少满足：

- 有明确输入/输出；
- 有实现；
- 有测试；
- `moon check` 通过；
- `moon test` 通过；
- 行为变化写入文档；
- 不把未实现能力写成已完成。

## 8. AI Coding 使用约定

允许使用 AI 辅助：

- 代码草拟；
- API 设计讨论；
- 测试补全；
- 文档校对；
- 重构建议。

但提交者必须能解释：

- 为什么采用该结构；
- 规则的证据依据；
- 测试覆盖什么；
- AI 生成代码是否真的运行通过。

最终质量以仓库中可复现的结果为准。
