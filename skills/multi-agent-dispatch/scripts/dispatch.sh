#!/bin/bash
# dispatch.sh - Main CLI entry point for multi-agent dispatch
#
# Usage:
#   dispatch.sh single <agent> <task>
#   dispatch.sh batch "agent1:task1" "agent2:task2" ...
#   dispatch.sh route <filepath> <task>
#   dispatch.sh status [session-id]
#   dispatch.sh list
#   dispatch.sh cleanup [days]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/acpx-wrapper.sh"
source "$SCRIPT_DIR/session-manager.sh"
source "$SCRIPT_DIR/cmux-monitor.sh"
source "$SCRIPT_DIR/visual-monitor.sh"
source "$SCRIPT_DIR/task-coordinator.sh"

# Initialize config on first run
init_config
load_runtime_config

usage() {
    cat << 'EOF'
Multi-Agent Dispatch - Orchestrate tasks across AI coding agents

Usage:
  dispatch.sh [--cmux] [--visual <backend>] [--visual-split|--no-visual-split] [--approve-all|--approve-reads|--deny-all] [--timeout <seconds>] single <agent> <task>
  dispatch.sh [--cmux] [--visual <backend>] [--visual-split|--no-visual-split] [--approve-all|--approve-reads|--deny-all] [--timeout <seconds>] batch <agent:task> ...
  dispatch.sh [--cmux] [--visual <backend>] [--visual-split|--no-visual-split] [--approve-all|--approve-reads|--deny-all] [--timeout <seconds>] batch-json <json>
  dispatch.sh [--cmux] [--visual <backend>] [--visual-split|--no-visual-split] [--approve-all|--approve-reads|--deny-all] [--timeout <seconds>] auto-split <task>
  dispatch.sh [--cmux] [--visual <backend>] [--visual-split|--no-visual-split] [--approve-all|--approve-reads|--deny-all] [--timeout <seconds>] review <path> [dims]
  dispatch.sh [--cmux] [--visual <backend>] [--visual-split|--no-visual-split] [--approve-all|--approve-reads|--deny-all] [--timeout <seconds>] route <filepath> <task>
  dispatch.sh status [session-id]                Show session status
  dispatch.sh list                               List all sessions
  dispatch.sh agents                             List available agents
  dispatch.sh cleanup [days]                     Clean sessions older than N days

Agents: claude | codex | gemini | codebuddy | claude-internal | codex-internal
        gemini-internal | copilot | cursor | opencode | pi

Review dimensions: security | performance | architecture | maintainability | accessibility

Options:
  --cmux    Force cmux split-pane mode (auto-detected if inside cmux)
  --visual  Visual split-pane backend: auto | tmux | ghostty | iterm2
  --visual-split     Force visual backend to use split panes
  --no-visual-split  Disable visual split panes even when a backend is selected
  --visual-new-window  Force Ghostty/iTerm2 to open a new window instead of reusing the front window
  --approve-all    Allow file-changing agent execution
  --approve-reads  Read-only agent execution
  --deny-all       Strict no-approval mode
  --timeout        Override timeout for this invocation in seconds
  --json    Output results as JSON (for programmatic consumption)

Examples:
  dispatch.sh single codex "Implement the auth endpoint"
  dispatch.sh batch "codex:Implement feature" "claude:Security review"
  dispatch.sh auto-split "Build user registration with email verification"
  dispatch.sh review src/auth/ security,performance,architecture
  dispatch.sh batch-json '[{"agent":"codex","task":"impl"},{"agent":"claude","task":"review"}]'
  echo '[...]' | dispatch.sh batch-json -
  dispatch.sh --json batch "codex:task1" "claude:task2"
  dispatch.sh --timeout 1800 single codebuddy "Implement and test the login flow"
  dispatch.sh agents
EOF
}

# Parse global flags before command
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cmux)
            export ENABLE_CMUX=true
            shift
            ;;
        --visual)
            export VISUAL_BACKEND="${2:-auto}"
            shift 2
            ;;
        --visual-new-window)
            export VISUAL_NEW_WINDOW=true
            shift
            ;;
        --visual-split)
            export VISUAL_SPLIT_MODE=on
            shift
            ;;
        --no-visual-split)
            export VISUAL_SPLIT_MODE=off
            shift
            ;;
        --json)
            export OUTPUT_JSON=true
            shift
            ;;
        --approve-all)
            export APPROVAL_MODE=approve-all
            shift
            ;;
        --approve-reads)
            export APPROVAL_MODE=approve-reads
            shift
            ;;
        --deny-all)
            export APPROVAL_MODE=deny-all
            shift
            ;;
        --timeout)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for --timeout"
                usage
                exit 1
            fi
            if [[ ! "${2}" =~ ^[0-9]+$ ]] || [[ "${2}" -lt 1 ]]; then
                echo "Invalid timeout value: ${2} (expected positive integer seconds)"
                exit 1
            fi
            export TIMEOUT="${2}"
            shift 2
            ;;
        --*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

cmd="${1:-help}"
shift || true

# Auto-detect cmux if not explicitly set
if [[ -n "${CMUX_SURFACE_ID:-}" ]]; then
    export ENABLE_CMUX="${ENABLE_CMUX:-true}"
fi

# Auto-enable visual backend discovery when running inside tmux.
# Explicit --visual/--no-visual flags still take precedence.
if [[ -z "${VISUAL_BACKEND:-}" ]] && [[ -n "${TMUX:-}" ]]; then
    export VISUAL_BACKEND="auto"
fi

export ENABLE_CMUX="${ENABLE_CMUX:-false}"
export VISUAL_BACKEND="${VISUAL_BACKEND:-}"
export VISUAL_NEW_WINDOW="${VISUAL_NEW_WINDOW:-false}"
export VISUAL_SPLIT_MODE="${VISUAL_SPLIT_MODE:-}"
export OUTPUT_JSON="${OUTPUT_JSON:-false}"

unique_session_name() {
    local prefix="$1"
    printf '%s-%s-%s-%s' "$prefix" "$(date +%s)" "$$" "$RANDOM"
}

case "$cmd" in
    single)
        agent="${1:?Agent required (codex/claude/gemini)}"
        task="${2:?Task description required}"
        session="${3:-$(unique_session_name dispatch)}"
        dispatch "$agent" "$task" "$session"
        ;;

    batch)
        if [[ $# -lt 1 ]]; then
            echo "Usage: dispatch.sh batch 'agent1:task1' 'agent2:task2' ..."
            exit 1
        fi
        dispatch_parallel "$@"
        ;;

    batch-json)
        json_input="${1:-}"
        if [[ "$json_input" == "-" ]] || [[ -z "$json_input" ]]; then
            json_input=$(cat)
        fi
        if [[ -z "$json_input" ]]; then
            echo "Usage: dispatch.sh batch-json '<json>' or echo '<json>' | dispatch.sh batch-json -"
            exit 1
        fi
        dispatch_batch "$json_input"
        ;;

    auto-split)
        task="${1:?Task description required}"
        dispatch_auto_split "$task"
        ;;

    review)
        filepath="${1:?File or directory path required}"
        dimensions="${2:-security,performance,architecture}"
        dispatch_review "$filepath" "$dimensions"
        ;;

    route)
        filepath="${1:?File path required}"
        task="${2:?Task description required}"
        agent=$(route_file "$filepath")
        log_info "Routing $filepath -> $agent"
        dispatch "$agent" "$task" "$(unique_session_name route)"
        ;;

    status)
        session="${1:-}"
        if [[ -n "$session" ]]; then
            status=$(get_status "$session")
            echo "Session: $session"
            echo "Status: $status"
            if [[ -f "${SESSIONS_DIR}/${session}/metadata.json" ]]; then
                cat "${SESSIONS_DIR}/${session}/metadata.json"
            fi
        else
            list_active_sessions
        fi
        ;;

    list)
        list_sessions
        ;;

    agents)
        echo "Checking available agents..."
        list_available_agents
        ;;

    cleanup)
        days="${1:-7}"
        cleanup_old_sessions "$days"
        ;;

    help|--help|-h)
        usage
        ;;

    *)
        echo "Unknown command: $cmd"
        usage
        exit 1
        ;;
esac
