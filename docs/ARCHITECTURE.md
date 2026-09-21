# AgentTrace 系统架构

## 1. 架构目标

AgentTrace 采用“采集 → 归一化 → 诊断 → 报告”的流水线结构。核心诊断逻辑保持纯函数化，尽量把文件系统、进程和终端等副作用放在边界层。

这样做的目的：

- 规则更容易测试；
- fixtures 可以直接驱动核心逻辑；
- 后续可同时支持 Native CLI 与 WASM/Web；
- AI 解释层可以被替换或完全关闭。

## 2. 高层数据流

```text
Local Repository / Logs
          │
          ▼
┌─────────────────────┐
│ Collectors           │
│ Git / Env / Logs    │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Normalizers         │
│ Raw -> Evidence     │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Diagnosis Engine    │
│ Rules + Correlation │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Reporters           │
│ Text / JSON         │
└─────────────────────┘
```

## 3. 与 AI Coding Agent 的关系

AgentTrace 位于 AI Coding Agent 与底层工程状态之间，职责不是替代 Agent 的推理与修复，而是提供稳定的工程事实和确定性诊断。

```text
Codex / Claude Code / other Agent
              │
              │ reasoning / repair
              ▼
          AgentTrace
              │
        DiagnosisResult
              │
              ▼
 Git / Worktree / Env / Build / Test
```

职责边界：

- AgentTrace 负责采集、归一化、关联和输出证据；
- 上层 Agent 根据 DiagnosisResult 决定是否继续检查、修改代码或执行修复；
- AgentTrace 默认不直接修改用户源码，也不承担多 Agent 调度；
- 相同输入应尽可能得到相同的诊断结果，避免把基础故障归因完全交给概率性模型。

Text Reporter 面向人类终端使用；JSON Reporter 面向 Codex、Claude Code、CI 和其他自动化工具集成。

典型调用可以是：

```text
Agent modifies code
       │
       ▼
build / test fails
       │
       ▼
agenttrace inspect . --format json
       │
       ▼
structured evidence + diagnosis
       │
       ▼
Agent decides next repair step
```

这样可以避免上层 Agent 仅凭最后一段错误日志就直接修改或回滚源码，而忽略 Worktree、HEAD、依赖或环境异常。

## 4. 模块划分

### 4.1 git

职责：

- 当前分支；
- HEAD；
- dirty files；
- ahead/behind 等可获得信息；
- Worktree 列表和当前路径关联。

该模块只负责采集和解析，不直接做“故障”结论。

### 4.2 environment

职责：

- 检查已知 lockfile；
- 检查依赖目录/关键配置文件是否存在；
- 记录环境一致性信号；
- 将平台差异归一化。

首版只输出 evidence，不主动修改环境。

### 4.3 testlog

职责：

- 读取日志；
- 识别 runner；
- 提取错误行、测试统计、重复模式；
- 生成统一的 TestObservation。

### 4.4 diagnosis

职责：

- 接收归一化 evidence；
- 执行确定性规则；
- 合并多个弱信号；
- 生成 DiagnosisResult。

该模块应避免直接读取文件或执行命令。

### 4.5 report

职责：

- 文本输出；
- JSON 输出；
- 保证机器可读字段稳定。

### 4.6 cmd/main

只做：

- CLI 参数解析；
- 调用应用层；
- 设置 exit code；
- 打印最终结果。

不在这里堆叠诊断业务逻辑。

## 5. 建议目录

```text
.
├─ cmd/
│  └─ main/
├─ src/
│  ├─ model/
│  ├─ git/
│  ├─ environment/
│  ├─ testlog/
│  ├─ diagnosis/
│  └─ report/
├─ fixtures/
│  ├─ repository/
│  ├─ logs/
│  └─ expected/
└─ docs/
```

实际 MoonBit package 布局在初始化时根据编译器和包系统验证后落地。

## 6. 依赖方向

推荐：

```text
cmd -> application -> collectors
                  -> diagnosis
                  -> report

collectors -> model
diagnosis  -> model
report     -> model
```

禁止：

```text
diagnosis -> cmd
model     -> filesystem/process APIs
```

## 7. AI 增强层

未来可添加：

```text
DiagnosisResult
      │
      ├── deterministic report
      │
      └── optional explainer -> LLM
```

LLM 只能解释已有证据或提出额外检查建议，不能静默覆盖确定性诊断结果。

## 8. Reporter 架构与 Visual Report

MVP 首选 Native CLI，以便直接访问本地 Git、文件系统、Worktree、进程和测试输出。Native 入口承担真实工程现场扫描，是 AgentTrace 的主要工作形态。

诊断核心只生成结构化 `DiagnosisResult`，不同 Reporter 负责不同消费场景：

```text
Git / Worktree / Env / Build / Test
                 │
                 ▼
          Collect + Normalize
                 │
                 ▼
          Diagnosis Engine
                 │
                 ▼
        DiagnosisResult JSON
          ┌──────┼────────┐
          │      │        │
          ▼      ▼        ▼
        Text    JSON    Visual
      Reporter Reporter Reporter
          │      │        │
       terminal agent/CI  browser
```

### 8.1 Text Reporter

面向终端用户，强调快速阅读和明确建议。

### 8.2 JSON Reporter

作为稳定机器接口，面向：

- Codex / Claude Code 等 Agent；
- CI；
- Visual Report；
- 后续外部工具集成。

Visual Report 不重新实现诊断规则，而应严格消费 JSON Reporter 的输出。

### 8.3 Visual Report

Visual Report 是 AgentTrace 的正式展示型 Reporter，而不是独立产品。

职责：

- 展示 Diagnosis、Severity、Confidence、Rule IDs；
- 展示 Evidence 与其来源；
- 将可用的时间信息组织为诊断时间线；
- 展示 Suggested Action；
- 标出输入是否来自真实扫描、fixture 或脱敏日志；
- 为内置 Demo 提供对应 CLI 复现命令。

Visual Report 不负责：

- 在浏览器里完整扫描本地 Git 仓库；
- 重新计算一套与 CLI 不同的诊断；
- 为了展示效果伪造概率、Evidence 或时间线事件；
- 替代 Native CLI 的真实工程诊断。

## 9. 可复现 Live Demo

公开 Live Demo 应建立在仓库内的 fixture 和真实 `DiagnosisResult` 上。推荐流程：

```text
fixture / sample log
        │
        ▼
agenttrace inspect ... --format json
        │
        ▼
checked-in / generated DiagnosisResult
        │
        ▼
Visual Report
```

至少覆盖 3–5 个代表性事故：

- 依赖环境异常导致大量测试共享同一错误签名；
- 在错误 Worktree 中执行验收；
- HEAD / branch 与预期状态不一致；
- dirty state 或残留状态干扰验收；
- 多个弱信号关联后得到高置信度故障归因。

每个网页案例必须能够回到仓库复现。评审者看到的可视化结果，应与对应 CLI 输出保持一致。

## 10. WASM 边界

WASM 是可选增强，而不是 Visual Report 的前置条件。

如果后续需要在浏览器内直接解析脱敏日志或运行纯函数化诊断规则，可复用：

- model；
- log parser；
- diagnosis engine；
- serializer；
- 与平台无关的 rule / evidence correlation。

文件系统、Git 命令、Worktree 发现、进程执行等能力仍属于 Native 平台适配层。普通浏览器无法等价替代这些能力，因此浏览器入口始终不是完整本地扫描器。
