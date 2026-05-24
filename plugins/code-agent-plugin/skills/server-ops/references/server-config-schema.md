# servers.yaml 配置格式

## 完整示例

```yaml
servers:
  - name: prod-api-01           # 服务器别名（必填）
    host: 10.0.1.10             # IP 或域名（必填）
    user: deploy                # SSH 用户名（必填）
    key: ~/.ssh/prod_key        # SSH 私钥路径（可选，默认用 ssh-agent）
    port: 22                    # SSH 端口（可选，默认 22）
    env: prod                   # 环境标识（可选：prod/staging/dev）
    services:                   # 该服务器上的服务列表（可选）
      - name: user-service      # 服务名称
        log_path: /var/log/user-service/app.log  # 日志文件路径
        log_format: json        # 日志格式：json / text
        container: user-svc     # Docker 容器名（可选，用于 docker logs）
      - name: order-service
        log_path: /var/log/order-service/app.log
        log_format: text
```

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| servers | list | 是 | 服务器列表 |
| servers[].name | string | 是 | 服务器别名，用于显示和引用 |
| servers[].host | string | 是 | IP 地址或域名 |
| servers[].user | string | 是 | SSH 登录用户名 |
| servers[].key | string | 否 | SSH 私钥路径，默认用 ssh-agent |
| servers[].port | int | 否 | SSH 端口，默认 22 |
| servers[].env | string | 否 | 环境标识：prod / staging / dev |
| servers[].services | list | 否 | 该服务器上运行的服务 |
| services[].name | string | 是 | 服务名称 |
| services[].log_path | string | 是 | 日志文件路径（支持通配符如 /var/log/app/*.log） |
| services[].log_format | string | 否 | 日志格式：json / text，默认 text |
| services[].container | string | 否 | Docker 容器名，设置后可用 docker logs 查看 |

## 配置文件查找顺序

1. 项目根目录 `./servers.yaml`
2. 用户全局配置 `~/.config/code-agent/servers.yaml`
