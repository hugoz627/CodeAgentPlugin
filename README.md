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

在 Claude Code 中调用：

- `/init-project` — 初始化新项目规范
- `/setup-rules` — 为已有项目补全规范
- `/deploy-config` — 生成部署配置
- `/server-ops` — 服务器运维操作
- `/troubleshoot-flow` — 生成问题定位流程

## 安装

将本插件目录放入 `~/.claude/plugins/` 下，或通过插件管理器安装。
