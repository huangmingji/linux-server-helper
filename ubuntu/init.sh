#!/bin/bash

set -Eeuo pipefail
trap 'status=$?; printf "Error: command failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2; exit "$status"' ERR

if (( EUID != 0 )); then
  echo "Error: Run this script as root, for example: sudo bash $0" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Error: Cannot determine the operating system (/etc/os-release is missing)." >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" || -z "${VERSION_ID:-}" ]]; then
  echo "Error: This script supports Ubuntu only." >&2
  exit 1
fi
printf 'Detected Ubuntu %s.\n' "$VERSION_ID"

sources_file=""
if [[ -s /etc/apt/sources.list.d/ubuntu.sources ]] &&
  grep -Eq '^[[:space:]]*URIs:.*(ubuntu\.com|mirrors\.aliyun\.com)' /etc/apt/sources.list.d/ubuntu.sources; then
  sources_file=/etc/apt/sources.list.d/ubuntu.sources
elif [[ -s /etc/apt/sources.list ]] &&
  grep -Eq '^[[:space:]]*deb(-src)?[[:space:]].*(ubuntu\.com|mirrors\.aliyun\.com)' /etc/apt/sources.list; then
  sources_file=/etc/apt/sources.list
else
  echo "Error: No supported Ubuntu APT source configuration was found." >&2
  exit 1
fi

backup_file="${sources_file}.backup"
cp -p -- "$sources_file" "$backup_file"
sed -i -E \
  's#https?://([[:alnum:]-]+\.)?(archive|security|ports)\.ubuntu\.com#https://mirrors.aliyun.com#g' \
  "$sources_file"
printf 'Updated APT sources in %s (backup: %s).\n' "$sources_file" "$backup_file"

apt update
apt upgrade -y

echo "Do you need a firewall?(Y/n)"
read -r answer || answer=""
if [[ "$answer" == "y" || "$answer" == "Y" || -z "$answer" ]]; then
  apt install ufw -y

  if ! command -v sshd >/dev/null 2>&1; then
    echo "Error: Cannot determine the SSH port because sshd is not installed; UFW was not enabled." >&2
    exit 1
  fi

  ssh_ports_output=$(sshd -T | awk '$1 == "port" { print $2 }' | sort -nu)
  if [[ -z "$ssh_ports_output" ]]; then
    echo "Error: Cannot determine the active SSH port; UFW was not enabled." >&2
    exit 1
  fi

  while IFS= read -r ssh_port; do
    if [[ ! "$ssh_port" =~ ^[0-9]+$ ]] || (( 10#$ssh_port < 1 || 10#$ssh_port > 65535 )); then
      echo "Error: sshd reported an invalid port ($ssh_port); UFW was not enabled." >&2
      exit 1
    fi
    ufw allow "$ssh_port/tcp"
    printf 'Allowed SSH port: %s\n' "$ssh_port"
  done <<< "$ssh_ports_output"

  ufw default deny incoming
  ufw default allow outgoing
  ufw allow http
  ufw allow https
  ufw --force enable
fi

echo "Do you need to install the jdk?(Y/n)"
read -r answer || answer=""
if [[ "$answer" == "y" || "$answer" == "Y" || -z "$answer" ]]; then
  if ! command -v javac >/dev/null 2>&1; then
    apt install openjdk-11-jdk -y
  else
    echo "JDK is already installed."
  fi
fi
