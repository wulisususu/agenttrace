# AgentTrace 项目范围

## 1. 问题定义

AI Coding 工具可以快速修改代码、运行命令和处理测试，但当工程失败时，失败原因经常被混在一起：

- 源码本身存在编译或逻辑错误；
- 依赖没有完整安装；
- lockfile 与实际依赖目录不一致；
- Git Worktree 状态异常；
- 测试框架配置缺失；
- 多个错误只是同一个根因的重复表现；
- Agent 执行被中断，留下半完成状态。

AgentTrace 的目标不是替代测试框架，也不是替代 Codex、Claude Code 等 Agent 的推理和修复能力，而是对这些工程事实进行归一化与关联，帮助开发者或上层 Agent 判断 **故障属于什么类别、有哪些证据、下一步应验证什么**。

可以把职责边界概括为：

- AI Agent：根据上下文决定“怎么修”；
- AgentTrace：先确认“哪里坏了、证据是什么、当前工程现场是否可信”。

## 2. 典型使用场景

### 2.1 多 Agent / 多 Worktree 验收

多个 Agent 可以同时在不同分支或 Worktree 中开发。进入测试和验收阶段后，失败并不一定意味着某个 Agent 写坏了代码，也可能是：

- 当前验收目录不是目标 Worktree；
- 当前 HEAD、分支或基线与预期不一致；
- 工作区存在未提交修改；
- 某个 Worktree 的依赖状态与其他 Worktree 不一致；
- Agent 在执行过程中被中断，留下半完成环境。

AgentTrace 不调度 Agent，而是提供只读的工程状态采集和诊断，帮助确认测试所处的工程现场。

### 2.2 环境故障伪装成代码故障

例如：

```text
compile = pass
27 test files = failed
155 cases = failed
error signature = repeated missing matcher
dependency state = inconsistent
```

如果只查看测试失败，可能会误判为最近源码修改导致回归。

AgentTrace 应通过跨信号关联得出更接近：

```text
Diagnosis: dependency_environment_error
Confidence: high
```

并建议先验证依赖环境，再决定是否修改或回滚源码。

### 2.3 给 AI Coding Agent 提供结构化诊断输入

AgentTrace 的 JSON 输出可以作为 Codex、Claude Code、CI 或其他自动化工具的输入，使上层工具不必每次都从零执行并解释大量 Git、依赖和测试命令。

这不意味着 AgentTrace 替代 AI，而是把可确定、可重复的工程事实先归一化，让 AI 把推理能力集中在后续修复上。

## 3. MVP 输入

MVP 只处理本地工程中可明确获取的信息：

1. Git 仓库状态；
2. Worktree 状态；
3. 文件变更摘要；
4. 依赖与 lockfile 信号；
5. 构建/编译命令结果；
6. 测试日志文本；
7. 用户显式提供的日志文件。

首版不要求接入任何云服务或大模型 API。

## 4. MVP 输出

输出包含四部分：

- **Summary**：当前工程整体状态；
- **Diagnosis**：故障类别与置信等级；
- **Evidence**：支持结论的结构化证据；
- **Suggested checks**：建议的后续验证步骤。

支持两种输出目标：

- 人类可读终端文本；
- 机器可读 JSON。

## 5. 首版故障分类

初始分类控制在有限集合内：

- `repository_state_error`
- `worktree_state_error`
- `dependency_environment_error`
- `build_compile_error`
- `test_runtime_error`
- `test_assertion_failure`
- `configuration_error`
- `unknown`

分类名称在实现阶段可以调整，但应保持稳定、可测试和可序列化。

## 6. 非目标

MVP 明确不做：

- 完整 IDE；
- 通用 CI/CD 平台；
- 多 Agent 调度器；
- 自动提交或推送代码；
- 自动删除、回滚或覆盖用户文件；
- 自动执行高风险修复命令；
- 仅依靠大模型自由推理给出诊断；
- 对所有语言和测试框架宣称完整支持。

## 7. 支持策略

首版优先支持最容易建立可靠 fixtures 的 Node.js/TypeScript 工程信号，同时将内部模型设计为与语言无关。

这意味着：

- 解析器可以先针对 npm/pnpm、Vitest/Jest 等常见输出；
- 核心诊断模型不能把 Node.js 专属字段写死为全局概念；
- 后续可以新增 Python、Rust、MoonBit 等生态适配器。

## 8. 验收标准

MVP 达到以下条件即可视为首版完成：

1. MoonBit 为主要实现语言；
2. 可以对一个本地 fixture 或样例仓库执行诊断；
3. 至少识别 4 类故障；
4. 每类故障都有自动化测试；
5. 能生成文本报告与 JSON 报告；
6. 对同一输入产生稳定结果；
7. README 提供可复现的运行示例；
8. 错误输入不会导致不可解释崩溃。

## 9. 后续扩展

MVP 完成后再考虑：

- Agent session 时间线；
- Codex / Claude Code 日志适配器；
- GitHub Actions 日志分析；
- WASM/Web Dashboard；
- 可选 LLM 解释器；
- 插件式诊断规则；
- 多仓库批量分析。

范围控制原则：**先把一个小而可靠的工程诊断器做完整，再扩展成更大的 Agent 工具链。**
