# PPT 分享页 HTML 模板参考

以下是构建全屏翻页演示页面的核心代码模式。

## 1. HTML 骨架

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>项目名 源码深度解析</title>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet"/>
  <style>/* CSS here */</style>
</head>
<body>
  <!-- Reading Progress Bar -->
  <div class="progress-bar" id="progress-bar"></div>

  <!-- Page Indicators (right side dots) -->
  <div class="page-indicators" id="page-indicators"></div>

  <!-- Slide Counter -->
  <div class="slide-counter">
    <span class="current" id="counter-current">1</span>
    <span class="separator">/</span>
    <span id="counter-total">17</span>
  </div>

  <!-- Slides Container -->
  <div class="slides-container" id="slides-container">
    <div class="slide" id="slide-1">
      <div class="slide-content">...</div>
    </div>
    <div class="slide" id="slide-2">
      <div class="slide-content">...</div>
    </div>
    <!-- ... more slides ... -->
  </div>

  <!-- Overview Overlay (Esc key) -->
  <div class="overview-overlay" id="overview-overlay" role="dialog">
    <p class="overview-title">按 Esc 关闭概览 · 点击幻灯片跳转</p>
    <div class="overview-grid" id="overview-grid"></div>
  </div>
  <button class="overview-close" id="overview-close" aria-label="关闭">✕</button>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-typescript.min.js"></script>
  <script>/* Slide engine JS */</script>
</body>
</html>
```

## 2. CSS 变量（深色赛博朋克）

```css
:root {
  --bg: #0a0e1a;
  --bg-card: rgba(15, 23, 42, 0.8);
  --accent-cyan: #00d4ff;
  --accent-purple: #7c3aed;
  --accent-orange: #f97316;
  --text: #e2e8f0;
  --text-muted: #94a3b8;
  --border: rgba(0, 212, 255, 0.15);
  --glow-cyan: 0 0 20px rgba(0, 212, 255, 0.25);
  --transition: 200ms ease;
  --radius: 12px;
}

html { overflow: hidden; height: 100vh; }
body {
  margin: 0; overflow: hidden; height: 100vh;
  background: var(--bg); color: var(--text);
  font-family: 'IBM Plex Sans', sans-serif;
}

@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

## 3. 幻灯片容器 CSS

```css
.slides-container {
  transition: transform 500ms cubic-bezier(0.4, 0, 0.2, 1);
  will-change: transform;
}

.slide {
  height: 100vh; width: 100vw;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden; position: relative;
}

.slide-content {
  width: 100%; max-width: 1100px;
  padding: 0 48px;
}
```

## 4. 页面指示器 CSS

```css
.page-indicators {
  position: fixed; right: 20px; top: 50%;
  transform: translateY(-50%); z-index: 90;
  display: flex; flex-direction: column; gap: 8px;
}

.page-dot {
  width: 10px; height: 10px; border-radius: 50%;
  background: rgba(255,255,255,0.2); border: none;
  cursor: pointer; transition: all 0.3s;
}
.page-dot.active {
  background: var(--accent-cyan);
  box-shadow: 0 0 8px rgba(0,212,255,0.5);
  transform: scale(1.3);
}

.slide-counter {
  position: fixed; right: 24px; bottom: 24px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem; color: var(--text-muted);
  z-index: 90;
}
.slide-counter .current { color: var(--accent-cyan); font-weight: 600; }

.progress-bar {
  position: fixed; top: 0; left: 0; height: 2px;
  background: linear-gradient(90deg, var(--accent-cyan), var(--accent-purple));
  z-index: 100; transition: width 0.3s;
}
```

## 5. 概览模式 CSS

```css
.overview-overlay {
  display: none; position: fixed; inset: 0;
  background: rgba(5,8,18,0.95); z-index: 200;
  flex-direction: column; align-items: center;
  padding: 40px 20px; overflow-y: auto;
}
.overview-overlay.active { display: flex; }

.overview-grid {
  display: grid; grid-template-columns: repeat(4, 1fr);
  gap: 16px; max-width: 1000px; width: 100%;
}

.overview-thumb {
  aspect-ratio: 16/9; background: var(--bg-card);
  border: 1px solid var(--border); border-radius: 8px;
  cursor: pointer; padding: 12px;
  transition: all 0.2s;
}
.overview-thumb:hover { border-color: var(--accent-cyan); transform: scale(1.03); }
.overview-thumb.current { border-color: var(--accent-cyan); box-shadow: var(--glow-cyan); }
```

## 6. 幻灯片引擎 JS（核心）

```javascript
const slidesContainer = document.getElementById('slides-container');
const pageIndicatorsEl = document.getElementById('page-indicators');
const counterCurrent = document.getElementById('counter-current');
const counterTotal = document.getElementById('counter-total');
const overviewOverlay = document.getElementById('overview-overlay');
const overviewGrid = document.getElementById('overview-grid');
const progressBar = document.getElementById('progress-bar');

const slides = document.querySelectorAll('.slide');
const TOTAL = slides.length;
let currentSlide = 0;
let isAnimating = false;
let overviewOpen = false;

counterTotal.textContent = TOTAL;

// 每页标题（用于概览模式）
const slideTitles = [
  '封面', '项目介绍', '核心数据', '架构总览',
  // ... 按实际幻灯片填充
];

// 构建页面指示器圆点
for (let i = 0; i < TOTAL; i++) {
  const dot = document.createElement('button');
  dot.className = 'page-dot' + (i === 0 ? ' active' : '');
  dot.setAttribute('aria-label', `跳转到第 ${i + 1} 页`);
  dot.addEventListener('click', () => goToSlide(i));
  pageIndicatorsEl.appendChild(dot);
}

// 构建概览缩略图
for (let i = 0; i < TOTAL; i++) {
  const thumb = document.createElement('div');
  thumb.className = 'overview-thumb' + (i === 0 ? ' current' : '');
  thumb.innerHTML = `
    <div style="font-size:1.5rem;font-weight:700;color:var(--accent-cyan)">${String(i+1).padStart(2,'0')}</div>
    <div style="font-size:0.75rem;color:var(--text-muted);margin-top:4px">${slideTitles[i] || ''}</div>
  `;
  thumb.addEventListener('click', () => { goToSlide(i); toggleOverview(false); });
  overviewGrid.appendChild(thumb);
}

function goToSlide(n, animate = true) {
  if (n < 0 || n >= TOTAL) return;
  if (isAnimating && animate) return;
  currentSlide = n;

  if (animate) {
    isAnimating = true;
    setTimeout(() => { isAnimating = false; }, 520);
  }

  slidesContainer.style.transition = animate
    ? 'transform 500ms cubic-bezier(0.4, 0, 0.2, 1)'
    : 'none';
  slidesContainer.style.transform = `translateY(-${currentSlide * 100}vh)`;

  updateUI();
}

function updateUI() {
  counterCurrent.textContent = currentSlide + 1;
  progressBar.style.width = ((currentSlide + 1) / TOTAL * 100) + '%';

  pageIndicatorsEl.querySelectorAll('.page-dot').forEach((dot, i) => {
    dot.classList.toggle('active', i === currentSlide);
  });
  overviewGrid.querySelectorAll('.overview-thumb').forEach((thumb, i) => {
    thumb.classList.toggle('current', i === currentSlide);
  });
}

function nextSlide() { goToSlide(currentSlide + 1); }
function prevSlide() { goToSlide(currentSlide - 1); }

function toggleOverview(force) {
  overviewOpen = force !== undefined ? force : !overviewOpen;
  overviewOverlay.classList.toggle('active', overviewOpen);
}
```

## 7. 导航事件处理 JS

```javascript
// 键盘导航
document.addEventListener('keydown', (e) => {
  if (overviewOpen) {
    if (e.key === 'Escape') toggleOverview(false);
    return;
  }
  switch (e.key) {
    case 'ArrowDown': case 'ArrowRight': case ' ':
      e.preventDefault(); nextSlide(); break;
    case 'ArrowUp': case 'ArrowLeft':
      e.preventDefault(); prevSlide(); break;
    case 'Escape':
      toggleOverview(true); break;
  }
});

// 滚轮导航（防抖 700ms）
let wheelCooldown = false;
document.addEventListener('wheel', (e) => {
  if (overviewOpen) return;
  e.preventDefault();
  if (wheelCooldown) return;
  wheelCooldown = true;
  setTimeout(() => { wheelCooldown = false; }, 700);
  if (e.deltaY > 0) nextSlide();
  else if (e.deltaY < 0) prevSlide();
}, { passive: false });

// 触屏滑动导航
let touchStartY = 0;
document.addEventListener('touchstart', (e) => {
  touchStartY = e.touches[0].clientY;
}, { passive: true });
document.addEventListener('touchend', (e) => {
  if (overviewOpen) return;
  const dy = touchStartY - e.changedTouches[0].clientY;
  if (Math.abs(dy) > 40) {
    if (dy > 0) nextSlide(); else prevSlide();
  }
}, { passive: true });

// 概览关闭
document.getElementById('overview-close').addEventListener('click', () => toggleOverview(false));
overviewOverlay.addEventListener('click', (e) => {
  if (e.target === overviewOverlay) toggleOverview(false);
});

// 初始化
goToSlide(0, false);
if (window.Prism) window.addEventListener('load', () => Prism.highlightAll());
```

## 8. 单页布局模式参考

### 封面页
```html
<div class="slide">
  <div class="slide-content" style="text-align:center">
    <h1 style="font-size:3rem;background:linear-gradient(135deg,var(--accent-cyan),var(--accent-purple));-webkit-background-clip:text;color:transparent">
      项目名 源码深度解析
    </h1>
    <p style="color:var(--text-muted);margin-top:16px">副标题描述</p>
    <p style="color:var(--text-muted);font-size:0.8rem;margin-top:40px">按方向键或滚动翻页 · Esc 查看概览</p>
  </div>
</div>
```

### 双栏页（左代码右解释）
```html
<div class="slide">
  <div class="slide-content">
    <h2>标题</h2>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:32px;margin-top:24px">
      <pre><code class="language-typescript">// code here</code></pre>
      <div>
        <p>解释文字...</p>
        <ul><li>要点 1</li><li>要点 2</li></ul>
      </div>
    </div>
  </div>
</div>
```

### 卡片网格页
```html
<div class="slide">
  <div class="slide-content">
    <h2>标题</h2>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-top:24px">
      <div style="background:var(--bg-card);padding:20px;border-radius:var(--radius);border:1px solid var(--border)">
        <h3 style="color:var(--accent-cyan)">卡片标题</h3>
        <p style="color:var(--text-muted);font-size:0.9rem">卡片内容</p>
      </div>
      <!-- more cards -->
    </div>
  </div>
</div>
```
