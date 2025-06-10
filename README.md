# 自用脚本库

本仓库收录了一些常用的 Shell 脚本，用于简化服务器环境下的常规操作，如软件一键安装、硬盘/网盘挂载和数据备份等。所有脚本均可通过一行命令快速执行，极大提升运维效率。

---

## 目录

- [一键安装 qbittorrent](#一键安装-qbittorrent)
- [挂载硬盘/网盘](#挂载硬盘网盘)
- [备份到网盘](#备份到网盘)
- [备份脚本使用示例](#备份脚本使用示例)
- [参数说明](#参数说明)
- [免责声明](#免责声明)

---

## 一键安装 qbittorrent

无需手动配置，直接运行下列命令即可完成 qbittorrent 的下载与安装：

```bash
curl -sSL https://raw.githubusercontent.com/danielzi/script-lib/main/qbittorrent_install.sh | bash
