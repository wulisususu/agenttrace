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

### Web/WASM Playground

在 Native CLI 稳定后，为项目提供一个无需安装即可体验的 Web Playground，用于降低首次体验和评审演示门槛。

目标：

- 将可纯函数化的 MoonBit 核心（model、log parser、diagnosis engine、serializer）复用到 WASM；
- 提供内置故障场景，例如 Worktree 状态异常、重复测试失败、依赖环境异常和多 Agent 修改冲突；
- 用户可以在浏览器中选择场景、运行诊断，并查看 Evidence、Diagnosis、Suggested Action 等结构化结果；
- 支持加载脱敏后的日志或预构造 fixture，便于展示诊断能力；
- Web 页面保持静态部署友好，可直接作为项目 Live Demo 发布，不依赖常驻后端服务；
- Web Playground 不替代 Native CLI，也不声称能够在普通浏览器中完整扫描用户本地 Git 仓库。

建议形态：

```text
                    AgentTrace Core
                       MoonBit
                          │
             ┌────────────┴────────────┐
             │                         │
          Native                    WASM
             │                         │
             ▼                         ▼
      agenttrace CLI            Web Playground
      real repository           fixtures / logs
        inspection               interactive demo
```

完成标准：访问公开 Demo 后，不安装 AgentTrace、不准备真实故障仓库，也能在数步操作内理解 AgentTrace 的诊断输入、证据链和输出结果。

### Optional AI Explainer

基于结构化 DiagnosisResult 生成自然语言解释。

### Plugin Rules

允许社区扩展：

- 新语言；
- 新测试框架；
- 新故障规则。

## 不做时间承诺的原因

路线图表达依赖关系和优先级，不把尚未验证的工作写成具体完成日期。每个阶段以可运行、可测试的交付物作为完成依据。
