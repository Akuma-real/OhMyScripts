#!/bin/bash

# 清理屏幕
clear

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"
RESET="\033[0m"
BOLD='\033[1m'

# FRP 安装路径
FRPS_DIR="/opt/frps"
FRPC_DIR="/opt/frpc"
FRP_VERSION="0.60.0"

# 打印欢迎信息
echo -e "${GREEN}==========================================="
echo -e "          欢迎使用 FRP 安装/更新/卸载脚本"
echo -e "===========================================${RESET}"
echo ""
echo -e "${YELLOW}此脚本将帮助您自动安装、更新或卸载 FRP。${RESET}"
echo ""

# 权限检查
function check_permissions() {
    if [ "$UID" -ne 0 ]; then
        echo -e "${RED}权限不足，请使用 root 用户运行本脚本。${RESET}"
        exit 1
    fi
}

# 检测系统架构与操作系统
function detect_system() {
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$ARCH" in
        "x86_64")
            ARCH="amd64"
            ;;
        "aarch64")
            ARCH="arm64"
            ;;
        "armv7l")
            ARCH="arm_hf"
            ;;
        "mips64")
            ARCH="mips64"
            ;;
        "mips64le")
            ARCH="mips64le"
            ;;
        "riscv64")
            ARCH="riscv64"
            ;;
        *)
            echo -e "${RED}不支持的架构: $ARCH${RESET}"
            exit 1
            ;;
    esac

    echo -e "${BLUE}检测到系统架构: ${ARCH}, 操作系统: ${OS}${RESET}"
}

# 获取本地 FRP 版本
function get_local_version() {
    local component="$1"
    local install_dir="$2"
    local version

    if [ -x "${install_dir}/${component}" ]; then
        version=$("${install_dir}/${component}" --version 2>&1)
        echo "$version"
    else
        echo "未安装"
    fi
}

# 打印本地和最新版本信息
function print_version_info() {
    local frps_version_local="$1"
    local frpc_version_local="$2"

    echo -e "════════════════════════════════════════"
    echo -e "  本地 frps：${YELLOW}${frps_version_local}${RESET}    GitHub 最新版本：${YELLOW}${FRP_VERSION}${RESET}  "
    echo -e "  本地 frpc：${YELLOW}${frpc_version_local}${RESET}    GitHub 最新版本：${YELLOW}${FRP_VERSION}${RESET}  "
    echo -e "════════════════════════════════════════"
    echo ""
}

# 下载和安装 FRP
function download_and_install_frp() {
    local component="$1"
    local install_dir="$2"
    local url="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_${OS}_${ARCH}.tar.gz"
    local tmp_dir="/tmp/frp_install"

    # 创建安装目录
    mkdir -p "$install_dir" || { echo -e "${RED}无法创建目录 $install_dir${RESET}"; exit 1; }

    # 创建临时目录
    mkdir -p "$tmp_dir"

    # 下载 FRP
    echo -e "${BLUE}正在下载 ${component}...${RESET}"
    if curl -Lo "$tmp_dir/frp.tar.gz" "$url"; then
        echo -e "${GREEN}FRP 下载完成！${RESET}"
    else
        echo -e "${RED}FRP 下载失败！请检查您的网络连接并重试。${RESET}"
        rm -rf "$tmp_dir"
        exit 1
    fi

    # 解压和安装
    echo -e "${BLUE}正在解压 ${component} 并安装到 ${install_dir}...${RESET}"
    tar -xzf "$tmp_dir/frp.tar.gz" -C "$tmp_dir" || { echo -e "${RED}解压失败${RESET}"; rm -rf "$tmp_dir"; exit 1; }
    
    # 移动对应的二进制文件和配置文件
    if [ "$component" == "frps" ]; then
        mv "$tmp_dir"/frp_*/frps "$install_dir/" || { echo -e "${RED}移动 frps 失败${RESET}"; exit 1; }
        mv "$tmp_dir"/frp_*/frps.toml "$install_dir/" || { echo -e "${RED}移动 frps.toml 失败${RESET}"; exit 1; }
        echo -e "${GREEN}frps 安装成功！${RESET}"
    elif [ "$component" == "frpc" ]; then
        mv "$tmp_dir"/frp_*/frpc "$install_dir/" || { echo -e "${RED}移动 frpc 失败${RESET}"; exit 1; }
        mv "$tmp_dir"/frp_*/frpc.toml "$install_dir/" || { echo -e "${RED}移动 frpc.toml 失败${RESET}"; exit 1; }
        echo -e "${GREEN}frpc 安装成功！${RESET}"
    fi

    # 清理临时文件
    rm -rf "$tmp_dir"
}

# 检查是否需要更新
function check_for_update() {
    local component="$1"
    local local_version="$2"
    local github_version="$3"

    if [ "$local_version" == "$github_version" ]; then
        echo -e "${GREEN}${component} 已是最新版本（$local_version），无需更新。${RESET}"
        return 1
    else
        return 0
    fi
}

# 卸载 FRP
function uninstall_frp() {
    local component="$1"
    local install_dir="$2"

    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir"
        echo -e "${GREEN}${component} 已成功卸载！${RESET}"
    else
        echo -e "${RED}未检测到已安装的 ${component}。${RESET}"
    fi
}

# 完成安装后的提示
function post_installation_summary() {
    local install_dir="$1"
    local component="$2"

    echo -e "${GREEN}==========================================="
    echo -e "          ${component} 安装/更新完成"
    echo -e "===========================================${RESET}"
    echo ""
    echo -e "${YELLOW}${component} 已安装在 ${install_dir} 目录下。${RESET}"
    echo -e "${YELLOW}配置文件在 ${install_dir} 目录下。${RESET}"
    echo ""
    echo -e "${YELLOW}您可以使用以下命令启动 ${component} 服务：${RESET}"
    echo -e "${BLUE}${install_dir}/${component} -c ${install_dir}/${component}.toml${RESET}"
    echo ""
}

# 主执行流程
function main() {
    check_permissions
    detect_system

    # 获取本地版本信息
    frps_version_local=$(get_local_version "frps" "$FRPS_DIR")
    frpc_version_local=$(get_local_version "frpc" "$FRPC_DIR")

    # 打印版本信息
    print_version_info "$frps_version_local" "$frpc_version_local"

    echo -e "${GREEN}请选择您要执行的操作：${RESET}"
    echo -e "${BLUE}1) 安装/更新 FRPS（服务器端）${RESET}"
    echo -e "${BLUE}2) 安装/更新 FRPC（客户端）${RESET}"
    echo -e "${BLUE}3) 卸载 FRPS（服务器端）${RESET}"
    echo -e "${BLUE}4) 卸载 FRPC（客户端）${RESET}"
    echo -e "${BLUE}5) 退出${RESET}"
    read -p "请输入数字选择: " step_choice

    # 验证用户输入
    if [[ ! "$step_choice" =~ ^[1-5]$ ]]; then
        echo -e "${RED}无效的选择，脚本将退出。${RESET}"
        exit 1
    fi

    case "$step_choice" in
        1)
            check_for_update "frps" "$frps_version_local" "$FRP_VERSION"
            if [ $? -eq 0 ]; then
                download_and_install_frp "frps" "$FRPS_DIR"
                post_installation_summary "$FRPS_DIR" "frps"
            fi
            ;;
        2)
            check_for_update "frpc" "$frpc_version_local" "$FRP_VERSION"
            if [ $? -eq 0 ]; then
                download_and_install_frp "frpc" "$FRPC_DIR"
                post_installation_summary "$FRPC_DIR" "frpc"
            fi
            ;;
        3)
            uninstall_frp "frps" "$FRPS_DIR"
            ;;
        4)
            uninstall_frp "frpc" "$FRPC_DIR"
            ;;
        5)
            echo -e "${YELLOW}脚本已退出。${RESET}"
            exit 0
            ;;
    esac
}

# 调用主函数
main
