# AgentTrace Visual Report

这个目录是 AgentTrace JSON 的静态可视化 Reporter，不包含第二套诊断规则。

页面默认使用中文展示，底层 JSON 的机器字段（例如 `category`、`rule_ids`、
`schema_version`）保持稳定英文标识，以保证 CLI、CI 和外部工具的兼容性。

当前页面包含三个由真实 Native CLI 生成的可复现案例：

1. R001：依赖 / 测试环境故障；
2. R004：显式分支预期不一致；
3. R002：带源码定位的 TypeScript 编译错误。

CI 会生成对应 JSON、校验诊断契约、通过 HTTP smoke test，并将同一份静态站点部署到 GitHub Pages。
