#!/bin/bash

# 脚本名称: rclone_mount_manager.sh

# 日志文件路径
LOG_FILE="/var/log/rclone_mounts.log"

# 自定义 rclone 配置
#格式：RCLONE网盘=系统目录
declare -A MOUNTS=(
    ["od-e5-media"]="/home/od-e5-media"
    ["od-e5-media1"]="/home/od-e5-media1"
    ["od-e5-media2"]="/home/od-e5-media2"
    ["od-e5-media3"]="/home/od-e5-media3"
    ["od-e5-media4"]="/home/od-e5-media4"
    ["od-e5-media5"]="/home/od-e5-media5"
)
CACHE_DIR="/home/cache"

# 函数：写入日志
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    echo "$1"
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
            log "警告：$MOUNT_POINT 已经被挂载。"
        else
            log "开始挂载 $REMOTE:/ 到 $MOUNT_POINT"
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
                log "成功：$REMOTE:/ 已挂载到 $MOUNT_POINT"
            else
                log "错误：挂载 $REMOTE:/ 到 $MOUNT_POINT 失败。"
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
            log "正在卸载 $MOUNT_POINT"
            fusermount -u "$MOUNT_POINT"
            if ! mountpoint -q "$MOUNT_POINT"; then
                log "成功卸载 $MOUNT_POINT"
            else
                log "错误：卸载 $MOUNT_POINT 失败"
            fi
        else
            log "$MOUNT_POINT 未挂载"
        fi
        sleep 1
    done
}

# 函数：检查挂载状态
check_status() {
    for REMOTE in "${!MOUNTS[@]}"; do
        MOUNT_POINT="${MOUNTS[$REMOTE]}"
        if mountpoint -q "$MOUNT_POINT"; then
            echo "$REMOTE 已挂载在 $MOUNT_POINT"
        else
            echo "$REMOTE 未挂载"
        fi
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
            *)
                echo "用法: $0 [mount|unmount|status]"
                exit 1
                ;;
        esac
    fi
}

# 交互式菜单函数
interactive_menu() {
    while true; do
        echo ""
        echo "RClone 挂载管理器"
        echo "1. 挂载所有远程存储"
        echo "2. 卸载所有远程存储"
        echo "3. 检查挂载状态"
        echo "4. 退出"
        read -p "请选择操作 [1-4]: " choice

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
                echo "退出程序"
                exit 0
                ;;
            *)
                echo "无效选择，请重试"
                ;;
        esac
    done
}

# 调用主程序
main "$@"
