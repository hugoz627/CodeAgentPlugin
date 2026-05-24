# Python 项目脚手架模板（FastAPI + Poetry）

## 目录结构（API 服务）

> `<project>` 是将项目名转为 snake_case 的 Python 包名。
> 例如项目名 `MyAPI` → `my_api`，项目名 `UserService` → `user_service`。

```
src/
└── <project>/
    ├── __init__.py
    ├── types/
    │   └── __init__.py       # Pydantic models（纯类型，无 IO）
    ├── config/
    │   └── __init__.py       # pydantic-settings 配置加载
    ├── repo/
    │   └── __init__.py       # DB / 外部 IO
    ├── service/
    │   └── __init__.py       # 业务逻辑
    ├── api/
    │   ├── __init__.py       # FastAPI routers 注册
    │   └── main.py           # FastAPI app 入口
    └── providers/
        ├── __init__.py
        └── logger.py         # 日志配置（structlog）
tests/
    __init__.py
    conftest.py               # pytest fixtures
pyproject.toml
poetry.lock
```

## 初始文件内容

### src/<project>/types/__init__.py
```python
# 纯类型定义，无 IO 依赖
# Layer: types（最底层，只依赖标准库和 pydantic）
from __future__ import annotations
```

### src/<project>/config/__init__.py
```python
# 配置加载（pydantic-settings）
# Layer: config（只依赖 types/）
from __future__ import annotations
```

### src/<project>/repo/__init__.py
```python
# 数据访问层
# Layer: repo（只依赖 types/ 和 config/）
from __future__ import annotations
```

### src/<project>/service/__init__.py
```python
# 业务逻辑层
# Layer: service（只依赖 types/、config/、repo/）
from __future__ import annotations
```

### src/<project>/api/main.py
```python
# FastAPI 应用入口
# Layer: api（最外层，可依赖所有内层）
from __future__ import annotations

from fastapi import FastAPI

app = FastAPI(title="<项目名>")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
```

### src/<project>/providers/logger.py
```python
# 日志 provider（横切关注点，通过 providers/ 统一管理）
# Layer: providers（只依赖标准库和日志库）
from __future__ import annotations

import structlog

logger = structlog.get_logger()
```

### tests/conftest.py
```python
# pytest 全局 fixtures
from __future__ import annotations

import pytest
from httpx import AsyncClient, ASGITransport

from src.<project>.api.main import app


@pytest.fixture
async def client() -> AsyncClient:
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client
```

## pyproject.toml（Poetry）

```toml
[tool.poetry]
name = "<项目名>"
version = "0.1.0"
description = ""
authors = []
readme = "README.md"
packages = [{include = "<project>", from = "src"}]

[tool.poetry.dependencies]
python = "^3.12"
fastapi = "^0.115"
uvicorn = {extras = ["standard"], version = "^0.32"}
pydantic-settings = "^2.6"
structlog = "^24.4"

[tool.poetry.group.dev.dependencies]
pytest = "^8.3"
pytest-asyncio = "^0.24"
pytest-cov = "^6.0"
ruff = "^0.8"
mypy = "^1.13"
httpx = "^0.28"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "B", "SIM", "UP", "ANN"]
ignore = ["ANN101", "ANN102"]

[tool.ruff.lint.isort]
known-first-party = ["<project>"]

[tool.mypy]
strict = true
python_version = "3.12"
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

## 常用命令

```bash
# 安装依赖
poetry install

# 启动开发服务器
poetry run uvicorn src.<project>.api.main:app --reload

# 运行测试（含覆盖率）
poetry run pytest --cov=src --cov-report=term-missing

# 代码检查
poetry run ruff check src/ tests/

# 类型检查
poetry run mypy src/
```

## Lint 验证命令
```bash
poetry run ruff check src/ && poetry run mypy src/
```
