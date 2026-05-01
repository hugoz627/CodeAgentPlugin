#!/bin/bash
# task-coordinator.sh - Coordinate parallel task execution across multiple agents
#
# Uses acpx for headless execution, with optional cmux split-pane visibility.
# When inside cmux, automatically creates split panes showing real-time output.
#
# Usage:
#   source task-coordinator.sh
#   dispatch_parallel "codex:Implement feature" "claude:Review security"
#
# Or with JSON:
#   dispatch_batch '[{"agent":"codex","task":"impl"},{"agent":"claude","task":"review"}]'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/acpx-wrapper.sh"
source "$SCRIPT_DIR/session-manager.sh"
source "$SCRIPT_DIR/visual-monitor.sh"

DISPATCH_LAST_SUMMARY_JSON=""

emit_batch_dispatch_start() {
    local total="$1"
    event_print "[Multi-Agent Dispatch] START batch total=$total parallelism=$PARALLELISM"
    shift

    local entry
    for entry in "$@"; do
        local agent="${entry%%:*}"
        local task="${entry#*:}"
        event_print "  - $agent: $task"
    done
}

emit_batch_dispatch_done() {
    local total="$1"
    local failed="$2"
    local completed="$3"
    local duration="$4"

    event_print "[Multi-Agent Dispatch] DONE batch completed=$completed failed=$failed duration=${duration}s total=$total"
}

reap_finished_pids() {
    local array_name="$1"
    local current_pids=()
    local remaining_pids=()
    local pid
    local reaped_any=1

    eval "current_pids=(\"\${${array_name}[@]}\")"

    for pid in "${current_pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            remaining_pids+=("$pid")
        else
            wait "$pid" 2>/dev/null || true
            reaped_any=0
        fi
    done

    if [[ ${#remaining_pids[@]} -gt 0 ]]; then
        eval "$array_name=(\"\${remaining_pids[@]}\")"
    else
        eval "$array_name=()"
    fi
    return "$reaped_any"
}

wait_for_available_slot() {
    local array_name="$1"
    local limit="$2"
    local current_count=0

    while true; do
        eval "current_count=\${#${array_name}[@]}"
        if [[ "$current_count" -lt "$limit" ]]; then
            return 0
        fi
        if ! reap_finished_pids "$array_name"; then
            sleep 0.01
        fi
    done
}

wait_for_all_pids() {
    local array_name="$1"
    local current_count=0

    while true; do
        eval "current_count=\${#${array_name}[@]}"
        if [[ "$current_count" -eq 0 ]]; then
            return 0
        fi
        if ! reap_finished_pids "$array_name"; then
            sleep 0.01
        fi
    done
}

# Dispatch multiple tasks in parallel using simple "agent:task" format
# Usage: dispatch_parallel "codex:Implement X" "claude:Review X" "gemini:Design X"
#
# If inside cmux (auto-detected or --cmux flag), creates split panes
# showing real-time output alongside acpx execution.
dispatch_parallel() {
    local tasks=("$@")
    local use_cmux=false
    local use_visual=false

    load_runtime_config
    log_info "Starting parallel dispatch of ${#tasks[@]} tasks (parallelism=$PARALLELISM)"

    # Initialize cmux if enabled
    if [[ "${ENABLE_CMUX:-false}" == "true" ]]; then
        cmux_init
        if [[ "$CMUX_AVAILABLE" == "true" ]]; then
            use_cmux=true
            cmux_log info "Dispatching ${#tasks[@]} tasks in parallel"
            cmux_notify_task "Multi-Agent Dispatch" "Starting ${#tasks[@]} tasks..."
        fi
    fi

    if [[ "$use_cmux" != "true" ]] && [[ -n "${VISUAL_BACKEND:-}" ]]; then
        local resolved_visual_backend=""
        resolved_visual_backend="$(visual_backend_resolve "${VISUAL_BACKEND}")"
        if [[ -n "$resolved_visual_backend" ]] && visual_split_enabled_for_backend "$resolved_visual_backend" && visual_init "${VISUAL_BACKEND}"; then
            use_visual=true
        fi
    fi

    emit_batch_dispatch_start "${#tasks[@]}" "${tasks[@]}"

    dispatch_parallel_acpx "$use_cmux" "$use_visual" "${tasks[@]}"
}

# Dispatch using acpx, optionally with cmux split-pane visibility
dispatch_parallel_acpx() {
    local use_cmux="$1"
    local use_visual="$2"
    shift 2
    local tasks=("$@")
    local pids=()
    local sessions=()
    local agents=()
    local start_time=$(date +%s)
    local batch_id="batch-$(date +%s)-$$"
    local approval_mode=""
    local results_file=""

    load_runtime_config
    approval_mode="${APPROVAL_MODE:-approve-all}"

    local validated_agents=""
    local needs_acpx=false
    for entry in "${tasks[@]}"; do
        local agent="${entry%%:*}"
        if [[ ",$validated_agents," == *",$agent,"* ]]; then
            continue
        fi
        if agent_uses_acpx "$agent"; then
            needs_acpx=true
        fi
        validated_agents="${validated_agents},${agent}"
    done

    if [[ "$needs_acpx" == "true" ]]; then
        check_acpx || return 1
    fi

    validated_agents=""
    for entry in "${tasks[@]}"; do
        local agent="${entry%%:*}"
        if [[ ",$validated_agents," == *",$agent,"* ]]; then
            continue
        fi
        ensure_agent_available "$agent" || return 1
        validated_agents="${validated_agents},${agent}"
    done

    for i in "${!tasks[@]}"; do
        local entry="${tasks[$i]}"
        local agent="${entry%%:*}"
        local task="${entry#*:}"
        local session_name="${batch_id}-$i"

        wait_for_available_slot pids "$PARALLELISM"
        log_info "[$((i+1))/${#tasks[@]}] Dispatching to $agent: ${task:0:60}..."

        sessions+=("$session_name")
        agents+=("$agent")

        # Create cmux pane for this agent if available
        local cmux_sid=""
        local visual_sid=""
        if [[ "$use_cmux" == "true" ]]; then
            local direction="right"
            if [[ $i -gt 0 ]]; then
                direction="down"
            fi
            cmux_sid=$(cmux_create_split_pane "$direction" "$agent" 2>/dev/null) || true
            cmux_set_agent_status "$agent" "running"
        elif [[ "$use_visual" == "true" ]]; then
            local direction="right"
            if [[ $i -gt 0 ]]; then
                direction="down"
            fi
            visual_sid=$(visual_create_split_pane "$direction" "$agent" 2>/dev/null) || true
            visual_set_agent_status "$agent" "running"
        fi

        (
            local log_file="${SESSIONS_DIR}/${session_name}/stdout.log"
            local status_file="${SESSIONS_DIR}/${session_name}/status.txt"
            if [[ -n "$cmux_sid" ]] && [[ "$use_cmux" == "true" ]]; then
                cmux_stream_to_surface "$cmux_sid" "$log_file" "$agent" 2>/dev/null || true
            elif [[ -n "$visual_sid" ]] && [[ "$use_visual" == "true" ]]; then
                visual_stream_to_surface "$visual_sid" "$log_file" "$status_file" "$agent" 2>/dev/null || true
            fi
            execute_task "$agent" "$session_name" "$task" "$PWD" "$approval_mode" 2>/dev/null
            local exit_code=$?
            if [[ "$use_cmux" == "true" ]]; then
                if [[ $exit_code -eq 0 ]]; then
                    cmux_set_agent_status "$agent" "completed" 2>/dev/null || true
                else
                    cmux_set_agent_status "$agent" "failed" 2>/dev/null || true
                fi
            elif [[ "$use_visual" == "true" ]]; then
                if [[ $exit_code -eq 0 ]]; then
                    visual_set_agent_status "$agent" "completed" 2>/dev/null || true
                else
                    visual_set_agent_status "$agent" "failed" 2>/dev/null || true
                fi
            fi
        ) &
        pids+=("$!")
    done

    wait_for_all_pids pids

    local failed=0
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local results_json="[]"
    local summary_json=""

    results_file=$(mktemp)
    for j in "${!sessions[@]}"; do
        local session="${sessions[$j]}"
        local agent="${agents[$j]}"
        local task_text="${tasks[$j]#*:}"
        local status
        local output

        status=$(get_status "$session" 2>/dev/null || echo "unknown")
        output=$(get_output "$session" 2>/dev/null || echo "")

        if [[ "$status" == "failed" ]] || [[ "$status" == "unknown" ]]; then
            failed=$((failed + 1))
        fi

        jq -n \
            --arg agent "$agent" \
            --arg session "$session" \
            --arg status "$status" \
            --arg task "$task_text" \
            --arg output "$output" \
            '{agent: $agent, session: $session, status: $status, task: $task, output: $output}' \
            >> "$results_file"
    done

    if [[ -s "$results_file" ]]; then
        results_json=$(jq -s '.' "$results_file")
    fi
    rm -f "$results_file"

    summary_json=$(jq -n \
        --argjson total "${#tasks[@]}" \
        --argjson completed "$((${#tasks[@]} - failed))" \
        --argjson failed "$failed" \
        --argjson duration "$duration" \
        --argjson results "$results_json" \
        '{total: $total, completed: $completed, failed: $failed, duration_seconds: $duration, results: $results}')
    DISPATCH_LAST_SUMMARY_JSON="$summary_json"

    if [[ "${OUTPUT_JSON:-false}" == "true" ]]; then
        echo "$summary_json" | jq .
    else
        echo ""
        echo "===== Multi-Agent Dispatch Results ====="
        echo ""
        echo "Summary:"
        echo "  Total tasks: ${#tasks[@]}"
        echo "  Completed: $((${#tasks[@]} - failed))"
        echo "  Failed: $failed"
        echo "  Duration: ${duration}s (parallel)"
        if [[ "$use_cmux" == "true" ]]; then
            echo "  Mode: cmux (split-pane visible)"
        elif [[ "$use_visual" == "true" ]]; then
            echo "  Mode: ${VISUAL_BACKEND_ACTIVE} (split-pane visible)"
        fi
        echo ""

        for j in "${!sessions[@]}"; do
            local session="${sessions[$j]}"
            local agent="${agents[$j]}"
            local status

            status=$(get_status "$session" 2>/dev/null || echo "unknown")
            echo "--- ${agent} (${session}) [${status}] ---"
            get_output "$session" 2>/dev/null || echo "(no output)"
            echo "--- end ${agent} ---"
            echo ""
        done

        echo "===== End Results ====="
    fi

    if [[ "$use_cmux" == "true" ]]; then
        local status_msg="${#tasks[@]} tasks done (${failed} failed) in ${duration}s"
        cmux_notify_task "Dispatch Complete" "$status_msg"
        cmux_set_progress 1.0 "Done"
        cmux_cleanup
    elif [[ "$use_visual" == "true" ]]; then
        visual_cleanup
    fi

    emit_batch_dispatch_done "${#tasks[@]}" "$failed" "$((${#tasks[@]} - failed))" "$duration"

    return $((failed > 0 ? 1 : 0))
}

# Dispatch from JSON array
# Usage: dispatch_batch '[{"agent":"codex","task":"impl"},{"agent":"claude","task":"review"}]'
dispatch_batch() {
    local tasks_json=$1
    local parsed_tasks=""
    local task_args=()

    if ! command -v jq &> /dev/null; then
        log_error "jq is required for batch dispatch"
        return 1
    fi

    parsed_tasks=$(jq -r '.[] | [.agent, .task] | @tsv' <<< "$tasks_json") || {
        log_error "Invalid JSON for batch dispatch"
        return 1
    }

    while IFS=$'\t' read -r agent task; do
        [[ -n "$agent" ]] || continue
        task_args+=("${agent}:${task}")
    done <<< "$parsed_tasks"

    dispatch_parallel "${task_args[@]}"
}

# Auto-split: AI decomposes a big task and auto-assigns to best agents
# Usage: dispatch_auto_split "Build a user registration system with email verification"
dispatch_auto_split() {
    local task="$1"
    local split_agent
    split_agent=$(config_get '.auto_split_agent // "claude"' 2>/dev/null || echo "claude")

    ensure_agent_available "$split_agent" || return 1
    if agent_uses_acpx "$split_agent"; then
        check_acpx || return 1
    fi

    log_info "Auto-split: Using $split_agent to decompose task..."

    # Ask the split agent to decompose the task into subtasks with agent assignments
    local decompose_prompt
    decompose_prompt="You are a task decomposition assistant. Break the following task into independent subtasks and assign each to the best AI coding agent.

Available agents and their strengths:
- codex: Fast implementation, refactoring, focused execution
- claude: Architecture, security review, complex reasoning
- gemini: Frontend/UI, creative design, multimodal

Task to decompose:
${task}

Output ONLY a list in this exact format, one per line, no other text:
agent:subtask description

Example output:
codex:Implement the REST API endpoints with input validation
claude:Review the authentication flow for security vulnerabilities
gemini:Create the responsive login form with accessibility support"

    local tmp_output
    tmp_output=$(mktemp)

    # Run decomposition via the configured agent transport (read-only, short timeout)
    if ! run_agent_exec "$split_agent" "deny-all" "$PWD" "120" "$decompose_prompt" > "$tmp_output" 2>/dev/null; then
        log_error "Failed to decompose task via $split_agent"
        rm -f "$tmp_output"
        return 1
    fi

    # Parse output: extract lines matching "agent:task" format
    local tasks=()
    while IFS= read -r line; do
        local parsed_agent=""
        local parsed_task=""

        # Skip empty lines and lines that don't match agent:task format
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -n "$line" ]] || continue
        [[ "$line" == *:* ]] || continue

        parsed_agent="${line%%:*}"
        parsed_task="${line#*:}"

        if candidate_agent_known "$parsed_agent"; then
            tasks+=("${parsed_agent}:${parsed_task}")
        fi
    done < "$tmp_output"
    rm -f "$tmp_output"

    if [[ ${#tasks[@]} -eq 0 ]]; then
        log_error "No subtasks extracted from $split_agent output"
        return 1
    fi

    log_info "Decomposed into ${#tasks[@]} subtasks:"
    for t in "${tasks[@]}"; do
        local agent="${t%%:*}"
        local subtask="${t#*:}"
        log_info "  -> $agent: ${subtask:0:80}..."
    done

    echo ""
    dispatch_parallel "${tasks[@]}"
}

review_default_agent() {
    local dim="$1"
    case "$dim" in
        security) echo "claude" ;;
        performance) echo "codex" ;;
        architecture) echo "claude" ;;
        maintainability) echo "codex" ;;
        accessibility) echo "gemini" ;;
        *) echo "claude" ;;
    esac
}

review_default_prompt() {
    local dim="$1"
    case "$dim" in
        security)
            echo "Review for security vulnerabilities: OWASP Top 10, input validation, authentication/authorization issues, injection risks, data exposure"
            ;;
        performance)
            echo "Review for performance issues: algorithmic complexity, unnecessary allocations, N+1 queries, caching opportunities, memory leaks"
            ;;
        architecture)
            echo "Review for architectural issues: separation of concerns, SOLID principles, testability, coupling, design patterns"
            ;;
        maintainability)
            echo "Review for maintainability: code clarity, naming conventions, technical debt, dead code, documentation gaps"
            ;;
        accessibility)
            echo "Review for accessibility: WCAG 2.1 AA compliance, color contrast, keyboard navigation, screen reader support, semantic HTML"
            ;;
        *)
            echo "Review this code for ${dim} issues"
            ;;
    esac
}

uppercase_text() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Multi-dimensional code review: dispatch parallel reviews from different angles
# Usage: dispatch_review "src/auth/" "security,performance,architecture"
dispatch_review() {
    local filepath="$1"
    local dimensions_csv="${2:-security,performance,architecture}"

    check_acpx || return 1
    local config_dims
    config_dims=$(config_get '.review_dimensions // empty' 2>/dev/null || echo "")

    # Parse dimensions
    IFS=',' read -ra dims <<< "$dimensions_csv"

    local tasks=()
    for dim in "${dims[@]}"; do
        dim=$(echo "$dim" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        local dim_upper=""
        local agent=""
        local prompt_template=""

        if [[ -n "$config_dims" ]] && [[ "$config_dims" != "null" ]]; then
            agent=$(jq -r --arg dim "$dim" '.[$dim].agent // empty' <<< "$config_dims" 2>/dev/null || true)
            prompt_template=$(jq -r --arg dim "$dim" '.[$dim].prompt // empty' <<< "$config_dims" 2>/dev/null || true)
        fi

        if [[ -z "$agent" ]]; then
            agent=$(review_default_agent "$dim")
        fi
        if [[ -z "$prompt_template" ]]; then
            prompt_template=$(review_default_prompt "$dim")
        fi

        dim_upper=$(uppercase_text "$dim")
        local full_prompt="[${dim_upper} REVIEW] Review the file/directory: ${filepath}. ${prompt_template}. Provide specific findings with file paths and line numbers where possible."

        tasks+=("${agent}:${full_prompt}")
        log_info "Review [$dim] -> $agent"
    done

    if [[ ${#tasks[@]} -eq 0 ]]; then
        log_error "No valid review dimensions specified"
        return 1
    fi

    log_info "Starting ${#tasks[@]}-dimensional code review of $filepath"
    echo ""

    # Override approval mode to read-only for reviews
    local orig_approval="${APPROVAL_MODE:-}"
    export APPROVAL_MODE="approve-reads"

    # Save original OUTPUT_JSON and force text for intermediate output
    local orig_json="${OUTPUT_JSON:-false}"
    export OUTPUT_JSON="false"

    dispatch_parallel "${tasks[@]}"
    local exit_code=$?

    # Restore settings
    if [[ -n "$orig_approval" ]]; then
        export APPROVAL_MODE="$orig_approval"
    else
        unset APPROVAL_MODE 2>/dev/null || true
    fi
    export OUTPUT_JSON="$orig_json"

    # Generate review summary
    echo ""
    echo "===== Code Review Summary: $filepath ====="
    echo "Dimensions: ${dimensions_csv}"
    echo ""

    # Collect per-dimension findings from the latest dispatch summary
    local review_json="[]"
    local dispatch_summary_json="${DISPATCH_LAST_SUMMARY_JSON:-}"
    local review_file=""
    local idx=0

    review_file=$(mktemp)
    for dim in "${dims[@]}"; do
        dim=$(echo "$dim" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        local dim_upper=""
        local agent
        agent=$(review_default_agent "$dim")
        local output=""
        local result_json="{}"

        if [[ -n "$config_dims" ]] && [[ "$config_dims" != "null" ]]; then
            local config_agent=""
            config_agent=$(jq -r --arg dim "$dim" '.[$dim].agent // empty' <<< "$config_dims" 2>/dev/null || true)
            if [[ -n "$config_agent" ]]; then
                agent="$config_agent"
            fi
        fi

        if [[ -n "$dispatch_summary_json" ]]; then
            result_json=$(jq -c ".results[$idx] // {}" <<< "$dispatch_summary_json" 2>/dev/null || echo "{}")
            agent=$(jq -r --arg default_agent "$agent" '.agent // $default_agent' <<< "$result_json")
            output=$(jq -r '.output // ""' <<< "$result_json")
        fi

        dim_upper=$(uppercase_text "$dim")
        echo "--- [${dim_upper}] reviewed by $agent ---"
        if [[ -n "$output" ]]; then
            echo "$output" | head -50
            local total_lines
            total_lines=$(echo "$output" | wc -l)
            if [[ $total_lines -gt 50 ]]; then
                echo "... (${total_lines} lines total, truncated)"
            fi
        else
            echo "(no output)"
        fi
        echo ""

        jq -n \
            --arg dim "$dim" \
            --arg agent "$agent" \
            --arg output "$output" \
            '{dimension: $dim, agent: $agent, output: $output}' \
            >> "$review_file"

        idx=$((idx + 1))
    done

    if [[ -s "$review_file" ]]; then
        review_json=$(jq -s '.' "$review_file")
    fi
    rm -f "$review_file"

    echo "===== End Review Summary ====="

    # If JSON output requested, print structured result
    if [[ "$orig_json" == "true" ]]; then
        jq -n \
            --arg filepath "$filepath" \
            --arg dimensions "$dimensions_csv" \
            --argjson reviews "$review_json" \
            --argjson failed "$exit_code" \
            '{filepath: $filepath, dimensions: $dimensions, failed: ($failed > 0), reviews: $reviews}'
    fi

    return $exit_code
}

# Run function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${@:?Usage: task-coordinator.sh <function> [args...]}"
fi
