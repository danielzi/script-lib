# script-lib
自用脚本库

一键安装qb
curl -sSL https://raw.githubusercontent.com/danielzi/script-lib/main/qbittorrent_install.sh | bash



挂载硬盘
curl -sSL https://raw.githubusercontent.com/danielzi/script-lib/main/multi_rclone_mount.sh | bash


备份到网盘 
wget https://raw.githubusercontent.com/danielzi/script-lib/main/backup_script.sh && chmod +x backup_script.sh
  使用示例
  ./backup_script.sh -s /root/emby -b /root/backup -r infini -d emby
