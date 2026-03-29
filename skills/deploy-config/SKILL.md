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
