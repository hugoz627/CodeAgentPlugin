# Swift/iOS 开发规范

## 类型系统

- 使用 Codable struct 定义数据模型
- 使用 enum 定义有限状态集合
- 避免使用 Any 或强制解包 (!)

## 日志

- 使用 OSLog 或自定义日志组件，必须支持文件落地
- 网络层请求/响应必须有日志（URL、参数、状态码、耗时）
- 配置示例：
  ```swift
  import OSLog
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
  logger.info("Request: \(url), cost: \(elapsed)ms")
  ```

## 网络层

- 使用 URLSession 或 Alamofire，统一封装请求/响应日志
- 错误处理使用 Result 类型
