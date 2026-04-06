# Go 项目脚手架模板

## 目录结构

```
internal/
├── domain/
│   └── domain.go             # 纯类型 + 接口定义（无实现）
├── config/
│   └── config.go             # 配置加载
├── repo/
│   └── repo.go               # 数据访问接口 + 实现
├── service/
│   └── service.go            # 业务逻辑
├── handler/
│   └── handler.go            # HTTP / gRPC handlers
└── provider/
    └── provider.go           # 横切关注点（日志、遥测）
cmd/
└── server/
    └── main.go               # 启动入口
.golangci.yml
go.mod
go.sum
```

## 初始文件内容

### internal/domain/domain.go
```go
// Package domain 定义纯类型和接口，不包含具体实现。
// Layer: domain（最底层，只依赖标准库）
package domain
```

### internal/config/config.go
```go
// Package config 负责配置加载和校验。
// Layer: config（只依赖 domain/）
package config
```

### internal/repo/repo.go
```go
// Package repo 实现数据访问层。
// Layer: repo（只依赖 domain/ 和 config/）
package repo
```

### internal/service/service.go
```go
// Package service 包含业务逻辑。
// Layer: service（只依赖 domain/、config/、repo/）
package service
```

### internal/handler/handler.go
```go
// Package handler 处理 HTTP/gRPC 请求。
// Layer: handler（最外层，可依赖所有内层）
package handler
```

### cmd/server/main.go
```go
// main 是应用启动入口。
package main

func main() {
	// TODO: 初始化配置、依赖注入、启动服务器
}
```

## go.mod 初始内容
```
module github.com/<owner>/<项目名>

go 1.22
```

### internal/provider/provider.go
```go
// Package provider 管理横切关注点：日志、遥测、配置注入。
// 所有横切关注点统一通过此模块管理。
package provider
```

## .golangci.yml
```yaml
run:
  timeout: 5m
  go: "1.22"

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - revive
    - godot
    - misspell

linters-settings:
  revive:
    rules:
      - name: exported
        severity: warning
      - name: error-return
      - name: error-naming
      - name: if-return
      - name: var-naming
  goimports:
    local-prefixes: github.com/<owner>/<项目名>
  godot:
    scope: declarations
    capital: false

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - errcheck
```

## Lint 验证命令
```bash
golangci-lint run ./...
```
