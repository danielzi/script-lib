#!/bin/bash

# 脚本名称: multi_rclone_mount.sh
# 版本: 2.0
# 描述: RClone 挂载管理器，支持多远程存储挂载和 systemd 服务管理

# 日志文件路径
LOG_FILE="/var/log/rclone_mounts.log"

# systemd 服务文件路径
SYSTEMD_SERVICE_PATH="/etc/systemd/system/rclone-mount.service"

# rclone 配置
declare -A MOUNTS=(
    ["od-e5-media"]="/home/od-e5-media"
    ["od-e5-media1"]="/home/od-e5-media1"
    ["od-e5-media2"]="/home/od-e5-media2"
    ["od-e5-media3"]="/home/od-e5-media3"
    ["od-e5-media4"]="/home/od-e5-media4"
    ["od-e5-media5"]="/home/od-e5-media5"
)
CACHE_DIR="/home/cache"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 函数：写入日志
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    echo "$1"
}

# 函数：检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误：此操作需要 root 权限。请使用 sudo 运行。${NC}"
        exit 1
    fi
}

# 函数：挂载所有远程存储
mount_all() {
    for REMOTE in "${!MOUNTS[@]}"; do
        MOUNT_POINT="${MOUNTS[$REMOTE]}"
        REMOTE_CACHE_DIR="$CACHE_DIR/$REMOTE"

        # 创建缓存目录
        if [ ! -d "$REMOTE_CACHE_DIR" ]; then
            mkdir -p "$REMOTE_CACHE_DIR"
            log "创建缓存目录：$REMOTE_CACHE_DIR"
        fi

        if [ ! -d "$MOUNT_POINT" ]; then
            mkdir -p "$MOUNT_POINT"
            log "创建挂载点目录：$MOUNT_POINT"
        fi

        if mountpoint -q "$MOUNT_POINT"; then
            log "${YELLOW}警告：$MOUNT_POINT 已经被挂载。${NC}"
        else
            log "${BLUE}开始挂载 $REMOTE:/ 到 $MOUNT_POINT${NC}"
            rclone mount "$REMOTE":/ "$MOUNT_POINT" \
                --copy-links \
                --allow-other \
                --allow-non-empty \
                --no-checksum \
                --umask 000 \
                --daemon \
                --vfs-cache-mode full \
                --vfs-cache-max-size 2G \
                --cache-dir "$REMOTE_CACHE_DIR" \
                --buffer-size 256M \
                --vfs-read-chunk-size 128M \
                --vfs-read-chunk-size-limit 64M

            if mountpoint -q "$MOUNT_POINT"; then
                log "${GREEN}成功：$REMOTE:/ 已挂载到 $MOUNT_POINT${NC}"
            else
                log "${RED}错误：挂载 $REMOTE:/ 到 $MOUNT_POINT 失败。${NC}"
            fi
        fi
        sleep 2
    done
}

# 函数：卸载所有远程存储
unmount_all() {
    for REMOTE in "${!MOUNTS[@]}"; do
        MOUNT_POINT="${MOUNTS[$REMOTE]}"
        if mountpoint -q "$MOUNT_POINT"; then
            log "${BLUE}正在卸载 $MOUNT_POINT${NC}"
            fusermount -u "$MOUNT_POINT"
            if ! mountpoint -q "$MOUNT_POINT"; then
                log "${GREEN}成功卸载 $MOUNT_POINT${NC}"
            else
                log "${RED}错误：卸载 $MOUNT_POINT 失败${NC}"
            fi
        else
            log "${YELLOW}$MOUNT_POINT 未挂载${NC}"
        fi
        sleep 1
    done
}

# 函数：检查挂载状态
check_status() {
    echo "远程存储挂载状态："
    for REMOTE in "${!MOUNTS[@]}"; do
        MOUNT_POINT="${MOUNTS[$REMOTE]}"
        if mountpoint -q "$MOUNT_POINT"; then
            echo -e "${GREEN}✓ $REMOTE 已挂载在 $MOUNT_POINT${NC}"
        else
            echo -e "${RED}× $REMOTE 未挂载${NC}"
        fi
    done
}

# 函数：创建 systemd 服务文件
create_systemd_service() {
    check_root

    # 获取当前用户
    CURRENT_USER=$(logname)

    # 获取脚本绝对路径
    SCRIPT_PATH=$(readlink -f "$0")

    # 创建 systemd 服务文件
    cat > "$SYSTEMD_SERVICE_PATH" << EOF
[Unit]
Description=RClone Mount Service
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH mount
RemainAfterExit=yes
User=$CURRENT_USER

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载 systemd
    systemctl daemon-reload

    echo -e "${GREEN}✓ systemd 服务文件已创建：$SYSTEMD_SERVICE_PATH${NC}"
    echo -e "${YELLOW}提示：您可以使用 systemd 服务管理菜单进行进一步配置。${NC}"
}

# 函数：管理 systemd 服务
manage_systemd_service() {
    check_root

    if [[ ! -f "$SYSTEMD_SERVICE_PATH" ]]; then
        echo -e "${RED}× 未找到 systemd 服务文件。请先创建服务。${NC}"
        return
    fi

    while true; do
        echo ""
        echo -e "${BLUE}systemd 服务管理${NC}"
        echo "1. 启用服务（开机自启）"
        echo "2. 禁用服务"
        echo "3. 启动服务"
        echo "4. 停止服务"
        echo "5. 查看服务状态"
        echo "6. 返回上级菜单"
        read -p "请选择操作 [1-6]: " service_choice

        case $service_choice in
            1)
                systemctl enable rclone-mount.service
                echo -e "${GREEN}✓ 服务已设置为开机自启${NC}"
                ;;
            2)
                systemctl disable rclone-mount.service
                echo -e "${YELLOW}! 服务已禁用${NC}"
                ;;
            3)
                systemctl start rclone-mount.service
                echo -e "${GREEN}✓ 服务已启动${NC}"
                ;;
            4)
                systemctl stop rclone-mount.service
                echo -e "${YELLOW}! 服务已停止${NC}"
                ;;
            5)
                systemctl status rclone-mount.service
                ;;
            6)
                break
                ;;
            *)
                echo -e "${RED}× 无效选择，请重试${NC}"
                ;;
        esac
    done
}

# 函数：显示脚本帮助信息
show_help() {
    echo "RClone 挂载管理器 (版本 2.0)"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项："
    echo "  mount      挂载所有配置的远程存储"
    echo "  unmount    卸载所有远程存储"
    echo "  status     检查远程存储挂载状态"
    echo "  help       显示此帮助信息"
    echo ""
    echo "无参数时进入交互式菜单"
}

# 交互式菜单函数
interactive_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}RClone 挂载管理器${NC}"
        echo "1. 挂载所有远程存储"
        echo "2. 卸载所有远程存储"
        echo "3. 检查挂载状态"
        echo "4. systemd 服务管理"
        echo "5. 创建 systemd 服务文件"
        echo "6. 帮助信息"
        echo "7. 退出"
        read -p "请选择操作 [1-7]: " choice

        case $choice in
            1)
                mount_all
                ;;
            2)
                unmount_all
                ;;
            3)
                check_status
                ;;
            4)
                manage_systemd_service
                ;;
            5)
                create_systemd_service
                ;;
            6)
                show_help
                ;;
            7)
                echo "退出程序"
                exit 0
                ;;
            *)
                echo -e "${RED}× 无效选择，请重试${NC}"
                ;;
        esac
    done
}

# 主程序入口
main() {
    # 检查是否有传入参数
    if [ $# -eq 0 ]; then
        # 无参数时进入交互菜单
        interactive_menu
    else
        case "$1" in
            mount)
                mount_all
                exit 0
                ;;
            unmount)
                unmount_all
                exit 0
                ;;
            status)
                check_status
                exit 0
                ;;
            help)
                show_help
                exit 0
                ;;
            *)
                echo "未知的参数。使用 help 查看帮助。"
                exit 1
                ;;
        esac
    fi
}

# 调用主程序
main "$@"
