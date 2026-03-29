---
name: setup-rules
description: Use when joining an existing project that lacks development standards or CLAUDE.md - scans the project, detects tech stack, identifies missing rules, and adds them without overwriting existing content
---

# 已有项目补全规范

为已有项目检测并补全缺失的开发规范。不覆盖已有内容，只追加缺失部分。

## 流程

1. **扫描项目现状**：
   - 使用 Glob 检测是否存在 CLAUDE.md、AGENTS.md、.cursorrules、.editorconfig
   - 使用 Glob 检测项目文件（*.py, *.go, *.ts, *.swift, *.kt, Dockerfile, go.mod, package.json, pyproject.toml, Podfile, build.gradle）
   - 如果存在规则文件，使用 Read 读取内容

2. **识别技术栈**：
   - 根据检测到的文件类型确定使用的语言和框架
   - 向用户确认识别结果

3. **对比缺失项**：
   - 读取本插件 `skills/init-project/references/rules-common.md` 和对应语言的 `skills/init-project/references/rules-{lang}.md`（使用 Read 工具，路径相对于插件安装目录）
   - 逐项检查已有规则文件中是否包含以下内容：
     - 中文注释 / 中文 commit / 英文 log 约定
     - 日志规范（文件落地、主流程日志、异常日志、请求 I/O 日志）
     - 语言特定规范
     - 部署说明
   - 列出所有缺失项

4. **用户确认**：
   - 使用 AskUserQuestion 展示缺失项列表（multiSelect），让用户选择要补全哪些
   - 如果全部缺失，建议直接运行 init-project skill

5. **追加规范**：
   - 如果 CLAUDE.md 存在：在文件末尾追加选中的规范章节，使用 `---` 分隔
   - 如果 CLAUDE.md 不存在：创建新文件，内容为选中的规范
   - 读取对应的 references 模板，将内容追加到规则文件中

## 关键规则

- 绝不覆盖已有内容：使用 Read 读取现有文件后，只在末尾追加
- 冲突检测：如果已有规则和模板矛盾（如已有规则写了"注释用英文"），提示用户确认
- 追加时用 `## [章节名]（由 CodeAgentPlugin 补全）` 标记，方便辨识
