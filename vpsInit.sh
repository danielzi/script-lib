#!/bin/bash

# 更新系统并安装常用软件包
apt update -y && apt install wget sudo systemd-timesyncd vim screen ufw curl zip git htop -y

# 设置命令历史记录的时间格式
echo 'export HISTTIMEFORMATT "' >> ~/.bashrc && source ~/.bashrc

# 设置时区为上海
sudo timedatectl set-timezone Asia/Shanghai

# 安装Docker
curl -fsSL https://get.docker.com | bash -s docker

# 安装Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "所有操作"
