#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-$HOME/ieducar-laguna}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_INSTALL="$(cd "$SCRIPT_DIR/.." && pwd)"
ALL_FLAG="${2:-}"

echo "=== i-Educar Laguna — install ==="
echo "Destino: $DEST"

if [[ ! -d "$DEST/.git" ]]; then
  echo ">> clonando core i-Educar 2.12"
  git clone -b 2.12 git@github.com:i-Educar/i-educar.git "$DEST"
else
  echo "OK  core já presente em $DEST"
fi

"$SCRIPT_DIR/clone-modules.sh" "$DEST" ${ALL_FLAG:+--all}

if [[ ! -f "$DEST/.env" && -f "$DEST/.env.example" ]]; then
  cp "$DEST/.env.example" "$DEST/.env"
  echo "OK  .env criado a partir de .env.example — revise DB_*/REDIS_*"
fi

if [[ -f "$DEST/docker-compose.yml" ]]; then
  echo ">> subindo postgres + redis"
  (cd "$DEST" && docker compose up -d postgres redis)
else
  echo "WARN docker-compose.yml ausente — suba Postgres/Redis manualmente"
fi

echo ">> checagem de ambiente"
sleep 2
"$SCRIPT_DIR/check-ambiente.sh" "$DEST" || true

cat <<EOF

Próximos passos:
  1. Revise $DEST/.env
  2. cd $DEST && composer dump-autoload -o
  3. Se banco novo: docker compose exec php composer new-install && php artisan db:seed
  4. Siga $ROOT_INSTALL/TUTORIAL.md (seção 4 — validar Onda 0/1)

EOF
