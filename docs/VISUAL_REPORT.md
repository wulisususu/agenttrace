# AgentTrace Visual Report 规范

## 0. 当前实现状态

首个纵向切片已经实现：

- Case A（Dependency Environment Failure）已有静态 Visual Report；
- 页面消费由真实 `agenttrace inspect ... --format json` 生成的数据；
- CI 校验 `schema_version`、build/test 事实、category、severity、confidence、R001、Evidence 和 Suggested Action；
- 静态 bundle 通过 HTTP smoke test 后作为 `agenttrace-visual-report` Actions artifact 上传；
- 浏览器代码只负责展示，不重新判断故障类型；
- 当前尚未把 artifact 宣称为公开 Live Demo，也尚未完成 Case B–E。

## 1. 目标

Visual Report 是 AgentTrace 的一个正式 Reporter，用来把真实的 `DiagnosisResult JSON` 转换成更容易理解和展示的诊断界面。

它解决的是“如何看懂诊断结果”，而不是“如何重新做一次诊断”。

核心原则：

> 同一个输入，CLI、JSON Reporter 和 Visual Report 必须表达同一份诊断事实。

## 2. 数据来源

Visual Report 只接受 AgentTrace 已生成的结构化结果。

推荐数据流：

```text
Repository / Worktree / Env / Build / Test
                    │
                    ▼
             AgentTrace Core
                    │
                    ▼
           DiagnosisResult JSON
                    │
                    ▼
             Visual Report
```

首版 Live Demo 可以使用：

- 仓库 fixture 的真实诊断输出；
- 脱敏后的真实日志；
- CI 生成并校验过的示例 JSON。

不得为了页面效果手写一个与 AgentTrace 实际输出不一致的“演示答案”。

## 3. 首版界面信息

Visual Report 首版优先展示以下内容。

### Summary

- Diagnosis category；
- Severity；
- Confidence；
- Rule IDs；
- 一句话诊断摘要。

### Evidence

逐条展示诊断依据，例如：

- build exit code；
- test suite / case 统计；
- repeated error signature；
- branch / HEAD；
- dirty files；
- Worktree 状态；
- dependency / lockfile signal。

每条 Evidence 应尽量保留来源信息，方便回到原始输入核验。

### Timeline

只有数据中存在可验证的顺序或时间信息时才展示时间线。

不得为了“看起来更像事故分析”而虚构 Agent 启动时间、文件修改时间或 Git 事件。

### Suggested Action

展示确定性规则已经给出的下一步建议，例如：

1. verify dependency installation；
2. restore environment；
3. rerun tests；
4. only then consider reverting source changes。

### Reproduce

每个内置案例给出对应的 CLI 复现命令。

示例：

```bash
moon run cmd/main inspect . \
  --log fixtures/logs/vitest-missing-matcher.txt \
  --build-exit-code 0 \
  --format json
```

## 4. 首批 Demo 场景

建议至少准备 3 个，目标 5 个。

### Case A — Dependency Environment Failure

特征：

- compile / build PASS；
- 大量测试失败；
- 多个 suite 共享相同错误签名；
- 诊断为环境或依赖问题。

这是首个主 Demo。

### Case B — Wrong Worktree Validation

特征：

- 修改发生在 Worktree A；
- 验收发生在 Worktree B；
- branch / HEAD / path evidence 不一致。

### Case C — Unexpected HEAD / Branch State

特征：

- 当前 HEAD 与预期基线不一致；
- 或处于 detached / unexpected branch 状态；
- 诊断明确指出仓库现场不可信。

### Case D — Dirty State Interference

特征：

- 工作区存在残留修改；
- 当前测试结果不能被可靠归因到目标提交。

### Case E — Correlated Failure

多个单独看较弱的信号经过规则关联后形成高置信度诊断。

## 5. 展示结构

推荐单页结构：

```text
┌─────────────────────────────────────────┐
│ Diagnosis Summary                       │
│ category / severity / confidence        │
├─────────────────────────────────────────┤
│ Evidence                                │
│ ✓ signal 1                              │
│ ✓ signal 2                              │
│ ✓ signal 3                              │
├─────────────────────────────────────────┤
│ Timeline (only when evidence exists)    │
├─────────────────────────────────────────┤
│ Suggested Action                        │
├─────────────────────────────────────────┤
│ Reproduce with CLI                      │
└─────────────────────────────────────────┘
```

首版不要做：

- IDE；
- 复杂拖拽编辑器；
- Agent 调度平台；
- 仓库管理后台；
- 登录、账号、云同步；
- 独立于 AgentTrace Core 的第二套诊断逻辑。

## 6. 一致性要求

对于同一个 fixture：

- CLI 的 category 必须等于 Visual Report category；
- severity 必须一致；
- confidence 必须一致；
- rule IDs 必须一致；
- Evidence 不得添加不存在于 JSON 中的事实；
- Suggested Action 不得与核心诊断相冲突。

首个 R001 页面已经在 CI 中校验真实 CLI JSON 的关键契约；后续扩展多案例时再评估完整 golden JSON / snapshot 校验。

## 7. Live Demo 定位

Live Demo 的目标不是证明“AgentTrace 有一个网站”，而是证明：

1. AgentTrace 可以真实诊断；
2. 诊断证据可解释；
3. 结果可复现；
4. 同一套核心结果既能给人看，也能给 Agent / CI 消费。

一句话：

> Visual Report 是诊断结果的可视化，不是诊断能力的替代品。
