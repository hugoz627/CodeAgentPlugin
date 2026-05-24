<!-- 本文件是 Claude Code 专属配置。通用规范（命令、架构、边界）见 @AGENTS.md -->

# <项目名>

## 语言约定

| 场景 | 语言 |
|------|------|
| 代码注释 | 中文 |
| 变量/函数名 | 英文 |
| Git Commit 描述 | 中文 |
| 日志内容（log） | 英文 |

## Git 提交规范

格式：`type(scope): 中文描述`

```
feat(auth): 添加 JWT 刷新令牌接口
fix(order): 修复重复扣款问题
refactor(user): 重构用户服务分层结构
```

类型：`feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `perf` / `ci`

- scope 用英文，描述用中文
- 破坏性变更加 `!`：`feat(api)!: 移除旧版登录接口`

## 自我验证循环

完成实现后，不能直接认为没问题——必须按以下顺序验证：

1. **Plan**：读任务、扫代码库、制定计划，想好如何验证
2. **Build**：实现时同步写测试（含边界情况）
3. **Verify**：运行测试，对照原始需求检查（不是对照自己的代码）
4. **Fix**：分析错误，回看原始规格，修复后重新 Verify

## Claude 专属禁止事项

- 不声称任务完成，除非测试已运行并通过
- 不手动绕过 linter（禁止 `--no-verify`、`# noqa` 等）
- 不在仓库外存储架构决策（Slack/飞书 → `docs/`）
- 不引入训练数据中不熟悉的新依赖（Ask First）

## 开始新任务

1. 先读 [@AGENTS.md](AGENTS.md) 了解知识库地图
2. 查看 [docs/exec-plans/active/](docs/exec-plans/active/) 确认当前任务
3. 提 PR 前：运行所有 lint 和测试，更新相关文档
