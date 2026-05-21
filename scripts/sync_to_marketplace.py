#!/usr/bin/env python3

import json
import shutil
import sys
from pathlib import Path


def copy_path(src: Path, dst: Path) -> None:
    if dst.exists() or dst.is_symlink():
        if dst.is_dir() and not dst.is_symlink():
            shutil.rmtree(dst)
        else:
            dst.unlink()
    if src.is_dir():
        shutil.copytree(src, dst)
    else:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: sync_to_marketplace.py <marketplace-repo-path>")
        return 1

    source_root = Path(__file__).resolve().parent.parent
    marketplace_root = Path(sys.argv[1]).resolve()
    plugin_root = marketplace_root / "plugins" / "code-agent-plugin"

    plugin_root.mkdir(parents=True, exist_ok=True)

    copy_path(source_root / ".codex-plugin", plugin_root / ".codex-plugin")
    copy_path(source_root / "commands", plugin_root / "commands")
    copy_path(source_root / "skills", plugin_root / "skills")
    copy_path(source_root / "hooks" / "hooks.json", plugin_root / "hooks.json")

    marketplace = {
        "name": "code-agent-marketplace",
        "interface": {
            "displayName": "Code Agent Marketplace"
        },
        "plugins": [
            {
                "name": "code-agent-plugin",
                "source": {
                    "source": "local",
                    "path": "./plugins/code-agent-plugin"
                },
                "policy": {
                    "installation": "AVAILABLE",
                    "authentication": "ON_INSTALL"
                },
                "category": "Productivity"
            }
        ]
    }
    marketplace_path = marketplace_root / ".agents" / "plugins" / "marketplace.json"
    marketplace_path.parent.mkdir(parents=True, exist_ok=True)
    marketplace_path.write_text(
        json.dumps(marketplace, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
