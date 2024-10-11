#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-wg-init.sh | sudo sh -- <ip>

TXT_YELLOW=`tput setaf 3`
TXT_NORMAL=`tput sgr0`

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Disable swap
swapoff -a
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# Configure K3S
mkdir -p /etc/rancher/k3s
wget -O /etc/rancher/k3s/config.yaml https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.yaml
wget -O /etc/multipath.conf https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/multipath.conf

# Install K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.27.1+k3s1" sh -s server --disable local-storage --flannel-backend=wireguard-native --flannel-external-ip --node-external-ip=$1 --cluster-init --token "surveily"

# Configure NVIDIA
k3s kubectl apply -f https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/nvidia.yaml

# Make sure to `vim /etc/rancher/k3s/config.yaml` and `systemctl start k3s` after this script!
systemctl stop k3s
vim /etc/rancher/k3s/config.yaml
systemctl start k3s
