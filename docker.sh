#!/bin/bash

# 更新系统包
echo "Updating system packages..."
sudo apt-get update

# 安装 Docker
echo "Installing Docker..."
curl -sSL https://get.docker.com/ | sh

# 启动 Docker 服务
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# 创建 Docker 网络
echo "Creating Docker network 'docker-network' with subnet 192.168.0.0/24..."
docker network create --subnet=192.168.0.0/24 docker-network

# 验证网络创建
echo "Verifying Docker network creation..."
docker network ls

echo "Docker network setup complete."

sudo apt install docker-compose -y
