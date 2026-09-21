# AgentTrace CLI 规范

> 本文描述目标接口。命令在实现前均视为草案。

## 1. 命令总览

```text
agenttrace inspect <path>
agenttrace analyze-log <file>
agenttrace doctor <path>
agenttrace version
```

## 2. inspect

用途：读取仓库和工程环境状态，但不执行破坏性操作。

```bash
agenttrace inspect .
agenttrace inspect C:\src\project
agenttrace inspect . --format json
```

计划选项：

- `--format text|json`
- `--log <path>`
- `--no-git`
- `--no-env`
- `--verbose`

输出：

- repository summary；
- environment observations；
- test observations（如提供日志）；
- diagnosis；
- evidence；
- suggested checks。

## 3. analyze-log

只解析已有日志文件，不读取仓库。

```bash
agenttrace analyze-log ./fixtures/logs/vitest-missing-matcher.txt
```

适合：

- 单元测试解析器；
- CI 日志离线分析；
- 用户不希望扫描仓库时。

## 4. doctor

目标是执行一组安全检查。

原则：

- 默认只读；
- 不自动运行 `npm install`、`git reset`、删除目录等操作；
- 如果未来增加修复动作，必须要求显式参数和二次确认。

## 5. 输出格式

### 5.1 text

面向人类：

```text
Diagnosis: dependency_environment_error
Confidence: high

Evidence:
- build succeeds
- 27 test files fail with the same missing matcher

Suggested checks:
1. verify test dependency installation
2. reinstall dependencies
3. rerun tests
```

### 5.2 json

面向工具集成：

```json
{
  "schema_version": "0.1",
  "diagnosis": {
    "category": "dependency_environment_error",
    "confidence": "high"
  },
  "evidence": [],
  "suggested_checks": []
}
```

字段实现后应尽量保持向后兼容。

## 6. Exit Code 草案

- `0`：执行成功，未发现阻断性异常；
- `1`：执行成功，发现诊断问题；
- `2`：参数错误；
- `3`：输入不可读或仓库不可访问；
- `4`：内部错误。

诊断到“工程有问题”与“AgentTrace 自己执行失败”必须区分。

## 7. Windows 注意事项

路径解析必须覆盖：

- 盘符路径；
- 反斜杠；
- 含空格路径；
- 非 ASCII 路径。

任何 shell 命令执行都不能依赖只存在于 Unix 的语法。

## 8. 稳定性约束

首版 CLI 优先保证：

- 相同输入得到稳定输出；
- JSON 可以被程序解析；
- 不修改用户仓库；
- 错误信息指出失败阶段；
- `--help` 能说明命令用途。
