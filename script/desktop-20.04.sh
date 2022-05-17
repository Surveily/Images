#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/desktop-20.04.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Register Nvidia
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu20.04/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
#   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

# Upgrade dependencies
apt-get update && apt-get upgrade -y && apt-get install -y wireguard resolvconf vim net-tools apt-transport-https openssh-server git

# Install Keys
mkdir -p ~/.ssh
wget -qO ~/.ssh/authorized_keys https://github.com/turowicz.keys

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Driver
apt-get -y install nvidia-driver-470

# Install Nvidia-Docker
apt-get install -y nvidia-docker2
systemctl restart docker
docker network create development

# Add user to Docker
usermod -aG docker $USER
#newgrp docker

# Install Brave
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
apt-get update && apt-get install -y brave-browser

# Install Mainline
add-apt-repository ppa:cappelikan/ppa
apt-get update && apt-get install -y mainline

echo "Please Reboot the computer."
