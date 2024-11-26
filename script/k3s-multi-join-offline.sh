#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-multi-join.sh | sudo sh -s -- <ip>

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

# Install K3S
INSTALL_K3S_VERSION="v1.27.1+k3s1" K3S_TOKEN="surveily" INSTALL_K3S_SKIP_DOWNLOAD=true ./install.sh -s server --disable local-storage --server https://$1:6443

# Configure K3S
systemctl stop k3s

wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.yaml
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/multipath.conf

mv config.yaml /etc/rancher/k3s
mv multipath.conf /etc/multipath.conf

# Make sure to `vim /etc/rancher/k3s/config.yaml` and `systemctl start k3s` after this script!
vim /etc/rancher/k3s/config.yaml
systemctl start k3s
