# 诊断引擎设计

## 1. 核心思想

AgentTrace 不把“错误字符串”直接等同于“根因”。

诊断分为三层：

1. **Observation**：观察到了什么；
2. **Evidence**：这个观察能支持什么判断；
3. **Diagnosis**：多个证据组合后的结论。

例如：

```text
Observation:
155 tests fail with "Invalid Chai property"

Observation:
TypeScript compilation passes

        ↓

Evidence:
failures are highly repetitive
compile layer appears healthy

        ↓

Diagnosis:
dependency_environment_error
confidence = high
```

## 2. 规则结构

每条规则至少包含：

- `id`
- `description`
- 前置条件；
- 正向证据；
- 反向证据；
- 输出 category；
- severity；
- confidence；
- suggested checks。

## 3. 置信等级

MVP 不使用伪精确百分比，先采用：

- `low`
- `medium`
- `high`

原因：首版规则没有足够训练数据支撑“91%”之类概率含义。

未来如果拥有标注数据，再考虑概率模型。

## 4. 初始规则

### R001：编译通过 + 测试大面积同源失败

条件：

- compile = pass；
- test = fail；
- 多个 suite 出现高度相似错误签名；
- 错误指向测试依赖、matcher、runner setup 或模块缺失。

倾向：

`dependency_environment_error`

### R002：编译阶段明确语法/类型错误

MVP 最小条件：

- compiler exit code != 0；
- 日志至少包含一个明确的源码位置；
- 对应错误具有可识别的编译器错误码。

倾向：

`build_compile_error`

如果后续同时取得 RepositorySnapshot，可再用“错误文件是否属于 changed files”等信息增强证据；该关联不是首版 R002 的必要条件，避免因为用户正在编译既有错误代码而漏诊。

### R003：断言失败且 runner 正常初始化

条件：

- 测试框架成功启动；
- 少量测试断言与预期不符；
- 不存在全局 setup 失败。

倾向：

`test_assertion_failure`

### R004：Worktree 有未预期状态

MVP 不把 dirty worktree 本身视为错误。调用方必须显式提供预期约束：

- `expected_branch` 非空时，当前 branch 与目标 branch 不一致；
- `require_clean = true` 时，工作区存在未提交文件。

倾向：

`worktree_state_error`

分支不匹配属于强信号，首版使用 error + high confidence；仅违反显式 clean 要求时使用 warning + medium confidence。未提供相应预期时，不根据 dirty/branch 状态猜测故障。

### R005：顶层 lockfile 指向多个包管理器

条件：

- 仓库顶层存在至少两个 lockfile；
- 这些 lockfile 对应至少两个不同包管理器。

倾向：

`package_manager_ambiguity`

该规则只描述环境配置歧义，不自动声称它是某次 build/test 失败的根因，因此首版使用 warning + medium confidence。

## 5. 错误签名

为了识别“大量错误其实是一个根因”，日志解析器应生成 error signature。

首版可采用保守归一化：

- 去除绝对路径；
- 去除行列号；
- 去除时间戳；
- 保留错误类型和核心消息；
- 对重复签名计数。

避免过度归一化导致不同错误被错误合并。

## 6. Evidence 原则

每个 DiagnosisResult 必须至少包含一个证据。

不允许：

```text
Diagnosis: environment issue
Evidence: none
```

当证据不足时应返回：

`unknown`

而不是猜测。

## 7. Suggested Checks

建议应优先是 **验证动作**，不是直接修复动作。

推荐：

- verify lockfile and installed dependency state
- rerun a targeted test
- compare worktree status
- check setup file loading

谨慎：

- delete node_modules
- reset --hard
- clean repository

危险或破坏性命令不能作为默认自动动作。

## 8. 可解释性

文本报告应回答：

1. AgentTrace 认为是什么问题？
2. 为什么？
3. 哪些证据支持？
4. 哪些信息仍不确定？
5. 下一步如何最小成本验证？
