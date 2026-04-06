# CI 模板文件

## ci/lint-docs.yml（GitHub Actions）

name: Lint Docs

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  lint-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 检查 AGENTS.md 行数
        run: |
          lines=$(wc -l < AGENTS.md)
          if [ "$lines" -gt 100 ]; then
            echo "AGENTS.md 超过 100 行（当前 $lines 行），请保持精简"
            exit 1
          fi
          echo "AGENTS.md 行数检查通过：$lines 行"

      - name: 检查必要文档存在
        run: |
          failed=0
          for f in AGENTS.md CLAUDE.md ARCHITECTURE.md \
                   docs/design-docs/core-beliefs.md \
                   docs/product-specs/index.md; do
            if [ ! -f "$f" ]; then
              echo "缺少必要文档: $f"
              failed=1
            fi
          done
          if [ $failed -eq 1 ]; then exit 1; fi
          echo "必要文档检查通过"

      - name: 检查 exec-plans 目录结构
        run: |
          for d in docs/exec-plans/active docs/exec-plans/completed; do
            if [ ! -d "$d" ]; then
              echo "缺少目录: $d"
              exit 1
            fi
          done
          echo "exec-plans 目录检查通过"

      - name: 检查文档无空文件（非 .gitkeep）
        run: |
          empty=$(find docs/ -name "*.md" -empty 2>/dev/null)
          if [ -n "$empty" ]; then
            echo "发现空的 Markdown 文档："
            echo "$empty"
            exit 1
          fi
          echo "文档内容检查通过"

## ci/lint-arch.yml（GitHub Actions）

name: Lint Architecture

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  lint-arch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 检测项目语言
        id: detect
        run: |
          if [ -f "package.json" ]; then echo "lang=typescript" >> $GITHUB_OUTPUT
          elif [ -f "pyproject.toml" ]; then echo "lang=python" >> $GITHUB_OUTPUT
          elif [ -f "go.mod" ]; then echo "lang=go" >> $GITHUB_OUTPUT
          elif [ -f "Cargo.toml" ]; then echo "lang=rust" >> $GITHUB_OUTPUT
          elif [ -f "pubspec.yaml" ]; then echo "lang=flutter" >> $GITHUB_OUTPUT
          else echo "lang=unknown" >> $GITHUB_OUTPUT
          fi

      - name: TypeScript lint
        if: steps.detect.outputs.lang == 'typescript'
        run: npx biome check src/

      - name: Set up Python
        if: steps.detect.outputs.lang == 'python'
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: Python lint
        if: steps.detect.outputs.lang == 'python'
        run: |
          pip install ruff==0.7.0 mypy==1.13.0
          ruff check src/
          mypy src/

      - name: Go lint
        if: steps.detect.outputs.lang == 'go'
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest

      - name: Rust lint
        if: steps.detect.outputs.lang == 'rust'
        run: cargo clippy -- -D warnings

      - name: Flutter lint
        if: steps.detect.outputs.lang == 'flutter'
        run: flutter analyze

## docker-compose.observability.yml（可选 Layer 4）

version: "3.8"

services:
  vector:
    image: timberio/vector:0.39-alpine
    volumes:
      - ./vector.toml:/etc/vector/vector.toml:ro
      - /var/log:/var/log:ro
    ports:
      - "8686:8686"
    restart: unless-stopped

  victoria-logs:
    image: victoriametrics/victoria-logs:latest
    ports:
      - "9428:9428"
    volumes:
      - victoria-logs-data:/victoria-logs-data
    restart: unless-stopped

  victoria-metrics:
    image: victoriametrics/victoria-metrics:latest
    ports:
      - "8428:8428"
    volumes:
      - victoria-metrics-data:/victoria-metrics-data
    restart: unless-stopped

volumes:
  victoria-logs-data:
  victoria-metrics-data:
