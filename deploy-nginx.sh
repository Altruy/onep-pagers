#!/usr/bin/env bash

set -euo pipefail

DOMAINS=(
  "turyal.cloud"
  "altyur.cloud"
)

EMAIL="turyal.neeshat5@gmail.com" 
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root:"
  echo "sudo bash $0"
  exit 1
fi

echo "Installing nginx and certbot..."

if command -v apt >/dev/null 2>&1; then
  apt update
  apt install -y nginx certbot python3-certbot-nginx
elif command -v yum >/dev/null 2>&1; then
  yum install -y nginx certbot python3-certbot-nginx
else
  echo "Unsupported package manager. Please install nginx and certbot manually."
  exit 1
fi

systemctl enable nginx
systemctl start nginx

echo "Deploying sites..."

for DOMAIN in "${DOMAINS[@]}"; do
  SOURCE_FILE="$REPO_DIR/$DOMAIN/index.html"
  WEB_ROOT="/var/www/$DOMAIN"
  NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

  if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Missing file: $SOURCE_FILE"
    exit 1
  fi

  echo "Deploying $DOMAIN..."

  mkdir -p "$WEB_ROOT"
  cp "$SOURCE_FILE" "$WEB_ROOT/index.html"

  if id www-data >/dev/null 2>&1; then
    chown -R www-data:www-data "$WEB_ROOT"
  else
    chown -R nginx:nginx "$WEB_ROOT"
  fi

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

  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN"
done

rm -f /etc/nginx/sites-enabled/default

echo "Testing nginx config..."
nginx -t

echo "Reloading nginx..."
systemctl reload nginx

echo "Requesting HTTPS certificates..."

for DOMAIN in "${DOMAINS[@]}"; do
  certbot --nginx \
    -d "$DOMAIN" \
    -d "www.$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --redirect
done

echo "Testing nginx config after SSL..."
nginx -t

echo "Reloading nginx..."
systemctl reload nginx

echo "Checking certbot renewal timer..."
systemctl enable certbot.timer 2>/dev/null || true
systemctl start certbot.timer 2>/dev/null || true

echo "Done."
echo ""
echo "HTTPS should now work for:"
for DOMAIN in "${DOMAINS[@]}"; do
  echo "  https://$DOMAIN"
  echo "  https://www.$DOMAIN"
done
