#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
cd "$ROOT"

ok=0
fail=0
warn=0
say() {
  local st="$1"; shift
  echo "[$st] $*"
  case "$st" in
    OK) ok=$((ok+1));;
    WARN) warn=$((warn+1));;
    *) fail=$((fail+1));;
  esac
}

php -r 'echo PHP_VERSION, "\n";' >/dev/null && say OK "PHP $(php -r 'echo PHP_VERSION;')" || say FAIL "PHP"
php -r 'exit(version_compare(PHP_VERSION,"8.3.0",">=")?0:1);' && say OK "PHP ≥ 8.3" || say FAIL "PHP ≥ 8.3"

for ext in pdo_pgsql pgsql gd zip xml mbstring; do
  php -m | grep -qi "^${ext}$" && say OK "ext $ext" || say FAIL "ext $ext"
done

[[ -f .env ]] && say OK ".env presente" || say FAIL ".env ausente"
[[ -f artisan ]] && say OK "artisan" || say FAIL "artisan"

if [[ -f .env ]]; then
  set +u
  DB_HOST=$(grep -E '^DB_HOST=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_PORT=$(grep -E '^DB_PORT=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_DATABASE=$(grep -E '^DB_DATABASE=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_USERNAME=$(grep -E '^DB_USERNAME=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  DB_PASSWORD=$(grep -E '^DB_PASSWORD=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  REDIS_HOST=$(grep -E '^REDIS_HOST=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  REDIS_PORT=$(grep -E '^REDIS_PORT=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  set -u
  DB_HOST=${DB_HOST:-127.0.0.1}
  DB_PORT=${DB_PORT:-5432}
  REDIS_HOST=${REDIS_HOST:-127.0.0.1}
  REDIS_PORT=${REDIS_PORT:-6379}

  if php -r "new PDO('pgsql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');" 2>/dev/null; then
    say OK "Postgres ${DB_HOST}:${DB_PORT}/${DB_DATABASE}"
    for t in pmieducar.escola pmieducar.turma pmieducar.aluno; do
      n=$(php -r "\$p=new PDO('pgsql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}','${DB_USERNAME}','${DB_PASSWORD}'); echo (int)\$p->query('SELECT COUNT(*) FROM ${t}')->fetchColumn();" 2>/dev/null || echo err)
      if [[ "$n" == "err" ]]; then say WARN "$t inacessível"
      elif [[ "$n" -gt 0 ]]; then say OK "$t: $n"
      else say WARN "$t: 0 registros"; fi
    done
  else
    say FAIL "Postgres não conecta"
  fi

  if timeout 1 bash -c "echo >/dev/tcp/${REDIS_HOST}/${REDIS_PORT}" 2>/dev/null; then
    say OK "Redis ${REDIS_HOST}:${REDIS_PORT}"
  else
    say WARN "Redis não alcançável"
  fi
fi

REQUIRED=(
  packages/buriti/i-educar-exportacao-unificada-package
  packages/buriti/i-educar-escolar-aderencia-package
  packages/buriti/i-educar-transporte-escolar-v2
  packages/portabilis/pre-matricula-digital
  packages/buriti/i-educar-apps-api-package
  packages/buriti/i-educar-laguna-ambiente-package
  packages/buriti/i-educar-setup-package
  packages/buriti/i-educar-contratacoes-temporarias-package
  packages/buriti/i-educar-busca-ativa-package
)

for p in "${REQUIRED[@]}"; do
  [[ -d "$p" ]] && say OK "módulo $p" || say FAIL "faltando $p"
done

if [[ -f artisan ]] && php artisan list --raw 2>/dev/null | grep -q '^laguna:check'; then
  say OK "comando laguna:check registrado"
else
  say WARN "laguna:check ausente (composer dump-autoload / package discover)"
fi

echo
echo "Resumo: $ok ok, $warn avisos, $fail falhas"
[[ "$fail" -eq 0 ]] || exit 1
