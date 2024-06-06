#!/bin/bash

# 定义公钥变量
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCybZq+l2HyVoHSa45b0v07yNap5KgDMUsruivIFfuEZr/Dgfd28u6nEcKhvkBX439Ro/fX7PIn2Jvs09iu+xnkzkhrnnO2GMn7ZCuLJv/qaKZ4I1/3H5FVygbi4DPxof6eOMcb5CRdheih+TAELhHhlGIKrw/hqMQOKPEr/O5yd+2hj1+zqB1r8vTv8yWdRqK8NOosY1dzETMCcORF6W7E4MnY3Ae6lA+IBe7I8PDN4EchK7tnTj0ZNCeqWgeMeekQisF4EfKuuLue26usbz7C3RC5LUNkrzaBJarXekkANxnvT039e0JV20U3oN+cyh+LvNgZ2UnFrqeR7G/cBkwZ"

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
