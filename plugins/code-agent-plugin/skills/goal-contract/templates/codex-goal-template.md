# Codex Goal Template

按以下骨架渲染 Codex 版 `/goal`。根据具体任务替换占位内容，不要机械保留所有标题；空字段、重复字段、简单任务不需要的字段应省略。

## Template

- Objective: {objective}
- Deliverable: {deliverable}
- Done when:
  - {done_when_1}
  - {done_when_2}
- First read:
  - {plan_or_doc_1}
  - {diff_or_file_2}
- Scope in:
  - {scope_in}
- Scope out:
  - {scope_out}
- Constraints:
  - {constraint_1}
- Checkpoints:
  - {checkpoint_1}
  - {checkpoint_2}
- Verification:
  - {proof_1}
  - {proof_2}
- Stop and clarify if:
  - {stop_condition_1}
  - {stop_condition_2}

## Rendering Notes

- 第一行就锁定 durable objective
- `Done when` 必须是 stopping condition，不是待办清单
- `First read` 只列真正相关的计划、文件或 diff
- `Verification` 优先写命令、测试、构建、截图、日志等可执行证据
- `Stop and clarify if` 用来阻止 agent 带着错误假设冲太远
- 简单任务可以压缩成一段话，保留目标、完成条件、验证方式、边界即可

## Example Shape

“基于当前计划与相关 diff，为 `skills/goal-contract/` 新增一个共享 skill，使其能够先收敛任务目标与验收条件，再渲染宿主最佳实践 `/goal`。当 skill 文档、模板和验证样例齐备，且相关 README/设计文档已更新并通过最小静态检查时停止。”
