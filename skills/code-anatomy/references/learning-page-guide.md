# 交互式学习页面生成规范

## 1. 设计系统

### 主题
- 暗色主题（类 VS Code）
- 背景: #1a1a2e 或 #0d1117
- 文字: #e2e8f0
- 强调色: #61dafb (cyan), #7c3aed (purple)

### 字体
- 标题/代码: JetBrains Mono (Google Fonts CDN)
- 正文: IBM Plex Sans 或 Inter (Google Fonts CDN)

### 代码高亮
- Prism.js CDN (tomorrow 主题)
- 必须引入的组件: prism-typescript, prism-json, prism-markdown
- CDN links:
  ```html
  <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet"/>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-typescript.min.js"></script>
  ```

## 2. 页面结构

### 布局
```
┌─────────────────────────────────────────┐
│ 固定侧边栏 (280px)  │  主内容区 (flex-1) │
│                      │  max-width: 900px  │
│ - 标题               │                    │
│ - 章节导航           │  各章节内容        │
│   - 子节导航         │  代码块            │
│                      │  架构图 (SVG)       │
│ (移动端: 汉堡菜单)   │  表格              │
└─────────────────────────────────────────┘
```

### 必须包含的交互功能
1. **Scroll Spy** — 滚动时自动高亮侧边栏对应章节
2. **可折叠章节** — 点击展开/收起详细内容
3. **移动端适配** — 侧边栏变为汉堡菜单
4. **平滑滚动** — 点击导航平滑滚到目标位置
5. **代码高亮** — Prism.js 自动高亮所有代码块

### 内容 Section 结构（8+节）
每个分析章节对应一个 section:
1. 全景概览
2. 启动/入口
3. 核心机制 A
4. 核心机制 B
5. 核心机制 C
6. 能力层
7. 扩展体系
8. 学习路径 + 术语表

## 3. SVG 架构图要求

### 必须的图
- 全局架构图（入口 → 核心 → 支撑层）
- 至少一个核心模块的流程图
- 至少一个数据流图

### SVG 规范
- 内联 SVG（不用外部文件）
- 用 CSS class 控制样式（方便主题适配）
- 节点用圆角矩形: `rx="8"`
- 连线用箭头: `<marker id="arrowhead">`
- 颜色: 用 CSS 变量引用主题色
- 字体: `font-family: 'JetBrains Mono', monospace`

## 4. 中英文双版本

### 翻译规则
| 翻译 | 不翻译 |
|------|--------|
| 页面标题、导航标签 | 代码块内容 |
| 段落文字、解释 | SVG 图表标签 |
| 表格描述文字 | 函数名、类名、变量名 |
| 学习路径建议 | 文件路径 |
| 术语表的解释 | 技术术语(在中文句中保持英文) |

### 生成策略
1. 先生成英文版（或中文版，取决于用户偏好）
2. 复制文件，逐一翻译文本节点
3. 保持 HTML 结构、CSS、JS 完全不变

## 5. 质量标准

### HTML
- 单文件自包含（CSS/JS 内联）
- 语义化标签: `<nav>`, `<main>`, `<section>`, `<article>`
- ARIA labels: `role="navigation"`, `aria-label` 等
- `lang` 属性: zh-CN 或 en

### CSS
- CSS 变量定义主题色
- 移动端断点: 768px
- 最小触控目标: 44x44px
- `prefers-reduced-motion` 支持

### JS
- 无外部依赖（除 Prism.js CDN）
- Intersection Observer 替代 scroll 事件
- 事件委托优于逐个绑定

### 代码
- 所有 `<pre><code>` 必须有 `class="language-xxx"`
- 代码块不超过 40 行（过长的截取关键部分）

## 6. 参考模板

关键 CSS/JS 模式见 [learning-page-template.md](../templates/learning-page-template.md)
