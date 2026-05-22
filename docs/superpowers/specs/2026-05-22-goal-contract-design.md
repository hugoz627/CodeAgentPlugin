# goal-contract 设计稿

## 目标

新增一个共享 skill：`goal-contract`。

它的职责不是单纯润色 `/goal`，而是先把模糊任务收敛成可执行、可验证、可停止的 `goal contract`，再根据当前宿主渲染成 Codex 或 Claude Code 的最佳实践 `/goal`。

## 适用场景

- 用户准备启动长任务，但目标、边界或验收条件还不够清晰
- 用户已经有目标描述，但希望快速润色成更稳的 `/goal`
- 用户担心 agent 跑偏、验收不清或 token 浪费
- 用户希望当前仓库上下文被充分利用，而不是每次手工补计划路径和任务背景

## 核心设计

### 共享合同优先

内部统一使用一份 `goal contract`。这些字段是内部扫描槽位，不代表最终输出必须全部展示：

- `objective`
- `deliverable`
- `done_when`
- `proof`
- `scope_in`
- `scope_out`
- `constraints`
- `risks`
- `assumptions`
- `open_questions`
- `checkpoints`
- `stop_conditions`

宿主差异只体现在渲染层，不拆成两套语义。最终展示时按信息密度裁剪：简单任务只展示 `目标 / 完成条件 / 验证方式 / 边界限制`，复杂任务再增加 `假设 / 待确认 / 阶段检查点 / 停止条件`。

### 默认全上下文

skill 默认主动读取：

1. 当前 worktree 和分支线索
2. 当前 diff
3. `docs/superpowers/plans/` 下最相关的计划文件
4. 与当前任务最相关的 `commands/`、`skills/`、manifest 或说明文档

如果上下文已经足够，直接走快速模式；否则进入脑暴。

### 完整性扫描

按五个槽位判断是否需要脑暴：

- 明确产物
- 验收标准
- 验证方式
- 范围边界
- 约束或风险

缺少任意两项及以上时进入脑暴；否则快速生成。

### 脑暴策略

- 每轮只问一个问题
- 优先补 `deliverable`，再补 `done_when`，再补 `proof`
- 允许基于仓库上下文提出候选推断，但必须显式标成推断
- 最多追问 5 轮
- 5 轮后仍有缺口时，带着假设生成，不把推断伪装成事实

## 宿主渲染差异

### Codex

Codex 版 `/goal` 更强调：

- durable objective
- verifiable stopping condition
- validation loop
- checkpoints
- 先读哪些计划或文件

### Claude Code

Claude 版 `/goal` 更强调：

- goal evaluator 只能根据对话里已经 surfaced 的证据判断
- 要明确要求展示哪些测试、命令输出、diff 摘要或截图说明
- 验收语句要能直接从 transcript 中判断是否成立

## 输出层级

统一输出两层：

1. `goal contract` 可审阅版
2. 可直接粘贴的 `/goal`

复杂任务额外输出：

- 上下文摘要
- 推断项
- 假设
- 待确认项

## 风险控制

- 不把 unrelated backlog 混入一个 `/goal`
- 不输出无法验证的“完成标准”
- 不在宿主识别不确定时强行单边渲染
- 不跳过当前仓库的计划和 diff
- 不做无上限提问

## 验证样例

至少覆盖以下 4 类场景：

1. 目标明确，应该快速直出
2. 目标模糊，但仓库上下文很强，应该先推断再确认
3. 目标模糊且上下文弱，应该进入脑暴并在 5 轮内补关键缺口
4. 宿主不明确，应该输出共享合同加双版本 `/goal`
