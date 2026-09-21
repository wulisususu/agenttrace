# AgentTrace 项目范围

## 1. 项目主体

AgentTrace 的主体是 **MoonBit 结构化诊断基础库**，不是单一面向 AI Coding 的落地产品。

公共核心包位于：

```text
wulisususu/agenttrace/core
```

Core 提供：

- Evidence 数据模型；
- Rule 数据模型；
- Diagnosis 数据模型；
- 确定性规则评估；
- 多规则评估。

Core 本身不依赖 Git、Vitest、TypeScript、CLI、Web 或 LLM。

## 2. 要解决的通用问题

很多工程工具都需要把“多个结构化事实”组合成“可解释结论”：

```text
facts / observations
        ↓
     Evidence
        ↓
   deterministic rules
        ↓
     Diagnosis
```

如果每个工具都把解析、规则和输出写死在应用层：

- 规则难以复用；
- 很难测试结论依据；
- 上层 UI 和底层诊断强耦合；
- 不同领域无法共享模型。

AgentTrace 希望提供一组足够小、可复用的 MoonBit 基础组件。

## 3. 公共基础能力

首版 Core 包含：

1. `Evidence`：结构化事实；
2. `Rule`：规则声明；
3. `Diagnosis`：可解释诊断结果；
4. `evaluate_rule`：单规则确定性匹配；
5. `evaluate_rules`：规则集评估；
6. `unknown_diagnosis`：明确的未知结果。

当前规则模型采用 all-of evidence kinds，优先保证行为稳定和容易测试。

## 4. 参考适配器

AgentTrace 仓库同时提供一组建立在 Core 上的真实适配器：

- Vitest 日志解析；
- TypeScript Build Log 解析；
- Git / Worktree 状态采集；
- Node.js 环境信号采集；
- R001–R005 工程诊断规则；
- Text / JSON Reporter；
- CLI；
- Visual Report。

这些模块证明 Core 可以落地到实际开发者工具，但不定义 Core 的使用边界。

## 5. 可复用场景

Core 可被其他 MoonBit 项目用于：

- CI / 构建诊断；
- 配置校验；
- 服务健康判断；
- 网络故障归因；
- 测试结果分析；
- Agent 执行状态判断；
- 静态检查工具；
- 其他基于 Evidence 的规则系统。

## 6. 非目标

Core 首版明确不做：

- 完整 IDE；
- 多 Agent 调度器；
- 自动代码修复；
- Git 自动提交或回滚；
- 云端日志平台；
- LLM 推理框架；
- 通用复杂规则语言。

这些能力可以由上层应用实现。

## 7. 设计约束

基础库必须：

- 可以独立于 CLI 使用；
- 可以独立于 AI Coding 场景使用；
- 保持确定性；
- 保留诊断证据；
- 可通过 fixtures 和单元测试复现；
- 不进行隐式文件系统或网络访问。

## 8. 验收标准

首版基础库完成条件：

1. MoonBit 为主要实现语言；
2. 独立 `core` package 可被其他 package import；
3. 提供公开 Evidence / Rule / Diagnosis 模型；
4. 提供规则评估 API；
5. 有与 AgentTrace 产品无关的消费者示例；
6. 有正例和反例自动化测试；
7. 现有 CLI 能作为 Core 的参考应用继续工作；
8. Linux / Windows CI 通过。

## 9. 后续扩展

优先增强基础库属性：

- error signature / normalization；
- composable conditions；
- rule priority；
- Evidence metadata；
- adapter interface；
- stable report schema；
- WASM 可复用核心。

原则：**新增能力首先判断能否被 AgentTrace 之外的 MoonBit 项目独立复用。**
