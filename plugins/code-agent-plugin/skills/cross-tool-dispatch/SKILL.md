---
name: cross-tool-dispatch
description: Use when you want the deterministic multi-tool dispatch workflow previously invoked as `/cross-tool-dispatch`, especially in Codex where plugin commands may not surface in the UI.
---

# cross-tool-dispatch

## Overview

这是 `commands/cross-tool-dispatch.md` 的 Codex skill alias。

它的职责不是重新定义第二套工作流，而是在 Codex 里把原本期望的 slash command 入口，稳定地映射到同一份 command 真源。

## When to Use

- 你原本想执行 `/cross-tool-dispatch`
- 你在 Codex 中已经安装了 Code Agent Plugin，但看不到插件 commands
- 你想执行这条确定性 workflow：基于当前任务和当前计划拆分低耦合子任务，并分派给不同开发工具并行执行或审查

## Workflow

1. 先读取 `../../commands/cross-tool-dispatch.md`。
2. 把该 command 文档视为单一事实源，完整遵循其中的上下文发现、执行要求、验证方式和输出格式。
3. 如果用户额外提供了范围、路径、分支、SHA、计划文件或其他约束，只把它们当作补充上下文，不要破坏这条 workflow 的默认零参数体验。
4. 如果 `commands/cross-tool-dispatch.md` 与当前会话更高优先级的 system、developer 或 repo 规则冲突，优先服从高优先级规则，同时尽量保持该 workflow 的原始意图。

## Output

- 对用户直接执行等价 workflow，不要把“commands 在 Codex 里是否可见”当成阻塞理由。
- 如果需要解释入口，可以称这是 `/cross-tool-dispatch` 的 skill alias。
