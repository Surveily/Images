#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-22.04.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

arch=$(arch)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID$)

# Register NVIDIA Container Toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Register NVIDIA Cuda
wget https://developer.download.nvidia.com/compute/cuda/repos/${distribution/./""}/${arch}/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb && rm cuda-keyring_1.0-1_all.deb

# Upgrade dependencies
apt-get update && apt-get upgrade -y && apt-get install -y wireguard resolvconf nvme-cli nfs-common smartmontools iperf iputils-ping inetutils-traceroute lm-sensors net-tools software-properties-common vim rsync htop

# Uninstall unattended upgrades to prevent from unexpected updates
apt-get remove -y unattended-upgrades

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Cuda
apt-get -y install --no-install-recommends cuda-drivers-525

# Install Nvidia-Docker
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Install Mainline
add-apt-repository -y ppa:cappelikan/ppa
apt-get install -y mainline

# Install QEMU
apt-get install -y qemu binfmt-support qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes
cat /proc/sys/fs/binfmt_misc/status
cat /proc/sys/fs/binfmt_misc/qemu-aarch64
