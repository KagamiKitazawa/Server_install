#!/bin/bash

# 安装 rclone
echo "正在安装 rclone..."
curl https://rclone.org/install.sh | sudo bash

# 验证安装
echo "验证 rclone 安装..."
rclone --version

echo "rclone 安装完成。"
