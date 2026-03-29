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
