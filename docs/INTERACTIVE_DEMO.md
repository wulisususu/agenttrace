# AgentTrace Incident Lab

## 目标

Incident Lab 是 Visual Report 之后的可玩交互演示层。它不替代 Native CLI，也不重新定义故障真相。

第一关使用已经存在并由 CI 校验的 R001 fixture：

- Build = PASS；
- 27 个测试文件失败；
- 155 个测试失败；
- 重复错误为 missing matcher；
- AgentTrace 诊断为 `dependency_environment_error / R001 / high`。

## 第一关玩法

用户扮演 Tech Lead，同时面对三个模拟 Agent：

- Agent A / Builder：功能开发；
- Agent B / Validator：测试验收；
- Agent C / Fixer：等待用户指令。

故障出现后，用户可以：

1. 在文本框自由输入一条想发给 Fixer 的指令；
2. 获取渐进式提示；
3. 随时调用 AgentTrace；
4. 如果自己判断到环境方向，也可以直接修复；
5. AgentTrace 诊断后，会根据真实 R001 JSON 生成一条可编辑的下一步 Agent 指令；
6. 将指令发送给 Fixer 后，模拟恢复环境并重新验收；
7. 结算页回放用户的排查路径、无效操作数和是否使用 AgentTrace。

## 输入理解

M22 不接外部大模型。

浏览器使用一个明确可读的本地意图分类器，将自由文本归类为：

- 调用 AgentTrace；
- 检查环境 / 依赖；
- 回滚源码；
- 修改测试；
- 修改源码；
- 重跑测试；
- 检查仓库现场；
- 模糊指令。

关卡真相不由分类器决定。分类器只决定“玩家想执行什么动作”，结果由固定状态机产生。

这样做是为了先验证交互闭环，同时避免把 LLM 的主观判断伪装成游戏正确答案。

## 后续模型接入

如果后续加入模型，模型只负责把自然语言映射成结构化 Intent，例如：

```json
{
  "intent": "inspect_environment",
  "confidence": "high"
}
```

最终状态变化、故障真相、AgentTrace 诊断和成功条件仍由确定性状态机 / 真实诊断 JSON 决定。

## 数据边界

AgentTrace 救场环节读取：

```text
web/data/dependency-environment.json
```

该文件不是手写答案，而是 Visual Report workflow 通过真实 Native CLI 从 fixture 生成。
