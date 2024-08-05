#!/bin/bash

# 更新系统包
echo "Updating system packages..."
sudo apt-get update

# 安装工具
echo "Installing htop, lsof, nload, and net-tools..."
sudo apt-get install -y htop lsof nload net-tools

# 验证安装
echo "Verifying installations..."
dpkg -l | grep -E 'htop|lsof|nload|net-tools'

echo "Installation complete."
