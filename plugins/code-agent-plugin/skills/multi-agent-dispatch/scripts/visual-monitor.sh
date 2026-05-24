#!/bin/bash
# visual-monitor.sh - Visual pane backends for tmux, Ghostty, and iTerm2

set -euo pipefail

VISUAL_AVAILABLE=false
VISUAL_BACKEND_ACTIVE=""
VISUAL_TARGET_ID=""
VISUAL_BASE_SURFACE=""
VISUAL_TEMP_FILES=()

visual_split_enabled_for_backend() {
    local backend="${1:-}"
    local mode="${VISUAL_SPLIT_MODE:-auto}"

    case "$mode" in
        on) return 0 ;;
        off) return 1 ;;
        auto)
            case "$backend" in
                tmux) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
}

visual_log() {
    local level="$1"
    shift
    case "$level" in
        info)  echo "[visual] $*" ;;
        warn)  echo "[visual] $*" >&2 ;;
        error) echo "[visual] $*" >&2 ;;
    esac
}

visual_backend_resolve() {
    local requested="${1:-auto}"
    case "$requested" in
        auto)
            if [[ -n "${TMUX:-}" ]]; then
                echo "tmux"
            elif [[ "${TERM_PROGRAM:-}" == "ghostty" ]]; then
                echo "ghostty"
            elif [[ "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
                echo "iterm2"
            else
                echo ""
            fi
            ;;
        tmux|ghostty|iterm2)
            echo "$requested"
            ;;
        *)
            echo ""
            ;;
    esac
}

visual_backend_is_available() {
    local backend="$1"
    case "$backend" in
        tmux)
            command -v tmux >/dev/null 2>&1
            ;;
        ghostty)
            osascript -e 'id of application "Ghostty"' >/dev/null 2>&1
            ;;
        iterm2)
            osascript -e 'id of application "iTerm"' >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

visual_init_tmux() {
    local session_name="${VISUAL_TMUX_SESSION_NAME:-dispatch-visual-$$}"
    if [[ -n "${TMUX:-}" ]]; then
        local current_pane current_target
        current_pane="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}"
        current_target="$(tmux display-message -p -t "$current_pane" '#{session_name}:#{window_name}')"
        VISUAL_TARGET_ID="$current_target"
        VISUAL_BASE_SURFACE="$current_pane"
        event_print "[Multi-Agent Dispatch] VISUAL tmux target=current-window"
    else
        tmux new-session -d -s "$session_name" -n "dispatch-visual"
        VISUAL_TARGET_ID="${session_name}:dispatch-visual"
        VISUAL_BASE_SURFACE="$(tmux display-message -p -t "$VISUAL_TARGET_ID" '#{pane_id}')"
        event_print "[Multi-Agent Dispatch] VISUAL tmux session=$session_name"
        event_print "  attach: tmux attach -t $session_name"
    fi
}

visual_init_ghostty() {
    local output
    local open_new_window="${VISUAL_NEW_WINDOW:-false}"
    output="$(
        osascript <<APPLESCRIPT
set forceNewWindow to ${open_new_window}
tell application "Ghostty"
  activate
  set cfg to new surface configuration
  if (count of windows) is 0 or forceNewWindow then
    set win to new window with configuration cfg
  else
    set win to front window
  end if
  tell selected tab of win
    set baseTerminal to terminal 1
    return (id of win) & linefeed & (id of baseTerminal)
  end tell
end tell
APPLESCRIPT
    )"
    VISUAL_TARGET_ID="$(printf '%s' "$output" | sed -n '1p')"
    VISUAL_BASE_SURFACE="$(printf '%s' "$output" | sed -n '2p')"
}

visual_init_iterm2() {
    local output
    local open_new_window="${VISUAL_NEW_WINDOW:-false}"
    output="$(
        osascript <<APPLESCRIPT
set forceNewWindow to ${open_new_window}
tell application "iTerm"
  activate
  if (count of windows) is 0 or forceNewWindow then
    create window with default profile
  end if
  tell current window
    tell current tab
      set baseSession to current session
      return (id of current window) & linefeed & (id of baseSession)
    end tell
  end tell
end tell
APPLESCRIPT
    )"
    VISUAL_TARGET_ID="$(printf '%s' "$output" | sed -n '1p')"
    VISUAL_BASE_SURFACE="$(printf '%s' "$output" | sed -n '2p')"
}

visual_init() {
    local requested="${1:-auto}"
    local resolved=""

    VISUAL_AVAILABLE=false
    VISUAL_BACKEND_ACTIVE=""
    VISUAL_TARGET_ID=""
    VISUAL_BASE_SURFACE=""

    resolved="$(visual_backend_resolve "$requested")"
    [[ -n "$resolved" ]] || return 1
    visual_backend_is_available "$resolved" || return 1

    case "$resolved" in
        tmux) visual_init_tmux ;;
        ghostty) visual_init_ghostty ;;
        iterm2) visual_init_iterm2 ;;
    esac

    VISUAL_BACKEND_ACTIVE="$resolved"
    VISUAL_AVAILABLE=true
    event_print "[Multi-Agent Dispatch] VISUAL backend=$resolved"
    return 0
}

visual_create_split_pane() {
    local direction="${1:-right}"
    local agent_name="${2:-agent}"
    local surface=""

    [[ "$VISUAL_AVAILABLE" == "true" ]] || return 1

    case "$VISUAL_BACKEND_ACTIVE" in
        tmux)
            if [[ -z "$VISUAL_BASE_SURFACE" ]]; then
                return 1
            fi
            if [[ "$direction" == "down" ]]; then
                surface="$(tmux split-window -v -P -F '#{pane_id}' -t "$VISUAL_BASE_SURFACE")"
            else
                surface="$(tmux split-window -h -P -F '#{pane_id}' -t "$VISUAL_BASE_SURFACE")"
            fi
            tmux select-layout -t "$VISUAL_TARGET_ID" tiled >/dev/null 2>&1 || true
            ;;
        ghostty)
            surface="$(
                osascript <<APPLESCRIPT
tell application "Ghostty"
  tell (first window whose id is "${VISUAL_TARGET_ID}")
    tell selected tab
      set baseTerminal to first terminal whose id is "${VISUAL_BASE_SURFACE}"
      set newTerminal to split baseTerminal direction ${direction}
      return id of newTerminal
    end tell
  end tell
end tell
APPLESCRIPT
            )"
            ;;
        iterm2)
            surface="$(
                osascript <<APPLESCRIPT
tell application "iTerm"
  tell (first window whose id is "${VISUAL_TARGET_ID}")
    tell current tab
      set baseSession to first session whose id is "${VISUAL_BASE_SURFACE}"
      tell baseSession
        if "${direction}" is "down" then
          set newSession to split vertically with default profile
        else
          set newSession to split horizontally with default profile
        end if
        return id of newSession
      end tell
    end tell
  end tell
end tell
APPLESCRIPT
            )"
            ;;
    esac

    [[ -n "$surface" ]] || return 1
    echo "$surface"
}

visual_send_command() {
    local surface_id="$1"
    local command="$2"
    case "$VISUAL_BACKEND_ACTIVE" in
        tmux)
            tmux send-keys -t "$surface_id" "$command" Enter
            ;;
        ghostty)
            osascript <<APPLESCRIPT >/dev/null
tell application "Ghostty"
  tell (first window whose id is "${VISUAL_TARGET_ID}")
    tell selected tab
      set cmdText to "${command//\"/\\\"}" & linefeed
      input text cmdText to (first terminal whose id is "${surface_id}")
    end tell
  end tell
end tell
APPLESCRIPT
            ;;
        iterm2)
            osascript <<APPLESCRIPT >/dev/null
tell application "iTerm"
  tell (first window whose id is "${VISUAL_TARGET_ID}")
    tell current tab
      write text "${command//\"/\\\"}" to (first session whose id is "${surface_id}")
    end tell
  end tell
end tell
APPLESCRIPT
            ;;
    esac
}

visual_create_stream_script() {
    local log_file="$1"
    local status_file="$2"
    local agent_name="${3:-agent}"
    local temp_root="${TMPDIR:-/tmp}/multi-agent-dispatch-visual"
    local script_path=""

    mkdir -p "$temp_root"
    script_path="$(mktemp "$temp_root/${agent_name}.XXXXXX")"
    cat > "$script_path" <<EOF
#!/bin/bash
clear
echo '=== ${agent_name} output ==='
echo '[visual] waiting for output...'
touch '${log_file}'
tail -n +1 -f '${log_file}' &
TAIL_PID=\$!
while [[ ! -f '${status_file}' ]] || grep -q '^running$' '${status_file}'; do
    sleep 0.2
done
kill \$TAIL_PID >/dev/null 2>&1 || true
wait \$TAIL_PID 2>/dev/null || true
echo
echo '[visual] ${agent_name} finished'
EOF
    chmod +x "$script_path"
    VISUAL_TEMP_FILES+=("$script_path")
    printf '%s' "$script_path"
}

visual_build_stream_command() {
    local script_path="$1"
    printf "bash '%s'" "$script_path"
}

visual_stream_to_surface() {
    local surface_id="$1"
    local log_file="$2"
    local status_file="$3"
    local agent_name="${4:-agent}"
    local script_path=""
    [[ "$VISUAL_AVAILABLE" == "true" ]] || return 0
    touch "$log_file" 2>/dev/null || true
    script_path="$(visual_create_stream_script "$log_file" "$status_file" "$agent_name")"
    case "$VISUAL_BACKEND_ACTIVE" in
        tmux)
            tmux respawn-pane -k -t "$surface_id" "$(visual_build_stream_command "$script_path")"
            ;;
        *)
            visual_send_command "$surface_id" "$(visual_build_stream_command "$script_path")"
            ;;
    esac
}

visual_set_agent_status() {
    :
}

visual_cleanup() {
    local path=""
    for path in "${VISUAL_TEMP_FILES[@]:-}"; do
        rm -f "$path" 2>/dev/null || true
    done
    VISUAL_TEMP_FILES=()
}
