#!/bin/sh

set -e

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Register OpenVPN
curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" > /etc/apt/sources.list.d/openvpn-aptrepo.list

# Register Nvidia
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

# Upgrade dependencies
apt-get update && apt-get upgrade -y && apt-get install -y gnupg-curl openvpn htop

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Cuda
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-ubuntu1604.pin
mv cuda-ubuntu1604.pin /etc/apt/preferences.d/cuda-repository-pin-600
apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/ /"
apt-get update
apt-get -y install cuda-drivers

# Install Nvidia-Docker
apt-get install -y nvidia-docker2

# Nvidia Persistance
nvidia-persistenced --user $USER
