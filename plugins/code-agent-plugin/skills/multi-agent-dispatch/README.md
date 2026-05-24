# Multi-Agent Dispatch Skill

Orchestrate tasks across multiple AI coding agents (Claude Code, Codex CLI, Gemini CLI) through the local dispatch wrapper on top of ACP/acpx.

## Quick Start

```bash
# Install into Codex skill directory
bash ./scripts/install.sh --codex

# Single agent dispatch
./scripts/dispatch.sh --timeout 1800 single codex "Implement the user authentication module"

# Parallel batch dispatch
./scripts/dispatch.sh --timeout 1800 batch \
  "codex:Implement feature X" \
  "claude:Review architecture of feature X" \
  "gemini:Design the UI for feature X"

# Auto-route by file pattern
./scripts/dispatch.sh route src/ui/Button.tsx "Add loading state"
```

## Features

- Multi-agent dispatch via ACP protocol (acpx CLI)
- Parallel execution with configurable concurrency
- Pattern-based automatic routing
- Session management and result aggregation
- Cross-model adversarial review
- Detailed logging and audit trail

Always invoke `./scripts/dispatch.sh` from the outer agent. The wrapper owns approval mode, session tracking, and `acpx` integration.

Prefer passing `--timeout <seconds>` explicitly for each call. A good starting policy is `600` for review/analysis, `1800` for standard implementation, and `3600` for dependency installs or long build/test flows.

## Directory Structure

```
multi-agent-dispatch/
├── SKILL.md                       # Main skill documentation
├── README.md                      # This file
├── QUICKSTART.md                  # 5-minute guide
├── INSTALL.md                     # Setup instructions
├── agent-dispatch-prompt.md       # Template for structured dispatch
├── dispatch-single-prompt.md      # Single agent guide
├── dispatch-batch-prompt.md       # Batch dispatch guide
├── scripts/
│   ├── dispatch.sh                # Main CLI entry point
│   ├── install.sh                 # Install into a local skill directory
│   ├── acpx-wrapper.sh            # acpx CLI wrapper with error handling
│   ├── session-manager.sh         # Session lifecycle and config
│   ├── task-coordinator.sh        # Parallel task coordination
│   └── cmux-monitor.sh            # CMUX split-pane integration
└── examples/
    ├── example-01-simple-dispatch.md
    ├── example-02-parallel-batch.md
    └── example-03-routing-patterns.md
```

## CLI Commands

| Command | Description |
|---------|-------------|
| `dispatch.sh [--timeout <seconds>] single <agent> <task>` | Dispatch to one agent |
| `dispatch.sh [--timeout <seconds>] batch <agent:task> ...` | Parallel dispatch to multiple agents |
| `dispatch.sh [--timeout <seconds>] route <filepath> <task>` | Auto-route by file pattern |
| `dispatch.sh status [session]` | Show session status |
| `dispatch.sh list` | List all sessions |
| `dispatch.sh agents` | List available agents |
| `dispatch.sh cleanup [days]` | Clean old sessions |

## Configuration

Edit `~/.multi-agent-dispatch/config.json`:

```json
{
  "version": "1.0",
  "agents": {
    "claude": { "capabilities": ["architecture", "review", "security"], "available": true },
    "codex": { "capabilities": ["implementation", "refactoring", "speed"], "available": true },
    "gemini": { "capabilities": ["frontend", "ui", "creativity"], "available": true },
    "codebuddy": { "capabilities": ["implementation", "refactoring", "acp"], "available": true },
    "claude-internal": { "capabilities": ["architecture", "review", "security"], "available": true },
    "codex-internal": { "capabilities": ["implementation", "refactoring", "speed"], "available": true },
    "gemini-internal": { "capabilities": ["frontend", "ui", "creativity"], "available": true }
  },
  "routes": [
    { "pattern": "src/ui/*", "agent": "gemini" },
    { "pattern": "src/api/*", "agent": "codex" },
    { "pattern": "src/auth/*", "agent": "claude" }
  ],
  "parallelism": 3,
  "timeout_seconds": 1800
}
```

`agents.*.available` is optional and only used to explicitly disable an agent. The dispatch layer still probes supported/configured agents automatically at runtime.

You can also add a project-local config file named `.multi-agent-dispatch.json` in the repository root, or any parent directory above the current working directory.

Config resolution order:

1. Load global config from `~/.multi-agent-dispatch/config.json`
2. Search upward for `.multi-agent-dispatch.json`
3. Merge both configs, with **project-level values overriding global values**
4. Fall back to built-in defaults for any missing keys

Example project-level override:

```json
{
  "parallelism": 5,
  "approval_mode": "approve-reads",
  "routes": [
    { "pattern": "src/ui/*", "agent": "gemini" },
    { "pattern": "src/auth/*", "agent": "claude" }
  ],
  "review_dimensions": {
    "security": { "agent": "claude-internal", "prompt": "Review for security vulnerabilities and auth/session risks" }
  }
}
```

Environment-variable overrides:

- `PROJECT_CONFIG_FILE`: use an explicit project config path instead of auto-discovery
- `PROJECT_CONFIG_FILENAME`: change the auto-discovery filename from `.multi-agent-dispatch.json`

## Installation Target

Recommended default:

```text
~/.codex/skills/multi-agent-dispatch
```

## See Also

- [SKILL.md](SKILL.md) - Full skill documentation
- [INSTALL.md](INSTALL.md) - Installation guide
- [QUICKSTART.md](QUICKSTART.md) - 5-minute getting started
- [examples/](examples/) - Real-world usage examples
