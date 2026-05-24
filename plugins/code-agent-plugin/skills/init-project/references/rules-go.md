# Go 开发规范

## 类型系统

- 使用 struct 定义数据结构，避免 map[string]interface{}
- 使用自定义类型替代原始类型（如 `type UserID int64`）

## 错误处理

- 错误必须处理，禁止 `_ = err`
- 使用 fmt.Errorf 或 errors 包装错误添加上下文：`fmt.Errorf("create order failed: %w", err)`

## 日志

- 使用 zap 或 zerolog 做结构化日志
- 配置文件输出：
  ```go
  logger, _ := zap.Config{
      OutputPaths: []string{"logs/app.log", "stdout"},
  }.Build()
  ```

## 上下文

- 使用 context.Context 传递 traceId、请求级别数据
- 第一个参数始终是 ctx context.Context
