---
name: harness-init
version: 2.0.0
description: "新建或改造项目时，通过5个引导式问题了解项目特征，一键生成 AI 编程友好的项目脚手架 + 基建文件（CLAUDE.md、AGENTS.md、.cursor/rules/、CODEBUDDY.md、架构约束 linter、docs/ 知识库）。支持 TypeScript、Python/FastAPI、Go、Rust/Tauri、Flutter。同时支持 Claude Code、Codex、Cursor、CodeBuddy。"
---

# harness-init

## 触发后立即执行：检测模式

运行以下检测，确定走哪个流程：

```bash
PROJ_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJ_ROOT" 2>/dev/null

has_agents=false; [ -f AGENTS.md ] && has_agents=true
has_claude=false; [ -f CLAUDE.md ] && has_claude=true
has_cursor=false; [ -d .cursor/rules ] && has_cursor=true
has_codebuddy=false; [ -f CODEBUDDY.md ] && has_codebuddy=true
```

- **全部不存在** → 新建模式（走完整 5 问对话）
- **部分存在** → 补全模式（跳过已有部分，只生成缺失文件）
- **AGENTS.md + CLAUDE.md 都存在** → 健康检查模式

---

## 新建模式：5 个对话问题

**严格按顺序，每次只问一个问题，等用户回答后再问下一个。**

### 问题 1：语言/框架
"项目使用哪种语言/框架？
- A. TypeScript（Node.js API / 全栈）
- B. Python（FastAPI + Poetry）
- C. Go
- D. Rust（Tauri 桌面应用 / CLI 工具）
- E. Flutter（移动/桌面应用）"

### 问题 2：项目类型
"项目类型是？
- A. API 服务（后端接口）
- B. 全栈应用（前后端一体）
- C. CLI 工具
- D. 库/SDK
- E. Tauri 桌面应用（Rust 后端 + Web 前端）
- F. 移动端应用（Flutter 专属）"

### 问题 3：团队规模
"团队规模？
- A. Solo（只有你）
- B. 小团队（2-5 人）
- C. 大团队（5 人以上）"

### 问题 4：AI 工作模式
"AI 主要用来做什么？
- A. 写新功能（主要新增代码）
- B. 修 Bug（主要调试和修复）
- C. 全自动（CI 中自动触发 agent）"

### 问题 5：扩展配置
"需要哪些扩展配置？
- A. 容器部署（Dockerfile + docker-compose + GitHub Actions 镜像发布）
- B. 本地可观测性（日志/指标 docker-compose，可被 AI 查询）
- C. 两者都需要
- D. 跳过"

---

## 生成阶段

收集完 5 个回答后，按以下顺序生成文件。

**变量替换说明：**
- `<项目名>` → 当前目录名（basename of cwd），保持原始大小写
- `<project>` → 仅 Python 脚手架使用，将项目名转为 snake_case

生成任何文件前，先检查是否已存在；若已存在，询问用户"文件 {文件名} 已存在，是否覆盖？"得到确认后再写入。

### Step 1：读取模板文件

用 Read 工具读取以下模板（路径相对于本 SKILL.md 所在目录）：
- `references/claude-md-template.md`
- `references/agents-md-template.md`
- `references/cursor-rules-template.md`
- `references/codebuddy-template.md`
- `references/architecture-md-template.md`
- `references/docs-structure.md`
- `references/scaffold-<language>.md`（如 scaffold-typescript.md）
- `references/ci-templates.md`
- 若问题 5 选 A 或 C：`references/deploy-templates.md`

### Step 2：生成 Layer 0（多 AI 工具配置）

生成以下文件（所有 AI 工具的入口）：

1. **`AGENTS.md`**（通用层，覆盖 Codex/Cursor/Aider/OpenHands）
   - 按黄金六节法：Overview / Key Commands / Architecture / Code Style / Testing / Boundaries
   - 目标 < 150 行，作为地图指向 docs/

2. **`CLAUDE.md`**（Claude Code 专属）
   - 开头注释声明通用规范见 @AGENTS.md
   - 包含：语言约定、自我验证循环、Claude 专属禁止事项

3. **`.cursor/rules/core.mdc`**（Cursor - Always Apply，< 200 词）
   - 核心约束：技术栈、架构层次、禁止事项

4. **`.cursor/rules/<lang>.mdc`**（Cursor - Auto Attached，按文件 glob）
   - 根据问题 1 的语言选择对应模板（typescript/python/go/rust/flutter）

5. **`CODEBUDDY.md`**（CodeBuddy 专属）
   - 项目概述、关键命令、架构约束、边界约定

### Step 3：生成 Layer 1（AI 知识库）

1. `ARCHITECTURE.md`
2. `docs/design-docs/index.md`、`docs/design-docs/core-beliefs.md`
3. `docs/exec-plans/active/.gitkeep`、`docs/exec-plans/completed/.gitkeep`
4. `docs/product-specs/index.md`
5. `docs/references/.gitkeep`

### Step 4：生成 Layer 2（架构约束）

根据语言生成对应 linter 配置文件（见 scaffold-<language>.md）+ `.editorconfig`、`ci/lint-docs.yml`、`ci/lint-arch.yml`。

`.editorconfig`：2 空格缩进、LF 换行、UTF-8 编码、移除尾部空格、文件末尾换行。

**ci/lint-docs.yml 新增检查**：
- 检查 `.cursor/rules/core.mdc` 存在
- 检查 `CODEBUDDY.md` 存在
- 检查 AGENTS.md 行数 ≤ 150 行

### Step 5：生成 Layer 3（项目脚手架）

根据语言 + 项目类型，按 scaffold-<language>.md 模板生成对应目录结构和初始文件。

所有初始文件仅包含注释说明层和依赖方向。

**Tauri 项目（Rust + TypeScript）**：同时读取 scaffold-rust.md 和 scaffold-typescript.md，生成前后端混合结构。

### Step 6：生成 Layer 4（部署配置，按问题 5）

若问题 5 选 A 或 C，根据语言从 `references/deploy-templates.md` 生成：
- `Dockerfile`（多阶段构建）
- `docker-compose.yml`（本地开发）
- `.github/workflows/build-push.yml`（构建并推送镜像）

### Step 7：生成 Layer 5（可观测性，按问题 5）

若问题 5 选 B 或 C，从 `references/ci-templates.md` 生成：
- `docker-compose.observability.yml`（vector + victoria-logs + victoria-metrics）

### Step 8：Skill 推荐配置

所有文件生成完毕后，执行 skill 扫描并向用户推荐。

**执行步骤：**

1. 扫描用户已安装 skill：`ls ~/.claude/skills/`
2. 检查 AGENTS.md 是否已存在 `## 推荐 Skill` 节（grep 判断）
3. 根据项目语言和类型，从下表筛选"已安装"的 skill
4. 对比缺失项，若有推荐 skill 尚未在 AGENTS.md 中列出，询问用户：
   > "以下 skill 与当前项目匹配且已安装，是否添加到 AGENTS.md 的推荐列表？（Y/n）"
   > 列出具体 skill 名和用途
5. 用户确认后，在 AGENTS.md 末尾追加 `## 推荐 Skill` 节

**推荐 Skill 映射表（按优先级排列）：**

| 适用场景 | Skill | 调用方式 | 说明 |
|---------|-------|---------|------|
| 通用（所有项目）| `coding:test` | `/coding:test` | 生成单元测试 |
| 通用 | `coding:review` | `/coding:review` | 代码审查 |
| 通用 | `debug:fix` | `/debug:fix` | 分析并修复 Bug |
| 通用 | `git:commit` | `/git:commit` | 生成规范 Git 提交 |
| 通用 | `git:pr` | `/git:pr` | 生成 PR 描述 |
| API 服务 / 全栈 | `coding:refactor` | `/coding:refactor` | 重构业务逻辑 |
| API 服务 / 全栈 | `debug:analyze` | `/debug:analyze` | 深度问题分析 |
| 大团队（5人+）| `coding:review-by-codex` | `/coding:review-by-codex` | 多工具交叉审查 |
| 大团队 | `review-complete` | `/review-complete` | 需求完成后全面审查 |
| 文档需求 | `docs:generate` | `/docs:generate` | 生成 API 文档 |

**AGENTS.md 追加格式：**

```markdown
## 推荐 Skill

| 场景 | Skill | 调用方式 |
|------|-------|---------|
| 生成单元测试 | coding:test | `/coding:test` |
| 代码审查 | coding:review | `/coding:review` |
| 分析并修复 Bug | debug:fix | `/debug:fix` |
| 生成 Git 提交信息 | git:commit | `/git:commit` |
| 生成 PR 描述 | git:pr | `/git:pr` |
```

---

## 补全模式

检测已有文件列表，只询问缺失部分所需的问题（最少 1 个），只生成缺失文件，**不覆盖已有文件**：

```bash
ls CLAUDE.md AGENTS.md CODEBUDDY.md ARCHITECTURE.md \
   .cursor/rules/core.mdc \
   docs/design-docs/core-beliefs.md \
   docs/exec-plans/active/ ci/lint-docs.yml 2>/dev/null
```

文件补全完成后，**同样执行 Step 8 Skill 推荐配置**：扫描已安装 skill，检查 AGENTS.md 是否已有推荐节，若缺失则询问用户是否补充。

---

## 健康检查模式

当 CLAUDE.md 和 AGENTS.md 都已存在时，输出以下报告：

```
## harness-init 健康检查报告

### Layer 0：多 AI 工具配置
- [x/o] AGENTS.md（行数：N 行，目标：≤ 150 行）
- [x/o] CLAUDE.md
- [x/o] .cursor/rules/core.mdc
- [x/o] .cursor/rules/<lang>.mdc
- [x/o] CODEBUDDY.md

### Layer 1：AI 知识库
- [x/o] ARCHITECTURE.md
- [x/o] docs/design-docs/core-beliefs.md
- [x/o] docs/exec-plans/active/
- [x/o] docs/product-specs/index.md

### Layer 2：架构约束
- [x/o] .editorconfig
- [x/o] ci/lint-docs.yml
- [x/o] ci/lint-arch.yml
- [x/o] <语言对应 linter 配置>

### Layer 4：部署配置（可选）
- [x/o] Dockerfile
- [x/o] docker-compose.yml
- [x/o] .github/workflows/build-push.yml

### Layer 6：Skill 配置
- [x/o] AGENTS.md 包含 `## 推荐 Skill` 节
- [x/o] 推荐 skill 均已安装（列出：已安装 / 未安装）

### 改进建议
<列出缺失项、AGENTS.md 超行问题、以及缺失的 AI 工具配置、未安装的推荐 skill>

> 健康检查模式同样运行 Step 8 Skill 推荐配置逻辑：若 AGENTS.md 缺少推荐节或推荐 skill 有变化，询问用户是否补充/更新。
```

---

## 完成后输出摘要

生成完毕后输出摘要，包含：

- **已生成文件**：按 Layer 0/1/2/3/4/5 分组列出
- **跳过（已存在）**：列出未覆盖的文件
- **AI 工具支持状态**：Claude Code / Codex / Cursor / CodeBuddy
- **Skill 配置状态**：已添加到 AGENTS.md 的推荐 skill 列表（或"用户跳过"）
- **下一步**：
  1. 打开 `AGENTS.md`，填入项目真实的技术栈、命令和反直觉规范
  2. 打开 `docs/design-docs/core-beliefs.md`，填入项目特有的核心原则
  3. 更新 `.cursor/rules/<lang>.mdc` 中的状态管理方案（Flutter）或特殊规范
  4. 运行 lint 验证配置（见各 scaffold 模板末尾的命令）
  5. 将所有生成文件提交到 git
