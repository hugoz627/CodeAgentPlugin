# 学习页面 HTML 模板参考

以下是构建交互式学习页面的关键代码模式。生成时按需取用，不要完整复制。

## 1. HTML 骨架

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>项目名 源码分析</title>
  <!-- Google Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <!-- Prism.js -->
  <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet"/>
  <style>/* CSS here */</style>
</head>
<body>
  <button class="sidebar-toggle" onclick="toggleSidebar()" aria-label="Toggle">&#9776;</button>
  <nav class="sidebar" id="sidebar">
    <div class="sidebar-header">
      <h1>项目名</h1>
      <p class="subtitle">源码深度分析</p>
    </div>
    <div class="sidebar-nav" id="sidebar-nav">
      <!-- nav links generated per section -->
    </div>
  </nav>
  <main class="content">
    <section id="section-1">...</section>
    <section id="section-2">...</section>
    <!-- ... -->
  </main>
  <!-- Prism.js -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-typescript.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"></script>
  <script>/* JS here */</script>
</body>
</html>
```

## 2. CSS 变量（暗色主题）

```css
:root {
  --bg: #1a1a2e;
  --bg-sidebar: #16162a;
  --bg-card: #222244;
  --bg-code: #0d1117;
  --bg-hover: #2a2a4a;
  --text: #e2e8f0;
  --text-muted: #94a3b8;
  --accent: #61dafb;
  --accent-secondary: #7c3aed;
  --border: #333366;
  --sidebar-width: 280px;
  --collapsible-header: #333;
}

html { scroll-behavior: smooth; }
body {
  background: var(--bg);
  color: var(--text);
  font-family: 'IBM Plex Sans', sans-serif;
  margin: 0;
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

## 3. 侧边栏 CSS

```css
.sidebar {
  position: fixed; top: 0; left: 0; bottom: 0;
  width: var(--sidebar-width);
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  overflow-y: auto; z-index: 100;
  transition: transform 0.3s ease;
}

.sidebar-nav a {
  display: block; padding: 6px 20px; font-size: 0.85rem;
  color: var(--text-muted); text-decoration: none;
  border-left: 3px solid transparent;
  transition: all 0.2s;
}
.sidebar-nav a:hover { color: var(--text); background: var(--bg-hover); }
.sidebar-nav a.active {
  color: var(--accent); border-left-color: var(--accent);
  background: rgba(97, 218, 251, 0.08);
}

.content {
  margin-left: var(--sidebar-width);
  padding: 40px;
  max-width: calc(var(--sidebar-width) + 960px);
}

/* Mobile */
@media (max-width: 768px) {
  .sidebar { transform: translateX(-100%); }
  .sidebar.open { transform: translateX(0); }
  .sidebar-toggle { display: block; }
  .content { margin-left: 0; padding: 20px; }
}
```

## 4. 可折叠 Section CSS

```css
.collapsible-header {
  background: var(--collapsible-header);
  padding: 12px 16px; cursor: pointer;
  display: flex; align-items: center;
  border-radius: 6px; user-select: none;
}
.collapsible-header .arrow {
  transition: transform 0.2s; margin-right: 10px;
  color: var(--accent);
}
.collapsible-header.open .arrow { transform: rotate(90deg); }

.collapsible-body {
  max-height: 0; overflow: hidden;
  transition: max-height 0.35s ease;
}
.collapsible-body.open { max-height: 5000px; }
```

## 5. Scroll Spy JS

```javascript
// Intersection Observer-based scroll spy
const sections = document.querySelectorAll('main section[id]');
const navLinks = document.querySelectorAll('.sidebar-nav a');

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const id = entry.target.id;
      navLinks.forEach(link => {
        link.classList.toggle('active',
          link.getAttribute('href') === '#' + id);
      });
    }
  });
}, { rootMargin: '-20% 0px -75% 0px' });

sections.forEach(s => observer.observe(s));
```

## 6. 可折叠 Section JS

```javascript
document.querySelectorAll('.collapsible-header').forEach(header => {
  header.addEventListener('click', () => {
    header.classList.toggle('open');
    const body = header.nextElementSibling;
    body.classList.toggle('open');
  });
});
```

## 7. 移动端汉堡菜单 JS

```javascript
function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
}

// 点击内容区关闭侧边栏
document.querySelector('.content').addEventListener('click', () => {
  document.getElementById('sidebar').classList.remove('open');
});
```

## 8. SVG 架构图模式

```html
<svg viewBox="0 0 800 400" xmlns="http://www.w3.org/2000/svg"
     style="width:100%;max-width:800px;margin:20px auto;display:block">
  <defs>
    <marker id="arrow" viewBox="0 0 10 8" refX="9" refY="4"
            markerWidth="8" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 4 L 0 8 z" fill="var(--accent)"/>
    </marker>
  </defs>

  <!-- 节点: 圆角矩形 -->
  <rect x="50" y="50" width="140" height="50" rx="8"
        fill="var(--bg-card)" stroke="var(--accent)" stroke-width="1.5"/>
  <text x="120" y="80" text-anchor="middle" fill="var(--text)"
        font-family="JetBrains Mono" font-size="13">Module Name</text>

  <!-- 连线: 带箭头 -->
  <line x1="190" y1="75" x2="270" y2="75"
        stroke="var(--accent)" stroke-width="1.5"
        marker-end="url(#arrow)"/>
</svg>
```
