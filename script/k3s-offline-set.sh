#!/bin/sh

# Run: sudo ./k3s-prep.sh

TXT_YELLOW=`tput setaf 3`
TXT_NORMAL=`tput sgr0`

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Deploy Images
mkdir -p /var/lib/rancher/k3s/agent/images
cp k3s-airgap-images-amd64.* /var/lib/rancher/k3s/agent/images/

# Deploy Binaries
chmod +x k3s
cp k3s /usr/local/bin
