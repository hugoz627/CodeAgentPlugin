#!/bin/bash
# acpx-wrapper.sh - Wrapper around acpx CLI with error handling and logging
#
# Usage:
#   source acpx-wrapper.sh
#   dispatch codex "Implement the feature" my-session-name
#
# Or run directly:
#   ./acpx-wrapper.sh dispatch codex "Implement the feature"

set -euo pipefail

LOG_DIR="${HOME}/.multi-agent-dispatch/logs"
SESSIONS_DIR="${HOME}/.multi-agent-dispatch/sessions"
AGENT_CHECK_CACHE="${AGENT_CHECK_CACHE:-}"

mkdir -p "$LOG_DIR" "$SESSIONS_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_DIR/acpx.log"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_DIR/acpx.log"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_DIR/acpx.log" >&2; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_DIR/acpx.log"; }

event_print() {
    local message="$1"
    if [[ "${OUTPUT_JSON:-false}" == "true" ]]; then
        printf '%s\n' "$message" >&2
    else
        printf '%s\n' "$message"
    fi
}

emit_single_dispatch_start() {
    local agent="$1"
    local session="$2"
    local task="$3"
    event_print "[Multi-Agent Dispatch] START single agent=$agent session=$session"
    event_print "  task: $task"
}

emit_single_dispatch_done() {
    local agent="$1"
    local session="$2"
    local status="$3"
    event_print "[Multi-Agent Dispatch] DONE single agent=$agent status=$status session=$session"
}

# Check if acpx is available
check_acpx() {
    if command -v acpx &> /dev/null; then
        return 0
    fi
    # Check common install locations
    local paths=(
        "/opt/homebrew/lib/node_modules/openclaw/extensions/acpx/node_modules/.bin/acpx"
        "$HOME/.npm/bin/acpx"
        "$HOME/.local/bin/acpx"
    )
    for p in "${paths[@]}"; do
        if [[ -x "$p" ]]; then
            export ACPX_CMD="$p"
            return 0
        fi
    done
    log_error "acpx CLI not found. Install with: npm install -g acpx"
    return 1
}

# Get the acpx command
acpx_cmd() {
    echo "${ACPX_CMD:-acpx}"
}

agent_uses_acpx() {
    local agent="$1"
    case "$agent" in
        codebuddy) return 1 ;;
        *) return 0 ;;
    esac
}

codebuddy_cmd() {
    if [[ -n "${CODEBUDDY_CMD:-}" ]]; then
        printf '%s\n' "${CODEBUDDY_CMD}"
        return 0
    fi

    if command -v codebuddy >/dev/null 2>&1; then
        command -v codebuddy
        return 0
    fi

    return 1
}

build_agent_invocation_args() {
    local agent="$1"
    ACPX_AGENT_ARGS=()
    ACPX_AGENT_ARGS+=("$agent")
}

agent_cli_label() {
    local agent="$1"
    case "$agent" in
        codebuddy)
            echo "codebuddy(native-cli)"
            ;;
        *)
            echo "$agent"
            ;;
    esac
}

default_agent_catalog() {
    printf '%s\n' \
        "claude" \
        "codex" \
        "gemini" \
        "codebuddy" \
        "claude-internal" \
        "codex-internal" \
        "gemini-internal" \
        "copilot" \
        "cursor" \
        "opencode" \
        "pi"
}

configured_agent_candidates() {
    local merged_config=""

    if ! declare -F read_merged_config >/dev/null || ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    merged_config="$(read_merged_config 2>/dev/null || true)"
    if [[ -z "$merged_config" ]]; then
        return 0
    fi

    jq -r '
        (.agents // {} | keys[]?),
        (.routes[]?.agent // empty),
        (.review_dimensions // {} | to_entries[]? | .value.agent // empty)
    ' <<< "$merged_config" 2>/dev/null || true
}

extra_agent_candidates() {
    local raw="${MULTI_AGENT_DISPATCH_EXTRA_AGENTS:-}"
    if [[ -z "$raw" ]]; then
        return 0
    fi

    printf '%s' "$raw" | tr ', ' '\n\n'
}

candidate_agents() {
    local seen=","
    local agent=""

    while IFS= read -r agent; do
        [[ -n "$agent" ]] || continue
        if [[ "$seen" == *",$agent,"* ]]; then
            continue
        fi
        printf '%s\n' "$agent"
        seen="${seen}${agent},"
    done < <(
        default_agent_catalog
        configured_agent_candidates
        extra_agent_candidates
    )
}

candidate_agent_known() {
    local target="$1"
    local agent=""

    while IFS= read -r agent; do
        [[ -n "$agent" ]] || continue
        if [[ "$agent" == "$target" ]]; then
            return 0
        fi
    done < <(candidate_agents)

    return 1
}

run_acpx_agent() {
    local agent="$1"
    shift
    local -a leading_args=()
    local -a remaining_args=()
    local -a cmd=()

    if ! agent_uses_acpx "$agent"; then
        log_error "Agent '$agent' does not use acpx transport."
        return 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --approve-all|--approve-reads|--deny-all)
                leading_args+=("$1")
                shift
                ;;
            --cwd|--timeout)
                if [[ $# -lt 2 ]]; then
                    log_error "Missing value for acpx option: $1"
                    return 1
                fi
                leading_args+=("$1" "$2")
                shift 2
                ;;
            *)
                remaining_args=("$@")
                break
                ;;
        esac
    done

    build_agent_invocation_args "$agent"
    cmd=("$(acpx_cmd)")
    if [[ ${#leading_args[@]} -gt 0 ]]; then
        cmd+=("${leading_args[@]}")
    fi
    cmd+=("${ACPX_AGENT_ARGS[@]}")
    if [[ ${#remaining_args[@]} -gt 0 ]]; then
        cmd+=("${remaining_args[@]}")
    fi
    "${cmd[@]}"
}

run_codebuddy_exec() {
    local approval="$1"
    local cwd="$2"
    local timeout="$3"
    local prompt="$4"
    local codebuddy_bin=""
    local -a cmd=()

    codebuddy_bin="$(codebuddy_cmd)" || {
        log_error "codebuddy CLI not found. Install CodeBuddy Code and ensure 'codebuddy' is on PATH."
        return 1
    }

    cmd=("$codebuddy_bin" --print --output-format text)
    case "$approval" in
        approve-all)
            cmd+=(--dangerously-skip-permissions)
            ;;
        approve-reads|deny-all)
            cmd+=(--permission-mode plan)
            ;;
    esac

    if [[ "${CODEBUDDY_MAX_TURNS:-}" =~ ^[0-9]+$ ]] && [[ "${CODEBUDDY_MAX_TURNS}" -gt 0 ]]; then
        cmd+=(--max-turns "${CODEBUDDY_MAX_TURNS}")
    fi

    if [[ -n "${CODEBUDDY_MODEL:-}" ]]; then
        cmd+=(--model "${CODEBUDDY_MODEL}")
    fi

    # Native CodeBuddy does not expose an acpx-like timeout flag, so we
    # currently rely on the outer caller timeout for hard cancellation.
    if [[ -n "$timeout" ]] && [[ "$timeout" != "0" ]]; then
        :
    fi

    (
        cd "$cwd"
        "${cmd[@]}" "$prompt"
    )
}

run_agent_exec() {
    local agent="$1"
    local approval="$2"
    local cwd="$3"
    local timeout="$4"
    local prompt="$5"

    if agent_uses_acpx "$agent"; then
        run_acpx_agent "$agent" --"${approval}" --cwd "$cwd" --timeout "$timeout" exec "$prompt"
    else
        run_codebuddy_exec "$approval" "$cwd" "$timeout" "$prompt"
    fi
}

append_session_note() {
    local output_file="$1"
    local note="$2"
    printf '\n[dispatch] %s\n' "$note" >> "$output_file"
}

kill_process_descendants() {
    local pid="$1"
    local signal="${2:-TERM}"
    local child=""

    if ! command -v pgrep >/dev/null 2>&1; then
        return 0
    fi

    while IFS= read -r child; do
        [[ -n "$child" ]] || continue
        kill_process_descendants "$child" "$signal"
        kill "-${signal}" "$child" 2>/dev/null || true
    done < <(pgrep -P "$pid" 2>/dev/null || true)
}

terminate_process_tree() {
    local pid="$1"
    local signal="${2:-TERM}"

    [[ -n "$pid" ]] || return 0
    if ! kill -0 "$pid" 2>/dev/null; then
        return 0
    fi

    kill_process_descendants "$pid" "$signal"
    kill "-${signal}" "$pid" 2>/dev/null || true
}

update_session_result() {
    local session_dir="$1"
    local status="$2"
    local exit_code="$3"
    local termination_reason="${4:-}"
    local completed_at
    local tmp_meta=""

    completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "$status" > "$session_dir/status.txt"

    if [[ ! -f "$session_dir/metadata.json" ]] || ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    tmp_meta=$(mktemp)
    if [[ -n "$termination_reason" ]]; then
        jq \
            --arg completed_at "$completed_at" \
            --arg status "$status" \
            --arg reason "$termination_reason" \
            --argjson exit_code "$exit_code" \
            '. + {
                completed_at: $completed_at,
                status: $status,
                termination_reason: $reason,
                exit_code: $exit_code
            }' "$session_dir/metadata.json" > "$tmp_meta"
    else
        jq \
            --arg completed_at "$completed_at" \
            --arg status "$status" \
            --argjson exit_code "$exit_code" \
            '. + {
                completed_at: $completed_at,
                status: $status,
                exit_code: $exit_code
            }' "$session_dir/metadata.json" > "$tmp_meta"
    fi
    mv "$tmp_meta" "$session_dir/metadata.json"
}

agent_cache_get() {
    local agent="$1"
    if [[ "${DISPATCH_REFRESH_AGENTS:-0}" == "1" ]]; then
        return 1
    fi

    while IFS=$'\t' read -r cached_agent cached_status; do
        [[ -n "$cached_agent" ]] || continue
        if [[ "$cached_agent" == "$agent" ]]; then
            printf '%s' "$cached_status"
            return 0
        fi
    done <<< "$AGENT_CHECK_CACHE"

    return 1
}

agent_cache_set() {
    local agent="$1"
    local status="$2"
    local filtered=""

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ "${line%%$'\t'*}" != "$agent" ]]; then
            filtered+="${line}"$'\n'
        fi
    done <<< "$AGENT_CHECK_CACHE"

    AGENT_CHECK_CACHE="${filtered}${agent}"$'\t'"${status}"
}

configured_agent_enabled() {
    local agent="$1"
    local configured=""

    if declare -F config_get >/dev/null; then
        configured=$(config_get --arg agent "$agent" '.agents[$agent].available // empty' 2>/dev/null || true)
        case "$configured" in
            false) return 1 ;;
            true|"") return 0 ;;
        esac
    fi

    return 0
}

# Check if a specific agent is available
check_agent() {
    local agent=$1
    local cached_status=""
    local codebuddy_bin=""

    cached_status=$(agent_cache_get "$agent" 2>/dev/null || true)
    if [[ -n "$cached_status" ]]; then
        [[ "$cached_status" == "available" ]]
        return $?
    fi

    if ! agent_uses_acpx "$agent"; then
        if codebuddy_bin="$(codebuddy_cmd 2>/dev/null)" && "$codebuddy_bin" --version >/dev/null 2>&1; then
            agent_cache_set "$agent" "available"
            return 0
        fi
    else
        # 轻量探测只验证 ACP bridge/CLI 是否可启动，避免触发完整 agent 对话。
        # 在带有 AGENTS.md / bootstrap 约束的仓库里，直接 exec prompt 很容易因为前置流程超时，
        # 从而把“可用但初始化较慢”的 agent 误判成未安装。
        if run_acpx_agent "$agent" status &> /dev/null; then
            agent_cache_set "$agent" "available"
            return 0
        fi
    fi

    agent_cache_set "$agent" "unavailable"
    return 1
}

ensure_agent_available() {
    local agent="$1"

    if ! configured_agent_enabled "$agent"; then
        log_error "Agent '$agent' is disabled in config (.agents.${agent}.available=false)."
        log_error "Enable it in ~/.multi-agent-dispatch/config.json or route this task to another agent."
        return 1
    fi

    if ! check_agent "$agent"; then
        log_error "Agent '$agent' is not available."
        log_error "Install or configure the agent CLI, then verify with: ./scripts/dispatch.sh agents"
        return 1
    fi

    return 0
}

# List available agents
list_available_agents() {
    local agent=""
    local available=()
    while IFS= read -r agent; do
        [[ -n "$agent" ]] || continue
        if ! configured_agent_enabled "$agent"; then
            continue
        fi
        if check_agent "$agent" 2>/dev/null; then
            available+=("$agent")
        fi
    done < <(candidate_agents)
    printf '%s\n' "${available[@]}"
}

# Create a new acpx session
create_session() {
    local agent=$1
    local session_name=$2

    log_info "Creating $agent session: $session_name"
    if run_acpx_agent "$agent" sessions new --name "$session_name" 2>&1 | tee -a "$LOG_DIR/acpx.log"; then
        log_success "Session created: $session_name"
        return 0
    else
        log_error "Session creation failed: $session_name"
        return 1
    fi
}

# Validate session name (prevent path traversal)
validate_session_name() {
    local name=$1
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "Invalid session name: '$name' (only alphanumeric, dots, hyphens, underscores allowed)"
        return 1
    fi
}

# Execute a task via the configured agent transport
execute_task() {
    local agent=$1
    local session=$2
    local task=$3
    local cwd="${4:-$(pwd)}"
    local approval="${5:-${APPROVAL_MODE:-approve-all}}"

    validate_session_name "$session" || return 1
    local session_dir="${SESSIONS_DIR}/${session}"
    local started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    mkdir -p "$session_dir"

    echo "$task" > "$session_dir/prompt.txt"
    echo "running" > "$session_dir/status.txt"
    echo "$session" > "$session_dir/session-id.txt"

    local tmp_meta
    tmp_meta=$(mktemp)
    if [[ -f "$session_dir/metadata.json" ]]; then
        jq \
            --arg agent "$agent" \
            --arg session "$session" \
            --arg task "$task" \
            --arg cwd "$cwd" \
            --arg approval "$approval" \
            --arg started_at "$started_at" \
            --arg status "running" \
            '. + {
                task_id: (.task_id // $session),
                session: $session,
                agent: $agent,
                description: (.description // $task),
                prompt: $task,
                cwd: $cwd,
                approval_mode: $approval,
                created_at: (.created_at // $started_at),
                started_at: $started_at,
                status: $status
            }' "$session_dir/metadata.json" > "$tmp_meta"
    else
        jq -n \
            --arg agent "$agent" \
            --arg session "$session" \
            --arg task "$task" \
            --arg cwd "$cwd" \
            --arg approval "$approval" \
            --arg started_at "$started_at" \
            --arg status "running" \
            '{
                task_id: $session,
                session: $session,
                agent: $agent,
                description: $task,
                prompt: $task,
                cwd: $cwd,
                approval_mode: $approval,
                created_at: $started_at,
                started_at: $started_at,
                status: $status
            }' > "$tmp_meta"
    fi
    mv "$tmp_meta" "$session_dir/metadata.json"

    log_info "Executing in $agent session=$session cwd=$cwd"
    event_print "[Multi-Agent Dispatch] CALL agent=$agent cli=$(agent_cli_label "$agent") session=$session approval=$approval"

    local output_file="$session_dir/stdout.log"
    local exit_code=0
    local timeout_seconds="${TIMEOUT:-1800}"
    local child_pid=""
    local watchdog_pid=""
    local interrupted_signal=""
    local termination_reason=""
    local timeout_marker="$session_dir/.timeout"

    rm -f "$timeout_marker"

    on_execute_signal() {
        local signal="$1"
        if [[ -n "$interrupted_signal" ]]; then
            return 0
        fi

        interrupted_signal="$signal"
        termination_reason="signal:${signal}"
        append_session_note "$output_file" "Received ${signal}; stopping agent process tree."

        if [[ -n "$watchdog_pid" ]]; then
            terminate_process_tree "$watchdog_pid" TERM
            sleep 1
            terminate_process_tree "$watchdog_pid" KILL
        fi

        if [[ -n "$child_pid" ]]; then
            terminate_process_tree "$child_pid" TERM
            sleep 1
            terminate_process_tree "$child_pid" KILL
        fi
    }

    trap 'on_execute_signal TERM' TERM
    trap 'on_execute_signal INT' INT

    # Dispatch tasks as one-shot prompts. We keep our own session metadata locally,
    # and avoid saved-session reload noise for independent tasks.
    run_agent_exec "$agent" "$approval" "$cwd" "$timeout_seconds" "$task" > "$output_file" 2>&1 &
    child_pid=$!

    if [[ "$timeout_seconds" =~ ^[0-9]+$ ]] && [[ "$timeout_seconds" -gt 0 ]]; then
        (
            sleep "$timeout_seconds"
            if kill -0 "$child_pid" 2>/dev/null; then
                printf 'timeout\n' > "$timeout_marker"
                terminate_process_tree "$child_pid" TERM
                sleep 1
                terminate_process_tree "$child_pid" KILL
            fi
        ) >/dev/null 2>&1 &
        watchdog_pid=$!
    fi

    wait "$child_pid" || exit_code=$?

    if [[ -n "$watchdog_pid" ]]; then
        terminate_process_tree "$watchdog_pid" TERM
        wait "$watchdog_pid" 2>/dev/null || true
    fi

    if [[ -n "$interrupted_signal" ]]; then
        wait "$child_pid" 2>/dev/null || true
    fi

    trap - TERM INT

    local final_status="completed"
    if [[ -n "$interrupted_signal" ]]; then
        final_status="failed"
        exit_code=143
        log_error "Task interrupted by $interrupted_signal: $agent/$session"
    elif [[ -f "$timeout_marker" ]]; then
        final_status="failed"
        termination_reason="timeout"
        exit_code=124
        append_session_note "$output_file" "Timed out after ${timeout_seconds}s."
        log_error "Task timed out after ${timeout_seconds}s: $agent/$session"
    elif [[ $exit_code -eq 0 ]]; then
        log_success "Task completed: $agent/$session"
    else
        final_status="failed"
        log_error "Task failed (exit $exit_code): $agent/$session"
    fi
    rm -f "$timeout_marker"

    update_session_result "$session_dir" "$final_status" "$exit_code" "$termination_reason"

    return $exit_code
}

# Get output from a session
get_output() {
    local session=$1
    validate_session_name "$session" || return 1
    local output_file="${SESSIONS_DIR}/${session}/stdout.log"

    if [[ -f "$output_file" ]]; then
        cat "$output_file"
    else
        log_warn "No output for session: $session"
        return 1
    fi
}

# Get session status
get_status() {
    local session=$1
    validate_session_name "$session" || return 1
    local status_file="${SESSIONS_DIR}/${session}/status.txt"

    if [[ -f "$status_file" ]]; then
        cat "$status_file"
    else
        echo "unknown"
    fi
}

# Close an acpx session
close_session() {
    local agent=$1
    local session=$2

    run_acpx_agent "$agent" sessions close "$session" 2>/dev/null || true
    log_info "Session closed: $agent/$session"
}

# Full dispatch: create session -> execute -> collect output -> close
dispatch() {
    local agent=$1
    local task=$2
    local session_name="${3:-dispatch-$(date +%s)}"
    local cwd="${4:-$(pwd)}"
    local use_visual=false
    local visual_surface=""

    if declare -F load_runtime_config >/dev/null; then
        load_runtime_config
    fi

    if agent_uses_acpx "$agent"; then
        check_acpx || return 1
    fi
    ensure_agent_available "$agent" || return 1

    log_info "Dispatching to $agent: $session_name"
    emit_single_dispatch_start "$agent" "$session_name" "$task"

    if [[ -n "${VISUAL_BACKEND:-}" ]] && declare -F visual_init >/dev/null; then
        local resolved_visual_backend=""
        resolved_visual_backend="$(visual_backend_resolve "${VISUAL_BACKEND}")"
        if [[ -n "$resolved_visual_backend" ]] && visual_split_enabled_for_backend "$resolved_visual_backend" && visual_init "${VISUAL_BACKEND}"; then
            use_visual=true
            visual_surface="$(visual_create_split_pane "right" "$agent" 2>/dev/null || true)"
            if [[ -n "$visual_surface" ]]; then
                local log_file="${SESSIONS_DIR}/${session_name}/stdout.log"
                local status_file="${SESSIONS_DIR}/${session_name}/status.txt"
                visual_stream_to_surface "$visual_surface" "$log_file" "$status_file" "$agent" 2>/dev/null || true
            fi
        fi
    fi

    # Execute
    execute_task "$agent" "$session_name" "$task" "$cwd" || {
        log_error "Dispatch failed for $agent"
        if [[ "$use_visual" == "true" ]]; then
            visual_set_agent_status "$agent" "failed" 2>/dev/null || true
        fi
        emit_single_dispatch_done "$agent" "$session_name" "failed"
        return 1
    }

    # Show output
    echo ""
    echo "--- Output from $agent ($session_name) ---"
    get_output "$session_name"
    echo "--- End output ---"
    echo ""

    log_success "Dispatch completed: $agent/$session_name"
    if [[ "$use_visual" == "true" ]]; then
        visual_set_agent_status "$agent" "completed" 2>/dev/null || true
        visual_cleanup
    fi
    emit_single_dispatch_done "$agent" "$session_name" "completed"
}

# Run function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${@:?Usage: acpx-wrapper.sh <function> [args...]}"
fi
