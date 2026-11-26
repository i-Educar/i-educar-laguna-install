#!/usr/bin/env bash
# Carga de dados Laguna: migrate + cidade média + demos dos módulos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
shift || true

SKIP_POVOAR=0
FORCE_PROD=0
for arg in "$@"; do
  case "$arg" in
    --skip-povoar) SKIP_POVOAR=1 ;;
    --force-production) FORCE_PROD=1 ;;
  esac
done

cd "$ROOT"
echo "=== Carga Laguna em $ROOT ==="

if [[ ! -f artisan ]]; then
  echo "FAIL artisan não encontrado — rode a partir do core i-Educar"
  exit 1
fi

run_art() {
  laguna_php "$ROOT" php artisan "$@"
}

# Preferir comando unificado do pacote ambiente
if laguna_php "$ROOT" php artisan list --raw 2>/dev/null | grep -q '^laguna:setup'; then
  opts=(laguna:setup)
  if [[ "$SKIP_POVOAR" -eq 1 ]]; then
    opts+=(--skip-povoar)
  fi
  if [[ "$FORCE_PROD" -eq 1 ]]; then
    opts+=(--force-production)
  fi
  echo ">> php artisan ${opts[*]}"
  run_art "${opts[@]}"
  exit $?
fi

echo "WARN laguna:setup indisponível — tentando caminho mínimo"
run_art migrate --force || true
run_art db:seed --force || true

# Demos conhecidos (best-effort)
for cmd in \
  exportacao:demo \
  escolar:onda1-demo \
  alimentacao:demo \
  transporte:passagem-empenho-demo \
  act:demo \
  busca-ativa:demo
do
  if laguna_php "$ROOT" php artisan list --raw 2>/dev/null | grep -q "^${cmd%%:*}"; then
    echo ">> php artisan $cmd"
    run_art "$cmd" || echo "WARN $cmd falhou"
  fi
done

echo "Carga mínima concluída."
