#!/bin/bash

# 安装qbittorrent-nox
sudo apt-get update
sudo apt-get install qbittorrent-nox -y

# 创建并编辑qbittorrent-nox.service文件
echo "[Unit]
Description=qBittorrent-nox
After=network.target

[Service]
User=root
Type=forking
RemainAfterExit=yes
ExecStart=/usr/bin/qbittorrent-nox -d

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/qbittorrent-nox.service

# 修改qbittorrent-nox.service文件后重新载入
sudo systemctl daemon-reload

# 设置开机启动
sudo systemctl enable qbittorrent-nox

# 启动
sudo systemctl start qbittorrent-nox
