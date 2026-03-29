# 部署脚本模板

## docker-compose.yml 基础模板

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "${PORT:-8000}:8000"
    volumes:
      - ./logs:/app/logs
      - ./.env:/app/.env:ro
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
    env_file:
      - .env
```

## deploy.sh 基础模板

```bash
#!/bin/bash
set -euo pipefail

# 配置
APP_NAME="${APP_NAME:-myapp}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/$APP_NAME}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=== 部署 $APP_NAME ==="

# 构建镜像
if [ -n "$DOCKER_REGISTRY" ]; then
    IMAGE="$DOCKER_REGISTRY/$APP_NAME:$IMAGE_TAG"
    docker build -t "$IMAGE" .
    docker push "$IMAGE"
else
    IMAGE="$APP_NAME:$IMAGE_TAG"
    docker build -t "$IMAGE" .
fi

# 部署
cd "$DEPLOY_DIR"
docker compose pull 2>/dev/null || true
docker compose up -d

echo "=== 部署完成 ==="
docker compose ps
```

## systemd service 模板

```ini
[Unit]
Description={{APP_NAME}} Service
After=network.target

[Service]
Type=simple
User={{USER}}
WorkingDirectory={{WORK_DIR}}
ExecStart={{EXEC_START}}
Restart=on-failure
RestartSec=5
StandardOutput=append:{{WORK_DIR}}/logs/stdout.log
StandardError=append:{{WORK_DIR}}/logs/stderr.log

[Install]
WantedBy=multi-user.target
```
