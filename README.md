# CodeAgentPlugin

CodeAgentPlugin 是单仓自包含插件：集中维护 Claude Code / Codex 共用的 commands、skills、hooks 与 manifest，同时在仓库内提供 Codex repo marketplace 入口。

## 能力概览

| Skill | 用途 |
|-------|------|
| `init-project` | 新项目初始化，生成 CLAUDE.md 及开发规范 |
| `setup-rules` | 已有项目补全缺失的开发规范 |
| `deploy-config` | 生成 Dockerfile、部署脚本、CI/CD 配置 |
| `server-ops` | 服务器运维，SSH 登录查日志、定位问题 |
| `troubleshoot-flow` | 生成问题定位流程文档 |
| `api-design` | 生成统一响应结构、错误码体系、分页规范 |
| `env-setup` | 扫描代码中的环境变量，生成 .env.example 模板 |
| `incident-response` | 线上事故响应 SOP、排查引导、复盘报告生成 |
| `code-review-checklist` | 基于项目规范生成代码审查清单，逐项检查代码 |
| `nginx-config` | Nginx 反向代理配置，域名绑定端口/路径，配置 HTTPS |
| `plugin-repo-bootstrap` | 一键创建同时支持 Codex 和 Claude Code 的插件仓库骨架 |
| `goal-contract` | 先收敛目标、验收条件与验证方式，再生成最佳实践 `/goal` |

## Commands

插件提供以下 commands：

- `/autopilot-plan` — 自动梳理任务上下文并生成执行方案
- `/bug-sweep` — 面向当前 diff / 模块做缺陷扫查
- `/cross-review` — 交叉视角做代码审查
- `/cross-tool-dispatch` — 组织多工具 / 多 agent 协同
- `/review-complete` — 需求完成后做完整收尾审查
- `/stabilize-diff` — 面向当前改动做稳定性和回归检查

## Skill 用法

在 Claude Code、Codex、Cursor、Gemini 等支持 Agent Skills 的宿主里，也可以通过 skill 方式使用。

如果你要新建一个“单仓双端插件仓库”，优先使用：

- `plugin-repo-bootstrap`

它会提供：

- 目录结构约定说明
- `.claude-plugin/` + `.codex-plugin/` + `.agents/plugins/marketplace.json`
- `plugins/<plugin-name>/` repo marketplace 入口壳
- 示例 command / skill / hooks / README

## 安装

### Claude Code

按 Claude Code 官方插件结构，本仓库根目录已经包含：

- `.claude-plugin/plugin.json`
- `commands/`
- `skills/`
- `hooks/hooks.json`

本地调试可直接加载仓库根目录：

```bash
claude --plugin-dir .
```

Claude Code 插件是命名空间形式，技能/命令应按插件名前缀调用，例如：

```text
/code-agent-plugin:review-complete
/code-agent-plugin:bug-sweep
```

### Codex

按 Codex 官方文档，repo-scoped 本地安装需要：

- `$REPO_ROOT/.agents/plugins/marketplace.json`
- `$REPO_ROOT/plugins/<plugin-name>/`

本仓库已经内置：

- `.agents/plugins/marketplace.json`
- `plugins/code-agent-plugin/` 入口壳

打开本仓库并重启 Codex 后，Codex 会从仓库内 marketplace 读取插件入口。仓库根目录仍然保留一份完整的 `.codex-plugin/plugin.json` 作为真源，`plugins/code-agent-plugin/` 只负责给 Codex marketplace 提供本地路径。

如果你要做个人级安装，也可以把 `plugins/code-agent-plugin/` 复制到 `~/.codex/plugins/`，再在 `~/.agents/plugins/marketplace.json` 中引用。

## 传统 Skills

以下能力当前主要以 skill 形式提供：

- `init-project` — 初始化新项目规范
- `setup-rules` — 为已有项目补全规范
- `deploy-config` — 生成部署配置
- `server-ops` — 服务器运维操作
- `troubleshoot-flow` — 生成问题定位流程
- `api-design` — 生成 API 设计规范和错误码体系
- `env-setup` — 扫描环境变量，生成 `.env.example`
- `incident-response` — 线上事故响应和复盘
- `code-review-checklist` — 代码审查清单检查
- `nginx-config` — 配置 Nginx 反向代理和 HTTPS
- `goal-contract` — 生成结构化 goal contract 和宿主最佳实践 `/goal`

## 兼容性

本插件基于 [Agent Skills 规范](https://agentskills.io/specification)，兼容以下平台：

- **Claude Code** — 通过插件根目录加载，按 `/code-agent-plugin:<name>` 调用
- **Codex CLI** — 通过仓库内 `.agents/plugins/marketplace.json` 安装
- **Cursor** — 通过 activate_skill 工具调用
- **Gemini CLI** — 通过 activate_skill 工具调用
