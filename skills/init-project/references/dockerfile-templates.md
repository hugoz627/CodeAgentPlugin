# Dockerfile 模板

## Python (FastAPI/Flask)

```dockerfile
FROM python:3.12-slim AS base

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

COPY . .
RUN mkdir -p logs

EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Go

```dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/server ./cmd/server

FROM alpine:3.19
WORKDIR /app
COPY --from=builder /bin/server .
RUN mkdir -p logs

EXPOSE 8080
CMD ["./server"]
```

## TypeScript (Node.js)

```dockerfile
FROM node:20-slim AS builder

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .
RUN mkdir -p logs

EXPOSE 3000
CMD ["node", "dist/index.js"]
```
