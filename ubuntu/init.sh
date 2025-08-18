#!/bin/bash
echo "Your ubuntu version is (default 24.04):"
read version
if [ -z "$version" ]; then
    version="24.04"
fi

# 使用版本号比较而不是字符串比较
if [ "$(printf '%s\n' "24.04" "$version" | sort -V | head -n1)" != "24.04" ]; then
    # 检查是否具有足够权限
    if [ ! -w "/etc/apt/sources.list" ]; then
        echo "Error: Insufficient permissions to modify /etc/apt/sources.list"
        exit 1
    fi
    # 创建备份文件
    cp /etc/apt/sources.list /etc/apt/sources.list.backup
    sed -i 's/ports.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
else
    # 检查是否具有足够权限
    if [ ! -w "/etc/apt/sources.list.d/ubuntu.sources" ]; then
        echo "Error: Insufficient permissions to modify /etc/apt/sources.list.d/ubuntu.sources"
        exit 1
    fi
    # 创建备份文件
    cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.backup
    sed -i 's/ports.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/ubuntu.sources
fi

apt update
apt upgrade -y

# 开放防火墙
echo "Do you need a firewall?(Y/n)"
read answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ -z "$answer" ]; then
  apt install ufw -y
  ufw default deny incoming  # 拒绝入站
  ufw default allow outgoing # 允许出站

  # 获取SSH端口并开放防火墙
  sshPort=$(grep -oP 'Port \K.*' /etc/ssh/sshd_config)
  if [ -z "$sshPort" ]; then
    sshPort=22
  fi
  ufw allow $sshPort/tcp
  echo "SSH port: $sshPort"

  # 开放 HTTP（80）和 HTTPS（443）
  ufw allow http
  ufw allow https

  ufw enable
fi

# 输出提示是否安装jdk
echo "Do you need to install the jdk?(Y/n)"
read answer
# 判断是否安装jdk
if [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ -z "$answer" ]; then
  if [ -z "$(command -v java)" ]; then
    apt install openjdk-11-jdk
  else
    echo "JDK is already installed."
  fi
fi