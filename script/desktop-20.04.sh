#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-20.04.sh | sudo sh

set -e

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Register Nvidia
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

# Upgrade dependencies
apt-get update && apt-get upgrade -y && apt-get install -y wireguard resolvconf

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Driver
apt-get -y install nvidia-driver-470

# Install Nvidia-Docker
apt-get install -y nvidia-docker2
systemctl restart docker

# Add user to Docker
usermod -aG docker $USER

echo "Please Reboot the computer."
