#!/usr/bin/env bash
# Instalação completa Laguna: core + módulos + composer + docker + carga + testes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_INSTALL="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

DEST="${1:-$HOME/ieducar-laguna}"
shift || true

WITH_DIARIO=0
SKIP_CARGA=0
SKIP_TESTS=0
SKIP_DOCKER=0
SKIP_OPTIONAL=0
GIT_PROTO="${LAGUNA_GIT_PROTOCOL:-ssh}"

for arg in "$@"; do
  case "$arg" in
    --with-diario) WITH_DIARIO=1 ;;
    --skip-carga) SKIP_CARGA=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    --skip-docker) SKIP_DOCKER=1 ;;
    --skip-optional) SKIP_OPTIONAL=1 ;;
    --https) GIT_PROTO=https ;;
    --ssh) GIT_PROTO=ssh ;;
    -h|--help)
      cat <<EOF
Uso: $0 [DESTINO] [opções]

Opções:
  --with-diario     Clona também o i-Diário
  --https           Usa HTTPS no GitHub (padrão: ssh / LAGUNA_GIT_PROTOCOL)
  --skip-docker     Não sobe postgres/redis
  --skip-carga      Não roda laguna:setup / demos
  --skip-tests      Não roda smoke tests dos módulos
  --skip-optional   Não clona assinatura-digital

Env:
  LAGUNA_GIT_PROTOCOL=ssh|https
EOF
      exit 0
      ;;
  esac
done

export LAGUNA_GIT_PROTOCOL="$GIT_PROTO"

echo "=== i-Educar Laguna — install ==="
echo "Destino: $DEST"
echo "Protocolo Git: $LAGUNA_GIT_PROTOCOL"

# 1) Core
if [[ ! -d "$DEST/.git" ]]; then
  echo ">> clonando core i-Educar 2.12"
  CORE_URL="$(laguna_git_url i-Educar/i-educar)"
  git clone -b 2.12 "$CORE_URL" "$DEST"
else
  echo "OK  core já presente em $DEST"
fi

# 2) Módulos
CLONE_ARGS=()
[[ "$WITH_DIARIO" -eq 1 ]] && CLONE_ARGS+=(--with-diario)
[[ "$SKIP_OPTIONAL" -eq 1 ]] && CLONE_ARGS+=(--skip-optional)
"$SCRIPT_DIR/clone-modules.sh" "$DEST" "${CLONE_ARGS[@]}"

# 3) .env
if [[ ! -f "$DEST/.env" && -f "$DEST/.env.example" ]]; then
  cp "$DEST/.env.example" "$DEST/.env"
  # Defaults amigáveis ao Docker Compose do core
  if grep -q '^DB_HOST=' "$DEST/.env"; then
    sed -i 's/^DB_HOST=.*/DB_HOST=localhost/' "$DEST/.env" 2>/dev/null \
      || sed -i '' 's/^DB_HOST=.*/DB_HOST=localhost/' "$DEST/.env"
  fi
  echo "OK  .env criado — revise DB_*/REDIS_*/HOST_UID/HOST_GID"
fi

# 4) Composer path + require
echo ">> acoplando pacotes no composer.json"
php "$SCRIPT_DIR/wire-composer.php" "$DEST"

# 5) Docker
if [[ "$SKIP_DOCKER" -eq 0 && -f "$DEST/docker-compose.yml" ]]; then
  echo ">> subindo postgres + redis"
  (cd "$DEST" && docker compose up -d postgres redis)
  echo ">> aguardando Postgres…"
  for i in $(seq 1 30); do
    if (cd "$DEST" && docker compose exec -T postgres pg_isready -U ieducar >/dev/null 2>&1) \
      || (cd "$DEST" && docker compose exec -T postgres pg_isready >/dev/null 2>&1); then
      echo "OK  Postgres pronto"
      break
    fi
    sleep 2
    [[ "$i" -eq 30 ]] && echo "WARN Postgres ainda não respondeu"
  done
else
  echo "WARN docker pulado ou compose ausente"
fi

# 6) Dependências PHP
echo ">> composer update (path packages @dev)"
if command -v composer >/dev/null; then
  (cd "$DEST" && composer update \
    buriti/i-educar-laguna-ambiente-package \
    buriti/i-educar-setup-package \
    buriti/i-educar-exportacao-unificada-package \
    --with-all-dependencies --no-interaction 2>/dev/null) \
    || (cd "$DEST" && composer dump-autoload -o)
  (cd "$DEST" && composer dump-autoload -o)
else
  echo "WARN composer não encontrado no PATH — rode dentro do container php"
  if [[ -f "$DEST/docker-compose.yml" ]]; then
    (cd "$DEST" && docker compose up -d php 2>/dev/null || true)
    (cd "$DEST" && docker compose exec -T php composer dump-autoload -o) || true
  fi
fi

# 7) Instalação de banco (nova) ou migrate
echo ">> banco de dados"
HAS_TABLES=0
if [[ -f "$DEST/.env" ]]; then
  set +u
  # shellcheck disable=SC1091
  DB_HOST=$(grep -E '^DB_HOST=' "$DEST/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_PORT=$(grep -E '^DB_PORT=' "$DEST/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_DATABASE=$(grep -E '^DB_DATABASE=' "$DEST/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_USERNAME=$(grep -E '^DB_USERNAME=' "$DEST/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_PASSWORD=$(grep -E '^DB_PASSWORD=' "$DEST/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  set -u
  if php -r "try { \$p=new PDO('pgsql:host=${DB_HOST:-127.0.0.1};port=${DB_PORT:-5432};dbname=${DB_DATABASE}','${DB_USERNAME}','${DB_PASSWORD}'); \$n=(int)\$p->query(\"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='pmieducar'\")->fetchColumn(); echo \$n; } catch (Throwable \$e) { echo 0; }" 2>/dev/null | grep -qE '^[1-9]'; then
    HAS_TABLES=1
  fi
fi

if [[ "$HAS_TABLES" -eq 0 ]]; then
  echo ">> instalação nova (composer new-install + seed)"
  if laguna_in_docker "$DEST"; then
    (cd "$DEST" && docker compose exec -T php composer new-install) || true
    (cd "$DEST" && docker compose exec -T php php artisan db:seed --force) || true
  elif command -v composer >/dev/null; then
    (cd "$DEST" && composer new-install) || (cd "$DEST" && php artisan migrate --force) || true
    (cd "$DEST" && php artisan db:seed --force) || true
  else
    echo "WARN não foi possível instalar o banco automaticamente"
  fi
else
  echo "OK  schema pmieducar já existe — migrate incremental"
  laguna_php "$DEST" php artisan migrate --force || true
fi

# 8) Package discover
laguna_php "$DEST" php artisan package:discover --ansi 2>/dev/null || true

# 9) Checagem
echo ">> checagem de ambiente"
"$SCRIPT_DIR/check-ambiente.sh" "$DEST" || true

# 10) Carga
if [[ "$SKIP_CARGA" -eq 0 ]]; then
  echo ">> carga Laguna (laguna:setup)"
  "$SCRIPT_DIR/run-carga.sh" "$DEST" || echo "WARN carga com avisos"
else
  echo "SKIP carga (--skip-carga)"
fi

# 11) Testes
if [[ "$SKIP_TESTS" -eq 0 ]]; then
  echo ">> smoke tests dos módulos"
  "$SCRIPT_DIR/run-tests.sh" "$DEST" || echo "WARN testes com falhas"
else
  echo "SKIP testes (--skip-tests)"
fi

cat <<EOF

=== Install Laguna finalizado ===
Core:     $DEST
Tutorial: $ROOT_INSTALL/TUTORIAL.md

Comandos úteis:
  cd $DEST
  php artisan laguna:check
  php artisan laguna:setup
  php artisan laguna:ensaiar
  $ROOT_INSTALL/scripts/run-tests.sh $DEST
  $ROOT_INSTALL/scripts/run-carga.sh $DEST

Logins PoC (após carga): CPF = senha (ex.: 42091020001 admin SME).

EOF
