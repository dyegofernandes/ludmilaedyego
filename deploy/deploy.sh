#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

cat > .env <<EOF
POSTGRES_USER=${POSTGRES_USER:-casamento}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-casamento-change-me}
POSTGRES_DB=${POSTGRES_DB:-casamento}
JWT_SECRET=${JWT_SECRET:-change-me-casamento-jwt}
JWT_EXPIRES_IN=${JWT_EXPIRES_IN:-30d}
PUBLIC_WEB_URL=${PUBLIC_WEB_URL:-http://ludmilaedyego}
BOOTSTRAP_NOIVO_EMAIL=${BOOTSTRAP_NOIVO_EMAIL:-dyego.fernandes.vieira@gmail.com}
BOOTSTRAP_NOIVO_PASSWORD=${BOOTSTRAP_NOIVO_PASSWORD:-123456}
BOOTSTRAP_NOIVO_NOME=${BOOTSTRAP_NOIVO_NOME:-Dyego}
RUN_SEED=${RUN_SEED:-false}
EOF

docker compose -f docker-compose.prod.yml -p casamento down --remove-orphans || true
docker compose -f docker-compose.prod.yml -p casamento up -d --build --force-recreate
docker compose -f docker-compose.prod.yml -p casamento ps
echo "Web:     http://ludmilaedyego/"
echo "Web IP:  http://207.180.243.108/"
echo "API:     http://207.180.243.108/api/health"
