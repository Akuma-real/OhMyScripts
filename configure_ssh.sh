#!/bin/bash

# 定义公钥变量
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCybZq+l2HyVoHSa45b0v07yNap5KgDMUsruivIFfuEZr/Dgfd28u6nEcKhvkBX439Ro/fX7PIn2Jvs09iu+xnkzkhrnnO2GMn7ZCuLJv/qaKZ4I1/3H5FVygbi4DPxof6eOMcb5CRdheih+TAELhHhlGIKrw/hqMQOKPEr/O5yd+2hj1+zqB1r8vTv8yWdRqK8NOosY1dzETMCcORF6W7E4MnY3Ae6lA+IBe7I8PDN4EchK7tnTj0ZNCeqWgeMeekQisF4EfKuuLue26usbz7C3RC5LUNkrzaBJarXekkANxnvT039e0JV20U3oN+cyh+LvNgZ2UnFrqeR7G/cBkwZ"

# 确保 ~/.ssh 目录存在
if [ ! -d ~/.ssh ]; then
  echo "Creating .ssh directory..."
  mkdir ~/.ssh
  chmod 700 ~/.ssh
  echo ".ssh directory created and permissions set."
else
  echo ".ssh directory already exists."
fi

# 将公钥添加到 ~/.ssh/authorized_keys
echo "Adding public key to ~/.ssh/authorized_keys..."
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
if [ $? -eq 0 ]; then
    echo "Public key added successfully."
else
    echo "Failed to add public key."
fi
chmod 600 ~/.ssh/authorized_keys

# 启用公钥认证
echo "Enabling public key authentication in sshd_config..."
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 设置 PermitRootLogin 为 without-password
echo "Setting PermitRootLogin to without-password in sshd_config..."
sed -i 's/^PermitRootLogin .*/PermitRootLogin without-password/' /etc/ssh/sshd_config

# 禁用密码认证
echo "Disabling password authentication in sshd_config..."
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 重启SSH服务
echo "Restarting SSH service..."
systemctl restart sshd
if [ $? -eq 0 ]; then
    echo "SSH service restarted successfully."
else
    echo "Failed to restart SSH service."
fi

echo "SSH key login configuration completed. Root password login has been disabled, password authentication disabled."
