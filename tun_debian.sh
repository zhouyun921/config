#!/bin/bash

#################################################
# 描述: Debian/Ubuntu/Armbian sing-box TUN模式 配置脚本
# 版本: 1.1.0
# 作者: Youtube: 七尺宇
# 功能: 更新替换配置文件
#################################################

# 配置参数
BACKEND_URL="http://192.168.3.177:5000"                       # 后端服务器地址
SUBSCRIPTION_URL=""   # 订阅地址 Clash.Meta(mihomo)
TEMPLATE_URL="https://ghproxy.cc/https://raw.githubusercontent.com/zhouyun921/config/refs/heads/main/config_tun.json"  # 配置模板（确保使用TUN入站）
TUN_PORT=2080                                              # TUN 端口

# 检查是否以 root 权限运行并且 sing-box 是否已安装
[ "$(id -u)" != "0" ] && { echo "错误: 此脚本需要 root 权限"; exit 1; }
command -v sing-box &> /dev/null || { echo "错误: sing-box 未安装"; exit 1; }

# 停止 sing-box 服务
systemctl stop sing-box

# 构建完整的配置文件 URL
FULL_URL="${BACKEND_URL}/config/${SUBSCRIPTION_URL}&file=${TEMPLATE_URL}"

echo -e "\033[34m==============================================================================\033[0m"
echo -e "\033[33m*生成完整订阅链接: \033[0m\033[36m$FULL_URL\033[0m"
echo -e "\033[34m==============================================================================\033[0m"

# 备份当前配置
[ -f "/etc/sing-box/config.json" ] && cp /etc/sing-box/config.json /etc/sing-box/config.json.backup

# 下载并验证配置文件
if curl -L --connect-timeout 10 --max-time 30 "$FULL_URL" -o /etc/sing-box/config.json; then
    echo "配置文件下载成功"
    if ! sing-box check -c /etc/sing-box/config.json; then
        echo -e "\033[31m*** 配置文件验证失败，请检查配置文件格式及参数，正在还原备份 ***\033[0m"
        [ -f "/etc/sing-box/config.json.backup" ] && cp /etc/sing-box/config.json.backup /etc/sing-box/config.json
        exit 1
    fi
else
    echo -e "\033[31m*** 配置文件下载失败,请复制完整订阅链接，在浏览器是否可以正常打开! ***\033[0m"
    exit 1
fi

# 设置正确的权限
chmod 640 /etc/sing-box/config.json

# 启动 sing-box 服务
systemctl start sing-box

# 检查服务是否启动成功
if systemctl is-active --quiet sing-box; then
    echo -e "\033[36m===========================================================\033[0m"
    echo -e "\033[32m******** sing-box 启动成功，运行模式: Tun ********\033[0m"
else
    echo -e "\033[36m===========================================================\033[0m"
    echo -e "\033[31m******** 服务启动失败，请使用下方命令排查原因! ********\033[0m"
fi

# 显示常用命令
echo -e "\033[36m===========================================================\033[0m"
echo -e "\033[33m* 常用命令：\033[0m"
echo -e "\033[32m* 检查singbox: \033[0m\033[36msystemctl status sing-box.service\033[0m"
echo -e "\033[32m* 查看实时日志: \033[0m\033[36mjournalctl -u sing-box --output cat -f\033[0m"
echo -e "\033[32m* 检查配置文件: \033[0m\033[36msing-box check -c /etc/sing-box/config.json\033[0m"
echo -e "\033[32m* 运行singbox: \033[0m\033[36msing-box run -c /etc/sing-box/config.json\033[0m"
echo -e "\033[32m* 查看nf防火墙: \033[0m\033[36mnft list ruleset\033[0m"
echo -e "\033[36m===========================================================\033[0m"

# 启动失败时退出
if [ $? -ne 0 ]; then
    exit 1
fi