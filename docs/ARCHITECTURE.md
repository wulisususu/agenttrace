# AgentTrace 系统架构

## 1. Library First

AgentTrace 采用三层结构：

```text
┌──────────────────────────────────┐
│ Public Core Library              │
│ Evidence / Rule / Diagnosis      │
│ evaluate_rule / evaluate_rules   │
└─────────────────┬────────────────┘
                  │
        reusable by any MoonBit tool
                  │
┌─────────────────▼────────────────┐
│ Adapters                         │
│ parsers / collectors / rules     │
└─────────────────┬────────────────┘
                  │
┌─────────────────▼────────────────┐
│ Reference Applications           │
│ CLI / Visual Report              │
└──────────────────────────────────┘
```

依赖方向只能向下，Core 不得反向依赖适配器或应用。

## 2. Core

路径：

```text
core/
```

职责：

- 定义 Evidence；
- 定义 Rule；
- 定义 Diagnosis；
- 执行确定性规则；
- 返回可解释结果。

Core 不做：

- 文件系统 IO；
- Git 命令；
- 日志读取；
- 网络请求；
- LLM 调用；
- UI。

## 3. Adapters

### testlog

将特定测试日志转换为结构化观察。

### buildlog

将编译器输出转换为结构化观察。

### git

采集 Git / Worktree 状态。

### environment

采集工程环境信号。

### diagnosis

提供 AgentTrace 自带的领域规则 R001–R005。

领域规则可以直接构造 Core Diagnosis，也可以逐步迁移为通用 Rule + Evidence 组合。

### report

把 Core Diagnosis 或聚合报告输出为 Text / JSON。

## 4. Reference Applications

### CLI

负责：

- 参数解析；
- 调用 collectors / parsers；
- 运行内置规则；
- 输出报告。

CLI 是基础库消费者。

### Visual Report

负责：

- 展示真实 CLI 产生的 JSON；
- 演示结构化诊断结果如何被 UI 消费。

Web 不包含第二套诊断引擎。

## 5. 外部消费者

外部项目最小依赖只需：

```text
wulisususu/agenttrace/core
```

例如：

```text
custom collector
      ↓
Evidence[]
      ↓
AgentTrace Core
      ↓
Diagnosis[]
      ↓
custom UI / CI / service
```

仓库内 `examples/custom_rules` 用一个与 AI Coding 无关的服务健康场景验证这种用法。

## 6. 依赖规则

允许：

```text
CLI -> adapters -> core
report -> core
diagnosis -> core
external tool -> core
```

禁止：

```text
core -> CLI
core -> Git
core -> Vitest
core -> Node.js
core -> Web
```

## 7. 测试策略

Core 的测试不依赖真实 Git 仓库或系统环境，只使用纯数据。

Adapters 通过 fixtures 测试。

Reference Applications 通过集成测试和 CI 验证。

这样可以把：

- 基础库正确性；
- 领域适配正确性；
- 最终产品流程正确性

分开验证。
