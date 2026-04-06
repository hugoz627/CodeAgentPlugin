# 部署配置模板

## Dockerfile（多阶段构建）

### TypeScript/Node.js

```dockerfile
# Stage 1: 构建
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --frozen-lockfile
COPY . .
RUN npm run build

# Stage 2: 运行时（最小化镜像）
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm ci --frozen-lockfile --omit=dev && npm cache clean --force
USER node
EXPOSE 3000
CMD ["node", "dist/runtime/index.js"]
```

### Python/FastAPI + Poetry

```dockerfile
# Stage 1: 安装依赖
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install poetry==1.8.0
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root --without dev && rm -rf $POETRY_CACHE_DIR

# Stage 2: 运行时
FROM python:3.12-slim AS runner
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
COPY src/ ./src/
USER nobody
EXPOSE 8000
CMD ["uvicorn", "src.<project>.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go

```dockerfile
# Stage 1: 构建（使用完整 Go 镜像）
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server ./cmd/server

# Stage 2: 运行时（scratch 最小化）
FROM scratch AS runner
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Rust（后端 API，非 Tauri）

```dockerfile
# Stage 1: 构建（cargo-chef 加速缓存）
FROM rust:1.82-alpine AS chef
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --release --bin server

# Stage 2: 运行时
FROM alpine:3.20 AS runner
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/target/release/server ./server
USER nobody
EXPOSE 8080
CMD ["./server"]
```

---

## docker-compose.yml（本地开发）

```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      target: builder        # 开发时用 builder stage，含调试工具
    ports:
      - "${PORT:-3000}:3000"
    volumes:
      - .:/app
      - /app/node_modules    # 防止宿主 node_modules 覆盖容器内（TS 项目）
    environment:
      - NODE_ENV=development
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME:-app_dev}
      POSTGRES_USER: ${DB_USER:-app}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-dev_password}
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-app}"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db-data:
```

---

## GitHub Actions：构建并推送镜像

### .github/workflows/build-push.yml

```yaml
name: Build and Push Image

on:
  push:
    branches: [main]
    tags: ["v*"]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: 登录 Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: 提取元数据（tag、label）
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=sha-,format=short

      - name: 设置 Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: 构建并推送
        uses: docker/build-push-action@v6
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          target: runner           # 只推送运行时 stage
```
