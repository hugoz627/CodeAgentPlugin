# CodeAgentPlugin

CodeAgentPlugin 是插件源码仓库：集中维护 Claude Code / Codex 共用的 commands、skills、hooks 与插件 manifest。Codex marketplace 分发已拆分到独立仓库，避免源码仓和 marketplace 包装层混在一起。

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

## Commands

可直接调用的 commands：

- `/autopilot-plan` — 自动梳理任务上下文并生成执行方案
- `/bug-sweep` — 面向当前 diff / 模块做缺陷扫查
- `/cross-review` — 交叉视角做代码审查
- `/cross-tool-dispatch` — 组织多工具 / 多 agent 协同
- `/review-complete` — 需求完成后做完整收尾审查
- `/stabilize-diff` — 面向当前改动做稳定性和回归检查

## Skill 用法

在 Claude Code、Codex、Cursor、Gemini 等支持 Agent Skills 的宿主里，也可以通过 skill 方式使用。

## 安装

### Claude Code

将本仓库作为插件源码安装，或通过插件管理器安装。

### Codex Plugin（源码直装 / 本地调试）

本仓库根目录同时包含 Codex 所需的 `.codex-plugin/plugin.json`，可作为本地调试用插件源码。

### Codex Marketplace（推荐）

Codex 正式分发请使用独立 marketplace 仓库，而不是直接使用本仓库中的历史包装目录。marketplace 仓库会同步本仓库的：

- `commands/`
- `skills/`
- `hooks/hooks.json`
- `.codex-plugin/plugin.json`

同步脚本位于：

- `scripts/sync_to_marketplace.py`

示例：

```bash
python3 scripts/sync_to_marketplace.py ../code-agent-marketplace
```

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

## 兼容性

本插件基于 [Agent Skills 规范](https://agentskills.io/specification)，兼容以下平台：

- **Claude Code** — 通过 commands / Skill 工具调用
- **Codex CLI** — 通过 plugin 或 marketplace 安装
- **Cursor** — 通过 activate_skill 工具调用
- **Gemini CLI** — 通过 activate_skill 工具调用
