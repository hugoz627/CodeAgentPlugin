# CodeAgentPlugin 设计文档

## 概述

CodeAgentPlugin 是一个 Claude Code 插件，通过一组 skill 将个人/团队的开发规范、部署模板、服务器运维知识沉淀下来，避免每次新项目或新对话都要重复告诉 AI 相同的规范和约定。

**目标用户**：多语言开发者（Python、Go、TypeScript、Swift、Kotlin 等），使用云服务器 SSH 直连部署，个人/团队内部使用。

**核心问题**：每次新项目都要重复告诉 AI：
1. 中文注释、中文 commit、英文 log
2. 日志组件要求（文件落地、主流程/异常/请求 I/O 日志）
3. 语言特定规范（如 Python 用 pydantic、禁动态语法）
4. 部署脚本和 Dockerfile 编写方式
5. 服务器登录和日志查询方式

## 架构方案

采用纯 Skill 模板注入方案：每个 skill 是一个场景指南，调用时交互式收集信息，将规范模板写入项目的 CLAUDE.md / AGENTS.md 中。

## 插件目录结构

```
CodeAgentPlugin/
├── .claude-plugin/
│   └── plugin.json                    # 插件元数据
├── skills/
│   ├── init-project/
│   │   ├── SKILL.md                   # 新项目初始化 skill
│   │   └── references/
│   │       ├── claude-md-template.md  # CLAUDE.md 模板骨架
│   │       ├── rules-python.md        # Python 开发规范
│   │       ├── rules-go.md            # Go 开发规范
│   │       ├── rules-typescript.md    # TypeScript 开发规范
│   │       ├── rules-swift.md         # Swift/iOS 开发规范
│   │       ├── rules-kotlin.md        # Kotlin/Android 开发规范
│   │       ├── rules-common.md        # 通用规范（注释/commit/日志等）
│   │       ├── dockerfile-templates.md # Dockerfile 模板集
│   │       └── deploy-templates.md    # 部署脚本模板集
│   ├── setup-rules/
│   │   └── SKILL.md                   # 已有项目补全规范
│   ├── deploy-config/
│   │   └── SKILL.md                   # 部署配置生成
│   ├── server-ops/
│   │   ├── SKILL.md                   # 服务器运维 skill
│   │   └── references/
│   │       └── server-config-schema.md # servers.yaml 格式说明
│   └── troubleshoot-flow/
│       └── SKILL.md                   # 问题定位流程生成
├── hooks/
│   └── hooks.json                     # 预留，暂不使用
└── README.md
```

## Skill 详细设计

### 1. init-project — 新项目初始化

**Frontmatter:**
```yaml
---
name: init-project
description: Use when creating a new project - generates CLAUDE.md with development standards, logging requirements, deployment templates, and language-specific conventions
---
```

**触发方式**：`/init-project` 或 Skill("init-project")

**流程：**
1. 询问项目类型：后端服务 / 客户端 App / CLI 工具 / 库
2. 询问技术栈：Python / Go / TypeScript / Swift / Kotlin（可多选）
3. 询问部署方式：Docker / 裸机 / docker-compose
4. 读取 `references/rules-common.md` + 对应语言的 `references/rules-{lang}.md`
5. 读取 `references/claude-md-template.md` 骨架
6. 生成 `CLAUDE.md`，内容分为以下章节：
   - **基本约定**：中文注释、中文 commit message、英文 log
   - **日志规范**：日志组件要求、文件落地、主流程/异常/请求 I/O 日志格式
   - **语言规范**：所选语言的特定规范
   - **部署说明**：Docker/部署脚本的编写约定
7. 如用户需要，同时生成 Dockerfile 模板和部署脚本模板文件

**输出产物**：
- `CLAUDE.md`（核心规则文件）
- 可选：`Dockerfile`、`deploy.sh`、`docker-compose.yml`

### 2. setup-rules — 已有项目补全

**Frontmatter:**
```yaml
---
name: setup-rules
description: Use when joining an existing project that lacks development standards - scans the project, detects tech stack, and adds missing rules to CLAUDE.md or AGENTS.md
---
```

**触发方式**：`/setup-rules` 或 Skill("setup-rules")

**流程：**
1. 扫描项目结构，检测已有规则文件（CLAUDE.md、AGENTS.md、.cursorrules、.editorconfig 等）
2. 自动识别项目使用的语言和框架（通过文件扩展名、package.json、requirements.txt、go.mod 等）
3. 读取已有规则文件的内容
4. 对比模板规范，列出缺失项（如：缺少日志规范、缺少部署说明等）
5. 向用户展示缺失项列表，询问要补全哪些
6. 将选中的规范追加到已有规则文件末尾（不覆盖用户已有内容）
7. 如果项目完全没有规则文件，走 init-project 的完整流程

**关键约束**：
- 绝不覆盖用户已有的自定义规则
- 追加时使用明确的章节分隔，方便后续编辑
- 检测冲突：如果已有规则和模板矛盾，提示用户确认

### 3. deploy-config — 部署配置生成

**Frontmatter:**
```yaml
---
name: deploy-config
description: Use when setting up deployment for a project - generates Dockerfile, docker-compose.yml, deploy scripts, and CI/CD configuration based on project tech stack
---
```

**触发方式**：`/deploy-config` 或 Skill("deploy-config")

**流程：**
1. 检测项目语言和框架（同 setup-rules 的检测逻辑）
2. 检查是否已有 Dockerfile、docker-compose.yml 等
3. 询问部署目标：
   - Docker 单容器
   - docker-compose 多服务编排
   - 裸机 systemd service
   - CI/CD pipeline（GitHub Actions / GitLab CI）
4. 读取 `references/dockerfile-templates.md` 和 `references/deploy-templates.md`
5. 根据项目实际情况定制模板内容（端口、环境变量、构建步骤等）
6. 生成文件并将部署说明写入 CLAUDE.md 的部署章节

**输出产物**：
- `Dockerfile` 和/或 `docker-compose.yml`
- `deploy.sh` 或 systemd service 文件
- 可选：`.github/workflows/deploy.yml` 或 `.gitlab-ci.yml`
- CLAUDE.md 部署章节更新

### 4. server-ops — 服务器运维

**Frontmatter:**
```yaml
---
name: server-ops
description: Use when you need to connect to remote servers, check logs, diagnose issues, or manage services - loads server configuration and generates SSH commands
---
```

**触发方式**：`/server-ops` 或 Skill("server-ops")

**流程：**
1. 查找 `servers.yaml` 配置文件（优先项目根目录，其次 `~/.config/code-agent/servers.yaml`）
2. 如果不存在，引导用户交互式创建：
   - 输入服务器名称、IP、用户名、SSH key 路径
   - 输入该服务器上的服务名称和日志路径
3. 加载配置，展示服务器和服务列表
4. 根据用户需求生成命令：
   - 登录服务器：`ssh -i {key} {user}@{host}`
   - 查看实时日志：`ssh ... "tail -f {log_path}"`
   - 搜索日志关键字：`ssh ... "grep '{keyword}' {log_path}"`
   - 查看最近错误：`ssh ... "grep -i 'error\|exception' {log_path} | tail -50"`
   - 多服务器并行查询：生成多条命令供用户批量执行
5. 所有命令展示给用户确认后再执行（安全优先）

**servers.yaml 配置格式：**
```yaml
servers:
  - name: prod-api-01           # 服务器别名
    host: 10.0.1.10             # IP 或域名
    user: deploy                # SSH 用户名
    key: ~/.ssh/prod_key        # SSH 私钥路径（可选，默认用 ssh-agent）
    port: 22                    # SSH 端口（可选，默认 22）
    services:                   # 该服务器上的服务列表
      - name: user-service      # 服务名称
        log_path: /var/log/user-service/app.log  # 日志文件路径
        log_format: json        # 日志格式：json / text
        container: user-svc     # Docker 容器名（可选）
      - name: order-service
        log_path: /var/log/order-service/app.log
        log_format: text
```

### 5. troubleshoot-flow — 问题定位流程生成

**Frontmatter:**
```yaml
---
name: troubleshoot-flow
description: Use when you need to create or update troubleshooting procedures for a project - reads the codebase, asks questions to understand business flows, then generates diagnostic documentation
---
```

**触发方式**：`/troubleshoot-flow` 或 Skill("troubleshoot-flow")

**流程：**
1. **阅读项目上下文**：
   - 扫描项目结构和核心代码
   - 阅读已有的 CLAUDE.md 和文档
   - 识别 API 端点、服务间调用、数据库操作等
2. **向用户逐一提问对齐**：
   - 核心业务流程有哪些？（列出识别到的，请用户补充/修正）
   - 每个流程的关键节点？涉及哪些服务/组件？
   - 常见异常场景有哪些？（超时、第三方不可用、数据不一致等）
   - 目前有哪些监控/告警？日志中有 traceId 等关联字段吗？
3. **生成问题定位流程文档**，包括：
   - 各核心流程的调用链路图（文本描述）
   - 每个流程节点的日志查询关键字和 grep 命令
   - 常见异常场景的排查 checklist（按步骤）
   - 日志关联分析方法（如 traceId 串联）
   - 如果有 server-ops 配置，自动关联服务器和日志路径
4. **写入项目**：
   - 生成 `docs/troubleshooting.md`
   - 在 CLAUDE.md 中添加引用链接

## 规范模板内容要点

### rules-common.md（通用规范）

- **注释语言**：代码注释使用中文
- **Commit 语言**：commit message 使用中文
- **日志语言**：程序运行日志（log）使用英文
- **日志组件要求**：
  - 必须实现文件日志组件，日志必须落地到文件
  - 核心主流程必须有日志，包含关键上下文参数
  - 异常流程必须有日志，包含错误详情和上下文
  - 请求协议的输入输出必须有日志（请求参数、响应状态、耗时）
  - 日志需包含时间戳、级别、模块名、traceId（如有）
- **错误处理**：不吞异常，关键异常必须记录日志后再处理

### rules-python.md（Python 规范）

- 优先使用 pydantic 定义数据结构，少用 dict 类型
- 非特殊情况不使用 getattr/setattr 等动态语法
- 尽量使用明确的类型和明确的字段
- 使用 type hints 标注函数签名
- 使用 loguru 或 logging 模块，配置文件 handler
- 异步代码使用 asyncio + httpx，避免 requests 阻塞

### rules-go.md（Go 规范）

- 使用 struct 定义数据结构，避免 map[string]interface{}
- 错误必须处理，不要 `_ = err`
- 使用 zap 或 zerolog 做结构化日志
- 使用 context 传递 traceId

### rules-typescript.md（TypeScript 规范）

- 使用 interface/type 定义数据结构，避免 any
- 使用 zod 做运行时校验
- 使用 winston 或 pino 做日志，配置文件 transport

### rules-swift.md（Swift/iOS 规范）

- 使用 Codable struct 定义数据模型
- 使用 OSLog 或自定义日志组件，支持文件落地
- 网络层请求/响应日志

### rules-kotlin.md（Kotlin/Android 规范）

- 使用 data class 定义数据模型
- 使用 Timber 或自定义日志组件，支持文件落地
- 网络层使用 OkHttp interceptor 记录请求日志

## 数据流

```
用户调用 skill
      │
      ▼
SKILL.md 加载到上下文
      │
      ▼
交互式收集项目信息
      │
      ▼
读取 references/ 下的模板
      │
      ▼
根据项目情况定制内容
      │
      ▼
生成/更新 CLAUDE.md 和其他文件
```

## 设计约束

1. **不覆盖原则**：任何 skill 都不应覆盖用户已有的自定义规则，只追加或合并
2. **交互优先**：所有关键决策通过提问确认，不做假设
3. **模板可扩展**：references/ 下的模板文件可以由用户自行修改和扩展
4. **Token 效率**：模板放在 references/ 而非 SKILL.md 正文中，避免每次加载都消耗大量 token
5. **安全优先**：server-ops 生成的命令必须由用户确认后才执行，不自动执行远程命令
6. **servers.yaml 敏感信息**：配置文件中不存储密码，只存储 SSH key 路径，实际认证由 SSH agent 或 key 文件处理
