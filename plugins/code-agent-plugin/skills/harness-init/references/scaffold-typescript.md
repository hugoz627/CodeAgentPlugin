# TypeScript 项目脚手架模板

## 目录结构（API 服务）

```
src/
├── types/
│   └── index.ts          # 纯类型定义，无外部依赖
├── config/
│   └── index.ts          # 配置加载（zod 校验）
├── repo/
│   └── index.ts          # 数据访问层接口
├── service/
│   └── index.ts          # 业务逻辑层
├── runtime/
│   └── index.ts          # 启动和生命周期
├── api/
│   └── index.ts          # 路由/控制器
└── providers/
    ├── logger.ts         # 日志（pino）
    └── telemetry.ts      # OpenTelemetry
tests/
package.json
tsconfig.json
biome.json
.editorconfig
```

## 初始文件内容

### src/types/index.ts
```typescript
// 纯类型定义，无外部依赖
// Layer: types（最底层，不依赖任何其他层）
export type {};
```

### src/config/index.ts
```typescript
// 配置加载
// Layer: config（只依赖 types/）
export type {};
```

### src/repo/index.ts
```typescript
// 数据访问层
// Layer: repo（只依赖 types/ 和 config/）
export type {};
```

### src/service/index.ts
```typescript
// 业务逻辑层
// Layer: service（只依赖 types/、config/、repo/）
export type {};
```

### src/runtime/index.ts
```typescript
// 应用启动入口
// Layer: runtime（只依赖 types/、config/、repo/、service/）

import http from "http";

const PORT = parseInt(process.env.PORT ?? "3000", 10) || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ status: "ok" }));
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### src/api/index.ts
```typescript
// 对外接口（路由/控制器）
// Layer: api（最外层，可依赖所有内层）
export type {};
```

### src/providers/logger.ts
```typescript
// 日志 provider（横切关注点，通过 providers/ 统一管理）
export const logger = console;
```

## package.json
```json
{
  "name": "<项目名>",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/runtime/index.ts",
    "build": "tsc",
    "test": "vitest",
    "lint": "biome check src/",
    "lint:fix": "biome check --apply src/"
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.0",
    "typescript": "^5.0.0",
    "vitest": "^2.0.0",
    "tsx": "^4.0.0"
  }
}
```

## tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "outDir": "dist",
    "rootDir": "src",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

## biome.json
```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": "error"
      },
      "style": {
        "useNamingConvention": "error",
        "useFilenamingConvention": "warn"
      },
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "organizeImports": {
    "enabled": true
  }
}
```

## Lint 验证命令
```bash
npx biome check src/
```
