# Nginx 配置模板

## 模板 1：反向代理到端口（HTTP）

```nginx
server {
    listen 80;
    server_name {domain};

    access_log /var/log/nginx/{domain}_access.log;
    error_log  /var/log/nginx/{domain}_error.log;

    location / {
        proxy_pass http://127.0.0.1:{port};
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;

        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }
}
```

## 模板 2：反向代理到路径前缀（HTTP）

```nginx
server {
    listen 80;
    server_name {domain};

    access_log /var/log/nginx/{domain}_access.log;
    error_log  /var/log/nginx/{domain}_error.log;

    location /api/ {
        proxy_pass http://127.0.0.1:{port};
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;

        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }

    location / {
        root /var/www/{domain};
        index index.html;
        try_files $uri $uri/ /index.html;
    }
}
```

## 模板 3：HTTPS 配置（Let's Encrypt / Certbot）

在 Ubuntu/Debian 上安装 certbot：

```bash
sudo apt install certbot python3-certbot-nginx
```

申请证书（域名需已解析到当前服务器）：

```bash
sudo certbot --nginx -d {domain}
```

验证自动续期：

```bash
sudo certbot renew --dry-run
```

certbot 申请成功后会自动修改配置，生成类似以下内容：

```nginx
server {
    listen 443 ssl;
    server_name {domain};

    ssl_certificate     /etc/letsencrypt/live/{domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{domain}/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    access_log /var/log/nginx/{domain}_access.log;
    error_log  /var/log/nginx/{domain}_error.log;

    location / {
        proxy_pass http://127.0.0.1:{port};
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;

        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }
}

server {
    listen 80;
    server_name {domain};
    return 301 https://$host$request_uri;
}
```

## 模板 4：手动配置 HTTPS（已有证书）

```nginx
server {
    listen 443 ssl;
    server_name {domain};

    ssl_certificate        /etc/nginx/ssl/{domain}.crt;
    ssl_certificate_key    /etc/nginx/ssl/{domain}.key;
    ssl_protocols          TLSv1.2 TLSv1.3;
    ssl_ciphers            HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache      shared:SSL:10m;
    ssl_session_timeout    10m;

    access_log /var/log/nginx/{domain}_access.log;
    error_log  /var/log/nginx/{domain}_error.log;

    location / {
        proxy_pass http://127.0.0.1:{port};
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;

        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }
}

server {
    listen 80;
    server_name {domain};
    return 301 https://$host$request_uri;
}
```

## 安全 Headers（建议添加到所有 HTTPS 站点）

```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "strict-origin-when-cross-origin";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
```

## 常用 Nginx 操作命令

```bash
# 检查配置语法
sudo nginx -t

# 热加载配置（不中断连接）
sudo systemctl reload nginx

# 重启 nginx
sudo systemctl restart nginx

# 查看 nginx 状态
sudo systemctl status nginx

# 实时查看错误日志
sudo tail -f /var/log/nginx/error.log

# 实时查看某域名访问日志
sudo tail -f /var/log/nginx/{domain}_access.log
```
