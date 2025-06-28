#!/bin/bash

# server-install.sh - Debian 12 系统安装脚本
# 作者: AI 助手
# 描述: 根据用户要求自动执行系统配置，包括用户创建、SSH 设置、fail2ban 和 Docker 安装。
# 注意: 请以 root 权限运行此脚本。

# 步骤1: 更新和升级系统，并安装基本包
apt update -y && apt upgrade -y && apt install wget curl sudo lsof nload htop net-tools  netfilter-persistent -y
echo "步骤1完成: 系统已更新并安装基本包。"

# 步骤2: 创建新用户，用户名和密码由用户输入，并添加到 sudo 组。如果用户已存在，跳过创建
read -p "请输入新用户名: " username
read -s -p "请输入密码 for $username: " password
echo  # 换行以美化输出
if id "$username" &>/dev/null; then
    echo "用户 $username 已存在，跳过创建。"
else
    useradd -m -s /bin/bash "$username"  # 创建用户并设置主目录和 shell
    echo "$username:$password" | chpasswd  # 设置密码
    usermod -aG sudo "$username"  # 将用户添加到 sudo 组
    echo "用户 $username 创建成功并添加到 sudo 组。"
fi

# 步骤4: 下载 SSH 密钥，使用 GitHub 的 SSH 作为本机 SSH，GitHub 用户名由用户输入
read -p "请输入 GitHub 用户名: " github_user
mkdir -p /home/$username/.ssh  # 创建 .ssh 目录
chown $username:$username /home/$username/.ssh  # 更改所有者
chmod 700 /home/$username/.ssh  # 设置权限
curl -s https://github.com/$github_user.keys > /home/$username/.ssh/authorized_keys  # 下载 GitHub 公钥
chown $username:$username /home/$username/.ssh/authorized_keys  # 更改所有者
chmod 600 /home/$username/.ssh/authorized_keys  # 设置权限
echo "SSH 公钥下载并设置成功。"

# 步骤5: 让用户输入所希望使用的 SSH 端口
read -p "请输入希望使用的 SSH 端口: " ssh_port
echo "SSH 端口设置为 $ssh_port。"

# 步骤6: 将指定内容添加到 /etc/ssh/sshd_config.d/ssh.conf，并使用输入的端口
echo "Port $ssh_port" > /etc/ssh/sshd_config.d/ssh.conf  # 创建或覆盖文件
echo "PermitRootLogin no" >> /etc/ssh/sshd_config.d/ssh.conf
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config.d/ssh.conf
echo "AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2" >> /etc/ssh/sshd_config.d/ssh.conf
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config.d/ssh.conf
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config.d/ssh.conf
systemctl restart ssh  # 重启 SSH 服务以应用配置
echo "SSHD 配置已更新并重启。注意: SSH 端口已更改为 $ssh_port，请确保防火墙允许该端口。"

# 步骤7: 安装 fail2ban，并使用自定义配置文件 fail2ban-client.conf
apt install fail2ban -y  # 安装 fail2ban
# 创建自定义配置文件 /etc/fail2ban/jail.d/fail2ban-client.conf
# 内容: 登录失败 3 次，使用 iptables 永久封禁 IP，日志使用 journal (systemd)
cat << EOF > /etc/fail2ban/jail.d/fail2ban-client.conf
[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = systemd
bantime = -1
findtime = 60
maxretry = 3
banaction = iptables-allports
EOF
systemctl restart fail2ban  # 重启 fail2ban 服务以应用配置
echo "Fail2ban 安装并配置成功。自定义配置文件已创建。"

# 步骤8: 让用户输入网段，安装 Docker 和 Docker Compose，创建桥接内网 docker-network
read -p "请输入网段，例如 10.11.0.0/24: " subnet
# 安装 Docker
apt install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install docker-ce docker-ce-cli containerd.io -y
# 安装 Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# 创建桥接网络 docker-network，使用用户输入的网段
docker network create --driver bridge --subnet=$subnet docker-network
echo "Docker 和 Docker Compose 安装成功，桥接网络 docker-network 已创建，使用网段 $subnet。"

# 脚本结束
echo "脚本执行完成。请验证所有设置。如果需要切换到新用户，请手动执行 'su - $username'。"
