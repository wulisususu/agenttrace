# AgentTrace CLI 规范

> 本文描述 MVP CLI 接口。已实现项与后续规划分开标记。

## 1. 命令总览

当前已实现：

```text
agenttrace inspect <path>
agenttrace analyze-log <file>
agenttrace version
agenttrace --help
```

后续规划：

```text
agenttrace doctor <path>
```

## 2. inspect

状态：**已实现**。

用途：只读采集 Git/Worktree 与工程环境事实，并可关联用户显式提供的测试/编译结果。

```bash
agenttrace inspect .
agenttrace inspect . --format json
agenttrace inspect . --log ./test-output.txt --format json
agenttrace inspect . --log ./test-output.txt --build-exit-code 0 --format json
agenttrace inspect . --build-log ./tsc-output.txt --build-exit-code 2 --format json
agenttrace inspect . --expected-branch main --require-clean --format json
```

当前选项：

- `--format text|json`
- `--log <path>`：已有 Vitest 日志
- `--build-exit-code <n>`：显式提供非负编译退出码
- `--build-log <path>`：可选 TypeScript/tsc 日志；使用时必须同时给出 `--build-exit-code`
- `--expected-branch <name>`：显式声明当前仓库应该位于哪个分支；不提供时不对分支做猜测
- `--require-clean`：显式要求工作区必须干净；不提供时普通 dirty 开发状态不会被视为故障

设计约束：

- AgentTrace 不自动运行 build/test；
- `--build-exit-code 0` 是用户显式提供的 compile-pass 事实，可与测试证据组合触发 R001；
- 非零 build exit code 只有在 build log 含源码定位错误时才触发 R002；
- 只有 build log、没有 exit code 时返回参数错误，不从日志猜测编译状态；
- R004 只在用户显式提供 `--expected-branch` 或 `--require-clean` 时运行约束判断；默认 inspect 不把普通开发分支/dirty 状态自动判错。

后续可评估：

- `--no-git`
- `--no-env`
- `--verbose`

当前聚合输出：

- RepositorySnapshot；
- EnvironmentSnapshot；
- BuildObservation（提供 build context 时）；
- TestObservation（提供 `--log` 时）；
- 由现有证据成立的 diagnoses；
- text 或 `schema_version: 0.1` JSON。

## 3. analyze-log

状态：**已实现**。

只解析已有测试日志，不扫描仓库，也没有编译上下文。

```bash
agenttrace analyze-log ./fixtures/logs/vitest-assertion-failure.txt
agenttrace analyze-log ./fixtures/logs/vitest-assertion-failure.txt --format json
```

当前首版识别 Vitest 观察，并只运行不需要仓库或编译上下文即可成立的规则。只有 missing matcher 日志但没有明确 compile-pass 证据时，会返回 `unknown`，而不是猜测 R001。

## 4. doctor

状态：**尚未实现**。

目标是执行一组安全检查。默认仍只读，不自动运行 `npm install`、`git reset`、删除目录等操作。

## 5. 输出格式

### 5.1 text

面向人类终端阅读。`inspect` 聚合报告包含 repository/environment、可选 build/tests，以及 diagnoses 摘要。

### 5.2 json

面向 Codex、Claude Code、CI 和其他工具。当前 schema version：

```json
{
  "schema_version": "0.1"
}
```

`inspect` 的 DiagnosticReport 包含：

```text
repository
environment
build?
tests?
diagnoses[]
summary
```

新增字段优先向后兼容；改变字段语义时提高 schema version。

## 6. Exit Code

状态：**已实现**。

- `0`：执行成功，未产生诊断问题；
- `1`：执行成功，产生至少一个诊断；
- `2`：参数错误；
- `3`：输入/日志不可读或仓库不可访问；
- `4`：内部命令分发错误。

## 7. Windows 注意事项

当前 Windows CI 覆盖：

- 盘符/反斜杠参数解析；
- 含空格路径字符串；
- 非 ASCII/中文路径 Git parser fixture；
- Native build；
- CLI version/analyze-log/inspect smoke；
- R001 build-pass + repeated matcher 端到端场景；
- R002 tsc 源码编译错误场景；
- R004 显式 expected-branch mismatch 端到端场景。

Git 调用使用可执行文件 + 参数数组，不依赖 Bash、PowerShell 或 `cmd /c` 拼接用户路径。

## 8. 稳定性约束

- 相同输入得到稳定输出；
- JSON 可以被程序解析；
- 默认只读，不修改用户仓库；
- stdout 用于结果，stderr 用于参数/输入/内部错误；
- 证据不足时返回 `unknown` 或空 diagnoses，而不是补造上下文。
