---
name: nginx-config
description: Use when you need to configure nginx for a domain - generates reverse proxy configuration, sets up HTTP to port or path routing, and configures HTTPS via certbot or manual SSL certificates
---

# Nginx 域名配置

生成 nginx 反向代理配置，将域名绑定到后端端口或路径，并配置 HTTPS。

## 流程

1. **收集基本信息**（使用 AskUserQuestion 逐一询问）：
   - 域名是什么？（如 `api.example.com`）
   - 代理目标：整个域名代理到某个端口，还是某个路径前缀代理到某个端口？
   - 后端服务运行在哪个端口？
   - 服务器 IP 或别名（如果有 servers.yaml，从中读取）

2. **确认 SSL 方式**（使用 AskUserQuestion）：
   - 使用 Let's Encrypt（certbot 自动申请，需要域名已解析到服务器）
   - 已有 SSL 证书文件（需要提供 .crt 和 .key 文件路径）
   - 暂时只配置 HTTP（不配置 HTTPS）

3. **读取配置模板**：
   - 读取本插件 `skills/nginx-config/references/nginx-templates.md`（路径相对于插件安装目录）
   - 根据代理方式选择：模板 1（整个域名→端口）或 模板 2（路径前缀→端口）
   - 根据 SSL 方式选择：模板 3（certbot）或 模板 4（手动证书）或仅 HTTP

4. **生成 nginx 配置**：
   - 将模板中的 `{domain}`、`{port}`、`{path}` 替换为实际值
   - 如果是 HTTPS，在配置中加入安全 Headers（来自模板末尾的安全 Headers 片段）
   - 生成配置文件内容，文件名建议：`/etc/nginx/sites-available/{domain}.conf`

5. **生成部署命令**：

   根据 SSL 方式生成对应的操作步骤：

   **方式 A（certbot）**：
   ```bash
   # 1. 将配置写入服务器
   sudo tee /etc/nginx/sites-available/{domain}.conf << 'EOF'
   {生成的 HTTP 配置}
   EOF

   # 2. 启用站点
   sudo ln -sf /etc/nginx/sites-available/{domain}.conf /etc/nginx/sites-enabled/

   # 3. 检查配置并重载
   sudo nginx -t && sudo systemctl reload nginx

   # 4. 申请 SSL 证书（确保域名已解析到当前服务器）
   sudo certbot --nginx -d {domain}

   # 5. 验证 HTTPS
   curl -I https://{domain}
   ```

   **方式 B（已有证书）**：
   ```bash
   # 1. 上传证书到服务器
   sudo mkdir -p /etc/nginx/ssl
   sudo cp {cert.crt} /etc/nginx/ssl/{domain}.crt
   sudo cp {cert.key} /etc/nginx/ssl/{domain}.key
   sudo chmod 600 /etc/nginx/ssl/{domain}.key

   # 2. 写入配置并启用
   sudo tee /etc/nginx/sites-available/{domain}.conf << 'EOF'
   {生成的 HTTPS 配置}
   EOF
   sudo ln -sf /etc/nginx/sites-available/{domain}.conf /etc/nginx/sites-enabled/

   # 3. 检查并重载
   sudo nginx -t && sudo systemctl reload nginx
   ```

6. **通过 server-ops 执行**（如果有 servers.yaml 配置）：
   - 提示用户可以通过 server-ops skill 连接到目标服务器执行上述命令
   - 所有命令展示给用户确认后才执行

## 关键规则

- 配置文件写入前必须先 `nginx -t` 检查语法
- 使用 `systemctl reload nginx`（不是 restart）来热加载配置，不中断现有连接
- certbot 申请证书前确认：域名已正确解析到服务器 IP，80 端口已开放
- HTTPS 配置必须包含 HTTP → HTTPS 的 301 重定向（不能让 HTTP 版本同时存在）
- 证书私钥文件权限设置为 600，不能被其他用户读取
- 如果是 WebSocket 服务，确保配置中有 `Upgrade` 和 `Connection` headers
