---
name: plugin-repo-bootstrap
description: Use when creating a new plugin repository that should support both Codex and Claude Code from one self-contained repo, especially when you need the correct manifests, repo-scoped Codex marketplace wrapper, commands/skills layout, and a bootstrap script instead of assembling the structure by hand.
---

# Plugin Repo Bootstrap

## Overview

为“单仓同时支持 Codex 与 Claude Code”的插件仓库提供统一脚手架。核心原则：**根目录是真源，Codex 的 `plugins/<name>/` 只是 repo marketplace 入口壳，不维护第二份内容。**

## 何时使用

- 你要新建一个插件仓库，而不是只补某个单独 skill
- 你希望同一仓库同时支持 Claude Code 与 Codex
- 你不想再手工拼 `.claude-plugin/`、`.codex-plugin/`、`.agents/plugins/marketplace.json`、`plugins/<name>/`
- 你希望自带最小命令、最小 skill、README 与 hooks 模板

## 关键要点

- Claude Code 真源：
  - `.claude-plugin/plugin.json`
  - `commands/`
  - `skills/`
  - `hooks/`
- Codex 真源：
  - `.codex-plugin/plugin.json`
  - `.agents/plugins/marketplace.json`
- Codex repo marketplace 入口壳：
  - `plugins/<plugin-name>/`
  - 该目录应尽量只用 symlink 指向根目录真源
- 不要复制两份 `commands/` / `skills/`

完整目录与说明见：`references/repo-layout.md`

## 快速开始

在目标父目录执行：

```bash
python3 skills/plugin-repo-bootstrap/scripts/create_plugin_repo.py \
  /path/to/my-plugin \
  --plugin-name my-plugin \
  --display-name "My Plugin" \
  --author "Your Name"
```

生成后你会得到：

- `.claude-plugin/`
- `.codex-plugin/`
- `.agents/plugins/marketplace.json`
- `commands/example-command.md`
- `skills/example-skill/SKILL.md`
- `hooks/hooks.json`
- `plugins/<plugin-name>/` symlink wrapper

## 输出约定

- `plugin-name` 必须用小写连字符
- README 会直接写明 Claude Code / Codex 两侧的安装与结构要点
- marketplace 采用 **repo-scoped local path**：`./plugins/<plugin-name>`
- wrapper 默认创建这些 symlink：
  - `.claude-plugin`
  - `.codex-plugin`
  - `commands`
  - `skills`
  - `hooks`

## 验证

创建完成后至少检查：

```bash
find /path/to/my-plugin -maxdepth 3 \( -type f -o -type l \) | sort
python3 - <<'PY'
import json
from pathlib import Path
root = Path('/path/to/my-plugin')
json.load((root/'.claude-plugin/plugin.json').open())
json.load((root/'.codex-plugin/plugin.json').open())
json.load((root/'.agents/plugins/marketplace.json').open())
print('ok')
PY
```

## 常见错误

- 把 Codex wrapper 当成第二份源码去维护
- marketplace 指向了错误路径，不是 `./plugins/<plugin-name>`
- hooks manifest 写成 `./hooks/hooks.json`，但实际没有 `hooks/` 目录
- 只写 `.codex-plugin/plugin.json`，却漏掉 `.agents/plugins/marketplace.json`
