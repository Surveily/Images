#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-multi-agent.sh | sudo sh -s -- <ip>

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

# Configure
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.yaml
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/multipath.conf

mkdir -p /etc/rancher/k3s
mv config.yaml /etc/rancher/k3s
mv multipath.conf /etc/multipath.conf

# Install K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.27.1+k3s1" K3S_TOKEN="surveily" sh -s agent --server https://$1:6443
