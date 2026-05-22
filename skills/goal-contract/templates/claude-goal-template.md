# Claude Code Goal Template

按以下骨架渲染 Claude Code 版 `/goal`。重点是让 evaluator 能仅凭 transcript 判断是否达成目标；空字段、重复字段、简单任务不需要的字段应省略。

## Template

- Goal: {objective}
- Deliverable: {deliverable}
- Success criteria:
  - {done_when_1}
  - {done_when_2}
- Evidence to show in the conversation:
  - {proof_in_transcript_1}
  - {proof_in_transcript_2}
- Scope in:
  - {scope_in}
- Scope out:
  - {scope_out}
- Constraints:
  - {constraint_1}
- Checkpoints to report:
  - {checkpoint_1}
  - {checkpoint_2}
- If assumptions are required:
  - {assumption_or_confirmation_rule}
- Stop and ask before:
  - {stop_condition_1}
  - {stop_condition_2}

## Rendering Notes

- `Success criteria` 必须能从会话中直接判断
- `Evidence to show in the conversation` 要写成需要展示的命令结果、摘要、截图说明或关键 diff
- 如果存在未确认项，写明在哪个 checkpoint 前必须回报确认
- 不要依赖 evaluator 去隐式读取仓库状态
- 简单任务可以压缩成一段话，保留目标、完成条件、会话证据、边界即可

## Example Shape

“整理并生成一个共享的 `goal-contract` skill，用于先收敛目标、验收条件和验证方式，再输出宿主最佳实践 `/goal`。在会话中展示新增文件列表、关键结构说明，以及针对验证样例的静态检查结果；只有当这些证据已经在对话中给出时，才算完成。”
