# CodeBuddy 配置模板

## CODEBUDDY.md

```markdown
# <项目名> CodeBuddy 指南

<!-- 通用规范（命令、架构、边界）见 AGENTS.md，本文件为 CodeBuddy 专属视图 -->

## 项目概述

<一句话描述：技术栈 + 核心功能 + 特殊架构决策>

## 关键命令

| 命令 | 说明 |
|------|------|
| `<install>` | 安装依赖 |
| `<dev>` | 启动开发环境 |
| `<build>` | 构建产物 |
| `<test>` | 运行测试套件 |
| `<lint>` | 代码检查（提交前必须通过）|

## 架构层次

依赖方向（linter 强制执行，不得反向依赖）：

```
types → config → repo → service → runtime → api/handler
```

横切关注点（认证、日志、遥测）只能通过 `providers/` 接口进入，不得直接引用。

## 边界约定

### ✅ 可自主执行
- 新增功能、修复 Bug
- 编写和更新测试
- 更新 `docs/` 文档
- 层内重构

### ⚠️ 需确认后执行
- 修改数据库 Schema 或迁移文件
- 新增外部依赖（倾向 API 稳定的"无聊技术"）
- 修改 CI/CD 配置
- 跨层重构（涉及依赖方向调整）

### 🚫 严格禁止
- 提交密钥、Token 或凭证到仓库
- 跳过 linter（`--no-verify`、`# noqa`、`@ts-ignore` 等）
- Force push 到主分支
- 将架构决策存于 Slack/飞书（必须同步进 `docs/`）

## 知识库地图

详见 [AGENTS.md](AGENTS.md)
```
