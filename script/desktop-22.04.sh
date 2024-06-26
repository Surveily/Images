#!/bin/sh

# Run: sudo apt install curl && curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/desktop-22.04.sh | sudo sh -s -- $USER

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Local name
echo "$(hostname -I | awk '{print $1}') local.surveily.com" >> /etc/hosts

# Register Nvidia
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu20.04/libnvidia-container.list | \
#      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Upgrade dependencies
apt-get update
apt-get upgrade -y
apt-get install -y wireguard resolvconf vim net-tools apt-transport-https openssh-server git iperf mpv

# Install Keys
mkdir -p ~/.ssh
wget -qO ~/.ssh/authorized_keys https://github.com/turowicz.keys

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Driver
apt-get -y install nvidia-driver-545

# Install Nvidia-Docker
apt-get install -y nvidia-docker2
systemctl restart docker
docker network create development

# Add user to Docker
usermod -aG docker $1
#newgrp docker

# Install Brave
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
apt-get update && apt-get install -y brave-browser

# Configure Snap
snap remove firefox
snap install code --classic
snap install kubectl --classic
snap install helm --classic
snap install vlc
snap install remmina

# Install Lens
LATEST_DEB_DOWNLOAD_URL=$(curl https://api.github.com/repos/MuhammedKalkan/OpenLens/releases/latest | jq -r '.assets[]| select(.name | test("^OpenLens-\\d+\\.\\d+\\.\\d+-\\d+.amd64.deb$")) | .browser_download_url')
curl -L $LATEST_DEB_DOWNLOAD_URL > openlens.amd64.deb
dpkg -i openlens.amd64.deb
rm openlens.amd64.deb

# Install Mainline
add-apt-repository ppa:cappelikan/ppa
apt-get update && apt-get install -y mainline

# Configure VS Code
# echo 'code --install-extension ms-vscode-remote.remote-containers' >> /home/$1/.profile

# Configure xhost
echo 'xhost +"local:docker@"' >> /home/$1/.profile

# Configure .NET
echo fs.inotify.max_user_instances=524288 | tee -a /etc/sysctl.conf && sysctl -p

echo "Please Reboot the computer."
