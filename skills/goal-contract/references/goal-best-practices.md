# Goal Best Practices

## 共享原则

无论宿主是 Codex 还是 Claude Code，稳定的 `/goal` 都应满足以下原则：

1. 只聚焦一个主要目标，不把 unrelated backlog 混进来
2. 明确交付物，不用“优化一下”“完善一下”之类模糊词当终态
3. 明确完成判定，写成可观察、可验证的状态
4. 明确 proof：测试、lint、构建、截图、日志、文件状态、命令输出等
5. 明确 scope in / scope out，减少 agent 无边界扩张
6. 明确 constraints：不能破坏什么、哪些规则必须继续满足
7. 长任务要分 checkpoint，不要只给一句大而空的口号
8. 如果 goal 依赖假设，必须显式写出假设和回报点

## Codex 侧偏好

Codex 的 `/goal` 更适合写成执行协议：

- 先写一个 durable objective
- 再写 verifiable stopping condition
- 明确先读哪些计划或文件
- 明确验证循环和 checkpoint
- 明确何时暂停并澄清

适合出现的表述：

- “先读取当前计划与相关 diff，再开始实现”
- “在每个 checkpoint 后运行对应验证命令”
- “当目标达成或出现以下阻塞时停止”

## Claude Code 侧偏好

Claude Code 的 `/goal` 更适合写成证据协议：

- 目标完成必须能由 transcript 中的证据证明
- 要写清需要展示哪些命令输出、摘要或截图说明
- 验收语句要让 evaluator 不依赖隐式仓库读取就能判断

适合出现的表述：

- “在会话中展示测试命令和结果摘要”
- “给出关键文件改动与验收依据的简明说明”
- “若存在未确认假设，在执行到对应 checkpoint 前先回报确认”

## 内部槽位与展示字段

内部可以扫描完整槽位，但最终不要机械输出全部字段。

内部槽位：

- `objective`: 一句话目标，说明要达成什么结果
- `deliverable`: 可指认的交付物，例如文件、功能、文档、验证报告
- `done_when`: 完成判定，必须是可观察状态
- `proof`: 证明方式，例如测试、构建、lint、截图、日志、diff 摘要
- `scope_in`: 本次明确包含的范围
- `scope_out`: 本次明确不做的范围
- `constraints`: 不可破坏项或必须遵守的规则
- `risks`: 可能导致跑偏、返工或误判的风险
- `assumptions`: 暂按某前提执行但尚未完全确认的信息
- `open_questions`: 必须继续澄清的问题
- `checkpoints`: 长任务的阶段性回报点
- `stop_conditions`: 需要停止并澄清的条件

最小展示字段：

- `目标`: 要完成什么
- `完成条件`: 什么状态算完成
- `验证方式`: 如何证明完成
- `边界/限制`: 什么不做，或不能破坏什么

按需增加字段：

- `目标/交付物`: 当产物和目标需要分开说明时使用
- `假设/待确认`: 当依赖推断或用户尚未确认时使用
- `阶段检查点`: 长任务或多阶段任务才使用
- `风险与停止条件`: 高风险或外部依赖任务才使用

合并规则：

- `objective` 和 `deliverable` 可合并
- `scope_in`、`scope_out`、`constraints` 可合并
- `risks`、`stop_conditions` 可合并
- `assumptions`、`open_questions` 可合并
- 空字段、重复字段、无法提升判断质量的字段应省略

## 复杂度判定

对以下五个槽位做扫描：

- 明确产物
- 验收标准
- 验证方式
- 范围边界
- 约束或风险

缺少任意两项及以上，就值得先脑暴而不是直接写 `/goal`。

## 提问优先级

每轮只问一个问题，按以下顺序补信息：

1. 交付物
2. 验收标准
3. 证明方式
4. 范围边界
5. 约束或风险

如果仓库上下文能给出候选答案，优先提出候选让用户确认，而不是让用户从零描述。

## 官方文档

- Codex Follow Goals: https://developers.openai.com/codex/use-cases/follow-goals
- Codex Slash Commands: https://developers.openai.com/codex/cli/slash-commands
- Claude Code Goal: https://code.claude.com/docs/en/goal
- Claude Code Best Practices: https://code.claude.com/docs/en/best-practices
