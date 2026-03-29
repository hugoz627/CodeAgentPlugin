# CodeAgentPlugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin with 5 skills that codify development standards, deployment templates, server operations, and troubleshooting flows into reusable, project-injectable rules.

**Architecture:** A Claude Code plugin consisting of 5 SKILL.md files with supporting reference templates in `references/` directories. Each skill is invoked via `/skill-name` or `Skill("skill-name")`, reads reference templates, interacts with the user, and generates/updates project rule files (CLAUDE.md, AGENTS.md, etc.).

**Tech Stack:** Markdown (SKILL.md + reference files), YAML (plugin metadata, server config schema)

---

## File Structure

```
CodeAgentPlugin/
├── .claude-plugin/
│   └── plugin.json                          # Plugin metadata
├── skills/
│   ├── init-project/
│   │   ├── SKILL.md                         # New project initialization skill
│   │   └── references/
│   │       ├── claude-md-template.md        # CLAUDE.md skeleton template
│   │       ├── rules-common.md              # Universal rules (comments, commits, logging)
│   │       ├── rules-python.md              # Python conventions
│   │       ├── rules-go.md                  # Go conventions
│   │       ├── rules-typescript.md          # TypeScript conventions
│   │       ├── rules-swift.md               # Swift/iOS conventions
│   │       ├── rules-kotlin.md              # Kotlin/Android conventions
│   │       ├── dockerfile-templates.md      # Dockerfile templates per language
│   │       └── deploy-templates.md          # Deploy script templates
│   ├── setup-rules/
│   │   └── SKILL.md                         # Existing project rule补全 skill
│   ├── deploy-config/
│   │   └── SKILL.md                         # Deployment configuration skill
│   ├── server-ops/
│   │   ├── SKILL.md                         # Server operations skill
│   │   └── references/
│   │       └── server-config-schema.md      # servers.yaml format spec
│   └── troubleshoot-flow/
│       └── SKILL.md                         # Troubleshooting flow generation skill
├── hooks/
│   └── hooks.json                           # Reserved for future use
└── README.md
```

---

### Task 1: Plugin Metadata and Project Skeleton

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `hooks/hooks.json`
- Create: `README.md`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "code-agent-plugin",
  "description": "Development standards, deployment templates, server operations, and troubleshooting flows for Claude Code - eliminates repetitive project setup instructions",
  "version": "0.1.0",
  "author": {
    "name": "CodeAgentPlugin"
  },
  "license": "MIT",
  "keywords": [
    "development-standards",
    "deployment",
    "server-ops",
    "troubleshooting",
    "project-init",
    "logging",
    "docker"
  ]
}
```

- [ ] **Step 2: Create hooks.json (reserved)**

```json
{
  "hooks": {}
}
```

- [ ] **Step 3: Create README.md**

```markdown
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
```

- [ ] **Step 4: Initialize git repo and commit**

```bash
cd /home/ubuntu/workspace/CodeAgentPlugin
git init
git add .claude-plugin/plugin.json hooks/hooks.json README.md docs/
git commit -m "初始化: 创建插件元数据和项目骨架"
```

---

### Task 2: Common Rules Reference Template

**Files:**
- Create: `skills/init-project/references/rules-common.md`

- [ ] **Step 1: Create rules-common.md**

This is the universal development standards template that applies to all languages. Write the following content:

```markdown
# 通用开发规范

## 语言约定

- 代码注释使用中文
- Git commit message 使用中文，格式：`<类型>: <描述>`，类型包括：feat/fix/refactor/docs/test/chore
- 程序运行日志（log）使用英文，日志消息中的变量值保持原样

## 日志规范

### 日志组件要求

- 必须实现文件日志组件，日志必须落地到文件，不能仅输出到 stdout
- 日志文件路径可配置，默认放在项目根目录下的 `logs/` 目录
- 支持日志轮转（按大小或按天）

### 日志内容要求

- **核心主流程**：每个关键步骤必须有日志，包含关键上下文参数（用户ID、订单号、请求ID等）
- **异常流程**：所有异常必须记录日志，包含错误详情、堆栈信息和触发上下文
- **请求协议 I/O**：HTTP/RPC 请求的输入参数和输出结果必须有日志，包含耗时
- **不吞异常**：捕获异常后必须先记录日志再处理，禁止空 catch/except

### 日志格式

每条日志必须包含：
- 时间戳（ISO 8601 格式）
- 日志级别（DEBUG/INFO/WARN/ERROR）
- 模块/类名
- traceId（如有链路追踪）
- 消息内容和关键参数

示例格式：
```
2024-01-15T10:30:00.123Z [INFO] [UserService] [trace:abc123] User login success, userId=12345, ip=192.168.1.1, cost=45ms
2024-01-15T10:30:01.456Z [ERROR] [OrderService] [trace:abc123] Create order failed, userId=12345, error=insufficient balance, amount=100.00
```

## 错误处理

- 不吞异常：关键异常必须记录日志后再处理
- 错误信息要包含上下文：什么操作、什么输入、导致了什么错误
- 对外接口返回的错误要有明确的错误码和错误描述
```

- [ ] **Step 2: Commit**

```bash
git add skills/init-project/references/rules-common.md
git commit -m "feat: 添加通用开发规范模板（注释/commit/日志/错误处理）"
```

---

### Task 3: Language-Specific Rules Templates

**Files:**
- Create: `skills/init-project/references/rules-python.md`
- Create: `skills/init-project/references/rules-go.md`
- Create: `skills/init-project/references/rules-typescript.md`
- Create: `skills/init-project/references/rules-swift.md`
- Create: `skills/init-project/references/rules-kotlin.md`

- [ ] **Step 1: Create rules-python.md**

```markdown
# Python 开发规范

## 类型系统

- 优先使用 pydantic BaseModel 定义数据结构，少用 dict 类型
- 非特殊情况不使用 getattr/setattr/hasattr 等动态语法
- 所有函数必须有 type hints 标注参数和返回值类型
- 使用 Enum 替代魔法字符串
- 配置项使用 pydantic Settings 管理

## 日志

- 使用 loguru 作为日志库，配置文件 sink
- 配置示例：
  ```python
  from loguru import logger
  logger.add("logs/app.log", rotation="100 MB", retention="7 days", encoding="utf-8")
  ```

## 异步

- 异步 HTTP 客户端使用 httpx，避免在异步代码中使用 requests（会阻塞事件循环）
- 异步框架优先使用 FastAPI

## 依赖管理

- 使用 pyproject.toml 管理项目元数据和依赖
- 使用 uv 或 poetry 做依赖管理
```

- [ ] **Step 2: Create rules-go.md**

```markdown
# Go 开发规范

## 类型系统

- 使用 struct 定义数据结构，避免 map[string]interface{}
- 使用自定义类型替代原始类型（如 `type UserID int64`）

## 错误处理

- 错误必须处理，禁止 `_ = err`
- 使用 fmt.Errorf 或 errors 包装错误添加上下文：`fmt.Errorf("create order failed: %w", err)`

## 日志

- 使用 zap 或 zerolog 做结构化日志
- 配置文件输出：
  ```go
  logger, _ := zap.Config{
      OutputPaths: []string{"logs/app.log", "stdout"},
  }.Build()
  ```

## 上下文

- 使用 context.Context 传递 traceId、请求级别数据
- 第一个参数始终是 ctx context.Context
```

- [ ] **Step 3: Create rules-typescript.md**

```markdown
# TypeScript 开发规范

## 类型系统

- 使用 interface 或 type 定义数据结构，禁止使用 any
- 使用 zod 做运行时数据校验
- 启用 strict 模式

## 日志

- 使用 winston 或 pino 做日志，配置文件 transport
- 配置示例（pino）：
  ```typescript
  import pino from 'pino';
  const logger = pino({
    transport: {
      targets: [
        { target: 'pino/file', options: { destination: 'logs/app.log' } },
        { target: 'pino-pretty', options: { destination: 1 } }
      ]
    }
  });
  ```

## 包管理

- 优先使用 pnpm
- 使用 ESM 模块格式
```

- [ ] **Step 4: Create rules-swift.md**

```markdown
# Swift/iOS 开发规范

## 类型系统

- 使用 Codable struct 定义数据模型
- 使用 enum 定义有限状态集合
- 避免使用 Any 或强制解包 (!)

## 日志

- 使用 OSLog 或自定义日志组件，必须支持文件落地
- 网络层请求/响应必须有日志（URL、参数、状态码、耗时）
- 配置示例：
  ```swift
  import OSLog
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
  logger.info("Request: \(url), cost: \(elapsed)ms")
  ```

## 网络层

- 使用 URLSession 或 Alamofire，统一封装请求/响应日志
- 错误处理使用 Result 类型
```

- [ ] **Step 5: Create rules-kotlin.md**

```markdown
# Kotlin/Android 开发规范

## 类型系统

- 使用 data class 定义数据模型
- 使用 sealed class 定义有限状态
- 避免使用 Any 或平台类型

## 日志

- 使用 Timber 或自定义日志组件，必须支持文件落地
- 配置文件日志：
  ```kotlin
  Timber.plant(FileLogTree("logs/app.log"))
  Timber.plant(Timber.DebugTree())
  ```

## 网络层

- 使用 OkHttp + Retrofit
- 使用 OkHttp Interceptor 统一记录请求/响应日志（URL、参数、状态码、耗时）
- 使用 Kotlin Serialization 或 Moshi 做序列化
```

- [ ] **Step 6: Commit**

```bash
git add skills/init-project/references/rules-python.md skills/init-project/references/rules-go.md skills/init-project/references/rules-typescript.md skills/init-project/references/rules-swift.md skills/init-project/references/rules-kotlin.md
git commit -m "feat: 添加各语言开发规范模板（Python/Go/TS/Swift/Kotlin）"
```

---

### Task 4: CLAUDE.md Template and Deployment Templates

**Files:**
- Create: `skills/init-project/references/claude-md-template.md`
- Create: `skills/init-project/references/dockerfile-templates.md`
- Create: `skills/init-project/references/deploy-templates.md`

- [ ] **Step 1: Create claude-md-template.md**

This is the skeleton that init-project will use to generate the final CLAUDE.md. Placeholders use `{{PLACEHOLDER}}` syntax.

```markdown
# {{PROJECT_NAME}} 开发规范

## 基本约定

{{RULES_COMMON}}

## 语言规范

{{RULES_LANG}}

## 日志规范

参见上方"通用开发规范"中的日志部分。本项目日志文件存放路径：`logs/`

## 部署

{{DEPLOY_SECTION}}

## 项目结构

{{PROJECT_STRUCTURE}}
```

- [ ] **Step 2: Create dockerfile-templates.md**

```markdown
# Dockerfile 模板

## Python (FastAPI/Flask)

```dockerfile
FROM python:3.12-slim AS base

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

COPY . .
RUN mkdir -p logs

EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Go

```dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/server ./cmd/server

FROM alpine:3.19
WORKDIR /app
COPY --from=builder /bin/server .
RUN mkdir -p logs

EXPOSE 8080
CMD ["./server"]
```

## TypeScript (Node.js)

```dockerfile
FROM node:20-slim AS builder

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .
RUN mkdir -p logs

EXPOSE 3000
CMD ["node", "dist/index.js"]
```
```

- [ ] **Step 3: Create deploy-templates.md**

```markdown
# 部署脚本模板

## docker-compose.yml 基础模板

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "${PORT:-8000}:8000"
    volumes:
      - ./logs:/app/logs
      - ./.env:/app/.env:ro
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
    env_file:
      - .env
```

## deploy.sh 基础模板

```bash
#!/bin/bash
set -euo pipefail

# 配置
APP_NAME="${APP_NAME:-myapp}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/$APP_NAME}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=== 部署 $APP_NAME ==="

# 构建镜像
if [ -n "$DOCKER_REGISTRY" ]; then
    IMAGE="$DOCKER_REGISTRY/$APP_NAME:$IMAGE_TAG"
    docker build -t "$IMAGE" .
    docker push "$IMAGE"
else
    IMAGE="$APP_NAME:$IMAGE_TAG"
    docker build -t "$IMAGE" .
fi

# 部署
cd "$DEPLOY_DIR"
docker compose pull 2>/dev/null || true
docker compose up -d

echo "=== 部署完成 ==="
docker compose ps
```

## systemd service 模板

```ini
[Unit]
Description={{APP_NAME}} Service
After=network.target

[Service]
Type=simple
User={{USER}}
WorkingDirectory={{WORK_DIR}}
ExecStart={{EXEC_START}}
Restart=on-failure
RestartSec=5
StandardOutput=append:{{WORK_DIR}}/logs/stdout.log
StandardError=append:{{WORK_DIR}}/logs/stderr.log

[Install]
WantedBy=multi-user.target
```
```

- [ ] **Step 4: Commit**

```bash
git add skills/init-project/references/claude-md-template.md skills/init-project/references/dockerfile-templates.md skills/init-project/references/deploy-templates.md
git commit -m "feat: 添加 CLAUDE.md 骨架模板和部署配置模板（Dockerfile/compose/deploy.sh）"
```

---

### Task 5: init-project Skill

**Files:**
- Create: `skills/init-project/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "feat: 添加 init-project skill（新项目初始化）"
```

---

### Task 6: setup-rules Skill

**Files:**
- Create: `skills/setup-rules/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
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
   - 读取 init-project skill 下的 `references/rules-common.md` 和对应语言的 `references/rules-{lang}.md`
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/setup-rules/SKILL.md
git commit -m "feat: 添加 setup-rules skill（已有项目补全规范）"
```

---

### Task 7: deploy-config Skill

**Files:**
- Create: `skills/deploy-config/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
---
name: deploy-config
description: Use when setting up deployment for a project - generates Dockerfile, docker-compose.yml, deploy scripts, systemd service files, or CI/CD configuration based on the detected tech stack
---

# 部署配置生成

为项目生成部署相关配置文件。

## 流程

1. **检测项目信息**：
   - 使用 Glob 检测项目语言（同 setup-rules 的检测逻辑）
   - 使用 Glob 检查是否已有 Dockerfile、docker-compose.yml、deploy.sh、.github/workflows/
   - 向用户展示检测结果

2. **选择部署目标**（使用 AskUserQuestion）：
   - Docker 单容器
   - docker-compose 多服务编排
   - 裸机 systemd service
   - CI/CD pipeline（GitHub Actions / GitLab CI）
   - 可多选

3. **生成配置文件**：
   - 读取 init-project skill 下的 `references/dockerfile-templates.md` 和 `references/deploy-templates.md`
   - 根据检测到的语言选择对应模板
   - 针对项目实际情况调整模板中的占位符：
     - 端口号：询问用户或从代码中检测
     - 入口文件：从 package.json / pyproject.toml / main.go 中检测
     - 环境变量：从 .env.example 或代码中检测
   - 使用 Write 工具写入文件

4. **更新 CLAUDE.md**：
   - 如果 CLAUDE.md 存在，使用 Edit 在部署章节追加生成说明
   - 说明如何构建、如何部署、如何查看日志

5. **输出文件列表**：展示生成的所有文件及简要说明

## 关键规则

- 如果已有 Dockerfile 等文件，询问用户是覆盖还是跳过
- 生成的 Dockerfile 必须包含 `mkdir -p logs` 以确保日志目录存在
- docker-compose.yml 必须挂载 logs 目录到宿主机
```

- [ ] **Step 2: Commit**

```bash
git add skills/deploy-config/SKILL.md
git commit -m "feat: 添加 deploy-config skill（部署配置生成）"
```

---

### Task 8: server-ops Skill and Server Config Schema

**Files:**
- Create: `skills/server-ops/SKILL.md`
- Create: `skills/server-ops/references/server-config-schema.md`

- [ ] **Step 1: Create server-config-schema.md**

```markdown
# servers.yaml 配置格式

## 完整示例

```yaml
servers:
  - name: prod-api-01           # 服务器别名（必填）
    host: 10.0.1.10             # IP 或域名（必填）
    user: deploy                # SSH 用户名（必填）
    key: ~/.ssh/prod_key        # SSH 私钥路径（可选，默认用 ssh-agent）
    port: 22                    # SSH 端口（可选，默认 22）
    env: prod                   # 环境标识（可选：prod/staging/dev）
    services:                   # 该服务器上的服务列表（可选）
      - name: user-service      # 服务名称
        log_path: /var/log/user-service/app.log  # 日志文件路径
        log_format: json        # 日志格式：json / text
        container: user-svc     # Docker 容器名（可选，用于 docker logs）
      - name: order-service
        log_path: /var/log/order-service/app.log
        log_format: text
```

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| servers | list | 是 | 服务器列表 |
| servers[].name | string | 是 | 服务器别名，用于显示和引用 |
| servers[].host | string | 是 | IP 地址或域名 |
| servers[].user | string | 是 | SSH 登录用户名 |
| servers[].key | string | 否 | SSH 私钥路径，默认用 ssh-agent |
| servers[].port | int | 否 | SSH 端口，默认 22 |
| servers[].env | string | 否 | 环境标识：prod / staging / dev |
| servers[].services | list | 否 | 该服务器上运行的服务 |
| services[].name | string | 是 | 服务名称 |
| services[].log_path | string | 是 | 日志文件路径（支持通配符如 /var/log/app/*.log） |
| services[].log_format | string | 否 | 日志格式：json / text，默认 text |
| services[].container | string | 否 | Docker 容器名，设置后可用 docker logs 查看 |

## 配置文件查找顺序

1. 项目根目录 `./servers.yaml`
2. 用户全局配置 `~/.config/code-agent/servers.yaml`
```

- [ ] **Step 2: Create SKILL.md**

```markdown
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
```

- [ ] **Step 3: Commit**

```bash
git add skills/server-ops/SKILL.md skills/server-ops/references/server-config-schema.md
git commit -m "feat: 添加 server-ops skill（服务器运维）及配置格式文档"
```

---

### Task 9: troubleshoot-flow Skill

**Files:**
- Create: `skills/troubleshoot-flow/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
---
name: troubleshoot-flow
description: Use when you need to create or update troubleshooting procedures for a project - reads the codebase to understand business flows, asks questions to align on key processes and failure scenarios, then generates diagnostic documentation with log query commands and runbooks
---

# 问题定位流程生成

阅读项目代码，通过提问对齐业务流程，生成问题定位流程文档。

## 流程

### 第一步：阅读项目上下文

- 使用 Glob 扫描项目结构（关注 src/、app/、cmd/、api/、routes/ 等目录）
- 使用 Read 阅读核心入口文件、路由定义、主要业务模块
- 使用 Grep 搜索：
  - API 端点定义（`@app.route`、`router.`、`http.Handle` 等）
  - 服务间调用（HTTP client、gRPC client）
  - 数据库操作（query、insert、update）
  - 消息队列操作（publish、subscribe、consume）
- 使用 Read 阅读已有的 CLAUDE.md 和 README.md
- 如果存在 servers.yaml，读取服务器和服务配置

### 第二步：向用户提问对齐

逐一提问（每次一个问题，使用 AskUserQuestion）：

1. "我识别到以下业务流程/API，对吗？有遗漏或需要修正的吗？"（列出识别结果）
2. "核心业务流程中，哪些环节最容易出问题？常见的异常场景有哪些？"
3. "日志中有 traceId 或请求 ID 等关联字段吗？格式是什么？"
4. "目前有监控/告警系统吗？（如 Prometheus + Grafana、云厂商监控等）"
5. "有没有特定的问题排查场景是你经常碰到但每次都要重新梳理的？"

### 第三步：生成问题定位流程文档

基于对齐结果，生成 `docs/troubleshooting.md`，包含以下章节：

#### 3.1 核心业务流程

对每个核心流程，列出：
- 流程名称和简要描述
- 调用链路（A → B → C 格式）
- 各节点关键日志关键字

#### 3.2 常见异常场景排查

对每个常见异常，生成排查 checklist：
```markdown
### 场景：用户下单失败

排查步骤：
1. 确认错误现象：查看用户反馈或告警信息
2. 查询请求日志：`grep '{requestId}' /var/log/order-service/app.log`
3. 检查依赖服务：库存服务是否正常、支付服务是否可用
4. 查看错误详情：`grep -A 5 'ERROR.*CreateOrder' /var/log/order-service/app.log | tail -20`
5. 检查数据状态：确认数据库中订单记录状态
```

#### 3.3 日志查询速查表

| 场景 | 命令 |
|------|------|
| 查某用户请求 | `grep 'userId={id}' {log_path}` |
| 查某次请求链路 | `grep '{traceId}' {log_path}` |
| 查最近错误 | `grep -iE 'error\|exception' {log_path} \| tail -50` |
| 查某时间段日志 | `awk '/2024-01-15T10:00/,/2024-01-15T11:00/' {log_path}` |

#### 3.4 服务器关联（如有 servers.yaml）

自动将服务名和日志路径关联到具体服务器，生成完整的 SSH 查询命令。

### 第四步：写入项目

- 使用 Write 写入 `docs/troubleshooting.md`
- 如果 CLAUDE.md 存在，使用 Edit 在末尾添加引用：
  ```
  ## 问题定位

  详见 [docs/troubleshooting.md](docs/troubleshooting.md)
  ```

## 关键规则

- 先阅读代码再提问，提问时带上自己的识别结果，减少用户负担
- 每次只问一个问题，不要一次性抛出所有问题
- 生成的排查步骤要具体到命令级别，不要只写"查看日志"
- 如果项目有 server-ops 配置，自动关联服务器信息
```

- [ ] **Step 2: Commit**

```bash
git add skills/troubleshoot-flow/SKILL.md
git commit -m "feat: 添加 troubleshoot-flow skill（问题定位流程生成）"
```

---

### Task 10: Final Verification and Summary Commit

**Files:**
- Verify: all files created in Tasks 1-9

- [ ] **Step 1: Verify complete file structure**

```bash
find /home/ubuntu/workspace/CodeAgentPlugin -type f | sort
```

Expected output should match the file structure defined at the top of this plan. Every file listed there should exist.

- [ ] **Step 2: Verify SKILL.md frontmatter**

For each SKILL.md, verify:
- Has `---` delimited YAML frontmatter
- Has `name` field (letters, numbers, hyphens only)
- Has `description` field starting with "Use when"

```bash
for f in $(find /home/ubuntu/workspace/CodeAgentPlugin/skills -name "SKILL.md"); do
  echo "=== $f ==="
  head -5 "$f"
  echo ""
done
```

- [ ] **Step 3: Verify references are accessible**

Check that all references mentioned in SKILL.md files exist:

```bash
ls -la /home/ubuntu/workspace/CodeAgentPlugin/skills/init-project/references/
ls -la /home/ubuntu/workspace/CodeAgentPlugin/skills/server-ops/references/
```

Expected:
- `init-project/references/` should contain 8 files: claude-md-template.md, rules-common.md, rules-python.md, rules-go.md, rules-typescript.md, rules-swift.md, rules-kotlin.md, dockerfile-templates.md, deploy-templates.md (9 files total)
- `server-ops/references/` should contain 1 file: server-config-schema.md

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git status
# Only commit if there are changes
git diff --cached --quiet || git commit -m "fix: 修复验证中发现的问题"
```
