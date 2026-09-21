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

用途：只读采集 Git/Worktree 与工程环境事实，可选关联已有 Vitest 日志。

```bash
agenttrace inspect .
agenttrace inspect C:\src\project
agenttrace inspect . --format json
agenttrace inspect . --log ./test-output.txt --format json
```

当前选项：

- `--format text|json`
- `--log <path>`

后续可评估：

- `--no-git`
- `--no-env`
- `--verbose`

当前输出：

- RepositorySnapshot；
- EnvironmentSnapshot；
- TestObservation（提供 `--log` 时）；
- 能由现有证据触发的 diagnoses；
- text 或 `schema_version: 0.1` JSON。

重要边界：`inspect` 不自动运行 build/test，也不会为了触发规则而虚构“compile pass”等不存在的事实。

## 3. analyze-log

状态：**已实现**。

只解析已有日志文件，不扫描仓库。

```bash
agenttrace analyze-log ./fixtures/logs/vitest-assertion-failure.txt
agenttrace analyze-log ./fixtures/logs/vitest-assertion-failure.txt --format json
```

当前首版识别 Vitest 观察，并只运行不需要仓库或编译上下文即可成立的规则。比如，只有 missing matcher 日志但没有明确 compile-pass 证据时，会返回 `unknown`，而不是猜测 R001。

适合：

- CI 日志离线分析；
- parser / rule 验证；
- 用户不希望扫描仓库时。

## 4. doctor

状态：**尚未实现**。

目标是执行一组安全检查。

原则：

- 默认只读；
- 不自动运行 `npm install`、`git reset`、删除目录等操作；
- 如果未来增加修复动作，必须要求显式参数和清楚的安全边界。

## 5. 输出格式

### 5.1 text

面向人类终端阅读。单诊断报告包含 category、severity、confidence、evidence 和 suggested checks；`inspect` 聚合报告还包含 repository/environment/tests 摘要。

### 5.2 json

面向 Codex、Claude Code、CI 和其他工具。当前 schema version：

```json
{
  "schema_version": "0.1"
}
```

`analyze-log` 输出诊断报告；`inspect` 输出聚合 DiagnosticReport，包含 repository、environment、可选 tests 和 diagnoses。

新增字段优先向后兼容；改变字段语义时提高 schema version。

## 6. Exit Code

状态：**已实现**。

- `0`：执行成功，未产生诊断问题；
- `1`：执行成功，产生至少一个诊断；
- `2`：参数错误；
- `3`：输入不可读或仓库不可访问；
- `4`：内部命令分发错误。

诊断到“工程有问题”与“AgentTrace 自己执行失败”明确区分。

## 7. Windows 注意事项

当前自动化测试与 Windows CI 已覆盖：

- 盘符/反斜杠参数解析；
- 含空格路径字符串；
- 非 ASCII/中文路径的 Git parser fixture；
- Native build；
- CLI version/analyze-log/inspect smoke tests。

Git 调用使用可执行文件 + 参数数组，不依赖 Bash、PowerShell 或 `cmd /c` 拼接用户路径。

## 8. 稳定性约束

首版 CLI 保证方向：

- 相同输入得到稳定输出；
- JSON 可以被程序解析；
- 默认只读，不修改用户仓库；
- stdout 用于结果，stderr 用于参数/输入/内部错误；
- `--help` 说明命令用途；
- 证据不足时返回 `unknown` 或空 diagnoses，而不是补造上下文。
