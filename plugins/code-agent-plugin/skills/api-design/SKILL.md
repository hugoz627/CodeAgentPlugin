---
name: api-design
description: Use when designing APIs for a new service or adding new endpoints - generates unified response structure, error code system, pagination conventions, and RESTful naming rules into CLAUDE.md
---

# API 设计规范生成

为项目生成统一的 API 设计规范，写入 CLAUDE.md，避免每次设计接口都重复约定响应结构和错误码。

## 流程

1. **了解项目背景**（使用 AskUserQuestion）：
   - 项目类型：纯后端 API / BFF（Backend for Frontend）/ 微服务网关
   - 主要消费方：移动端 App / Web 前端 / 第三方系统 / 内部服务
   - 是否已有错误码体系（如有，读取已有定义）

2. **读取规范模板**：
   - 读取本插件 `skills/api-design/references/api-response-template.md`（路径相对于插件安装目录）

3. **定制规范**：
   - 根据项目类型调整响应结构（如移动端可能需要 `timestamp` 字段）
   - 根据模块拆分定制错误码段位（替换模板中的示例模块）
   - 确认分页方式（普通分页 vs 游标分页）

4. **写入 CLAUDE.md**：
   - 如果 CLAUDE.md 已存在，使用 Edit 在末尾追加 `## API 设计规范` 章节
   - 如果不存在，使用 Write 创建，包含 API 规范章节
   - 章节内容包含：统一响应结构、错误码体系、分页规范、RESTful 命名规则

5. **生成错误码文件**（可选，询问用户）：
   - 如果用户需要，生成 `docs/error-codes.md` 列出所有约定的错误码

## 关键规则

- 错误码必须有模块段位划分，不能全部堆在一起
- HTTP 状态码和业务 code 的使用规则必须明确（避免混用）
- 分页方式一旦确定写入规范，同一项目统一使用
