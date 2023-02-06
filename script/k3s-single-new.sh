#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-single-new.sh | sudo sh

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
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.23.16+k3s1" sh -s server --cluster-init --disable local-storage --token "surveily"
systemctl stop k3s

# Configure K3S
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.yaml
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/multipath.conf

mv config.yaml /etc/rancher/k3s
mv multipath.conf /etc/multipath.conf

# Make sure to `vim /etc/rancher/k3s/config.yaml` and `systemctl start k3s` after this script!
printf "Make sure to: ${TXT_YELLOW}'vim /etc/rancher/k3s/config.yaml'${TXT_NORMAL}\nand start k3s with: ${TXT_YELLOW}'systemctl start k3s'${TXT_NORMAL} after this script!${TXT_NORMAL}\n"
