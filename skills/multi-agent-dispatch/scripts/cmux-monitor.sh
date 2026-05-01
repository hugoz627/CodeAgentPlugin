#!/bin/bash
# cmux-monitor.sh - CMUX integration for multi-agent dispatch
#
# Provides visual split-pane monitoring when running inside cmux.
# If not inside cmux, all functions are no-ops (graceful degradation).
#
# Usage:
#   source cmux-monitor.sh
#   if cmux_is_available; then
#       cmux_init
#       surface_id=$(cmux_create_split_pane "right" "codex")
#       cmux_stream_to_surface "$surface_id" "/path/to/stdout.log"
#       cmux_notify_task "codex" "completed"
#   fi

set -euo pipefail

CMUX_AVAILABLE=false
CMUX_SURFACE_IDS=()

log_cmux() {
    local level=$1; shift
    case "$level" in
        info)  echo -e "\033[0;34m[cmux]\033[0m $*" ;;
        ok)    echo -e "\033[0;32m[cmux]\033[0m $*" ;;
        warn)  echo -e "\033[1;33m[cmux]\033[0m $*" >&2 ;;
        error) echo -e "\033[0;31m[cmux]\033[0m $*" >&2 ;;
    esac
}

# Check if running inside cmux
# Returns 0 if cmux environment detected, 1 otherwise
cmux_is_available() {
    # Check cmux env variable
    if [[ -z "${CMUX_SURFACE_ID:-}" ]]; then
        return 1
    fi
    # Check cmux CLI exists
    if ! command -v cmux &>/dev/null; then
        return 1
    fi
    # Verify cmux socket is responsive
    if ! cmux ping &>/dev/null; then
        return 1
    fi
    return 0
}

# Initialize cmux integration
# Call once before creating panes
cmux_init() {
    if cmux_is_available; then
        CMUX_AVAILABLE=true
        log_cmux ok "CMUX detected (surface: ${CMUX_SURFACE_ID})"
    else
        CMUX_AVAILABLE=false
        log_cmux info "Not inside cmux, visual panes disabled"
    fi
}

# Create a split pane for an agent
# Args: direction (right|down) agent_name
# Returns: surface ID of the new pane (stdout)
cmux_create_split_pane() {
    local direction="${1:-right}"
    local agent_name="${2:-agent}"

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 1
    fi

    local output
    output=$(cmux new-split "$direction" 2>&1) || {
        log_cmux warn "Failed to create cmux split: $output"
        return 1
    }

    # Get the new surface ID from list-surfaces
    # The newest surface is the one we just created
    local surface_id
    surface_id=$(cmux list-surfaces --json 2>/dev/null | \
        jq -r '.[-1].id // empty' 2>/dev/null) || {
        log_cmux warn "Failed to get surface ID"
        return 1
    }

    if [[ -z "$surface_id" ]]; then
        log_cmux warn "Empty surface ID after split"
        return 1
    fi

    CMUX_SURFACE_IDS+=("$surface_id")

    # Set status indicator for this agent
    cmux set-status "$agent_name" "running" --color "blue" 2>/dev/null || true

    log_cmux ok "Created pane for $agent_name (surface: $surface_id)"
    echo "$surface_id"
}

# Send a command to a specific cmux surface
# Args: surface_id command
cmux_send_to_surface() {
    local surface_id="$1"
    local command="$2"

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    cmux send-surface --surface "$surface_id" "$command" 2>/dev/null || {
        log_cmux warn "Failed to send to surface $surface_id"
        return 1
    }
}

# Stream a log file to a cmux surface using tail -f
# Args: surface_id log_file_path agent_name
cmux_stream_to_surface() {
    local surface_id="$1"
    local log_file="$2"
    local agent_name="${3:-agent}"

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    # Ensure log file exists
    touch "$log_file" 2>/dev/null || true

    # Send tail -f command to the surface to show real-time output
    cmux_send_to_surface "$surface_id" "echo '=== $agent_name output ===' && tail -f '$log_file'\n"

    log_cmux info "Streaming $agent_name output to surface $surface_id"
}

# Update progress indicator in cmux sidebar
# Args: percent (0.0-1.0) label
cmux_set_progress() {
    local percent="$1"
    local label="${2:-}"

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    if [[ -n "$label" ]]; then
        cmux set-progress "$percent" --label "$label" 2>/dev/null || true
    else
        cmux set-progress "$percent" 2>/dev/null || true
    fi
}

# Update agent status in cmux sidebar
# Args: agent_name status (running|completed|failed) [color]
cmux_set_agent_status() {
    local agent_name="$1"
    local status="$2"
    local color="${3:-}"

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    # Auto-select color based on status
    if [[ -z "$color" ]]; then
        case "$status" in
            running)   color="blue" ;;
            completed) color="green" ;;
            failed)    color="red" ;;
            *)         color="yellow" ;;
        esac
    fi

    cmux set-status "$agent_name" "$status" --color "$color" 2>/dev/null || true
}

# Send a notification via cmux
# Args: title body
cmux_notify_task() {
    local title="$1"
    local body="${2:-}"

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    if [[ -n "$body" ]]; then
        cmux notify --title "$title" --body "$body" 2>/dev/null || true
    else
        cmux notify --title "$title" 2>/dev/null || true
    fi
}

# Log a message to cmux sidebar
# Args: level (info|success|warning|error) message
cmux_log() {
    local level="$1"
    shift

    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    cmux log --level "$level" "$*" 2>/dev/null || true
}

# Clean up all cmux resources
cmux_cleanup() {
    if [[ "$CMUX_AVAILABLE" != "true" ]]; then
        return 0
    fi

    log_cmux ok "Cleaned up cmux resources"
}

# Run function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${@:?Usage: cmux-monitor.sh <function> [args...]}"
fi
