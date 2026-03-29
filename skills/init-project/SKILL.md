---
name: init-project
description: Use when creating a new project and need to set up development standards - generates CLAUDE.md with coding conventions, logging requirements, deployment templates, and language-specific rules
---

# 新项目初始化

为新项目生成完整的 CLAUDE.md 开发规范文件，包含通用约定、语言规范、日志要求和部署配置。

## 流程

1. **收集项目信息**（使用 AskUserQuestion 逐一询问）：
   - 项目名称
   - 项目类型：后端服务 / 客户端 App / CLI 工具 / 库
   - 技术栈：Python / Go / TypeScript / Swift / Kotlin（可多选）
   - 部署方式：Docker / 裸机 / docker-compose / 暂不配置

2. **读取规范模板**：
   - 读取 `references/rules-common.md`（通用规范，必选）
   - 读取所选语言对应的 `references/rules-{lang}.md`
   - 读取 `references/claude-md-template.md`（CLAUDE.md 骨架）

3. **生成 CLAUDE.md**：
   - 基于骨架模板，将通用规范和语言规范填入对应章节
   - 根据部署方式填入部署章节
   - 使用 Write 工具写入项目根目录的 `CLAUDE.md`

4. **生成部署文件**（如用户选择了部署方式）：
   - 读取 `references/dockerfile-templates.md` 和 `references/deploy-templates.md`
   - 根据技术栈选择对应模板
   - 生成 Dockerfile、docker-compose.yml、deploy.sh 等
   - 在 CLAUDE.md 部署章节中说明如何使用

5. **确认产出物**：向用户展示生成的文件列表，询问是否需要调整

## 关键规则

- 如果项目根目录已有 CLAUDE.md，询问用户是覆盖还是合并
- 生成的 CLAUDE.md 中每个章节有明确分隔，方便后续编辑
- 部署文件中的端口、路径等占位符需根据实际项目调整
