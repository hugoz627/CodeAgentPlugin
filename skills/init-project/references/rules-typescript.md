# TypeScript 开发规范

## 类型系统

- 使用 interface 或 type 定义数据结构，禁止使用 any
- 使用 zod 做运行时数据校验
- 启用 strict 模式

## 日志

- 使用 winston 或 pino 做日志，配置文件 transport
- 配置示例（pino）：
  ```typescript
  import pino from 'pino';
  const logger = pino({
    transport: {
      targets: [
        { target: 'pino/file', options: { destination: 'logs/app.log' } },
        { target: 'pino-pretty', options: { destination: 1 } }
      ]
    }
  });
  ```

## 包管理

- 优先使用 pnpm
- 使用 ESM 模块格式
