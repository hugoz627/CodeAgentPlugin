---
name: code-anatomy
version: 1.0.0
description: "源码深度分析一站式工具：分析任意项目架构 → 生成多章节文档 → 创建交互式学习页面 → 创建 PPT 分享页 → 上传飞书。用 /code-anatomy 触发，分步引导。"
---

# Code Anatomy — 源码深度解剖工具

对任意项目进行架构级源码分析，生成由浅入深的多章节文档，并输出为飞书知识库文档、交互式学习网页、PPT 风格分享页等多种格式。

## 触发方式

```
/code-anatomy [项目路径]
```

- 如果不指定路径，默认分析当前工作目录
- 支持任何语言/框架的项目

## 完整工作流

```
/code-anatomy
  │
  ├─ Step 1: 深度分析源码（必选）
  │   ├─ 1a. 探索项目结构（Agent Explore，very thorough）
  │   ├─ 1b. 生成章节大纲（提交用户确认/调整）
  │   └─ 1c. 逐章生成详细 Markdown → docs/chapters/
  │
  ├─ Step 2: 选择输出格式（引导用户选择）
  │   ├─ A. 上传飞书文档
  │   ├─ B. 生成交互式学习页面（HTML）
  │   ├─ C. 生成 PPT 分享页（HTML）
  │   └─ D. 全部
  │
  └─ Step 3: 交付 & 通知
      ├─ 汇总所有产出（路径 + 链接）
      └─ 可选：飞书消息通知
```

---

## Step 1: 深度分析源码

**此步骤必须执行，是后续所有输出的基础。**

### 1a. 探索项目

使用 Agent(subagent_type=Explore, thoroughness=very thorough) 探索以下内容：

1. **顶层目录结构** — 每个目录的职责
2. **入口文件** — 应用从哪里启动，boot sequence
3. **核心框架/引擎** — 主循环、核心类、数据流
4. **关键子系统** — 工具/插件/扩展/配置/状态管理等
5. **技术栈** — 语言、框架、构建工具、依赖
6. **设计模式** — 架构决策、关键 trade-off

### 1b. 生成章节大纲

基于探索结果，生成 5-8 章的大纲。推荐结构：

| 章节 | 建议内容 |
|------|---------|
| 第 1 章 | 全景概览 — 项目定位、技术栈、目录结构、核心模块关系 |
| 第 2 章 | 启动/入口 — Boot sequence、初始化流程、入口文件 |
| 第 3 章 | 核心机制 A — 项目最核心的子系统（如 prompt、engine、renderer） |
| 第 4 章 | 核心机制 B — 第二核心子系统（如 tools、plugins、middleware） |
| 第 5 章 | 核心机制 C — 第三核心子系统（如 query、routing、state） |
| 第 6 章 | 能力/扩展层 — Skills、commands、hooks、API 等 |
| 第 7 章 | 扩展体系 — 插件、配置、集成、部署 |
| 第 8 章 | (可选) 设计哲学 — 架构决策、trade-off、值得学习的模式 |

**必须**用 AskUserQuestion 确认大纲，用户可调整章节数量和内容。

### 1c. 逐章生成文档

读取 [analyze-guide.md](references/analyze-guide.md) 获取详细的分析方法论和质量标准。

关键要求：
- **每章必须详细**，不偷懒不缩短
- 必须包含真实的类型定义、代码片段、架构图（ASCII）
- 中英混合：解释用中文，技术术语和代码保留英文
- 输出到 `docs/chapters/ch1-xxx.md`, `ch2-xxx.md`, ...

---

## Step 2: 选择输出格式

完成 Step 1 后，用 AskUserQuestion 引导用户选择输出格式：

```
你希望生成哪些输出？
  A. 上传飞书文档（知识库目录 + 逐章文档）
  B. 交互式学习页面（HTML，带侧边栏/代码高亮/架构图）
  C. PPT 分享页（HTML，全屏翻页演示）
  D. 全部（A + B + C）
```

### 路由 A: 上传飞书文档

读取 [feishu-upload-guide.md](references/feishu-upload-guide.md) 执行：

1. 在用户的飞书个人知识库创建目录页
2. 逐章创建子文档（长文档分段：overwrite + append）
3. 转换为 Lark-flavored Markdown（callout、lark-table 等）
4. 更新目录页添加各章节链接
5. 可选：飞书消息通知用户

### 路由 B: 生成学习页面

读取 [learning-page-guide.md](references/learning-page-guide.md) 执行：

1. 生成单文件交互式 HTML（暗色主题、侧边栏、代码高亮）
2. 包含 SVG 架构图、可折叠章节、scroll spy
3. 可选生成中文版（文字中文，代码/图表英文）
4. 输出到 `docs/xxx-learning.html`

### 路由 C: 生成分享页

读取 [share-page-guide.md](references/share-page-guide.md) 执行：

1. 生成 PPT 风格全屏翻页 HTML（15-18 页）
2. 深色赛博朋克 + 玻璃拟态设计
3. 键盘/滚轮/触屏导航 + Esc 概览模式
4. 每页是真实内容（代码、图、解释），不是概要卡片
5. 输出到 `docs/xxx-share.html`

### 路由 D: 全部

按 A → B → C 顺序依次执行。B 和 C 可以并行（使用 Agent）。

---

## Step 3: 交付 & 通知

汇总所有产出：

```
已完成的输出：
- 📄 docs/chapters/ — 7 章详细 Markdown（本地）
- 📚 飞书知识库 — https://xxx（如选了 A）
- 🌐 学习页面 — docs/xxx-learning.html（如选了 B）
- 🎬 分享页面 — docs/xxx-share.html（如选了 C）
```

如果用户有飞书，询问是否需要：
1. 将 HTML 文件上传到飞书云空间
2. 通过飞书消息发送所有链接

---

## 关键约束（CRITICAL）

### 内容质量

- **绝不偷懒**：每章文档必须详细、完整，包含真实代码和解释
- **绝不缩短**：长文档分段上传，不要为了省事而精简内容
- **代码必须真实**：所有代码片段必须来自实际源码，不要编造
- **架构图必须准确**：基于实际代码结构，不要想象

### 每章最低标准

- 概述段落（项目定位或模块职责）
- 至少 2 个关键类型定义或接口（TypeScript/代码块）
- 至少 1 个完整的执行流程图（ASCII 或 SVG）
- 关键函数/方法的签名和逻辑说明
- 设计哲学/trade-off 分析

### HTML 页面标准

- 单文件自包含（CSS/JS 内联）
- Prism.js CDN 代码高亮
- 移动端适配
- prefers-reduced-motion 支持
- 不使用 emoji 作为 icon（用 SVG）
- cursor-pointer 在所有可点击元素上

### 飞书文档标准

- 使用 callout 高亮重要内容
- 合理使用 lark-table 展示结构化数据
- 代码块标注语言
- 长文档分段上传（每段 < 30KB）

---

## 参考文件索引

| 文件 | 用途 | 何时读取 |
|------|------|---------|
| [analyze-guide.md](references/analyze-guide.md) | 源码分析方法论 | Step 1 |
| [feishu-upload-guide.md](references/feishu-upload-guide.md) | 飞书上传规范 | Step 2A |
| [learning-page-guide.md](references/learning-page-guide.md) | 学习页面生成规范 | Step 2B |
| [share-page-guide.md](references/share-page-guide.md) | PPT 分享页生成规范 | Step 2C |
| [learning-page-template.md](templates/learning-page-template.md) | 学习页面 HTML/CSS/JS 模板 | Step 2B |
| [share-page-template.md](templates/share-page-template.md) | PPT 页面翻页引擎模板 | Step 2C |
