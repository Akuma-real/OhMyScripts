#!/bin/bash

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检查是否在 Codespaces 环境中
if [ -n "$CODESPACES" ]; then
    echo -e "${GREEN}检测到当前环境是 GitHub Codespaces。${NC}"
    
    # 提示并删除当前目录中的所有文件和文件夹
    echo -e "${RED}即将删除当前目录中的所有文件和文件夹...${NC}"
    rm -rf ./*

    echo -e "${GREEN}当前目录已清空，继续执行脚本。${NC}"
else
    echo -e "${RED}当前环境不是 GitHub Codespaces，无法继续执行脚本。${NC}"
    exit 1
fi

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

# 开始克隆后端代码
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

# 开始克隆前端代码
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

# 安装 pnpm
print_message $BLUE "开始安装 pnpm..."
{
    npm install -g pnpm &>/dev/null
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "pnpm 安装成功!"
else
    print_message $RED "pnpm 安装失败，请检查 npm 是否已正确安装。"
    exit 1
fi

# 循环检查是否上传了 zh-CN.zip 文件
print_message $YELLOW "请上传 zh-CN.zip 文件到当前目录以继续操作。"
while [ ! -f "zh-CN.zip" ]; do
    print_message $YELLOW "等待 zh-CN.zip 文件上传..."
    sleep 5
done

# 一旦检测到 zh-CN.zip 文件存在，进行后续操作
print_message $GREEN "检测到 zh-CN.zip 文件，开始解压..."
{
    unzip zh-CN.zip -d alist-web/i18n &>/dev/null
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "语言文件解压成功!"
else
    print_message $RED "语言文件解压失败，请检查 zip 文件的完整性。"
    exit 1
fi

# 初始化语言文件
print_message $BLUE "初始化语言文件..."
{
    cd alist-web
    node ./scripts/i18n.mjs &>/dev/null
    cd ..
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "语言文件初始化成功!"
else
    print_message $RED "语言文件初始化失败，请检查 Node.js 环境。"
    exit 1
fi

# 清理 zh-CN.zip 文件
print_message $BLUE "清理 zh-CN.zip 文件..."
{
    rm zh-CN.zip &>/dev/null
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "清理完成!"
else
    print_message $RED "清理失败，请手动删除 zh-CN.zip 文件。"
fi

# 编译前端
print_message $BLUE "开始编译前端代码..."
{
    cd alist-web
    pnpm install && pnpm run build
} & spinner
if [ $? -eq 0 ]; then
    print_message $GREEN "前端编译成功!"
else
    print_message $RED "前端编译失败，请检查编译日志。"
    exit 1
fi

# 将编译好的前端文件移动到后端目录
print_message $BLUE "将编译好的前端文件移动到后端目录..."

# 打印当前工作目录
print_message $BLUE "当前工作目录是："
pwd

{
    cp -r ./alist-web/dist ./alist/public/
} & spinner

if [ $? -eq 0 ]; then
    print_message $GREEN "前端文件移动成功!"
else
    print_message $RED "前端文件移动失败，请检查路径和权限。"
    exit 1
fi

# 编译后端代码
print_message $BLUE "开始编译后端代码..."
{
    cd alist
    appName="alist"
    builtAt="$(date +'%F %T %z')"
    goVersion=$(go version | sed 's/go version //')
    gitAuthor=$(git show -s --format='format:%aN <%ae>' HEAD)
    gitCommit=$(git log --pretty=format:"%h" -1)
    version=$(git describe --long --tags --dirty --always)
    webVersion=$(wget -qO- -t1 -T2 "https://api.github.com/repos/alist-org/alist-web/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    ldflags="\
    -w -s \
    -X 'github.com/alist-org/alist/v3/internal/conf.BuiltAt=$builtAt' \
    -X 'github.com/alist-org/alist/v3/internal/conf.GoVersion=$goVersion' \
    -X 'github.com/alist-org/alist/v3/internal/conf.GitAuthor=$gitAuthor' \
    -X 'github.com/alist-org/alist/v3/internal/conf.GitCommit=$gitCommit' \
    -X 'github.com/alist-org/alist/v3/internal/conf.Version=$version' \
    -X 'github.com/alist-org/alist/v3/internal/conf.WebVersion=$webVersion' \
    "
    go build -ldflags="$ldflags" .
} & spinner

if [ $? -eq 0 ]; then
    print_message $GREEN "后端编译成功!"
else
    print_message $RED "后端编译失败，请检查编译日志。"
    exit 1
fi

print_message $YELLOW "Alist 项目已完成构建，所有操作成功完成。"
