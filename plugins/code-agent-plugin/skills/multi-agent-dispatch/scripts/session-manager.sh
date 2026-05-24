#!/bin/bash
# session-manager.sh - Manage multi-agent dispatch sessions and configuration
#
# Usage:
#   source session-manager.sh
#   init_config
#   create_dispatch_session "task-001" "codex" "Implement feature"

set -euo pipefail

SESSIONS_DIR="${HOME}/.multi-agent-dispatch/sessions"
DEFAULT_CONFIG_FILE="${HOME}/.multi-agent-dispatch/config.json"
CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
PROJECT_CONFIG_FILENAME="${PROJECT_CONFIG_FILENAME:-.multi-agent-dispatch.json}"

mkdir -p "$SESSIONS_DIR"

# Initialize default config if missing
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << 'CONFIGEOF'
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
  "routes": [],
  "parallelism": 3,
  "timeout_seconds": 1800,
  "approval_mode": "approve-all",
  "review_dimensions": {
    "security": { "agent": "claude", "prompt": "Review for security vulnerabilities: OWASP Top 10, input validation, authentication/authorization issues, injection risks, data exposure" },
    "performance": { "agent": "codex", "prompt": "Review for performance issues: algorithmic complexity, unnecessary allocations, N+1 queries, caching opportunities, memory leaks" },
    "architecture": { "agent": "claude", "prompt": "Review for architectural issues: separation of concerns, SOLID principles, testability, coupling, design patterns" },
    "maintainability": { "agent": "codex", "prompt": "Review for maintainability: code clarity, naming conventions, technical debt, dead code, documentation gaps" },
    "accessibility": { "agent": "gemini", "prompt": "Review for accessibility: WCAG 2.1 AA compliance, color contrast, keyboard navigation, screen reader support, semantic HTML" }
  },
  "auto_split_agent": "claude"
}
CONFIGEOF
        echo "Config initialized: $CONFIG_FILE"
    fi
}

find_project_config_file() {
    if [[ -n "${PROJECT_CONFIG_FILE:-}" ]]; then
        if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
            echo "$PROJECT_CONFIG_FILE"
        fi
        return
    fi

    local dir="$PWD"
    while true; do
        local candidate="$dir/$PROJECT_CONFIG_FILENAME"
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return
        fi
        if [[ "$dir" == "/" ]]; then
            return
        fi
        dir="$(dirname "$dir")"
    done
}

read_merged_config() {
    command -v jq &> /dev/null || return 1

    local project_config=""
    project_config="$(find_project_config_file)"

    if [[ -f "$CONFIG_FILE" ]] && [[ -n "$project_config" ]]; then
        jq -s 'reduce .[] as $item ({}; . * $item)' "$CONFIG_FILE" "$project_config"
    elif [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    elif [[ -n "$project_config" ]]; then
        cat "$project_config"
    else
        return 1
    fi
}

# Read config value using jq
config_get() {
    local key=$1
    shift || true
    local merged_config

    merged_config="$(read_merged_config 2>/dev/null || true)"
    if [[ -n "$merged_config" ]]; then
        jq "$@" -r "$key" <<< "$merged_config" 2>/dev/null || echo ""
    fi
}

load_runtime_config() {
    local configured_parallelism=""
    local configured_timeout=""
    local configured_approval=""
    local configured_visual_split=""

    configured_parallelism="$(config_get '.parallelism // empty')"
    configured_timeout="$(config_get '.timeout_seconds // empty')"
    configured_approval="$(config_get '.approval_mode // empty')"
    configured_visual_split="$(config_get '.visual_split_mode // empty')"

    if [[ -n "${PARALLELISM:-}" ]]; then
        PARALLELISM="$PARALLELISM"
    elif [[ -n "$configured_parallelism" ]]; then
        PARALLELISM="$configured_parallelism"
    else
        PARALLELISM=3
    fi

    if [[ -n "${TIMEOUT:-}" ]]; then
        TIMEOUT="$TIMEOUT"
    elif [[ -n "$configured_timeout" ]]; then
        TIMEOUT="$configured_timeout"
    else
        TIMEOUT=1800
    fi

    if [[ -n "${APPROVAL_MODE:-}" ]]; then
        APPROVAL_MODE="$APPROVAL_MODE"
    elif [[ -n "$configured_approval" ]]; then
        APPROVAL_MODE="$configured_approval"
    else
        APPROVAL_MODE="approve-all"
    fi

    if [[ -n "${VISUAL_SPLIT_MODE:-}" ]]; then
        VISUAL_SPLIT_MODE="$VISUAL_SPLIT_MODE"
    elif [[ -n "$configured_visual_split" ]]; then
        VISUAL_SPLIT_MODE="$configured_visual_split"
    else
        VISUAL_SPLIT_MODE="auto"
    fi

    if [[ ! "$PARALLELISM" =~ ^[0-9]+$ ]] || [[ "$PARALLELISM" -lt 1 ]]; then
        PARALLELISM=3
    fi

    if [[ ! "$TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT" -lt 1 ]]; then
        TIMEOUT=1800
    fi

    case "$VISUAL_SPLIT_MODE" in
        auto|on|off) ;;
        *) VISUAL_SPLIT_MODE="auto" ;;
    esac

    export PARALLELISM TIMEOUT APPROVAL_MODE VISUAL_SPLIT_MODE
}

# Create a tracked dispatch session
create_dispatch_session() {
    local task_id=$1
    local agent=$2
    local description=$3

    # Validate task_id to prevent path traversal
    if [[ ! "$task_id" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "Invalid task_id: '$task_id'" >&2
        return 1
    fi

    local session_dir="${SESSIONS_DIR}/${task_id}"

    mkdir -p "$session_dir"

    # Use jq to safely build JSON (prevents injection)
    jq -n \
        --arg task_id "$task_id" \
        --arg agent "$agent" \
        --arg description "$description" \
        --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            task_id: $task_id,
            session: $task_id,
            agent: $agent,
            description: $description,
            prompt: $description,
            created_at: $created_at,
            status: "pending"
        }' > "$session_dir/metadata.json"

    echo "pending" > "$session_dir/status.txt"
    echo "$task_id" > "$session_dir/session-id.txt"
    echo "$session_dir"
}

# Get session status
get_session_status() {
    local session_dir=$1
    local status_file="$session_dir/status.txt"

    if [[ -f "$status_file" ]]; then
        cat "$status_file"
    else
        echo "unknown"
    fi
}

# Update session status
update_session_status() {
    local session_dir=$1
    local status=$2
    echo "$status" > "$session_dir/status.txt"
}

# List all sessions with status
list_sessions() {
    if [[ ! -d "$SESSIONS_DIR" ]]; then
        echo "No sessions found."
        return
    fi

    printf "%-30s %-12s %-10s %s\n" "SESSION" "STATUS" "AGENT" "DESCRIPTION"
    printf "%-30s %-12s %-10s %s\n" "-------" "------" "-----" "-----------"

    for session in "$SESSIONS_DIR"/*/; do
        if [[ -d "$session" ]]; then
            local name=$(basename "$session")
            local status=$(get_session_status "$session")
            local agent=""
            local desc=""

            if [[ -f "$session/metadata.json" ]] && command -v jq &> /dev/null; then
                agent=$(jq -r '.agent // "?"' "$session/metadata.json" 2>/dev/null)
                desc=$(jq -r '.description // ""' "$session/metadata.json" 2>/dev/null | head -c 50)
            fi

            printf "%-30s %-12s %-10s %s\n" "$name" "$status" "$agent" "$desc"
        fi
    done
}

# List only active (non-completed) sessions
list_active_sessions() {
    if [[ -d "$SESSIONS_DIR" ]]; then
        for session in "$SESSIONS_DIR"/*/; do
            if [[ -d "$session" ]]; then
                local status=$(get_session_status "$session")
                if [[ "$status" != "completed" ]] && [[ "$status" != "failed" ]]; then
                    echo "$(basename "$session"): $status"
                fi
            fi
        done
    fi
}

# Route a file path to the appropriate agent based on config routes
route_file() {
    local filepath=$1
    local merged_config=""
    local route_lines=""

    if ! command -v jq &> /dev/null; then
        echo "codex"
        return
    fi

    merged_config="$(read_merged_config 2>/dev/null || true)"
    if [[ -z "$merged_config" ]]; then
        echo "codex"
        return
    fi

    route_lines=$(jq -r '.routes[]? | [.pattern, (.agent // .agents[0] // "")] | @tsv' <<< "$merged_config" 2>/dev/null || true)
    while IFS=$'\t' read -r pattern agent; do
        [[ -n "$pattern" ]] || continue
        if [[ "$filepath" == $pattern ]]; then
            echo "$agent"
            return
        fi
    done <<< "$route_lines"

    echo "codex"
}

# Clean up old sessions (older than N days)
cleanup_old_sessions() {
    local days=${1:-7}

    if [[ ! -d "$SESSIONS_DIR" ]]; then
        return
    fi

    local now=$(date +%s)
    local cutoff=$((now - days * 86400))
    local cleaned=0

    for session in "$SESSIONS_DIR"/*/; do
        if [[ -d "$session" ]]; then
            # Use file modification time as proxy
            local mtime
            if [[ "$(uname)" == "Darwin" ]]; then
                mtime=$(stat -f %m "$session" 2>/dev/null || echo "$now")
            else
                mtime=$(stat -c %Y "$session" 2>/dev/null || echo "$now")
            fi

            if [[ $mtime -lt $cutoff ]]; then
                rm -rf "$session"
                cleaned=$((cleaned + 1))
            fi
        fi
    done

    echo "Cleaned up $cleaned sessions older than $days days"
}

# Run function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${@:?Usage: session-manager.sh <function> [args...]}"
fi
