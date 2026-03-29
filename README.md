# CodeAgentPlugin

Claude Code 插件：将开发规范、部署模板、服务器运维知识沉淀为可复用的 skill，避免每次新项目重复告知 AI 相同的约定。

## Skills

| Skill | 用途 |
|-------|------|
| `init-project` | 新项目初始化，生成 CLAUDE.md 及开发规范 |
| `setup-rules` | 已有项目补全缺失的开发规范 |
| `deploy-config` | 生成 Dockerfile、部署脚本、CI/CD 配置 |
| `server-ops` | 服务器运维，SSH 登录查日志、定位问题 |
| `troubleshoot-flow` | 生成问题定位流程文档 |

## 使用方式

在 Claude Code 或 Codex 中调用：

- `/init-project` — 初始化新项目规范
- `/setup-rules` — 为已有项目补全规范
- `/deploy-config` — 生成部署配置
- `/server-ops` — 服务器运维操作
- `/troubleshoot-flow` — 生成问题定位流程

## 安装

### Claude Code

将本插件目录放入 `~/.claude/plugins/` 下，或通过插件管理器安装。

### Codex CLI

```bash
# 克隆插件到本地
git clone <repo-url> ~/.codex/code-agent-plugin

# 创建 skills 符号链接
mkdir -p ~/.agents/skills
ln -s ~/.codex/code-agent-plugin/skills ~/.agents/skills/code-agent-plugin

# 重启 Codex 使插件生效
```

## 兼容性

本插件基于 [Agent Skills 规范](https://agentskills.io/specification)，兼容以下平台：

- **Claude Code** — 通过 Skill 工具调用
- **Codex CLI** — 通过 skills 目录自动发现
- **Cursor** — 通过 activate_skill 工具调用
- **Gemini CLI** — 通过 activate_skill 工具调用
