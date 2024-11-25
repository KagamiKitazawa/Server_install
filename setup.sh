#!/bin/bash

# 更新系统包
echo "Updating system packages..."
sudo apt-get update -y && apt-get upgrade -y

# 安装工具
echo "Installing htop, lsof, nload, and net-tools..."
sudo apt-get install -y wget curl sudo htop lsof nload net-tools 

# 检查是否为root用户运行
if [ "$EUID" -ne 0 ]; then 
  echo "请使用root权限运行此脚本"
  exit 1
fi

# 交互式获取信息
read -p "请输入要创建的用户名: " NEW_USER
read -s -p "请输入用户密码: " USER_PASS
echo
read -p "请输入Github用户名(用于获取SSH密钥): " GITHUB_USER
read -p "请输入SSH端口号: " SSH_PORT

# 创建新用户
useradd -m -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$USER_PASS" | chpasswd

# 将用户添加到sudo组
usermod -aG sudo "$NEW_USER"

# 切换到新用户并配置SSH
su - "$NEW_USER" << EOF
# 创建.ssh目录
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 下载并验证GitHub用户的SSH公钥
wget -O ~/.ssh/authorized_keys https://github.com/$GITHUB_USER.keys 2>/dev/null

if [ ! -s ~/.ssh/authorized_keys ]; then
    echo "错误: 无法获取GitHub用户 $GITHUB_USER 的SSH密钥"
    echo "请确认用户名是否正确，以及该用户是否有公开的SSH密钥"
    rm -f ~/.ssh/authorized_keys
    exit 1
fi

chmod 600 ~/.ssh/authorized_keys
EOF

# 如果用户配置失败则退出
if [ $? -ne 0 ]; then
    echo "配置失败，请检查错误信息"
    exit 1
fi

# 配置SSH
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/sshd.conf << EOF
Port $SSH_PORT
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2
PasswordAuthentication no
PermitEmptyPasswords no
AllowUsers $NEW_USER
EOF

# 安装并配置fail2ban
apt update
apt install -y fail2ban

cat > /etc/fail2ban/jail.d/ssh-fail2ban.conf << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = -1
EOF

# 重启服务
systemctl restart ssh
systemctl enable fail2ban
systemctl restart fail2ban
read -p "请输入新的主机名: " NEW_HOSTNAME

# 设置主机名
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/127.0.0.1.*/127.0.0.1 localhost $NEW_HOSTNAME/" /etc/hosts
hostnamectl set-hostname "$NEW_HOSTNAME"

echo "请测试是否能够使用新配置登录:"
echo "1. 开启新的终端窗口"
echo "2. 使用以下命令测试登录:"
echo "   ssh -p $SSH_PORT $NEW_USER@<服务器IP>"
echo "3. 确认可以登录后，再关闭当前会话"
