# Single Agent Dispatch Template

## Usage

Delegate a focused task to one specialized agent via the dispatch wrapper.

```bash
# Always use the dispatch CLI (do not call acpx directly from the outer agent)
./scripts/dispatch.sh single <agent> "<task prompt>"
./scripts/dispatch.sh --approve-reads single <agent> "<task prompt>"
./scripts/dispatch.sh --approve-reads --timeout 600 single <agent> "<task prompt>"
```

## Agent Selection Guide

| Task Type | Recommended Agent | Why |
|-----------|------------------|-----|
| Implementation | codex | Fast, focused execution |
| Security review | claude | Deep reasoning, catches subtle issues |
| Architecture design | claude | Long context, systemic thinking |
| Frontend/UI | gemini | Strong at visual, creative work |
| Code refactoring | codex | Efficient, pattern-aware |
| Documentation | claude | Clear writing, comprehensive |
| Quick fix | codex | Speed-optimized |

## Steps

1. **Choose agent** based on task type (see table above)
2. **Write clear prompt** with specific requirements and constraints
3. **Dispatch** via `./scripts/dispatch.sh` with an explicit approval flag when needed
4. **Choose timeout** explicitly for the task size whenever possible
5. **Review output** - agent reports what it did and any concerns
6. **Verify** changes match expectations

## Approval Modes

| Mode | Use When |
|------|----------|
| `./scripts/dispatch.sh --approve-all ...` | Trusted tasks, implementation work |
| `./scripts/dispatch.sh --approve-reads ...` | Review/analysis (read-only execution) |
| `./scripts/dispatch.sh --deny-all ...` | Pure analysis, no file changes allowed |

## Timeout Guidance

| Example | Use When |
|---------|----------|
| `./scripts/dispatch.sh --timeout 600 ...` | Reviews, audits, read-only analysis |
| `./scripts/dispatch.sh --timeout 1800 ...` | Normal implementation or refactor tasks |
| `./scripts/dispatch.sh --timeout 3600 ...` | Long-running builds, installs, or repair loops |
