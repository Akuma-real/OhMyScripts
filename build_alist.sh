#!/bin/bash

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 动画函数
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep "$pid")" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 打印信息的函数
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 开始克隆项目
print_message $BLUE "开始克隆 Alist 后端代码..."
{
    git clone https://github.com/alist-org/alist.git &>/dev/null
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "后端代码克隆成功!"
else
    print_message $RED "后端代码克隆失败，请检查网络连接或仓库地址。"
    exit 1
fi

print_message $BLUE "开始克隆 Alist 前端代码..."
{
    git clone --recurse-submodules https://github.com/alist-org/alist-web.git &>/dev/null
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "前端代码克隆成功!"
else
    print_message $RED "前端代码克隆失败，请检查网络连接或仓库地址。"
    exit 1
fi

# 提示构建完成
print_message $YELLOW "Alist 项目克隆完成，您现在可以进入相应的目录进行后续操作。"
