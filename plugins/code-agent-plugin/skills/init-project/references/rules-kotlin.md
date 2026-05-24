# Kotlin/Android 开发规范

## 类型系统

- 使用 data class 定义数据模型
- 使用 sealed class 定义有限状态
- 避免使用 Any 或平台类型

## 日志

- 使用 Timber 或自定义日志组件，必须支持文件落地
- 配置文件日志：
  ```kotlin
  Timber.plant(FileLogTree("logs/app.log"))
  Timber.plant(Timber.DebugTree())
  ```

## 网络层

- 使用 OkHttp + Retrofit
- 使用 OkHttp Interceptor 统一记录请求/响应日志（URL、参数、状态码、耗时）
- 使用 Kotlin Serialization 或 Moshi 做序列化
