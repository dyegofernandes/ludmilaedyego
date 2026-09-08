#!/bin/sh
set -e
CERT_DIR=/etc/nginx/certs
mkdir -p "$CERT_DIR" /var/www/certbot

if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
  echo "[casamento-nginx] Sem certificado — gerando autoassinado temporário"
  openssl req -x509 -nodes -newkey rsa:2048 -days 30 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/CN=ludmilaedyego.ddns.net"
fi

exec nginx -g 'daemon off;'
