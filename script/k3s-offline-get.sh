#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-offline-get.sh | sh

TXT_YELLOW=`tput setaf 3`
TXT_NORMAL=`tput sgr0`

set -e

if [ `whoami` = root ]; then
    echo "Please run this script without sudo."
    exit 1
fi

mkdir -p .out-k3s

wget -O .out-k3s/k3s https://github.com/k3s-io/k3s/releases/download/v1.27.1%2Bk3s1/k3s
wget -O .out-k3s/k3s-airgap-images-amd64.tar.gz https://github.com/k3s-io/k3s/releases/download/v1.27.1%2Bk3s1/k3s-airgap-images-amd64.tar.gz
wget -O .out-k3s/install.sh https://get.k3s.io/

chmod +x .out-k3s/k3s
chmod +x .out-k3s/install.sh
