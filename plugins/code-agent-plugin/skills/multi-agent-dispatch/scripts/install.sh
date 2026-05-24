#!/bin/bash
# install.sh - 安装 multi-agent-dispatch skill 到指定目录

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="$(basename "$SKILL_DIR")"
DEFAULT_TARGET="${HOME}/.codex/skills/${SKILL_NAME}"

usage() {
    cat <<EOF
Usage:
  install.sh [--target <dir>]
  install.sh --codex

Options:
  --target <dir>   Install to an explicit directory
  --codex          Install to ${DEFAULT_TARGET}

Default:
  If no option is provided, installs to ${DEFAULT_TARGET}
EOF
}

target_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            shift
            target_dir="${1:-}"
            if [[ -z "$target_dir" ]]; then
                echo "Missing value for --target" >&2
                exit 1
            fi
            ;;
        --codex)
            target_dir="$DEFAULT_TARGET"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

target_dir="${target_dir:-$DEFAULT_TARGET}"

mkdir -p "$(dirname "$target_dir")"
rm -rf "$target_dir"
cp -R "$SKILL_DIR" "$target_dir"
chmod +x "$target_dir/scripts/"*.sh

echo "Installed ${SKILL_NAME} to: $target_dir"
