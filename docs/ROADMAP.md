# AgentTrace 路线图

路线图按“先完成可验收闭环，再增加平台能力”的原则安排。

## Phase 0 — Repository Foundation

目标：

- 项目文档；
- MoonBit 模块初始化；
- LICENSE；
- 基础 CI；
- commit 规范。

完成标准：新贡献者能理解项目为什么存在、准备做什么。

## Phase 1 — Diagnostic Core

目标：

- 核心数据模型；
- Evidence；
- Diagnosis；
- Rule；
- confidence 枚举；
- 文本报告。

完成标准：可以对手工构造 evidence 得出稳定诊断。

## Phase 2 — Test Log Analysis

目标：

- 日志读取；
- error signature；
- 重复错误聚类；
- 第一批 Vitest/Jest 类 fixture；
- compile vs test failure 区分。

完成标准：至少 4 个 fixture 可自动得到预期结果。

## Phase 3 — Repository & Environment

目标：

- Git snapshot；
- Worktree snapshot；
- lockfile/依赖信号；
- Windows 路径支持。

完成标准：可以对真实本地仓库执行只读扫描。

## Phase 4 — MVP CLI

目标：

- `inspect`；
- `analyze-log`；
- text/json reporter；
- exit codes；
- 完整 README Demo。

完成标准：用户 clone 后可按文档复现。

## Phase 5 — Validation

目标：

- 更多 fixtures；
- 边界输入；
- 故障案例说明；
- 性能检查；
- 文档一致性检查。

## Post-MVP

在 MVP 稳定后评估：

### Agent Timeline

记录不同 Agent 执行阶段及失败点。

### Adapter Layer

适配：

- Codex；
- Claude Code；
- GitHub Actions；
- 其他 CI 日志。

### Web/WASM

将纯解析与诊断核心复用到 Web Dashboard。

### Optional AI Explainer

基于结构化 DiagnosisResult 生成自然语言解释。

### Plugin Rules

允许社区扩展：

- 新语言；
- 新测试框架；
- 新故障规则。

## 不做时间承诺的原因

路线图表达依赖关系和优先级，不把尚未验证的工作写成具体完成日期。每个阶段以可运行、可测试的交付物作为完成依据。
