#!/bin/sh

# Run: sudo apt install curl && curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/desktop-24.04.sh | sudo sh -s -- $USER

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Local name
echo "$(hostname -I | awk '{print $1}') local.surveily.com" >> /etc/hosts

# Register NVIDIA
add-apt-repository -y ppa:graphics-drivers/ppa
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Upgrade dependencies
apt-get update
apt-get upgrade -y
apt-get install -y wireguard resolvconf vim net-tools apt-transport-https openssh-server git iperf mpv simplescreenrecorder

# Configure SSH
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Install Keys
mkdir -p /home/$1/.ssh
wget -qO /home/$1/.ssh/authorized_keys https://github.com/turowicz.keys

# Install Docker
curl https://get.docker.com | sh && systemctl --now enable docker

# Install Driver
apt-get -y install nvidia-driver-575

# Install NVIDIA Container Toolkit
apt-get install -y nvidia-container-toolkit
systemctl restart docker
docker network create development

# Add user to Docker
usermod -aG docker $1

# Install Brave
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
apt-get update && apt-get install -y brave-browser

# Install Code
wget -O code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
dpkg -i code.deb
rm code.deb

# Configure Snap
snap remove firefox
snap install kubectl --classic
snap install helm --classic
snap install vlc
snap install remmina

# Install Lens
LATEST_DEB_DOWNLOAD_URL=$(curl https://api.github.com/repos/freelensapp/freelens/releases/latest | jq -r '.assets[]| select(.name | test("^Freelens-.*.amd64.deb$")) | .browser_download_url')
curl -L $LATEST_DEB_DOWNLOAD_URL > lens.amd64.deb
dpkg -i lens.amd64.deb
rm lens.amd64.deb

# Install Mainline
# add-apt-repository ppa:cappelikan/ppa
# apt-get update && apt-get install -y mainline

# Configure VS Code
# echo 'code --install-extension ms-vscode-remote.remote-containers' >> /home/$1/.profile

# Configure xhost
echo 'xhost +"local:docker@"' >> /home/$1/.profile

# Configure .NET
echo fs.inotify.max_user_instances=524288 | tee -a /etc/sysctl.conf && sysctl -p

echo "Please Reboot the computer."

