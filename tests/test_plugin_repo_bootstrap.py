import json
import subprocess
import tempfile
import unittest
from pathlib import Path


class PluginRepoBootstrapTest(unittest.TestCase):
    def test_scaffold_creates_single_repo_dual_platform_layout(self) -> None:
        repo_root = Path(__file__).resolve().parent.parent
        script = repo_root / 'skills' / 'plugin-repo-bootstrap' / 'scripts' / 'create_plugin_repo.py'

        with tempfile.TemporaryDirectory() as tmp_dir:
            target = Path(tmp_dir) / 'demo-plugin'
            result = subprocess.run(
                [
                    'python3',
                    str(script),
                    str(target),
                    '--plugin-name',
                    'demo-plugin',
                    '--display-name',
                    'Demo Plugin',
                    '--author',
                    'Acme',
                ],
                cwd=repo_root,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr)

            claude_manifest = json.loads((target / '.claude-plugin' / 'plugin.json').read_text())
            codex_manifest = json.loads((target / '.codex-plugin' / 'plugin.json').read_text())
            marketplace = json.loads((target / '.agents' / 'plugins' / 'marketplace.json').read_text())

            self.assertEqual(claude_manifest['name'], 'demo-plugin')
            self.assertEqual(codex_manifest['name'], 'demo-plugin')
            self.assertEqual(codex_manifest['hooks'], './hooks/hooks.json')
            self.assertEqual(
                marketplace['plugins'][0]['source']['path'],
                './plugins/demo-plugin',
            )

            wrapper = target / 'plugins' / 'demo-plugin'
            self.assertTrue((wrapper / '.codex-plugin').is_symlink())
            self.assertTrue((wrapper / '.claude-plugin').is_symlink())
            self.assertTrue((wrapper / 'commands').is_symlink())
            self.assertTrue((wrapper / 'skills').is_symlink())
            self.assertTrue((wrapper / 'hooks').is_symlink())
            self.assertTrue((wrapper / 'hooks' / 'hooks.json').is_file())

            self.assertTrue((target / 'commands' / 'example-command.md').is_file())
            self.assertTrue((target / 'skills' / 'example-skill' / 'SKILL.md').is_file())
            readme = (target / 'README.md').read_text()
            self.assertIn('Claude Code', readme)
            self.assertIn('Codex', readme)


if __name__ == '__main__':
    unittest.main()
