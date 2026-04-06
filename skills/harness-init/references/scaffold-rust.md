# Rust 项目脚手架模板

## 目录结构

```
src/
├── types.rs                  # 纯类型定义（struct、enum、trait）
├── config.rs                 # 配置加载（config crate）
├── repo/
│   └── mod.rs                # 数据访问层
├── service/
│   └── mod.rs                # 业务逻辑层
├── api/
│   └── mod.rs                # axum/actix handlers
├── providers/
│   └── mod.rs                # 横切关注点（日志、遥测）
└── main.rs                   # 启动入口
Cargo.toml
.clippy.toml
rust-toolchain.toml
```

## 初始文件内容

### src/types.rs
```rust
//! 纯类型定义。
//! Layer: types（最底层，只依赖标准库和 serde）
```

### src/config.rs
```rust
//! 配置加载和校验。
//! Layer: config（只依赖 types）
```

### src/repo/mod.rs
```rust
//! 数据访问层。
//! Layer: repo（只依赖 types 和 config）
```

### src/service/mod.rs
```rust
//! 业务逻辑层。
//! Layer: service（只依赖 types、config、repo）
```

### src/api/mod.rs
```rust
//! HTTP handlers（axum）。
//! Layer: api（最外层，可依赖所有内层）
```

### src/providers/mod.rs
```rust
//! 横切关注点：日志、遥测、配置注入。
//! 所有横切关注点统一通过此模块管理。

/// 日志初始化器
pub fn init_logger() {
    tracing_subscriber::fmt::init();
}
```

### src/main.rs
```rust
//! 应用启动入口。
mod api;
mod config;
mod providers;
mod repo;
mod service;
mod types;

#[tokio::main]
async fn main() {
    // TODO: 初始化配置、构建路由、启动服务
}
```

## Cargo.toml
```toml
[package]
name = "<项目名>"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["full"] }
axum = "0.7"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
thiserror = "1"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

[dev-dependencies]
tokio-test = "0.4"
axum-test = "15"
```

## .clippy.toml
```toml
# 所有公开 API 必须有文档
missing-docs-in-private-items = false

# 避免过于复杂的函数
cognitive-complexity-threshold = 25
```

> 注意：`deny(unwrap)` 和 `deny(unused_result)` 规则应在 `.clippy.toml` 之外的 `src/lib.rs` 或 CI 中通过 `cargo clippy -- -D clippy::unwrap_used` 启用，
> 因为 `.clippy.toml` 本身不支持 deny/warn/allow lint 级别配置。
> 在 AGENTS.md 中注明：禁止在生产代码中使用 `unwrap()`，测试代码除外；用 `?` 或 `expect("明确的错误原因")` 替代。

## rust-toolchain.toml
```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
```

## Lint 验证命令
```bash
cargo clippy -- -D warnings && cargo fmt --check
```
