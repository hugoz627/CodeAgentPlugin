---
name: goal-contract
description: Use when you need to turn a vague task into a precise /goal with acceptance criteria, verification steps, scope boundaries, or host-specific Codex/Claude rendering.
---

# Goal Contract

## Overview

先把任务压缩成 `goal contract`，再生成宿主最佳实践 `/goal`。

这个 skill 的核心目标是减少目标漂移、验收歧义和无效 token 消耗，而不是把原话简单润色得更长。

默认优先利用当前仓库上下文；只有在关键信息仍然缺失时，才进入最多 5 轮、每轮 1 个问题的脑暴。

## When to Use

- 用户说“帮我写一个 `/goal`”或“润色这个 goal”
- 目标里出现“优化一下 / 完善一下 / 搞定 / 处理下”这类模糊表达
- 用户准备开启长任务，但还没定义好验收条件、验证方式或范围边界
- 你判断任务容易跑偏，或后续执行可能浪费较多 token
- 用户已经给出目标，但希望转换成更稳的 Codex / Claude Code `/goal`

不要在这些场景使用：

- 用户只要一句普通需求描述，不打算交给 `/goal`
- 任务是纯闲聊或探索，不需要明确 stopping condition
- 你已经拿到一份高质量、可验证、边界清晰的 `/goal`，只需原样转述

## Workflow

### 1. 读取当前上下文

默认分层读取以下信息，除非当前环境根本没有这些线索：

1. 先读用户刚给出的目标、约束和补充说明
2. 再读当前 worktree、分支名、最近 diff 摘要
3. 优先检索 `docs/superpowers/plans/` 中最相关的计划文件
4. 只有当前目标涉及插件入口、命令或 skill 行为时，才补读相关 `commands/`、`skills/`、README、manifest

上下文的作用是：

- 推断本次任务正在修改什么
- 找到可能已经存在的验收标准或验证命令
- 判断哪些范围边界已经被项目规范隐式定义

如果你做了推断，后续必须显式标成 `推断项`，不能直接伪装成用户已确认事实。

### 2. 做完整性扫描

按以下五个槽位检查目标是否完整：

- `deliverable`：最终交付物是什么
- `done_when`：什么状态算完成
- `proof`：如何证明完成
- `scope_boundary`：哪些内容在范围内，哪些不该碰
- `constraints_or_risks`：有哪些硬约束、风险或不可破坏项

判定规则：

- 缺少 0 到 1 项：走快速模式
- 缺少 2 项及以上：进入脑暴模式

简单任务即使进入快速模式，也要补齐最少必要的验收语句，不要只复述原任务。

### 3. 脑暴模式

每轮只问一个问题，优先级固定为：

1. 先补 `deliverable`
2. 再补 `done_when`
3. 再补 `proof`
4. 再补 `scope_boundary`
5. 最后补 `constraints_or_risks`

提问要求：

- 优先给出基于当前仓库的候选推断，让用户确认或修正
- 问题尽量短，不要一次堆多问
- 每轮只补一个最关键缺口
- 最多追问 5 轮

如果 5 轮后仍不完整：

- 显式列出 `推断项`、`假设`、`待确认项`
- 用保守表述生成 contract 和 `/goal`
- 不把未确认信息写成确定事实

### 4. 生成 goal contract

先输出结构化合同，再输出 `/goal`。

不要把内部扫描槽位原样全部打印给用户。内部可以完整，外部必须按任务复杂度压缩。

内部扫描槽位包括：

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

这些槽位用于判断目标是否完整，不代表最终输出必须逐项展开。

最终展示字段按复杂度选择：

- 最小版：`目标`、`完成条件`、`验证方式`、`边界/限制`
- 标准版：`目标/交付物`、`完成条件`、`验证方式`、`范围与限制`、`假设/待确认`
- 复杂版：在标准版基础上增加 `阶段检查点` 和 `停止/澄清条件`

合并规则：

- `objective` 和 `deliverable` 可合并成 `目标/交付物`
- `scope_in`、`scope_out`、`constraints` 可合并成 `范围与限制`
- `risks`、`stop_conditions` 可合并成 `风险与停止条件`
- `assumptions`、`open_questions` 可合并成 `假设/待确认`
- 空字段、重复字段、对当前任务没有增益的字段不要输出

当存在上下文推断或未确认信息时，显式区分：

- `已知事实`
- `推断项`
- `假设`
- `待确认项`

## Host Detection

优先判断当前宿主：

1. 如果 system prompt、工具上下文或会话元信息明确标识 Codex 或 Claude Code，直接使用该宿主
2. 如果宿主仍不明确，但环境变量里存在明确 `CODEX_*` 线索，可判断为 Codex
3. 如果仍不明确，且当前允许执行命令，可检查直接父进程名称或参数是否包含 `codex` 或 `claude`
4. 如果仍不够确定，就视为未识别

输出规则：

- 已识别 Codex：输出 Codex 版 `/goal`
- 已识别 Claude Code：输出 Claude 版 `/goal`
- 未识别：同时输出两版 `/goal`
- 只输出单版本时，用一句短语说明识别依据，例如 `host: codex, basis: system prompt`

## Rendering Rules

### Codex

Codex 版应强调：

- 单一 durable objective
- 明确的 stopping condition
- 要读哪些计划、文件或 diff
- checkpoint 如何推进
- 每个 checkpoint 用什么验证命令或产物证明
- 在什么情况下应该暂停并澄清

渲染前先读取 `templates/codex-goal-template.md`。

### Claude Code

Claude 版应强调：

- evaluator 只能依据对话里已经 surfaced 的证据判断 goal 是否成立
- 需要在会话中展示哪些测试结果、命令输出、diff 摘要或截图说明
- 验收语句必须让 evaluator 能从 transcript 直接判断
- 如果存在未确认项，要在 goal 中明确说明何时回报确认

渲染前先读取 `templates/claude-goal-template.md`。

## Output Format

### 简单任务

按以下顺序输出：

1. 精简 `goal contract`
2. `最终 /goal`

精简 contract 通常只保留：

- `目标`
- `完成条件`
- `验证方式`
- `边界/限制`

### 复杂任务

按以下顺序输出：

1. `上下文摘要`
2. `goal contract`
3. `推断项 / 假设 / 待确认项`（仅在非空时输出）
4. `最终 /goal`

如果宿主未识别，则在最后同时给出：

- `Codex /goal`
- `Claude Code /goal`

## Quality Bar

最终结果必须满足：

- 只覆盖一个主要目标，不混 unrelated backlog
- `done_when` 可验证，不是主观判断
- `proof` 可执行或可观察
- 范围或限制至少有一项明确，能阻止无关扩张
- 如果引用仓库上下文，引用点要真实存在
- 如果无法验证，就不能写成完成标准
- 输出字段要按信息密度裁剪，不能把内部 schema 机械暴露给用户
- 只输出单一宿主版本时必须说明宿主识别依据；依据不稳时输出双版本

## Common Mistakes

- 把“优化一下”直接改写成长句，却仍然没有验收条件
- 只写目标，不写 proof
- 把计划步骤当成目标本身，导致 `/goal` 失焦
- 把推断项写成事实，后续执行会跑偏
- 宿主不明确时只给单边模板
- 简单任务强行输出十几个字段，增加阅读成本

## References

- 最佳实践摘要：读取 `references/goal-best-practices.md`
- 验证样例：读取 `references/validation-cases.md`
- Codex 模板：读取 `templates/codex-goal-template.md`
- Claude 模板：读取 `templates/claude-goal-template.md`
