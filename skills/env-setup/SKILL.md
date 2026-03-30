---
name: env-setup
description: Use when setting up a project's environment configuration - scans source code to discover all environment variables used, generates .env.example with descriptions, and creates local .env from the template
---

# 环境变量配置生成

扫描项目代码，发现所有环境变量读取点，生成完整的 `.env.example` 模板和配置说明。

## 流程

1. **扫描环境变量读取点**：

   使用 Grep 搜索以下模式（根据检测到的语言选择对应命令）：

   - **Python**：`os.environ`, `os.getenv`, `settings.`, `BaseSettings`
   - **Go**：`os.Getenv`, `viper.Get`, `env.Get`
   - **TypeScript/JavaScript**：`process.env.`, `import.meta.env.`
   - **通用**：搜索全大写下划线变量名（如 `DATABASE_URL`, `API_KEY`）

   收集所有变量名，去重后列出。

2. **检查已有配置文件**：
   - 使用 Glob 查找 `.env`, `.env.example`, `.env.sample`, `.env.local`
   - 如果已有 `.env.example`，使用 Read 读取，对比扫描结果找出缺失变量

3. **分类整理变量**（使用 AskUserQuestion 逐一确认不明确的变量）：

   按功能分组：
   - **服务配置**：PORT, HOST, ENV/APP_ENV
   - **数据库**：DATABASE_URL 或 DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD
   - **缓存**：REDIS_URL 或 REDIS_HOST/REDIS_PORT
   - **认证**：JWT_SECRET, JWT_EXPIRES_IN, SESSION_SECRET
   - **第三方服务**：各种 API_KEY, API_SECRET, WEBHOOK_URL
   - **对象存储**：OSS_BUCKET, OSS_ACCESS_KEY, OSS_SECRET_KEY, OSS_REGION
   - **日志**：LOG_LEVEL, LOG_FILE_PATH
   - **其他**：未能归类的变量

4. **生成 .env.example**：

   使用 Write 写入 `.env.example`，格式如下：

   ```bash
   # ============================================================
   # 服务配置
   # ============================================================
   PORT=8000
   HOST=0.0.0.0
   # 环境标识：development / staging / production
   APP_ENV=development

   # ============================================================
   # 数据库
   # ============================================================
   # PostgreSQL 连接串
   DATABASE_URL=postgresql://user:password@localhost:5432/dbname

   # ============================================================
   # 认证
   # ============================================================
   # JWT 签名密钥，生产环境必须使用随机字符串（至少 32 位）
   JWT_SECRET=your-secret-key-here
   JWT_EXPIRES_IN=7d

   # ============================================================
   # 第三方服务
   # ============================================================
   # 示例：SMS 服务 API key
   SMS_API_KEY=
   SMS_API_SECRET=
   ```

5. **生成本地 .env**（可选，询问用户）：
   - 如果用户同意，复制 `.env.example` 为 `.env`，提醒填写真实值
   - 确认 `.env` 在 `.gitignore` 中

6. **更新 CLAUDE.md**（如果存在）：
   - 使用 Edit 追加环境变量配置说明：列出各变量的含义和获取方式

## 关键规则

- `.env` 绝对不能提交到 git，每次生成后检查 `.gitignore`
- 敏感变量（密码、密钥）在 `.env.example` 中使用占位符，不写真实值
- 有默认值的变量在 `.env.example` 中写出默认值，方便新人直接使用
- 变量名必须全大写加下划线，不使用小写或驼峰
