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

AgentTrace 的目标不是替代测试框架，而是对这些信息进行归一化与关联，帮助开发者判断 **故障属于什么类别、有哪些证据、下一步应验证什么**。

## 2. MVP 输入

MVP 只处理本地工程中可明确获取的信息：

1. Git 仓库状态；
2. Worktree 状态；
3. 文件变更摘要；
4. 依赖与 lockfile 信号；
5. 构建/编译命令结果；
6. 测试日志文本；
7. 用户显式提供的日志文件。

首版不要求接入任何云服务或大模型 API。

## 3. MVP 输出

输出包含四部分：

- **Summary**：当前工程整体状态；
- **Diagnosis**：故障类别与置信等级；
- **Evidence**：支持结论的结构化证据；
- **Suggested checks**：建议的后续验证步骤。

支持两种输出目标：

- 人类可读终端文本；
- 机器可读 JSON。

## 4. 首版故障分类

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

## 5. 非目标

MVP 明确不做：

- 完整 IDE；
- 通用 CI/CD 平台；
- 多 Agent 调度器；
- 自动提交或推送代码；
- 自动删除、回滚或覆盖用户文件；
- 自动执行高风险修复命令；
- 仅依靠大模型自由推理给出诊断；
- 对所有语言和测试框架宣称完整支持。

## 6. 支持策略

首版优先支持最容易建立可靠 fixtures 的 Node.js/TypeScript 工程信号，同时将内部模型设计为与语言无关。

这意味着：

- 解析器可以先针对 npm/pnpm、Vitest/Jest 等常见输出；
- 核心诊断模型不能把 Node.js 专属字段写死为全局概念；
- 后续可以新增 Python、Rust、MoonBit 等生态适配器。

## 7. 验收标准

MVP 达到以下条件即可视为首版完成：

1. MoonBit 为主要实现语言；
2. 可以对一个本地 fixture 或样例仓库执行诊断；
3. 至少识别 4 类故障；
4. 每类故障都有自动化测试；
5. 能生成文本报告与 JSON 报告；
6. 对同一输入产生稳定结果；
7. README 提供可复现的运行示例；
8. 错误输入不会导致不可解释崩溃。

## 8. 后续扩展

MVP 完成后再考虑：

- Agent session 时间线；
- Codex / Claude Code 日志适配器；
- GitHub Actions 日志分析；
- WASM/Web Dashboard；
- 可选 LLM 解释器；
- 插件式诊断规则；
- 多仓库批量分析。

范围控制原则：**先把一个小而可靠的工程诊断器做完整，再扩展成更大的 Agent 工具链。**
