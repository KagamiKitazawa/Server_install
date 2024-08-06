#!/bin/bash

# 检查是否以 root 用户运行
if [ "$(id -u)" -ne "0" ]; then
  echo "此脚本需要以 root 用户运行。"
  exit 1
fi

# 输入网段数量
read -p "请输入网段数量: " subnet_count

# 输入端口
read -p "请输入端口号: " port

# 循环输入网段
for ((i = 1; i <= subnet_count; i++)); do
  read -p "请输入网段 $i: " subnet
  iptables -A INPUT -p tcp --dport "$port" -s "$subnet" -j ACCEPT
done

# 禁止其他 IP 地址访问指定端口
iptables -A INPUT -p tcp --dport "$port" -j REJECT

# 禁止所有 IPv6 地址访问指定端口
ip6tables -A INPUT -p tcp --dport "$port" -j REJECT

# 保存规则
netfilter-persistent save

echo "规则配置完成并已保存。"
