# <项目名>

> 这是地图，不是说明书。按需深入对应文档。目标 < 150 行。

## Project Overview

<技术栈 + 版本 + 核心功能 + 特殊架构决策（如"选用 X 而非 Y 的原因"）>

## Key Commands

| 命令 | 说明 |
|------|------|
| `<install>` | 安装依赖 |
| `<dev>` | 启动开发环境 |
| `<build>` | 构建产物 |
| `<test>` | 运行测试（加 --coverage 查看覆盖率）|
| `<typecheck>` | 类型检查 |
| `<lint>` | 代码检查（提交前必须通过）|

## Architecture

依赖方向（linter 强制执行，不得反向依赖）：

```
types → config → repo → service → runtime → api/handler
```

横切关注点（认证、日志、遥测）只能通过 `providers/` 接口进入，不得直接引用。

**知识库地图：**

| 文档 | 内容 |
|------|------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | 模块分层和依赖方向详解 |
| [docs/design-docs/core-beliefs.md](docs/design-docs/core-beliefs.md) | 核心决策原则 |
| [docs/design-docs/index.md](docs/design-docs/index.md) | 设计文档索引 |
| [docs/product-specs/index.md](docs/product-specs/index.md) | 产品规格索引 |
| [docs/exec-plans/active/](docs/exec-plans/active/) | 进行中的执行计划 |
| [docs/exec-plans/completed/](docs/exec-plans/completed/) | 已完成（决策历史）|

## Conventions

**代码注释**：使用中文，变量/函数名使用英文。

**日志**：日志内容使用英文；核心路径入口/出口、所有异常路径必须打日志；后端和客户端都需要文件日志。

**常量与配置**：魔法数字/字符串提取为具名常量或枚举；所有配置值（URL、端口、密钥）从环境变量读取，禁止硬编码。

**安全**：输入校验在边界层（api/handler）统一处理；数据库必须参数化查询；对外错误信息不暴露内部细节。

**单元测试**：
- 优先通过公开接口测试行为；若私有方法含重要逻辑，应将其提取为独立纯函数/模块再直接测，不用反射/强制访问绕过可见性
- Mock 只在层边界（service 测试 mock repo，不 mock service 内部逻辑）
- AAA 结构：Arrange / Act / Assert，用空行或注释分隔
- 测试数据用工厂函数/fixtures，不散落在用例中
- 覆盖率目标：核心业务层 ≥ 80%

**Git 提交**：`type(scope): 中文描述`（Conventional Commits）
```
feat(auth): 添加 JWT 刷新令牌接口
fix(order): 修复重复扣款问题
```
类型：`feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `perf` / `ci`

## Code Style

> 只记录与常见约定不同的反直觉规则。

<在此插入 1 个代表性代码片段，或用 1-2 句话说明最重要的非显而易见规范>

## Testing

<测试框架> | 目标覆盖率 <N>%

```bash
# 完整测试命令（含覆盖率）
<test command with coverage>
```

声称任务完成前必须运行测试并确认通过，不能凭感觉判断。

## Boundaries

### ✅ Always（可自主执行）
- 新增功能、修复 Bug
- 编写和更新测试
- 更新 `docs/` 文档
- 层内重构

### ⚠️ Ask First（需确认后执行）
- 修改数据库 Schema 或迁移文件
- 新增外部依赖（倾向 API 稳定的"无聊技术"）
- 修改 CI/CD 配置
- 跨层重构（涉及依赖方向调整）

### 🚫 Never（严格禁止）
- 提交密钥、Token 或凭证
- 跳过 linter（`--no-verify`、`# noqa`、`@ts-ignore` 等）
- Force push 到主分支
- 将架构决策存于 Slack/飞书（必须同步进 `docs/`）
