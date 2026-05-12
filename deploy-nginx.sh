#!/usr/bin/env bash

set -euo pipefail

DOMAINS=(
  "turyal.cloud"
  "altyur.cloud"
)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root:"
  echo "sudo bash $0"
  exit 1
fi

echo "Installing nginx if needed..."

if command -v apt >/dev/null 2>&1; then
  apt update
  apt install -y nginx
elif command -v yum >/dev/null 2>&1; then
  yum install -y nginx
else
  echo "Unsupported package manager. Please install nginx manually."
  exit 1
fi

echo "Deploying sites..."

for DOMAIN in "${DOMAINS[@]}"; do
  SOURCE_DIR="$REPO_DIR/$DOMAIN"
  SOURCE_FILE="$SOURCE_DIR/index.html"
  WEB_ROOT="/var/www/$DOMAIN"
  NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

  if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Missing file: $SOURCE_FILE"
    exit 1
  fi

  echo "Deploying $DOMAIN..."

  mkdir -p "$WEB_ROOT"
  cp "$SOURCE_FILE" "$WEB_ROOT/index.html"

  chown -R www-data:www-data "$WEB_ROOT" 2>/dev/null || chown -R nginx:nginx "$WEB_ROOT"
  chmod -R 755 "$WEB_ROOT"

  cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    root $WEB_ROOT;
    index index.html;

    location = / {
        try_files /index.html =404;
    }

    location / {
        return 404;
    }
}
EOF

  ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN"
done

echo "Removing default nginx site if it exists..."
rm -f /etc/nginx/sites-enabled/default

echo "Testing nginx config..."
nginx -t

echo "Reloading nginx..."
systemctl enable nginx
systemctl reload nginx || systemctl restart nginx

echo "Done."
echo ""
echo "Make sure your DNS A records point to this VPS:"
for DOMAIN in "${DOMAINS[@]}"; do
  echo "  $DOMAIN -> VPS IP"
  echo "  www.$DOMAIN -> VPS IP"
done
