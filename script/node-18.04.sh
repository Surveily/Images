#!/bin/sh

# Run: curl https://raw.githubusercontent.com/Surveily/Images/master/script/node-18.04.sh | sudo sh

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
apt-get update && apt-get upgrade -y && apt-get install -y openvpn

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Cuda
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
apt-get update
apt-get -y install cuda-drivers

# Install Nvidia-Docker
apt-get install -y nvidia-docker2
