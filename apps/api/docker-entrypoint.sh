#!/bin/sh
set -e

echo "[casamento-api] Aplicando migrations…"
./node_modules/.bin/prisma migrate deploy

if [ "$RUN_SEED" = "true" ] || [ "$RUN_SEED" = "1" ]; then
  echo "[casamento-api] RUN_SEED ativo — populando dados de exemplo…"
  node scripts/docker-seed.js
else
  echo "[casamento-api] Garantindo conta do noivo…"
  node scripts/docker-bootstrap.js
fi

echo "[casamento-api] Subindo API…"
exec node dist/main.js
