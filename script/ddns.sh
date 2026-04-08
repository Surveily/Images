#!/usr/bin/env sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/ddns.sh | sudo bash -s -- <TOKEN>

set -eu

# Usage:
#   sudo ./setup-ddns.sh <API_KEY> [ZONE] [SUBDOMAIN]
# Example:
#   sudo ./setup-ddns.sh 'your_token_here' surveily.com "$(hostname -s).int"

API_KEY="${1:-}"
ZONE="${2:-surveily.com}"
SUBDOMAIN="${3:-$(hostname -s).int}"

if [ -z "$API_KEY" ]; then
  echo "Usage: sudo $0 <API_KEY> [ZONE] [SUBDOMAIN]" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

install -d -m 0700 -o root -g root /etc/surveily

cat > /etc/surveily/ddns.env <<EOF
API_KEY=${API_KEY}
ZONE=${ZONE}
SUBDOMAIN=${SUBDOMAIN}
CUSTOM_LOOKUP_CMD=sh -c "vpn_ip=\\\$(ip -o -4 addr show scope global | awk '{split(\\\$4, a, \"/\"); if (a[1] ~ /^172\\.20\\.0\\.[0-9]+$/) { print a[1]; exit }}'); if [ -n \"\\\$vpn_ip\" ]; then echo \"\\\$vpn_ip\"; else ip route get 1 | awk '{for (i = 1; i <= NF; i++) if (\\\$i == \"src\") { print \\\$(i + 1); exit }}'; fi"
EOF

chown root:root /etc/surveily/ddns.env
chmod 0600 /etc/surveily/ddns.env

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install/start Docker first." >&2
  exit 1
fi

# Refresh image
docker pull oznu/cloudflare-ddns >/dev/null

# Recreate container to apply env updates
docker rm -f ddns >/dev/null 2>&1 || true

docker run -d \
  --name ddns \
  --restart always \
  --env-file /etc/surveily/ddns.env \
  --network host \
  oznu/cloudflare-ddns >/dev/null

echo "DDNS container is running."
echo "Env file: /etc/surveily/ddns.env (root:root, 0600)"
