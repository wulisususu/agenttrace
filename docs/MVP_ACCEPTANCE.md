# MVP 验收清单

本文用于开发过程自检，不等同于赛事官方评分标准。

## A. 项目基础

- [x] 公开仓库
- [x] README
- [x] 开源许可证
- [x] 项目范围
- [x] 架构文档
- [x] 开发规范
- [x] MoonBit 模块初始化
- [x] 基础 CI

## B. MoonBit

- [x] 主要实现代码使用 MoonBit
- [x] 使用当前 `moon.mod` / `moon.pkg` 配置
- [x] `moon check` 通过
- [x] `moon test` 通过
- [x] Native build 通过

## C. 核心模型

- [x] RepositorySnapshot
- [x] EnvironmentSnapshot
- [x] TestObservation
- [x] Evidence
- [x] Diagnosis
- [x] DiagnosticReport

## D. Parser

- [x] 读取日志文件
- [x] 识别至少一种测试日志
- [x] 提取失败统计
- [x] 构造 error signature
- [x] 重复错误聚类

## E. Diagnosis

- [x] 至少 4 类诊断
- [x] 每类至少一个测试
- [x] unknown fallback
- [x] 每条 diagnosis 关联 evidence
- [x] 不输出伪精确概率

## F. Repository / Environment

- [x] Git branch
- [x] dirty state
- [x] Worktree 信息
- [x] lockfile 信号
- [x] Windows 路径测试

## G. Reporter

- [x] text
- [x] JSON
- [x] schema_version
- [ ] 脱敏策略
- [x] exit code 语义

## H. Demo

- [ ] 一个正常 fixture
- [ ] 一个编译故障 fixture
- [x] 一个断言故障 fixture
- [ ] 一个环境故障 fixture
- [ ] 一个“环境问题伪装成代码问题”完整案例

## I. 文档

- [x] README 中当前标记为已实现的 CLI 命令可运行
- [ ] README 中的示例输出来自实际程序
- [x] 不把规划功能写成已实现
- [ ] 安装步骤经过空环境复测
- [ ] 测试与 Demo 可复现

## J. 提交质量

- [x] 持续保留真实开发提交
- [x] commit message 描述实际变化
- [x] 不通过空提交或无意义拆分制造提交数
- [x] 关键设计变化同步更新 DECISIONS / 设计文档

完成 MVP 的标准不是“所有格子都越多越好”，而是核心诊断闭环确实可以运行、测试和复现。
