---
name: server-ops
description: Use when you need to connect to remote servers, check logs, diagnose issues, or manage services - loads server configuration from servers.yaml and generates SSH commands for log queries and troubleshooting
---

# 服务器运维

加载服务器配置，生成 SSH 命令用于登录服务器、查询日志、定位问题。所有命令由用户确认后执行。

## 流程

1. **加载服务器配置**：
   - 使用 Glob 查找 `servers.yaml`（先项目根目录，再 `~/.config/code-agent/servers.yaml`）
   - 如果找到，使用 Read 读取内容
   - 如果未找到，引导用户创建（见下方"创建配置"流程）
   - 配置格式参见 `references/server-config-schema.md`

2. **展示服务器列表**：
   - 列出所有服务器名称、IP、环境标识
   - 列出每台服务器上的服务和日志路径

3. **根据用户需求生成命令**（使用 AskUserQuestion 询问操作类型）：
   - **登录服务器**：`ssh -i {key} -p {port} {user}@{host}`
   - **查看实时日志**：`ssh ... "tail -f {log_path}"`
   - **按关键字搜索日志**：`ssh ... "grep '{keyword}' {log_path} | tail -100"`
   - **查看最近错误**：`ssh ... "grep -iE 'error|exception|fatal' {log_path} | tail -50"`
   - **按时间范围查询**（json 格式日志）：`ssh ... "cat {log_path} | jq 'select(.timestamp >= \"2024-01-15T10:00:00\")'"`
   - **按 traceId 查询**：`ssh ... "grep '{traceId}' {log_path}"`
   - **多服务器并行查询**：为每台相关服务器生成一条命令

4. **执行命令**：
   - 展示生成的命令，等待用户确认
   - 使用 Bash 工具执行，展示结果
   - 如果用户要进一步筛选或追查，继续生成新命令

## 创建配置流程

当 servers.yaml 不存在时：
1. 使用 AskUserQuestion 逐步收集：服务器名称、IP、用户名、SSH key 路径
2. 询问该服务器上有哪些服务，日志路径分别在哪
3. 生成 servers.yaml 并用 Write 写入项目根目录
4. 提醒用户将 servers.yaml 加入 .gitignore（包含服务器信息）

## 关键规则

- 所有 SSH 命令必须展示给用户确认后才执行
- 不存储密码，认证依赖 SSH key 或 ssh-agent
- servers.yaml 包含敏感信息，提醒用户不要提交到公开仓库
