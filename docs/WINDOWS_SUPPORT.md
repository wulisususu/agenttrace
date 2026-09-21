# Windows 支持要求

Windows 是 AgentTrace MVP 的一等支持平台。

## 1. 基线

首版目标至少覆盖：

- Windows 10 x86-64；
- Windows 11 x86-64。

## 2. 路径

必须测试：

```text
C:\repo\project
C:\Users\User Name\project
D:\开发\agent-project
```

要求：

- 不假设路径分隔符只有 `/`；
- 不通过简单字符串切割实现路径逻辑；
- 输出时避免破坏盘符；
- fixtures 覆盖空格和中文路径。

## 3. Git Worktree

Git 输出的路径需要标准化，但不能在内部模型中错误丢失 Windows 根路径。

测试场景：

- 主 worktree；
- 同盘其他 worktree；
- 不同盘 worktree；
- 路径含空格。

## 4. 进程调用

如需调用外部命令：

- 避免依赖 Bash；
- 不默认使用 `grep`、`sed`、`awk`；
- 参数与命令分离；
- 不把用户输入直接拼接为 shell 字符串。

## 5. 换行

日志 parser 必须处理：

- CRLF；
- LF；
- 混合换行。

## 6. 编码

首版默认优先 UTF-8。

遇到无法解析的输入时：

- 返回明确错误；
- 不静默产生错误诊断；
- 后续再评估 Windows 本地代码页兼容策略。

## 7. 可执行文件

Native build 的发布流程后续至少验证 Windows 可执行文件能：

- 启动；
- 输出 help；
- 扫描本地 fixture；
- 生成 JSON。

## 8. CI

如果项目启用 GitHub Actions，后续应加入 Windows runner，避免“Linux 测试通过”被错误当作 Windows 可用。
