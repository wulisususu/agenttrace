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

## 8. Native 与 Web/WASM 双入口

MVP 首选 Native CLI，以便直接访问本地 Git、文件系统、Worktree、进程和测试输出。Native 入口承担真实工程现场扫描，是 AgentTrace 的主要工作形态。

在核心诊断模型稳定后，可增加 Web/WASM 入口，用于交互式体验、案例复现和公开 Demo。两种入口共享同一套尽可能纯函数化的诊断核心，但平台边界不同：

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
      Git / Worktree            fixtures / logs
      Env / Build / Test        interactive demo
```

优先复用：

- model；
- log parser；
- diagnosis engine；
- serializer；
- 与平台无关的规则与 evidence correlation。

平台适配层单独实现：

- Native：文件系统、Git 命令、进程执行、真实环境采集；
- Web/WASM：浏览器输入、内置 fixture、脱敏日志和演示状态。

## 9. Web Playground 边界

Web Playground 的主要目的不是把 AgentTrace 变成浏览器版 IDE，而是让用户无需安装工具、无需主动制造一个故障仓库，也能快速理解 AgentTrace 如何从输入生成证据和诊断结果。

建议支持：

- 选择预置故障场景；
- 载入脱敏测试日志或 fixture；
- 执行 WASM 侧解析和确定性诊断；
- 展示 Evidence、Diagnosis、Confidence、Suggested Action；
- 以时间线或结构化面板解释多个工程信号之间的关系。

公开 Demo 应尽量保持静态部署友好，不依赖常驻后端服务。普通浏览器环境下无法等价获得 Native CLI 对本地 Git、Worktree、文件系统和进程的完整访问能力，因此 Web Playground 只作为体验与展示入口，不替代真实仓库诊断。
