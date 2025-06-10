#!/bin/bash

# 设置默认值
SOURCE_DIR=""
BACKUP_DIR=""
RCLONE_REMOTE=""
RCLONE_REMOTE_DIR=""
LOG_FILE="/var/log/backup.log"
DAYS_TO_KEEP=7

# 打印使用说明
usage() {
    echo "使用方法: $0 -s SOURCE_DIR -b BACKUP_DIR -r RCLONE_REMOTE -d RCLONE_REMOTE_DIR"
    echo "选项:"
    echo "  -s, --source        源目录路径（必填）"
    echo "  -b, --backup        本地备份目录路径（必填）"
    echo "  -r, --remote        RCLONE远程网盘名称（必填）"
    echo "  -d, --remote-dir    RCLONE远程网盘目录（必填）"
    echo "  -l, --log           日志文件路径（可选，默认 /var/log/backup.log）"
    echo "  -k, --keep-days     保留备份天数（可选，默认 7 天）"
    echo "  -h, --help          显示帮助信息"
    exit 1
}

# 解析命令行参数
ARGS=$(getopt -o s:b:r:d:l:k:h --long source:,backup:,remote:,remote-dir:,log:,keep-days:,help -n "$0" -- "$@")

# 参数解析错误处理
if [ $? -ne 0 ]; then
    usage
fi

eval set -- "$ARGS"

# 解析参数
while true; do
    case "$1" in
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -r|--remote)
            RCLONE_REMOTE="$2"
            shift 2
            ;;
        -d|--remote-dir)
            RCLONE_REMOTE_DIR="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -k|--keep-days)
            DAYS_TO_KEEP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "内部错误!"
            exit 1
            ;;
    esac
done

# 检查必填参数
if [ -z "$SOURCE_DIR" ] || [ -z "$BACKUP_DIR" ] || [ -z "$RCLONE_REMOTE" ] || [ -z "$RCLONE_REMOTE_DIR" ]; then
    echo "错误：源目录、备份目录、远程网盘名称和远程网盘目录为必填项"
    usage
fi

# 创建日期戳
TIMESTAMP=$(date +"%Y%m%d")

# 日志记录函数
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 压缩目录函数
compress_directory() {
    local source_dir="$1"
    local backup_dir="$2"
    local timestamp="$3"
    
    # 获取目录名称（不包含完整路径）
    local dir_name=$(basename "$source_dir")
    
    # 创建备份目录（如果不存在）
    mkdir -p "$backup_dir"
    
    # 压缩目录，使用目录名称+时间戳命名
    tar -czvf "${backup_dir}/${dir_name}_${timestamp}.tar.gz" -C "$source_dir" .
    
    # 检查压缩是否成功
    if [ $? -eq 0 ]; then
        log_message "成功压缩目录 $source_dir 到 ${backup_dir}/${dir_name}_${timestamp}.tar.gz"
    else
        log_message "压缩目录 $source_dir 失败"
        exit 1
    fi
}

# RCLONE备份函数
rclone_backup() {
    local backup_dir="$1"
    local rclone_remote="$2"
    local rclone_remote_dir="$3"
    local timestamp="$4"
    local dir_name=$(basename "$SOURCE_DIR")
    
    # 使用RCLONE同步备份到网盘
    rclone copy "${backup_dir}/${dir_name}_${timestamp}.tar.gz" "${rclone_remote}:${rclone_remote_dir}/" --verbose
    
    # 检查RCLONE备份是否成功
    if [ $? -eq 0 ]; then
        log_message "成功将备份同步到 $rclone_remote:$rclone_remote_dir"
    else
        log_message "RCLONE备份到 $rclone_remote:$rclone_remote_dir 失败"
        exit 1
    fi
}

# 清理旧备份函数
cleanup_old_backups() {
    local backup_dir="$1"
    local days_to_keep="$2"
    local dir_name=$(basename "$SOURCE_DIR")
    
    # 删除超过指定天数的备份
    find "$backup_dir" -type f -name "${dir_name}_*_backup.tar.gz" -mtime +$days_to_keep -delete
    
    log_message "清理 $days_to_keep 天前的旧备份"
}

# 磁盘空间检查函数
check_disk_space() {
    local threshold=90  # 磁盘使用率阈值
    local usage=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -gt "$threshold" ]; then
        log_message "磁盘空间警告：当前使用率 $usage%，超过 $threshold% 阈值"
    fi
}

# 主备份流程
main() {
    # 检查必要命令是否存在
    command -v tar >/dev/null 2>&1 || { log_message "tar 未安装"; exit 1; }
    command -v rclone >/dev/null 2>&1 || { log_message "rclone 未安装"; exit 1; }

    # 检查磁盘空间
    check_disk_space

    log_message "开始备份流程"
    
    # 压缩目录
    compress_directory "$SOURCE_DIR" "$BACKUP_DIR" "$TIMESTAMP"
    
    # RCLONE备份
    rclone_backup "$BACKUP_DIR" "$RCLONE_REMOTE" "$RCLONE_REMOTE_DIR" "$TIMESTAMP"
    
    # 清理旧备份
    cleanup_old_backups "$BACKUP_DIR" "$DAYS_TO_KEEP"
    
    log_message "备份流程完成"
}

# 执行主函数
main
