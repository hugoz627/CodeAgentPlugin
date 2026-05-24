#!/usr/bin/env python3

import argparse
import json
import re
import shutil
from pathlib import Path


def normalize_name(name: str) -> str:
    normalized = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
    normalized = re.sub(r'-{2,}', '-', normalized)
    if not normalized:
        raise ValueError('plugin name is empty after normalization')
    return normalized


def ensure_empty_target(target: Path) -> None:
    if target.exists() and any(target.iterdir()):
        raise FileExistsError(f'target is not empty: {target}')
    target.mkdir(parents=True, exist_ok=True)


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')


def create_link(link_path: Path, target: str) -> None:
    link_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        link_path.symlink_to(target)
    except OSError:
        source = (link_path.parent / target).resolve()
        if source.is_dir():
            shutil.copytree(source, link_path)
        else:
            shutil.copy2(source, link_path)


def build_readme(plugin_name: str, display_name: str) -> str:
    return f'''# {display_name}

{display_name} 是一个单仓自包含插件仓库，同时支持 Claude Code 与 Codex。

## 目录要点

- `.claude-plugin/plugin.json`：Claude Code 插件 manifest
- `.codex-plugin/plugin.json`：Codex 插件 manifest
- `.agents/plugins/marketplace.json`：Codex repo-scoped marketplace 入口
- `commands/`：共享 command 真源
- `skills/`：共享 skill 真源
- `hooks/`：共享 hooks 真源
- `plugins/{plugin_name}/`：Codex 入口壳，应尽量只保留 symlink

## Claude Code

仓库根目录已包含 Claude Code 所需结构，可直接作为插件目录加载。

## Codex

仓库内置 `.agents/plugins/marketplace.json`，指向 `./plugins/{plugin_name}`，适合 repo-scoped 使用。
'''


def main() -> int:
    parser = argparse.ArgumentParser(description='Create a single-repo plugin scaffold for Codex and Claude Code.')
    parser.add_argument('target_dir')
    parser.add_argument('--plugin-name', required=True)
    parser.add_argument('--display-name', required=True)
    parser.add_argument('--author', required=True)
    parser.add_argument('--description', default='A plugin that supports both Codex and Claude Code from one repository.')
    args = parser.parse_args()

    plugin_name = normalize_name(args.plugin_name)
    target = Path(args.target_dir).resolve()
    ensure_empty_target(target)

    write_json(
        target / '.claude-plugin' / 'plugin.json',
        {
            'name': plugin_name,
            'version': '0.1.0',
            'description': args.description,
            'author': {'name': args.author},
            'skills': './skills/'
        },
    )
    write_json(
        target / '.claude-plugin' / 'marketplace.json',
        {
            'name': plugin_name,
            'owner': {'name': args.author},
            'metadata': {'description': args.description},
            'plugins': [
                {
                    'name': plugin_name,
                    'source': './',
                    'description': args.description,
                    'version': '0.1.0',
                    'category': 'development',
                    'tags': ['skills', 'commands', 'codex', 'claude-code'],
                }
            ],
        },
    )
    write_json(
        target / '.codex-plugin' / 'plugin.json',
        {
            'name': plugin_name,
            'version': '0.1.0',
            'description': args.description,
            'author': {'name': args.author},
            'skills': './skills/',
            'hooks': './hooks/hooks.json',
            'interface': {
                'displayName': args.display_name,
                'shortDescription': args.description,
                'longDescription': args.description,
                'developerName': args.author,
                'category': 'Productivity',
                'capabilities': ['Write', 'Interactive'],
            },
        },
    )
    write_json(
        target / '.agents' / 'plugins' / 'marketplace.json',
        {
            'name': f'{plugin_name}-marketplace',
            'interface': {'displayName': args.display_name},
            'plugins': [
                {
                    'name': plugin_name,
                    'source': {'source': 'local', 'path': f'./plugins/{plugin_name}'},
                    'policy': {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'},
                    'category': 'Productivity',
                }
            ],
        },
    )
    write_json(target / 'hooks' / 'hooks.json', {'hooks': {}})
    write_text(
        target / 'commands' / 'example-command.md',
        '---\ndescription: Example command scaffold for this plugin\n---\n\n根据当前仓库上下文完成一个示例任务。\n',
    )
    write_text(
        target / 'skills' / 'example-skill' / 'SKILL.md',
        '---\nname: example-skill\ndescription: Use when testing the scaffolded skill layout in a new plugin repository.\n---\n\n# Example Skill\n\n这是脚手架生成的示例 skill，可按实际需求替换。\n',
    )
    write_text(target / 'README.md', build_readme(plugin_name, args.display_name))
    write_text(target / '.gitignore', '__pycache__/\n.DS_Store\n')

    wrapper_root = target / 'plugins' / plugin_name
    wrapper_root.mkdir(parents=True, exist_ok=True)
    create_link(wrapper_root / '.claude-plugin', '../../.claude-plugin')
    create_link(wrapper_root / '.codex-plugin', '../../.codex-plugin')
    create_link(wrapper_root / 'commands', '../../commands')
    create_link(wrapper_root / 'skills', '../../skills')
    create_link(wrapper_root / 'hooks', '../../hooks')

    print(f'Created plugin repository scaffold at {target}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
