#!/bin/bash

# 更新系统
sudo apt-get update

# 安装 fail2ban
sudo apt-get install -y fail2ban

# 创建 sshd-fail2ban.conf 文件并写入配置
sudo tee /etc/fail2ban/jail.d/sshd-fail2ban.conf > /dev/null <<EOL
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = -1
EOL

# 重新启动 fail2ban 服务
sudo systemctl restart fail2ban

# 检查 fail2ban 状态
sudo fail2ban-client status sshd
