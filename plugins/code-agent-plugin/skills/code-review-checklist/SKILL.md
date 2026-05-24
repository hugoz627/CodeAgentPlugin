---
name: code-review-checklist
description: Use when reviewing code changes or pull requests - generates a project-specific review checklist based on tech stack and project rules, then systematically checks each item against the actual code diff
---

# 代码审查清单

基于项目规范和技术栈，生成定制化的代码审查清单，并逐项检查代码 diff。

## 流程

1. **了解审查范围**：
   - 使用 AskUserQuestion 确认：是 PR review 还是对某个文件/功能的 review？
   - 如果是 PR，请用户提供 git diff 或文件范围
   - 如果是文件，使用 Glob/Read 读取相关文件

2. **读取项目规范**：
   - 使用 Glob 检查是否有 CLAUDE.md
   - 如果有，使用 Read 读取，提取语言规范和日志规范
   - 读取本插件 `skills/code-review-checklist/references/review-checklist-template.md`（路径相对于插件安装目录）
   - 根据项目技术栈选择对应的语言特定检查项

3. **检查代码**：

   逐项过检查清单，针对每一项：
   - 在代码中搜索相关模式（使用 Grep）
   - 给出具体的文件名和行号
   - 标记：✅ 通过 / ⚠️ 需关注 / ❌ 问题

   重点检查：
   - **日志覆盖**：核心流程是否有日志？异常是否有日志？Grep `logger.` 或 `log.` 查看覆盖情况
   - **错误处理**：搜索 `except:` / `catch {}` / `_ = err` 查找吞异常
   - **安全**：搜索直接字符串拼接 SQL、未校验的用户输入
   - **类型安全**：Python 搜索 `dict[` 或 `getattr`，TS 搜索 `: any`

4. **输出审查报告**：

   ```markdown
   ## Code Review 报告

   **审查范围**：{文件/功能描述}
   **技术栈**：{语言}

   ### ❌ 必须修改（阻断合并）
   - [文件名:行号] {问题描述}

   ### ⚠️ 建议修改（不阻断，但需跟踪）
   - [文件名:行号] {问题描述}

   ### ✅ 通过项
   - 日志覆盖：核心流程均有 INFO 日志
   - 错误处理：异常均有 ERROR 日志
   ...

   ### 总结
   {整体评价，是否可以合并}
   ```

## 关键规则

- 每个问题必须有文件名和行号，不写模糊的"某处有问题"
- 区分阻断问题（安全漏洞、吞异常、缺少关键日志）和建议问题（命名不规范、可以优化的写法）
- 先读代码再评价，不靠猜测
