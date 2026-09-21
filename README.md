# AgentTrace

> **MoonBit 结构化工程诊断基础库**：提供 Evidence 模型、确定性规则引擎、诊断结果模型与可复用 Reporter；AI Coding CLI 与 Visual Report 只是基于该基础库构建的参考应用。

AgentTrace 的核心目标不是再做一个“会读日志的 AI 产品”，而是为 MoonBit 生态提供一套可以被其他工具直接复用的 **结构化诊断基础设施**：

```text
Raw facts / parsers / collectors
            │
            ▼
      AgentTrace Core
  Evidence -> Rule -> Diagnosis
            │
            ├── custom MoonBit tools
            ├── CI diagnostics
            ├── config / service health checks
            └── AgentTrace built-in adapters
                         │
                         ▼
                 CLI / Visual Report
```

## 项目定位

### 主体：可复用基础库

公共包：

```text
wulisususu/agenttrace/core
```

Core 不依赖：

- Git
- Vitest
- TypeScript
- AgentTrace CLI
- Web 页面
- LLM
- 网络服务

外部 MoonBit 项目可以只导入 Core，自行提供 Evidence 和领域规则。

### 参考实现：工程诊断适配器

仓库同时提供：

- `src/testlog`：Vitest 日志解析
- `src/buildlog`：TypeScript 编译日志解析
- `src/git`：Git / Worktree 状态采集
- `src/environment`：Node.js 工程环境信号
- `src/diagnosis`：R001–R005 内置工程诊断规则
- `src/report`：Text / JSON Reporter
- `src/cli`：基于上述基础库与适配器构建的 CLI 示例

这些模块用于验证基础库能否落地到真实工程场景，不是 Core 的前置依赖。

---

## Core API

### Evidence

```moonbit
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}
```

Evidence 只描述“观察到了什么”，不直接承载根因判断。

### Rule

```moonbit
pub(all) struct Rule {
  id : String
  category : String
  severity : String
  confidence : String
  required_evidence_kinds : Array[String]
  suggested_checks : Array[String]
}
```

当前基础引擎提供确定性的 all-of 规则：当要求的 Evidence kind 全部存在时，规则命中。

### Diagnosis

```moonbit
pub(all) struct Diagnosis {
  category : String
  severity : String
  confidence : String
  rule_ids : Array[String]
  evidence : Array[Evidence]
  suggested_checks : Array[String]
}
```

每个诊断都保留命中规则和参与判断的 Evidence，因此结果可解释、可测试、可复现。

### 最小使用示例

```moonbit
let evidence : Array[@core.Evidence] = [
  {
    id: "E1",
    kind: "timeout",
    message: "request timed out",
    source: "http",
  },
  {
    id: "E2",
    kind: "retry_exhausted",
    message: "retry budget exhausted",
    source: "runtime",
  },
]

let rule : @core.Rule = {
  id: "SERVICE001",
  category: "service_unavailable",
  severity: "error",
  confidence: "high",
  required_evidence_kinds: ["timeout", "retry_exhausted"],
  suggested_checks: ["verify upstream service availability"],
}

match @core.evaluate_rule(rule, evidence) {
  Some(diagnosis) => {
    // use diagnosis.category / diagnosis.evidence / diagnosis.rule_ids
  }
  None => ()
}
```

完整可编译示例见：

```text
examples/custom_rules/
```

详细公共 API 文档见 [docs/LIBRARY_API.md](docs/LIBRARY_API.md)。

---

## 为什么要做成基础库

很多诊断工具把“采集、判断、展示”写死在同一个产品里，导致规则难以复用，也很难测试某个结论到底基于什么证据。

AgentTrace 将流程拆成：

```text
Observation
   ↓
Evidence
   ↓
Rule Engine
   ↓
Diagnosis
   ↓
Reporter / App
```

这样上层项目可以替换任何一层：

- 自己写日志解析器，只复用 Core；
- 自己定义规则，只复用 Evidence / Diagnosis 模型；
- 不使用 CLI，直接将 Diagnosis 接入 Web 或 CI；
- 不使用 AgentTrace 内置 R001–R005，自定义完全不同领域的规则。

因此 AgentTrace Core 可以用于：

- CI / 构建诊断
- 配置校验
- 服务健康判断
- 测试结果归因
- 网络故障分析
- Agent 执行状态分析
- 其他“结构化事实 → 可解释结论”的 MoonBit 工具

---

## 当前完成情况

当前已完成：

- [x] 独立 `core` 公共 MoonBit 包
- [x] Evidence / Rule / Diagnosis 公共数据模型
- [x] `evaluate_rule` / `evaluate_rules`
- [x] 通用规则引擎测试
- [x] 独立自定义规则消费示例
- [x] Git / Worktree Collector
- [x] Environment Collector
- [x] Vitest 日志解析
- [x] TypeScript Build Log 解析
- [x] R001–R005 内置工程规则
- [x] Text / JSON Reporter
- [x] Windows / Linux CI
- [x] Native CLI
- [x] Visual Report 与 GitHub Pages Demo

当前重点已经从“继续增加产品功能”调整为：**把 Core 做成即使脱离所有参考应用，也能独立成立的 MoonBit 基础库。**

Core 当前额外具备：

- [x] `Condition { all_of / any_of / none_of }`
- [x] `PolicyRule` 与 priority
- [x] `evaluate_policy_rule` / `evaluate_policy_rules`
- [x] `evaluate_highest_priority`
- [x] Evidence 查询 API
- [x] Rule Validation
- [x] duplicate rule id 检查
- [x] 外部 package contract test
- [x] 两个与具体开发工具无关的独立示例

---

## AgentTrace 自带的 AI Coding 工程诊断示例

AI Coding 只是基础库的一个真实使用场景。

例如出现：

```text
27 test files failed
155 tests failed
Invalid Chai property: toBeInTheDocument
```

结合：

```text
compile = pass
test failures = highly repetitive
dependency state = inconsistent
```

内置规则可以输出：

```text
category: dependency_environment_error
confidence: high
rule: R001
```

这里的价值不是“让 LLM 猜一下原因”，而是把工程现场转化成明确 Evidence，再由可测试规则产生 Diagnosis。

---

## CLI

CLI 是 Core 的参考应用之一。

当前已实现：

```bash
agenttrace version
agenttrace inspect .
agenttrace inspect . --format json
agenttrace inspect . --log ./test-output.txt --format json
agenttrace inspect . --build-log ./tsc-output.txt --build-exit-code 2 --format json
agenttrace inspect . --expected-branch main --require-clean --format json
agenttrace analyze-log ./test-output.txt
```

源码态运行：

```bash
moon run cmd/main version
moon run cmd/main inspect . --format json
```

---

## 从源码验证

已验证 MoonBit 编译器版本：

```text
0.10.14+7d59c7ec9
```

### Linux / macOS

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s "0.10.14+7d59c7ec9"
export PATH="$HOME/.moon/bin:$PATH"

git clone https://github.com/wulisususu/agenttrace.git
cd agenttrace

moon update
moon check --target native --deny-warn
moon test --target native
moon build --target native
```

### Windows PowerShell

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
$env:MOONBIT_INSTALL_VERSION = "0.10.14+7d59c7ec9"
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
$env:Path = "$HOME\.moon\bin;$env:Path"

git clone https://github.com/wulisususu/agenttrace.git
Set-Location agenttrace

moon update
moon check --target native --deny-warn
moon test --target native
moon build --target native
```

---

## 仓库结构

```text
agenttrace/
├─ core/                    # 公共基础库：项目主体
│  ├─ core.mbt
│  ├─ core_test.mbt
│  └─ moon.pkg
├─ examples/
│  └─ custom_rules/        # 独立消费者示例
├─ src/
│  ├─ buildlog/            # 参考适配器
│  ├─ diagnosis/           # 内置规则集
│  ├─ environment/         # 参考采集器
│  ├─ git/                 # 参考采集器
│  ├─ report/              # Reporter
│  ├─ testlog/             # 参考解析器
│  └─ cli/                 # 示例应用
├─ cmd/
│  └─ main/
├─ fixtures/
├─ docs/
└─ web/                    # Visual Report 示例
```

---

## 后续基础库路线

下一阶段仍然优先扩展可复用能力，而不是堆叠产品界面：

- 通用 error signature / normalization
- 更丰富的组合条件
- RuleSet / conflict policy
- Evidence metadata
- Core serializer / stable schema
- WASM 可复用核心
- property-based / fuzz 风格边界测试

---

## 文档

- [公共 Library API](docs/LIBRARY_API.md)
- [项目范围](docs/PROJECT_SCOPE.md)
- [系统架构](docs/ARCHITECTURE.md)
- [诊断引擎设计](docs/DIAGNOSIS_ENGINE.md)
- [数据模型](docs/DATA_MODEL.md)
- [测试计划](docs/TEST_PLAN.md)
- [开发指南](docs/DEVELOPMENT.md)
- [路线图](docs/ROADMAP.md)
- [贡献指南](CONTRIBUTING.md)

## 许可证

Apache License 2.0，详见 [LICENSE](LICENSE)。
