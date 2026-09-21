# Contributing to AgentTrace

感谢关注 AgentTrace。

项目当前处于早期阶段，贡献重点是：**小步、可测试、可解释。**

## 提交 Issue

Bug Issue 建议包含：

- 操作系统；
- AgentTrace 版本/commit；
- 输入类型；
- 预期结果；
- 实际结果；
- 可公开的最小日志片段。

提交日志前请移除：

- token；
- cookie；
- 私有仓库凭据；
- SSH key；
- 其他敏感信息。

## 功能建议

请说明：

1. 真实使用场景；
2. 当前为什么无法完成；
3. 建议输入/输出；
4. 是否会扩大默认权限。

## Pull Request

一个 PR 尽量只解决一个问题。

提交前：

```bash
moon fmt
moon check
moon test
```

如果功能新增了诊断规则，应同时提供：

- positive fixture/test；
- negative fixture/test；
- evidence 说明；
- 文档更新。

## 诊断规则要求

不接受只有字符串硬匹配、没有上下文的高置信诊断。

例如不应仅因为日志出现：

```text
module not found
```

就直接宣称“依赖安装损坏”。

需要结合 runner 阶段、重复范围、编译结果等证据。

## 安全原则

默认贡献不得新增：

- 自动删除文件；
- 自动 reset；
- 自动 clean；
- 未确认的依赖安装；
- 静默上传本地日志；
- 收集凭据。

如果确实需要改变权限边界，必须在 PR 中单独说明。

## Commit Message

推荐：

```text
feat: ...
fix: ...
test: ...
docs: ...
refactor: ...
chore: ...
```

请避免为了增加提交数量而拆分无意义提交。

## 文档语言

README 与核心设计文档可以优先中文；代码标识符、JSON 字段、错误类别保持英文，便于未来国际化和工具集成。
