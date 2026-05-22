# 单仓双端插件仓库结构

推荐结构：

```text
my-plugin/
├── .agents/
│   └── plugins/
│       └── marketplace.json
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── .codex-plugin/
│   └── plugin.json
├── commands/
│   └── example-command.md
├── hooks/
│   └── hooks.json
├── plugins/
│   └── my-plugin/
│       ├── .claude-plugin -> ../../.claude-plugin
│       ├── .codex-plugin -> ../../.codex-plugin
│       ├── commands -> ../../commands
│       ├── hooks -> ../../hooks
│       └── skills -> ../../skills
├── skills/
│   └── example-skill/
│       └── SKILL.md
└── README.md
```

## 设计原则

1. 根目录是真源
2. `plugins/<plugin-name>/` 只是 Codex marketplace 入口壳
3. `commands/` 与 `skills/` 不要复制第二份
4. `hooks/hooks.json` 路径必须与 `.codex-plugin/plugin.json` 保持一致
5. `.agents/plugins/marketplace.json` 用 repo-scoped local path：`./plugins/<plugin-name>`

## 适用场景

- 单个仓库直接自包含
- 同时服务 Claude Code 与 Codex
- 你希望后续扩展 commands / skills 时只改一份真源
