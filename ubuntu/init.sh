# 低于Ubuntu24.04版本
//判定系统版本更新源
if [ `lsb_release -rs` -lt "24.04" ]; then
  sed -i 's/ports.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
fi


# Ubuntu24.04
if [ `lsb_release -rs` -eq "24.04" ]; then
  sed -i 's/ports.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/ubuntu.sources
fi

apt update
apt upgrade

# 开放防火墙
echo "Do you need a firewall?(Y/n)"
read answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ -z "$answer" ]; then
  apt install ufw
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