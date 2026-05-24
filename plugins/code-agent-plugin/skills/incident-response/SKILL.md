---
name: incident-response
description: Use when a production incident occurs or when you need to create incident response procedures for a project - generates SOP documents, guides through investigation steps, and creates post-mortem templates
---

# 线上事故响应

生成事故响应 SOP，或在事故发生时引导排查步骤、生成复盘报告。

## 使用场景

- **预防**：为项目生成事故响应 SOP 文档，提前约定分级标准和响应流程
- **应急**：事故发生时，按流程引导排查，结合 server-ops 快速查日志
- **复盘**：事故处理后，生成结构化复盘报告

## 流程

### 场景 A：预防 — 生成项目 SOP

1. 读取本插件 `skills/incident-response/references/incident-sop-template.md`（路径相对于插件安装目录）
2. 使用 AskUserQuestion 收集项目信息：
   - 核心服务有哪些？各自的重要程度？
   - 目前有哪些监控告警？（如 Prometheus、云厂商告警）
   - 负责人和联系方式（写到 SOP 中）
   - 是否有现成的回滚方案？
3. 基于模板定制，生成 `docs/incident-response.md`
4. 在 CLAUDE.md 中添加引用

### 场景 B：应急 — 事故排查引导

1. 使用 AskUserQuestion 确认当前状况：
   - 什么服务出问题了？现象是什么？
   - 大约从什么时候开始？
   - 最近 24 小时有没有发布或配置变更？
2. 根据现象判断事故级别（P0~P3）
3. **优先止损**，询问是否需要生成回滚命令
4. 引导查日志（结合 server-ops 的服务器配置）：
   - 查看最近错误：`grep -iE 'error|exception|fatal' {log_path} | tail -100`
   - 查看特定时间段：`awk '/{start_time}/,/{end_time}/' {log_path}`
   - 对比正常/异常时段请求量
5. 列出可能的根因，逐一排除

### 场景 C：复盘 — 生成复盘报告

1. 使用 AskUserQuestion 收集事故信息：
   - 事故开始时间、恢复时间
   - 影响范围（用户数、功能）
   - 事故经过（时间线）
   - 根本原因
   - 改进措施
2. 基于 SOP 模板中的复盘格式生成 `docs/postmortem-{YYYY-MM-DD}-{标题}.md`

## 关键规则

- 止损优先：P0/P1 先止损再排查根因
- 不要在事故中重新造轮子：直接用 server-ops skill 加载服务器配置查日志
- 复盘报告必须有具体的改进措施和负责人，不能只写"加强测试"
- 改进措施要有截止日期和优先级
