# API 设计规范模板

## 统一响应结构

所有 HTTP 接口必须使用统一的响应结构：

```json
{
  "code": 0,
  "message": "success",
  "data": {},
  "requestId": "abc-123-def"
}
```

- `code`：业务状态码，0 表示成功，非 0 表示业务错误
- `message`：人可读的描述，成功时为 "success"，失败时为错误原因
- `data`：业务数据，成功时为实际数据，失败时可为 null 或错误详情
- `requestId`：请求唯一标识，方便日志追踪

## 错误码体系

错误码格式：`{模块编号}{错误类型}{序号}`，例如 `10001`

| 范围 | 含义 | 示例 |
|------|------|------|
| 0 | 成功 | |
| 1xxxx | 通用错误 | 10001=参数错误, 10002=未授权, 10003=禁止访问, 10004=资源不存在 |
| 2xxxx | 用户模块 | 20001=用户不存在, 20002=密码错误, 20003=账号已锁定 |
| 3xxxx | 订单模块 | 30001=订单不存在, 30002=库存不足, 30003=重复下单 |
| 5xxxx | 系统错误 | 50001=内部错误, 50002=依赖服务不可用, 50003=超时 |

HTTP 状态码规则：
- 业务错误（参数错误、资源不存在等）：HTTP 200 + 非 0 code
- 认证失败：HTTP 401
- 权限不足：HTTP 403
- 服务器内部错误：HTTP 500

## 分页规范

### 请求参数

```json
{
  "page": 1,
  "pageSize": 20
}
```

或游标分页（大数据量推荐）：

```json
{
  "cursor": "eyJpZCI6MTAwfQ==",
  "limit": 20
}
```

### 响应结构

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [],
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "hasMore": true
  }
}
```

游标分页响应：

```json
{
  "code": 0,
  "data": {
    "list": [],
    "nextCursor": "eyJpZCI6MTIwfQ==",
    "hasMore": true
  }
}
```

## RESTful 命名规范

- URL 使用名词复数：`/users`, `/orders`, `/products`
- 嵌套资源：`/users/{userId}/orders`
- 动作使用 HTTP 方法：GET=查询, POST=创建, PUT=全量更新, PATCH=部分更新, DELETE=删除
- 版本号放 URL 路径：`/api/v1/users`
- 查询参数用 camelCase：`?userId=123&pageSize=20`
- 响应字段用 camelCase：`{"userId": 123, "createdAt": "..."}`

## 接口文档规范

每个接口必须包含：
- 接口描述（做什么）
- 请求示例（含所有必要字段）
- 响应示例（成功和失败各一个）
- 错误码说明（该接口可能返回的错误码）
