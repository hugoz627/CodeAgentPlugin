# Python 开发规范

## 类型系统

- 优先使用 pydantic BaseModel 定义数据结构，少用 dict 类型
- 非特殊情况不使用 getattr/setattr/hasattr 等动态语法
- 所有函数必须有 type hints 标注参数和返回值类型
- 使用 Enum 替代魔法字符串
- 配置项使用 pydantic Settings 管理

## 日志

- 使用 loguru 作为日志库，配置文件 sink
- 配置示例：
  ```python
  from loguru import logger
  logger.add("logs/app.log", rotation="100 MB", retention="7 days", encoding="utf-8")
  ```

## 异步

- 异步 HTTP 客户端使用 httpx，避免在异步代码中使用 requests（会阻塞事件循环）
- 异步框架优先使用 FastAPI

## 依赖管理

- 使用 pyproject.toml 管理项目元数据和依赖
- 使用 uv 或 poetry 做依赖管理
