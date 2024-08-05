#!/bin/bash

# 提示用户输入域名和反向代理的IP地址和端口
read -p "请输入域名 (例如: www.qq.com): " DOMAIN
read -p "请输入反向代理的IP地址和端口 (例如: 127.0.0.1:3000): " PROXY_PASS

# 更新系统包
sudo apt update

# 安装 Nginx
sudo apt install -y nginx

# 创建 Nginx 配置文件
cat <<EOL | sudo tee /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://$PROXY_PASS;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# 创建符号链接到 sites-enabled
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# 测试 Nginx 配置
sudo nginx -t

# 重新加载 Nginx
sudo systemctl reload nginx

# 配置 UFW 防火墙
sudo ufw allow 'Nginx Full'

# 安装 Certbot（自动确认）
sudo apt install -y certbot python3-certbot-nginx

# 获取并安装 SSL 证书（自动确认）
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email test@qq.com

# 自动续订 SSL 证书
sudo systemctl enable certbot.timer

echo "Nginx 已配置，并为 $DOMAIN 设置了反向代理。"
