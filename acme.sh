#!/bin/bash

# 提示用户输入域名和文件夹名称
read -p "请输入你的域名 (例如 mydomain.com)： " domain
read -p "请输入你的文件夹名称 (例如 name)： " folder

# 安装 acme.sh
echo "安装 acme.sh..."
curl https://get.acme.sh | sh

# 需要重新加载 shell 环境，或者使用绝对路径调用 acme.sh
# 如果重新加载 shell 不可行，则使用 ~/.acme.sh/acme.sh 的绝对路径
ACME_SH_PATH=~/.acme.sh/acme.sh

# 设置默认 CA 服务器
echo "设置默认 CA 服务器为 Let's Encrypt..."
$ACME_SH_PATH --set-default-ca --server letsencrypt

# 发起证书申请
echo "发起证书申请，域名为 $domain..."
$ACME_SH_PATH --issue --dns -d "$domain" --yes-I-know-dns-manual-mode-enough-go-ahead-please

# 提示用户确认 TXT 记录
echo "请在 DNS 配置中添加以下 TXT 记录以验证域名，然后按 Enter 继续..."
read -p "按 Enter 键继续..."

# 续期证书
echo "续期证书，域名为 $domain..."
$ACME_SH_PATH --renew -d "$domain" --yes-I-know-dns-manual-mode-enough-go-ahead-please

# 创建目录
echo "创建目录 /domain/$folder..."
sudo mkdir -p /domain/"$folder"

# 安装证书
echo "安装证书到 /domain/$folder..."
$ACME_SH_PATH --install-cert -d "$domain" \
    --key-file /domain/"$folder"/key.pem \
    --fullchain-file /domain/"$folder"/cert.crt \
    --reloadcmd "service nginx force-reload"

echo "SSL 证书设置完成。"
