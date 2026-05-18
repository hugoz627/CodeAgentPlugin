# CodeAgentPlugin 协作说明

## 仓库定位

- 本仓库不是只服务单一工具的插件仓库，而是一个“共享能力源 + 双平台分发外壳”工程。
- 目标是让同一套能力同时服务 **Claude Code** 和 **Codex**，并尽量避免维护两份分叉逻辑。
- 仓库中已有 `skills/`、插件元数据、marketplace 元数据等多层结构；后续扩展应尽量减少重复包装。

## 为什么会有 `plugins/` 目录

- `plugins/` 目录是 **Codex marketplace 分发结构** 的一部分，不是误加的重复目录。
- 当前仓库根下的 `.agents/plugins/marketplace.json` 把插件入口指向 `./plugins/code-agent-plugin`。
- `plugins/code-agent-plugin/.codex-plugin/plugin.json` 是 Codex 插件清单；Codex 通过它识别可安装插件。
- 也就是说，这个仓库现在同时扮演两种角色：
  - 插件源码仓库
  - 本地 marketplace 根目录
- 结论：只要我们继续支持 Codex marketplace 安装，`plugins/` 目录就是合理且必要的。

## 哪些目录必须保留

如果目标是“同一个仓库同时支持 Claude Code 和 Codex”，以下几层都不能只保留其一：

- `skills/`：仓库现有能力资产。
- `.claude-plugin/`：Claude Code 的插件元数据入口。
- `.agents/plugins/marketplace.json`：Codex marketplace 入口。
- `plugins/code-agent-plugin/`：Codex 的插件分发目录。

可直接这样理解：

- `skills/` = 仓库已有能力资产
- `.claude-plugin/` = Claude 安装包装
- `.agents/plugins/marketplace.json` = Codex 市场索引
- `plugins/code-agent-plugin/` = Codex 安装包装

因此，不能只保留 `plugins/`；至少还要保留 `skills/` 与 `.agents/plugins/marketplace.json`，而如果还要支持 Claude，就还要保留 `.claude-plugin/`。

## 目录职责

- `skills/`：仓库原有能力资产。
- `commands/`：Claude 插件侧的 slash command 目录。
- `.claude-plugin/`：Claude Code 侧的插件元数据与兼容包装。
- `.agents/plugins/marketplace.json`：Codex 侧的 marketplace 清单。
- `plugins/code-agent-plugin/`：Codex 插件分发目录。
- `plugins/code-agent-plugin/commands/`：Codex 插件侧的 slash command 目录。
- `hooks/`：共享或平台可复用的 hook 资产。
- `docs/`：设计、计划、演进说明。

## 双平台支持原则

- 任何新能力，先判断它是不是共享能力；如果是，尽量避免为两个工具分别维护两套实现。
- Claude Code / Codex 的平台差异，尽量只体现在“入口层”和“元数据层”，不要复制核心内容。
- 如果一个能力需要两个平台都支持，命名、参数语义、输出结构尽量保持一致。
- 平台包装文件应当尽量薄，避免出现 Claude 一套、Codex 一套、内容长期漂移。

## Slash Command 扩展背景

- 这个仓库后续不仅要支持 plugin / marketplace 安装，还要支持一组可复用的 slash command。
- 目标不是为两个工具各写一套独立命令逻辑，而是共享一套命令语义，并分别提供双平台入口。
- Claude Code 官方支持插件根目录下的 `commands/` 作为插件命令目录；项目内命令则是 `.claude/commands/`。
- Codex 官方已确认支持 custom slash commands；当前仓库按插件分发约定，在 Codex 插件根目录下使用 `commands/` 暴露命令包装。
- 因此本仓库的实现约定是：
  - Claude 侧命令源放在仓库根 `commands/`
  - Codex 侧命令源放在 `plugins/code-agent-plugin/commands/`
  - 两边命令文件名保持一致
  - 两边命令内容保持语义一致

## 与 superpowers 流程对齐

- 当前仓库的高频开发流默认建立在 superpowers 的这条链路上：`brainstorming` -> `using-git-worktrees` -> `writing-plans` -> `subagent-driven-development` / `executing-plans` -> `requesting-code-review` / `verification-before-completion`。
- 当前仓库约定优先把实现计划放在 `docs/superpowers/plans/`，并把它视为 slash command 的默认计划发现目录。
- 如果命令需要定位“当前任务计划”，优先从当前 worktree、当前分支、当前 diff 和 `docs/superpowers/plans/` 下最近或最匹配的计划文件推断，不要默认要求用户每次手工传路径。
- `autopilot-plan` 和 `cross-tool-dispatch` 按零参数命令设计：默认直接消费当前 worktree 与当前任务上下文，而不是退化成手工 prompt 入口。
- 审查类命令在找不到显式计划参数时，也应优先检索 `docs/superpowers/plans/`，再回退到其他计划目录或当前需求说明。

## Slash Command 设计规范

新增或修改 slash command 时，遵守以下规则：

- **直接表达命令意图**：command 文件直接描述要做什么、输入什么、输出什么，不要再额外套一层无意义包装。
- **双目录同步**：新增命令时，必须同时检查：
  - `commands/`
  - `plugins/code-agent-plugin/commands/`
- **同名对齐**：Claude 与 Codex 两侧尽量使用同名命令文件，避免后续映射混乱。
- **前置元数据最小化**：命令 frontmatter 默认只放必要字段，至少包含 `description`。除非确有必要，不要堆叠宿主专属字段。
- **默认上下文优先**：高频工作流命令默认应为零参数，直接基于当前 worktree、当前 diff、当前计划和当前任务上下文推进；只有确实缺信息时才向用户要最小必要补充。
- **参数只作补充**：确实需要额外缩小范围时，才把 `$ARGUMENTS` 视为“用户补充上下文、目标、范围和约束”，不要把它设计成常规必填入口，也不要为不同宿主发明两套不同参数语义。
- **输出语言**：与用户沟通、总结、说明统一使用中文；代码变量名保持英文；日志内容保持英文；代码注释使用中文。
- **写入位置**：命令执行过程中生成的文件，应写入当前用户项目，不要写回插件目录，除非任务本身就是在维护这个插件仓库。
- **避免重复维护**：如果两个命令长期高度相似，应优先抽公共表述或模板，避免双端漂移。

## 当前 slash command 列表

当前仓库内已建立以下命令入口：

- `review-complete`：零参数执行完整收尾审查
- `autopilot-plan`：零参数读取当前计划，在 worktree 中连续实现、验证、审查、修复直到收敛
- `cross-tool-dispatch`：零参数基于当前计划拆分低耦合任务并分派给不同开发工具并行执行或审查
- `bug-sweep`：零参数扫描当前改动中的 bug、回归、边界条件和测试缺口
- `cross-review`：零参数发起另一开发工具的独立复审并汇总结论
- `stabilize-diff`：零参数对当前 diff 执行修复收敛循环

## 对新增命令的取舍

- 不要为了暴露 skill 而新增一个“只是转发 skill”的空命令。
- 新命令必须是高频、可执行、有闭环的工作流命令。
- 如果现有命令已经覆盖该工作流，就不要再造一个名称更花但语义重叠的新命令。
- 只有当一个新命令能明显减少上下文组装成本、减少人工盯盘成本或提高双工具协同时，才值得加入。

## 实施约束

- `CLAUDE.md` 作为这份协作说明的单一事实源。
- `AGENTS.md` 不单独维护，直接 symlink 到 `CLAUDE.md`，避免两份规则漂移。
- 涉及双平台行为调整时，优先同步检查：
  - `commands/`
  - `.claude-plugin/`
  - `.agents/plugins/marketplace.json`
  - `plugins/code-agent-plugin/.codex-plugin/plugin.json`
  - `plugins/code-agent-plugin/commands/`
- 若后续增加新的平台包装层，也继续遵守“共享语义一份，平台入口分离”的原则。

## 备注

- 以上关于 Codex plugin / marketplace 目录结构、Claude 插件命令目录，以及 Codex 自定义 slash command 支持边界，已在 2026-05-17 结合官方文档与本地已安装插件样例核验。
