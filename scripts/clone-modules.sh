#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

TARGET="${1:-}"
shift || true

if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "Uso: $0 /caminho/para/i-educar [--with-diario] [--skip-optional]"
  echo "Env: LAGUNA_GIT_PROTOCOL=ssh|https (padrão: ssh)"
  exit 1
fi

WITH_DIARIO=0
SKIP_OPTIONAL=0
for arg in "$@"; do
  case "$arg" in
    --with-diario|--all) WITH_DIARIO=1 ;;
    --skip-optional) SKIP_OPTIONAL=1 ;;
  esac
done

fail=0

clone_pair() {
  local slug="$1" path="$2" fallback="${3:-}"
  if ! laguna_clone_one "$slug" "$TARGET/$path" "" "$fallback"; then
    fail=$((fail + 1))
  fi
}

echo "=== Módulos Laguna (todas as ondas + infra) ==="
echo "Destino: $TARGET · protocolo: ${LAGUNA_GIT_PROTOCOL:-ssh}"

# Onda 0–1
clone_pair i-Educar/i-educar-exportacao-unificada-package packages/buriti/i-educar-exportacao-unificada-package
clone_pair i-Educar/i-educar-escolar-aderencia-package packages/buriti/i-educar-escolar-aderencia-package
clone_pair i-Educar/i-educar-transporte-escolar-v2-package packages/buriti/i-educar-transporte-escolar-v2
clone_pair i-Educar/pre-matricula-digital packages/portabilis/pre-matricula-digital portabilis/pre-matricula-digital
clone_pair i-Educar/i-educar-educacenso-import-package packages/buriti/i-educar-educacenso-import-package JaderGabriel/i-educar-educacenso-import-package

# Onda 2
clone_pair i-Educar/i-educar-alimentacao-escolar-package packages/buriti/i-educar-alimentacao-escolar-package
clone_pair i-Educar/i-educar-almoxarifado-escolar-package packages/buriti/i-educar-almoxarifado-escolar-package
clone_pair i-Educar/i-educar-servidor-educacional-package packages/buriti/i-educar-servidor-educacional-package
clone_pair i-Educar/i-educar-contratacoes-temporarias-package packages/buriti/i-educar-contratacoes-temporarias-package
clone_pair i-Educar/i-educar-horario-automatico-package packages/buriti/i-educar-horario-automatico-package
clone_pair i-Educar/i-educar-eventos-formacao-package packages/buriti/i-educar-eventos-formacao-package
clone_pair i-Educar/i-educar-atendimento-estudante-package packages/buriti/i-educar-atendimento-estudante-package
clone_pair i-Educar/i-educar-biblioteca-package packages/buriti/i-educar-biblioteca-package
clone_pair i-Educar/i-educar-solicitacao-servicos-package packages/buriti/i-educar-solicitacao-servicos-package
clone_pair i-Educar/i-educar-busca-ativa-package packages/buriti/i-educar-busca-ativa-package
clone_pair i-Educar/i-educar-rh-educacional-package packages/buriti/i-educar-rh-educacional-package

# Onda 3
clone_pair i-Educar/i-educar-apps-api-package packages/buriti/i-educar-apps-api-package

# Infra Laguna (obrigatório para laguna:setup / check / ensaiar)
clone_pair i-Educar/i-educar-laguna-ambiente-package packages/buriti/i-educar-laguna-ambiente-package
clone_pair i-Educar/i-educar-setup-package packages/buriti/i-educar-setup-package
clone_pair i-Educar/i-educar-setup-municipio-base-package packages/buriti/i-educar-setup-municipio-base-package

if [[ "$SKIP_OPTIONAL" -eq 0 ]]; then
  echo "=== Opcionais ==="
  clone_pair i-Educar/i-educar-assinatura-digital-package packages/buriti/i-educar-assinatura-digital-package || true
fi

if [[ "$WITH_DIARIO" -eq 1 ]]; then
  echo "=== i-Diário ==="
  laguna_clone_one i-Educar/i-diario "$TARGET/packages/portabilis/i-diario" "1.6" || fail=$((fail + 1))
fi

echo
if [[ "$fail" -gt 0 ]]; then
  echo "Clone concluído com $fail falha(s)."
  exit 1
fi
echo "Clone de módulos concluído."
