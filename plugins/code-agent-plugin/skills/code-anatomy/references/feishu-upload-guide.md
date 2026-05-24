# 飞书文档上传规范

## 1. 前置条件

- lark-cli 已安装且已认证（`lark-cli auth login`）
- 需要调用 lark-doc skill 的能力

## 2. 创建目录页

在用户的飞书个人知识库创建目录文档：

```bash
lark-cli docs +create \
  --title "项目名 源码深度分析" \
  --wiki-space my_library \
  --markdown "$(cat /tmp/toc.md)"
```

目录页内容模板：
```markdown
## 项目名 源码深度分析系列

<callout emoji="📚" background-color="light-blue">
本系列共 N 章，由浅入深分析项目架构。
</callout>

---

### 章节导航

| 章节 | 标题 | 核心内容 |
|------|------|---------|
| 第 1 章 | xxx | xxx |
| ... | ... | ... |
```

记录返回的 `doc_url` 中的 wiki token，用于后续创建子文档。

## 3. 逐章创建子文档

对每一章：

```bash
lark-cli docs +create \
  --title "第N章：章节标题" \
  --wiki-node <目录页wiki_token> \
  --markdown "$(cat /tmp/chN_part1.md)"
```

### 长文档分段策略

飞书 API 对单次请求有大小限制。对于长章节：

1. 将内容分为 2-3 个部分，每部分 < 30KB
2. 第一部分用 `docs +create` 创建文档
3. 后续部分用 `docs +update --mode append` 追加

```bash
# 创建（第一部分）
lark-cli docs +create --title "第N章：标题" --wiki-node <token> \
  --markdown "$(cat /tmp/chN_part1.md)"

# 追加（后续部分），使用返回的 doc_id
lark-cli docs +update --doc "<doc_id>" --mode append \
  --markdown "$(cat /tmp/chN_part2.md)"
```

## 4. Lark-flavored Markdown 转换要点

### 标准 Markdown → Lark 对照

| 标准 Markdown | Lark-flavored | 说明 |
|--------------|---------------|------|
| > 引用 | `<callout emoji="💡" background-color="light-blue">` | 重要提示用 callout |
| 复杂表格 | `<lark-table>` | 单元格内有列表/代码时必须用 |
| 并列展示 | `<grid cols="2"><column>` | 对比内容用分栏 |
| 代码块 | ` ``` ` 不变 | 标注语言 |

### callout 常用配色

| 场景 | emoji | background-color |
|------|-------|-----------------|
| 提示 | 💡 | light-blue |
| 警告 | ⚠️ | light-yellow |
| 成功 | ✅ | light-green |
| 重要 | 📌 | light-purple |

### 转换注意事项

- 去掉顶级标题（`# Chapter N: xxx`），因为 --title 已设置
- 下划线在飞书中可能被转义，技术术语中的 `_` 不需要特殊处理
- ASCII 图放在代码块中
- 图片用 `<image url="..." />` 或上传后引用

## 5. 更新目录页

所有子文档创建后，更新目录页添加链接：

```bash
lark-cli docs +update --doc "<目录doc_id>" --mode append \
  --markdown "### 各章节链接
- [第1章：标题](飞书链接)
- [第2章：标题](飞书链接)
..."
```

## 6. 飞书消息通知（可选）

使用 lark-im skill 发送消息：

```bash
lark-cli im +messages-send \
  --user-id <user_open_id> \
  --markdown "文档已就绪！
目录页：<链接>
第1章：<链接>
..." \
  --as bot
```

获取用户 open_id：
```bash
lark-cli contact +get-user
```
