#!/usr/bin/env bash
set -euo pipefail
# Advanced installer for gost + full Flask panel (Debian/Ubuntu)
# Usage: sudo bash install.sh [--domain example.com] [--email you@example.com] [--no-certbot]
DOMAIN=""
EMAIL=""
NOCERT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --no-certbot) NOCERT=1; shift;;
    *) echo "Unknown arg $1"; exit 1;;
  esac
done

echo "Updating apt and installing dependencies..."
apt update
apt install -y python3 python3-venv python3-pip git wget unzip nginx sqlite3 golang-go build-essential ca-certificates curl iproute2 iptables nftables iptables-persistent

echo "Create system user gostsvc..."
id -u gostsvc &>/dev/null || useradd -r -s /usr/sbin/nologin gostsvc || true

echo "Installing gost (latest release)..."
# Try to download a prebuilt binary for linux-amd64 from GitHub releases
GOST_URL=$(curl -s https://api.github.com/repos/go-gost/gost/releases/latest | grep -Eo "https://[^\"]+gost-linux-amd64[^\"]+\.tar\.gz" | head -n1)
if [ -n "$GOST_URL" ]; then
  echo "Found gost release: $GOST_URL"
  tmp=$(mktemp -d)
  wget -qO "$tmp/gost.tar.gz" "$GOST_URL"
  tar -xzf "$tmp/gost.tar.gz" -C "$tmp"
  # try common bin paths inside archive
  if [ -f "$tmp/gost" ]; then
    install -m 0755 "$tmp/gost" /usr/local/bin/gost
  else
    # search for gost binary
    find "$tmp" -type f -name gost -exec install -m 0755 {} /usr/local/bin/gost \; || true
  fi
  rm -rf "$tmp"
else
  echo "Could not find prebuilt release automatically, attempting 'go install'..."
  export GOPATH=/root/go
  export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
  /bin/bash -lc 'go install github.com/go-gost/gost@latest' || true
  if [ -f "/root/go/bin/gost" ]; then
    install -m 0755 /root/go/bin/gost /usr/local/bin/gost
  fi
fi

if ! command -v gost &>/dev/null; then
  echo "WARNING: gost binary not installed automatically. Please install manually and place binary at /usr/local/bin/gost"
else
  echo "gost installed at $(which gost)"
fi

echo "Install tun2socks (if available via apt)..."
if ! command -v tun2socks &>/dev/null; then
  # try apt or download simple releases
  apt install -y gvisor-tun2socks || true
fi

echo "Copying panel to /opt/gost-panel..."
PANEL_DIR=/opt/gost-panel
rm -rf $PANEL_DIR
mkdir -p $PANEL_DIR
cp -r ./panel/* $PANEL_DIR/
chown -R gostsvc:gostsvc $PANEL_DIR

echo "Creating python venv and installing requirements..."
python3 -m venv $PANEL_DIR/venv
$PANEL_DIR/venv/bin/pip install --upgrade pip
$PANEL_DIR/venv/bin/pip install -r $PANEL_DIR/requirements.txt

echo "Creating systemd service for gost-panel..."
cat >/etc/systemd/system/gost-panel.service <<'EOF'
[Unit]
Description=Gost Panel (Flask)
After=network.target

[Service]
User=gostsvc
Group=gostsvc
WorkingDirectory=/opt/gost-panel
Environment=PATH=/opt/gost-panel/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/gost-panel/venv/bin/python /opt/gost-panel/app.py
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now gost-panel

echo "Creating gost systemd service (uses /etc/gost/config.json by default)..."
mkdir -p /etc/gost
cat >/etc/systemd/system/gost.service <<'EOF'
[Unit]
Description=gost tunnel service
After=network.target

[Service]
Type=simple
User=gostsvc
Group=gostsvc
ExecStart=/usr/local/bin/gost -C /etc/gost/config.json
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gost || true

echo "Optional: configure nginx as reverse proxy with TLS (if domain provided)"
if [ -n "$DOMAIN" ] && [ "$NOCERT" -eq 0 ]; then
  echo "Configuring nginx for $DOMAIN and obtaining certificate via certbot..."
  apt install -y certbot python3-certbot-nginx
  cat >/etc/nginx/sites-available/gost-panel <<NGINX
server {
  listen 80;
  server_name $DOMAIN;
  location / {
    proxy_pass http://127.0.0.1:5000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
NGINX
  ln -sf /etc/nginx/sites-available/gost-panel /etc/nginx/sites-enabled/gost-panel
  nginx -t && systemctl restart nginx
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "${EMAIL:-admin@$DOMAIN}" || true
else
  echo "No domain provided or certbot disabled; panel is available on port 5000 (HTTP)."
fi

echo "Installer finished. Edit /opt/gost-panel/config.yml and set admin credentials before first run."
