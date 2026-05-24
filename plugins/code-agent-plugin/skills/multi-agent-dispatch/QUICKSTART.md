# Quick Start

Get multi-agent dispatch running in 3 steps.

## 1. Verify Prerequisites

```bash
# Check acpx is on PATH
command -v acpx

# Check wrapper + discovered agents
DISPATCH="$HOME/.codex/skills/multi-agent-dispatch/scripts/dispatch.sh"
bash "$DISPATCH" agents
```

No acpx? `npm install -g acpx`

## 2. Install the Skill

```bash
# Install for Codex discovery
bash skills/multi-agent-dispatch/scripts/install.sh --codex

DISPATCH="$HOME/.codex/skills/multi-agent-dispatch/scripts/dispatch.sh"
```

## 3. Try Single Dispatch

```bash
# Send a task to Codex
$DISPATCH --approve-reads --timeout 600 single codex "Review src/api/auth.ts for error handling issues"
```

## 4. Try Parallel Batch

```bash
# Three agents working simultaneously
$DISPATCH --timeout 1800 batch \
  "codex:Fix TypeScript errors in src/services/email.ts" \
  "claude:Review auth flow for security issues" \
  "gemini:Create password reset UI component"
```

Results from all three agents collected and displayed together.

## Common Commands

```bash
$DISPATCH single <agent> "<task>"              # One agent, one task
$DISPATCH batch "agent1:task1" "agent2:task2"  # Parallel execution
$DISPATCH --timeout 1800 single codex "<task>" # Override timeout for this call
$DISPATCH route src/ui/Modal.tsx "<task>"       # Auto-route by pattern
$DISPATCH list                                 # Show all sessions
$DISPATCH agents                               # Show available agents
$DISPATCH cleanup 7                            # Clean sessions >7 days old
```

## Agent Selection

| Need | Use | Why |
|------|-----|-----|
| Fast implementation | `codex` | Speed-optimized |
| Security review | `claude` | Deep reasoning |
| UI components | `gemini` | Strong at frontend |
| Architecture design | `claude` | Systemic thinking |
| Quick refactor | `codex` | Efficient patterns |

## Timeout Guidance

- `600` seconds: read-only review, analysis, architecture questions
- `1800` seconds: standard implementation or refactor work
- `3600` seconds: tasks likely to install deps or run long tests/builds

## Next Steps

- [README.md](README.md) - Full feature overview
- [INSTALL.md](INSTALL.md) - Detailed setup
- [examples/](examples/) - Real-world scenarios
- [SKILL.md](SKILL.md) - Complete documentation
