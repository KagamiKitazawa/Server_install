#!/bin/bash

# 检查是否以 root 用户运行
if [ "$(id -u)" -ne "0" ]; then
  echo "此脚本需要以 root 用户运行。"
  exit 1
fi

# 安装 iptables 持久化相关组件
echo "正在安装 iptables 持久化组件..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y iptables iptables-persistent netfilter-persistent

# 确保 netfilter-persistent 开机自启
systemctl enable --now netfilter-persistent

# 输入网段数量
read -p "请输入网段数量: " subnet_count

# 输入端口
read -p "请输入端口号: " port

# 循环输入网段
for ((i = 1; i <= subnet_count; i++)); do
  read -p "请输入网段 $i: " subnet
  iptables -A INPUT -p tcp --dport "$port" -s "$subnet" -j ACCEPT
done

# 禁止其他 IPv4 地址访问指定端口
iptables -A INPUT -p tcp --dport "$port" -j REJECT

# 禁止所有 IPv6 地址访问指定端口
ip6tables -A INPUT -p tcp --dport "$port" -j REJECT

# 创建规则保存目录
mkdir -p /etc/iptables

# 保存当前 IPv4 / IPv6 规则
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# 使用 netfilter-persistent 再保存一次
netfilter-persistent save

# 确保重启后自动恢复规则
systemctl enable netfilter-persistent

echo "规则配置完成，已保存，并已启用开机自动恢复。"
