#!/bin/sh

# Run: curl https://raw.githubusercontent.com/Surveily/Images/master/script/k3s.sh | sudo sh

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
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--no-deploy traefik" INSTALL_K3S_VERSION="v1.21.7+k3s1" sh -s - 
systemctl stop k3s

# Configure K3S
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.toml.tmpl
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/config.yaml
wget https://raw.githubusercontent.com/Surveily/Images/master/script/k3s/ingress-nginx.yaml

mv config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd
mv config.yaml /etc/rancher/k3s
mv ingress-nginx.yaml /var/lib/rancher/k3s/server/manifests