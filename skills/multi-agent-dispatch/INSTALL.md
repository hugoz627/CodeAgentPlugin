# Installation Guide

## Prerequisites

| Requirement | How to Check | Install |
|-------------|-------------|---------|
| **acpx CLI** | `acpx --version` | `npm install -g acpx` |
| **jq** | `jq --version` | `brew install jq` (macOS) |
| **Bash 3.2+** | `bash --version` | Pre-installed on macOS/Linux |
| **At least one agent CLI** | See below | See below |

### Agent CLIs

Install at least one:

```bash
# Codex CLI
npm install -g @openai/codex-cli

# Gemini CLI
npm install -g @google/gemini-cli

# Claude Code - if running inside Claude Code, already available
```

## Installation

### Option 1: Install for Codex discovery

```bash
# From this repository root
bash skills/multi-agent-dispatch/scripts/install.sh --codex
```

Default install target:

```text
~/.codex/skills/multi-agent-dispatch
```

### Option 2: Manual copy to any location

```bash
# From the CoCliSkill project
SKILL_SRC="$PWD/skills/multi-agent-dispatch"
SKILL_DST="$HOME/.codex/skills/multi-agent-dispatch"

cp -r "$SKILL_SRC" "$SKILL_DST"
chmod +x "$SKILL_DST/scripts/"*.sh
```

## Setup

### 1. Initialize configuration

```bash
# Creates ~/.multi-agent-dispatch/config.json with defaults
SKILL_DIR="$HOME/.codex/skills/multi-agent-dispatch"
bash "$SKILL_DIR/scripts/session-manager.sh" init_config
```

### 2. Customize routing (optional)

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

Set `"available": false` only when you want to explicitly disable an otherwise auto-detected agent.

### 3. Verify installation

```bash
SKILL_DIR="$HOME/.codex/skills/multi-agent-dispatch"

# Smoke test CLI entry
bash "$SKILL_DIR/scripts/dispatch.sh" help

# Probe discovered agents through the wrapper
bash "$SKILL_DIR/scripts/dispatch.sh" agents
```

If you are validating from the source repo, run:

```bash
bash tests/test-acpx-wrapper.sh
bash tests/test-session-manager.sh
bash tests/test-task-coordinator.sh
bash tests/test-dispatch.sh
```

### 4. Test a live dispatch (if agents available)

```bash
bash "$SKILL_DIR/scripts/dispatch.sh" single codex "Say hello"
```

## Troubleshooting

### "acpx: command not found"

```bash
npm install -g acpx
# Or check PATH
export PATH="$HOME/.npm/bin:$PATH"
```

### "jq: command not found"

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

### "Agent codex is not available"

1. Install the CLI: `npm install -g @openai/codex-cli`
2. Set up auth: `codex setup` or set API key env var
3. Re-run discovery: `bash "$HOME/.codex/skills/multi-agent-dispatch/scripts/dispatch.sh" agents`
4. If intentionally disabled, set `.agents.codex.available` to `true` in `~/.multi-agent-dispatch/config.json`

### "Permission denied" on scripts

```bash
SKILL_DIR="$HOME/.codex/skills/multi-agent-dispatch"
chmod +x "$SKILL_DIR/scripts/"*.sh
```

### Sessions directory issues

```bash
mkdir -p ~/.multi-agent-dispatch/{sessions,logs}
```
