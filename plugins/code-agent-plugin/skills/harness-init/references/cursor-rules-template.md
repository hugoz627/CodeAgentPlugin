# Cursor Rules 模板

## 目录结构

```
.cursor/rules/
├── core.mdc          # Always Apply（每次对话都加载，< 200 词）
└── <lang>.mdc        # Auto Attached（按文件 glob 触发）
```

激活模式：Always Apply（核心约束）/ Auto Attached（glob 触发）/ Agent Requested（按需）/ Manual（显式调用）

---

## core.mdc（Always Apply，所有语言共用）

```yaml
---
description: 核心项目规范，始终加载
alwaysApply: true
---

# <项目名> 核心规范

## 技术栈
<语言> <框架> <版本号>

## 架构层次（依赖方向）
```
types → config → repo → service → runtime → api/handler
```
横切关注点（认证、日志、遥测）只能通过 `providers/` 接口进入，不得直接引用。

## 通用约定
- 代码注释使用中文，变量/函数名使用英文
- 日志内容（log message）使用英文
- Git 提交：`type(scope): 中文描述`（Conventional Commits）
  - 类型：feat / fix / refactor / docs / test / chore / perf / ci

## 日志要求
- 核心业务路径入口/出口必须打印日志
- 所有异常/错误路径必须打印日志（含错误详情）
- 后端和客户端都需要文件日志（不只输出 stdout）

## 常量与配置
- 禁止魔法数字和魔法字符串，提取为具名常量或枚举
- 所有配置值（URL、端口、超时、密钥）从环境变量读取，禁止硬编码

## 安全
- 输入校验在 api/handler 层（边界层）统一处理
- 数据库查询必须使用参数化查询，禁止字符串拼接 SQL
- 对外错误信息不暴露内部细节（堆栈、SQL、路径等）
- 密码必须用 bcrypt 或 argon2 哈希存储（cost ≥ 12 / memory ≥ 64MB）；禁止 MD5、SHA-1、SHA-256 直接存密码
- 敏感字段（密码、token、密钥）禁止写入日志

## 禁止事项
- 不跳过 linter（禁止 `--no-verify`、`# noqa`、`@ts-ignore` 等）
- 不硬编码密钥或凭证

## 知识库
通用规范见 [AGENTS.md](../../AGENTS.md)
```

---

## typescript.mdc（Auto Attached，适用 TS/TSX 文件）

```yaml
---
description: TypeScript/Node.js 编码规范，AI 在修改 TS/TSX 文件时自动加载
globs: ["src/**/*.ts", "src/**/*.tsx", "tests/**/*.ts"]
alwaysApply: false
---

## TypeScript 规范

### 语言与工具
- Linter：biome（必须通过），不用 eslint/prettier
- 严格模式：strict + noUncheckedIndexedAccess + noImplicitOverride
- 函数优先于类（测试用 class 除外）
- 模块系统：仅使用 ESM，禁止 require()
- 命名：变量/函数 camelCase，类型/接口 PascalCase，文件 kebab-case

### 常量与配置
- 魔法数字/字符串提取为 `const` 或 `as const` 枚举
  ```typescript
  // ✅
  const MAX_RETRY_COUNT = 3
  const OrderStatus = { PENDING: "pending", PAID: "paid" } as const
  // ❌
  if (retries > 3) { ... }
  ```
- 所有配置从 `process.env` 读取，用 zod 在启动时校验
  ```typescript
  const Config = z.object({ DATABASE_URL: z.string().url(), PORT: z.coerce.number() })
  export const config = Config.parse(process.env)
  ```

### Null/Undefined 处理
- 禁止 `!` 非空断言（除非有明确注释说明为何不可能为 null）
- 用可选链 `?.` 和空值合并 `??` 替代
- 函数返回值明确：返回 `T | null` 并强制调用方处理

### 函数规范
- 单个函数不超过 50 行；超过则拆分
- 圈复杂度不超过 10（biome 已配置）
- 单一职责：一个函数只做一件事

### 错误处理
- 自定义错误类继承 `Error`，含 `code` 字段
- 对外 API 错误：只返回 `{ code, message }`，不暴露堆栈/内部路径
- 禁止吞错（空 catch 块）
- 异步：async/await，不用回调嵌套

### 安全
- API 入参用 zod schema 校验，放在 handler 层
- 数据库操作用 ORM 或参数化查询，禁止拼接 SQL

### 日志（pino）
```typescript
// 核心路径入口
logger.info({ userId, action: "checkout.start" }, "Starting checkout process")
// 异常路径
logger.error({ err, orderId }, "Failed to process payment")
```
- 生产环境写入文件：`pino({ transport: { target: "pino/file", options: { destination: "./logs/app.log" } } })`
- 所有 catch 块必须调用 `logger.error`，不能只 console.error

### 资源清理
- 数据库连接、文件句柄等在 finally 块或 `using` 声明中释放
- HTTP 客户端复用实例，不在每次请求中新建

### 单元测试（vitest）
- 文件命名：`*.test.ts`，与被测文件同目录或 `tests/` 下
- 结构：`describe` 描述模块，`it` 描述行为（用中文描述）
  ```typescript
  describe("OrderService", () => {
    it("创建订单时库存不足应抛出 InsufficientStockError", async () => { ... })
  })
  ```
- **测试行为，不测实现**：优先通过公开接口测试行为；若私有方法含重要逻辑，提取为独立纯函数/模块后直接测，不用反射/强制访问绕过可见性
- **Mock 只在层边界**：service 层测试 mock repo，不 mock service 内部逻辑
- **AAA 结构**：Arrange（准备）/ Act（执行）/ Assert（断言）
- 覆盖率目标：核心业务逻辑 ≥ 80%，工具函数 ≥ 90%
- 禁止在测试中使用 `any` 类型，测试数据用工厂函数生成

### 代码注释
- 函数/类/复杂逻辑必须有中文注释说明意图
- 参数含义不明显时加中文行内注释
```

---

## python.mdc（Auto Attached，适用 Python 文件）

```yaml
---
description: Python/FastAPI 编码规范，AI 在修改 Python 文件时自动加载
globs: ["src/**/*.py", "tests/**/*.py"]
alwaysApply: false
---

## Python 规范

### 类型系统（强制）
- 所有函数参数和返回值必须有类型注解
- 数据结构使用 Pydantic BaseModel，**禁止**用 `dict` 传递业务数据
- **禁止** `getattr` / `setattr`（用 `model.field` 直接访问）
- **禁止** `Any` 类型（除第三方库接口边界，需加注释说明原因）
- 动态构造对象用 `Model.model_validate(data)`，不用手动 setattr

### Pydantic V2 API（必须使用 V2 语法）
- 验证器：`@field_validator` + `@model_validator`，**禁止**旧的 `@validator`
- 配置：`model_config = ConfigDict(...)` **禁止**内嵌 `class Config`
- 解析：`Model.model_validate(data)`，**禁止** `Model.parse_obj(data)`
- 序列化：`model.model_dump()`，**禁止** `model.dict()`
- 类型提示：`X | None` 优先于 `Optional[X]`；`Annotated[T, Field(...)]` 用于字段约束
  ```python
  # ✅ Pydantic V2
  class UserCreate(BaseModel):
      model_config = ConfigDict(str_strip_whitespace=True)
      email: str
      age: int | None = None

      @field_validator("email")
      @classmethod
      def validate_email(cls, v: str) -> str:
          return v.lower()

  # ❌ Pydantic V1（禁止）
  class UserCreate(BaseModel):
      class Config:
          anystr_strip_whitespace = True
      @validator("email")
      def validate_email(cls, v): ...
  ```

```python
# ✅
class OrderItem(BaseModel):
    product_id: str
    quantity: int
def create_order(item: OrderItem) -> OrderResult: ...

# ❌
def create_order(item: dict) -> dict: ...
def create_order(item):
    setattr(item, "status", "pending")
```

### 常量与配置
- 字符串常量用 `Enum` 或 `Literal` 类型，禁止散落魔法字符串
  ```python
  class OrderStatus(str, Enum):
      PENDING = "pending"
      PAID = "paid"
  ```
- 所有配置通过 pydantic-settings 从环境变量加载，禁止硬编码
  ```python
  class Settings(BaseSettings):
      database_url: str
      redis_url: str
      jwt_secret: SecretStr
  settings = Settings()
  ```

### Null/Optional 处理
- 可能为 None 的返回值必须标注 `Optional[T]` 或 `T | None`
- 调用方必须显式处理 None，禁止直接 `.` 访问未经 None 检查的值
- 禁止用 `or` 短路代替 None 检查（`x or default` 会误处理 0/False/""）

### 函数规范
- 单个函数不超过 50 行；超过则拆分
- 圈复杂度不超过 10（ruff C901 规则）
- 单一职责：一个函数只做一件事

### 错误处理
- 自定义异常继承项目基础异常类，含 `code` 和 `message`
- FastAPI 统一异常处理器将内部异常转为安全的 HTTP 响应
- 禁止在 `except` 中 `pass`（必须至少打日志）

### 安全
- FastAPI 路由入参通过 Pydantic schema 自动校验
- 数据库查询使用 SQLAlchemy ORM 或参数化语句，禁止字符串拼接
- 对外响应不包含堆栈信息、数据库错误、内部路径

### 工具链
- 依赖管理：Poetry（pyproject.toml），不直接 `pip install`
- Linter：ruff（E/F/I/N/B/SIM/UP/C4/C901），类型检查：mypy strict
- Pydantic models 只放 `types/` 层

### 资源清理
- IO 操作（文件、DB 连接、HTTP 客户端）必须用 `async with` / `with` 管理
- 数据库 session 通过 FastAPI Depends 注入，不手动创建/关闭

### 日志（structlog）
```python
logger.info("order.create.start", user_id=user_id, product_id=item.product_id)
logger.error("order.create.failed", error=str(e), order_id=order_id)
```
- 配置文件日志：structlog + logging.FileHandler，写入 `./logs/app.log`
- 所有 `except` 块必须打日志，禁止 `pass` 或只 `print`

### 单元测试（pytest）
- 文件命名：`test_<module>.py`，放在 `tests/` 下，镜像 `src/` 结构
- 函数命名：`test_<描述>` （英文），docstring 用中文说明测试意图
  ```python
  def test_create_order_insufficient_stock_raises_error():
      """库存不足时应抛出 InsufficientStockError"""
  ```
- **测试行为，不测实现**：优先通过公开接口测试行为；若私有方法含重要逻辑，提取为独立纯函数/模块后直接测，不用反射/强制访问绕过可见性
- **Mock 只在层边界**：service 测试 mock repo 接口，不 mock service 内部
  ```python
  # ✅ mock repo 层
  repo = MagicMock(spec=OrderRepo)
  service = OrderService(repo=repo)
  # ❌ mock service 内部方法
  service._calculate_price = MagicMock()
  ```
- **AAA 结构**：Arrange / Act / Assert，用空行分隔
- Fixtures 放 `conftest.py`，测试数据用工厂函数，不散落在测试中
- 覆盖率目标：service 层 ≥ 80%，types/config 层 ≥ 90%
- 异步测试用 `pytest-asyncio`，标注 `@pytest.mark.asyncio`

### 代码注释
- 函数/类必须有中文文档字符串说明意图（用 `"""..."""`）
- 复杂逻辑加中文行内注释

### 异步
- FastAPI 路由用 `async def`，同步 IO 用 `asyncio.to_thread`
```

---

## go.mdc（Auto Attached，适用 Go 文件）

```yaml
---
description: Go 编码规范，AI 在修改 Go 文件时自动加载
globs: ["**/*.go"]
alwaysApply: false
---

## Go 规范

### 常量与配置
- 魔法数字/字符串提取为 `const` 块或 `iota` 枚举
  ```go
  const (
      MaxRetryCount = 3
      DefaultTimeout = 30 * time.Second
  )
  type OrderStatus string
  const (
      OrderPending OrderStatus = "pending"
      OrderPaid    OrderStatus = "paid"
  )
  ```
- 配置结构体字段通过环境变量加载（envconfig/viper），禁止硬编码

### Nil 处理
- 返回值可能为 nil 时在注释中明确说明
- 调用方必须在使用前检查 nil，不依赖"应该不会是 nil"的假设
- 接口值的 nil 判断注意类型 nil 与接口 nil 的区别

### 函数规范
- 单个函数不超过 50 行；超过则拆分
- 错误处理：明确 handle，不用 `_` 忽略错误返回
- 错误包装：`fmt.Errorf("context: %w", err)` 保留调用链
- **所有可能阻塞的函数**（数据库、HTTP、文件、channel 等）第一个参数必须是 `context.Context`；调用方必须正确传递和取消 context
  ```go
  // ✅
  func (r *OrderRepo) FindByID(ctx context.Context, id string) (*Order, error)
  // ❌
  func (r *OrderRepo) FindByID(id string) (*Order, error)
  ```

### 错误处理
- 自定义错误类型实现 `error` 接口，含业务错误码
- 对外 HTTP 响应屏蔽内部错误详情

### 安全
- 数据库查询用 `?` 占位符或 ORM，禁止字符串拼接
- 输入校验在 handler 层统一处理

### 资源清理
- 文件/DB/网络连接在 `defer` 中关闭
- goroutine 必须有退出机制，禁止泄漏

### 接口设计
- 接口定义在使用方（消费者），不在实现方
- 并发：channel 优先，避免共享内存
- 包名：单词小写，不用下划线或驼峰

### 日志（slog / zap）
```go
slog.Info("order create start", "userID", userID, "productID", productID)
slog.Error("order create failed", "err", err, "orderID", orderID)
```
- 生产环境配置文件输出：`slog.NewJSONHandler(file, nil)`
- 所有 `if err != nil` 返回前必须打日志

### 单元测试
- 文件命名：`<module>_test.go`，与被测文件同目录
- 函数命名：`Test<Function>_<场景>`
  ```go
  func TestCreateOrder_InsufficientStock_ReturnsError(t *testing.T) { ... }
  ```
- **table-driven tests**：多场景用 `[]struct{ name, input, expected }` 表驱动
- **Mock 只在层边界**：用接口 mock repo 层，不 mock service 内部
  ```go
  // 定义接口，用 mockery 或手写 mock
  type OrderRepo interface { FindByID(ctx, id) (*Order, error) }
  ```
- **AAA 结构**：注释标注 // Arrange / // Act / // Assert
- 覆盖率目标：`go test -coverprofile=coverage.out ./...`，核心包 ≥ 80%
- 并发测试用 `-race` 标志：`go test -race ./...`

### 代码注释
- 导出函数/类型必须有 Go doc 注释（英文，符合 godoc 规范）
- 非导出复杂逻辑加中文行内注释
```

---

## rust.mdc（Auto Attached，适用 Rust/Tauri 文件）

```yaml
---
description: Rust/Tauri 编码规范，AI 在修改 Rust 文件时自动加载
globs: ["src-tauri/**/*.rs", "src/**/*.rs"]
alwaysApply: false
---

## Rust/Tauri 规范

### 常量与配置
- 魔法值提取为 `const` 或 `static`
- 配置从环境变量或配置文件加载（config/dotenvy），禁止硬编码

### Option/Result 处理
- 不用 `unwrap()`/`expect()`（测试除外），用 `?` 或 `match`/`if let`
- `Option` 用 `unwrap_or`/`unwrap_or_else`/`ok_or` 转换
- Tauri 命令返回 `Result<T, String>`，错误信息对前端友好

### 函数规范
- 函数保持专注，超过 50 行考虑拆分
- clippy 的 `cognitive_complexity` 阈值：25

### 错误处理
- 使用 `thiserror` 定义结构化错误类型
- 用 `anyhow` 在应用层聚合错误
- 对外（Tauri 命令）错误信息不暴露内部路径/数据库详情

### 安全
- SQL 查询用 sqlx/diesel 参数绑定，禁止字符串拼接
- Tauri 命令：前端传入的数据必须校验后使用

### Tauri 特有
- 前后端通信只用 invoke/emit，不绕过
- 状态管理用 `tauri::State<T>`，不用全局可变变量
- 前端 TS 类型定义与 Rust 命令签名保持同步

### 资源清理
- 实现 `Drop` trait 管理资源生命周期
- 异步资源用 `tokio` 的 RAII 模式

### 日志（tracing）
```rust
tracing::info!(user_id = %user_id, "Starting file export");
tracing::error!(error = %e, file_path = %path, "Failed to export file");
```
- 配置文件日志：`tracing_appender::rolling::daily("./logs", "app.log")`
- Tauri 命令错误路径：先打日志再返回 `Err`

### 单元测试
- 测试模块放在同文件 `#[cfg(test)] mod tests { ... }`，集成测试放 `tests/`
- 函数命名：`test_<描述>`（下划线分隔）
  ```rust
  #[test]
  fn test_create_order_insufficient_stock_returns_error() { ... }
  ```
- **测试行为，不测实现**：优先通过公开接口测试行为；若私有函数含重要逻辑，提取为独立纯函数后直接测，不用 `#[cfg(test)]` 暴露私有符号绕过可见性
- **Mock**：用 `mockall` crate mock trait，只 mock 外部依赖
- **AAA 结构**：注释标注 // Arrange / // Act / // Assert
- 覆盖率：`cargo tarpaulin --out Html`，核心模块 ≥ 80%
- 异步测试用 `#[tokio::test]`

### 代码注释
- pub 函数/结构体必须有 `///` doc 注释
- 复杂逻辑加中文行内注释（`//`）
```

---

## flutter.mdc（Auto Attached，适用 Dart 文件）

```yaml
---
description: Flutter/Dart 编码规范，AI 在修改 Dart 文件时自动加载
globs: ["lib/**/*.dart", "test/**/*.dart"]
alwaysApply: false
---

## Flutter 规范

### 常量与配置
- 魔法值提取为 `const`，颜色/尺寸等放 `AppConstants` 或 `AppTheme`
- 环境配置用 flavor 或 `--dart-define` 传入，不硬编码 API URL
  ```dart
  // ✅
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  // ❌
  const apiBaseUrl = 'https://api.example.com';
  ```

### Null Safety
- 禁止 `!`（强制解包），除非有明确注释说明不可能为 null
- 用 `?.`、`??`、`if (x != null)` 处理可空值
- `late` 变量必须确保在访问前已初始化，谨慎使用

### 函数与 Widget 规范
- 单个函数/build 方法不超过 50 行；超过则提取子 Widget 或方法
- Widget 单一职责，超过 100 行考虑拆分
- 不在 `build()` 中执行异步操作或调用 setState

### 错误处理
- 网络/IO 错误转为业务 Result 类型，不直接在 UI 层 catch Exception
- 用 `Either<Failure, T>` 或自定义 Result 类型传递错误
- 禁止静默吞错（空 catch 块）

### 安全
- API 请求参数通过模型类序列化，禁止拼接 URL 参数
- 敏感信息（token）存 flutter_secure_storage，不存 SharedPreferences

### 语言约定
- 状态管理：<用户选择的方案，如 Riverpod / Bloc>
- 导航：GoRouter，不直接用 Navigator.push 硬编码路由
- 不可变数据用 `freezed` 生成，不手写 copyWith/==
- 国际化用 flutter_localizations，不硬编码用户可见字符串

### 资源清理
- StreamSubscription、AnimationController、TextEditingController 在 `dispose()` 中释放
- Riverpod provider 用 `autoDispose` 避免内存泄漏

### 日志
```dart
AppLogger.info("payment.start", {"orderId": orderId, "amount": amount});
AppLogger.error("payment.failed", {"error": e.toString(), "orderId": orderId});
```
- 用 `logger` 包 + `path_provider` 写入本地文件
- 核心用户操作路径（登录、支付、下单）必须打日志
- 所有 `catch` 块必须打 error 级别日志

### 单元测试
- 文件命名：`<module>_test.dart`，放 `test/` 下镜像 `lib/` 结构
- 测试描述用中文
  ```dart
  group('OrderService', () {
    test('库存不足时应返回 Failure', () async { ... });
  });
  ```
- **测试行为，不测实现**：优先通过公开接口测试行为；若私有方法含重要逻辑，提取为独立纯函数/模块后直接测，不用反射或强制手段绕过可见性
- **Mock 只在层边界**：用 `mocktail` mock repository 接口
  ```dart
  // ✅ mock repository 接口
  class MockOrderRepo extends Mock implements OrderRepository {}
  // ❌ mock service 内部方法
  ```
- **AAA 结构**：注释标注 // Arrange / // Act / // Assert
- Widget 测试：用 `testWidgets`，验证 UI 响应行为而非像素
  ```dart
  testWidgets('支付成功后显示确认页面', (tester) async {
    await tester.pumpWidget(...)
    expect(find.text('支付成功'), findsOneWidget);
  });
  ```
- 覆盖率：`flutter test --coverage`，domain/application 层 ≥ 80%
- Riverpod 测试用 `ProviderContainer` 隔离状态

### 代码注释
- 公开类/方法必须有 `///` doc 注释
- 复杂逻辑加中文行内注释（`//`）
```
