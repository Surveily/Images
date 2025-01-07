#! /bin/bash
mkdir -p /etc/rancher/k3s
rm -f /etc/rancher/k3s/config.yaml
wget -O /etc/rancher/k3s/config.yaml https://raw.githubusercontent.com/Surveily/Images/refs/heads/master/script/k3s/config-buildx.yaml
curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/cloud-disk-22.04.sh | bash -s -- sdb /buildx
curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/cloud-agent-22.04.sh | bash
systemctl restart k3s
