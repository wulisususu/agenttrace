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

### Visual Report & Live Demo

在 Native CLI 与 JSON Reporter 稳定后，增加一个正式的可视化报告入口。它不是另一套诊断实现，也不是浏览器版 IDE，而是消费 AgentTrace 真实 `DiagnosisResult JSON` 的 Reporter。

目标：

- CLI 对真实仓库、Worktree、环境和测试日志执行诊断；
- JSON Reporter 输出稳定、可复现的 `DiagnosisResult`；
- Visual Report 将同一份 JSON 展示为时间线、Evidence、Diagnosis、Confidence 和 Suggested Action；
- 提供 3–5 个可复现 fixture 场景，例如依赖环境异常、错误 Worktree 验收、异常 HEAD 变化和重复失败聚类；
- Live Demo 使用这些真实 fixture 的输出，不编造诊断结果；
- 每个网页案例都给出对应 CLI 复现命令，使评审者可以从网页展示回到仓库验证；
- 页面保持静态部署友好，可作为公开 Live Demo 发布，不要求常驻后端。

建议数据流：

```text
Git / Worktree / Env / Build / Test
                 │
                 ▼
          AgentTrace Core
                 │
                 ▼
        DiagnosisResult JSON
             ┌───┴────┐
             │        │
             ▼        ▼
       Text Reporter  Visual Report
          Terminal     Live Demo
```

完成标准：

1. 网页展示的数据来自 AgentTrace 实际 JSON 输出；
2. 至少 3 个展示案例可在仓库 fixture 中复现；
3. 同一案例的 CLI 与 Visual Report 必须得到一致的诊断类别、规则 ID、confidence 和 evidence；
4. 用户无需安装工具也能快速理解项目价值，但本地真实仓库诊断仍由 Native CLI 完成。

WASM 作为后续优化项：只有当浏览器内复用 MoonBit 解析/诊断核心能明显提升体验时再引入，不作为 Visual Report 的前置条件。

### Optional AI Explainer

基于结构化 DiagnosisResult 生成自然语言解释。

### Plugin Rules

允许社区扩展：

- 新语言；
- 新测试框架；
- 新故障规则。

## 不做时间承诺的原因

路线图表达依赖关系和优先级，不把尚未验证的工作写成具体完成日期。每个阶段以可运行、可测试的交付物作为完成依据。
