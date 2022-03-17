#!/bin/sh

# Run: curl https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-multi-join.sh | sudo sh <ip>

echo $1

TXT_YELLOW=`tput setaf 3`
TXT_NORMAL=`tput sgr0`

set -e

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Disable swap
swapoff -a
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# Install K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.21.7+k3s1" K3S_TOKEN="surveily" sh -s server --server https://$1:6443
systemctl stop k3s

# Configure K3S
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.toml.tmpl
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.yaml

mv config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd
mv config.yaml /etc/rancher/k3s

# Make sure to `vim /etc/rancher/k3s/config.yaml` and `systemctl start k3s` after this script!
printf "Make sure to: ${TXT_YELLOW}'vim /etc/rancher/k3s/config.yaml'${TXT_NORMAL}\nand start k3s with: ${TXT_YELLOW}'systemctl start k3s'${TXT_NORMAL} after this script!${TXT_NORMAL}\n"
