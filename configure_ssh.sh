#!/bin/bash

# 默认公钥变量为空
PUBLIC_KEY=""

# 通过命令行参数读取公钥
while getopts ":pub:" opt; do
  case $opt in
    pub)
      PUBLIC_KEY=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# 检查公钥是否被正确传递
if [ -z "$PUBLIC_KEY" ]; then
  echo "Usage: $0 -pub 'your-public-key'"
  exit 1
fi

# 确保 ~/.ssh 目录存在
if [ ! -d ~/.ssh ]; then
  mkdir ~/.ssh
  chmod 700 ~/.ssh
fi

# 将公钥添加到 ~/.ssh/authorized_keys
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 启用公钥认证
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 禁用root的密码登录
sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin without-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# 重启SSH服务
echo "正在重启SSH服务..."
systemctl restart sshd

echo "SSH密钥登录配置完成，已禁用root密码登录。"
