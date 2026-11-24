#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
ALL="${2:-}"

if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "Uso: $0 /caminho/para/i-educar [--all]"
  exit 1
fi

clone_one() {
  local git_url="$1"
  local dest="$2"
  if [[ -d "$dest/.git" ]]; then
    echo "OK  já existe: $dest"
    git -C "$dest" fetch --quiet || true
    return
  fi
  mkdir -p "$(dirname "$dest")"
  echo ">> clonando $git_url → $dest"
  git clone --depth 1 "$git_url" "$dest"
}

echo "=== Módulos Onda 0–1 ==="
clone_one git@github.com:i-Educar/i-educar-exportacao-unificada-package.git \
  "$TARGET/packages/buriti/i-educar-exportacao-unificada-package"
clone_one git@github.com:i-Educar/i-educar-escolar-aderencia-package.git \
  "$TARGET/packages/buriti/i-educar-escolar-aderencia-package"
clone_one git@github.com:i-Educar/i-educar-transporte-escolar-v2-package.git \
  "$TARGET/packages/buriti/i-educar-transporte-escolar-v2"
clone_one git@github.com:portabilis/pre-matricula-digital.git \
  "$TARGET/packages/portabilis/pre-matricula-digital"
clone_one git@github.com:JaderGabriel/i-educar-educacenso-import-package.git \
  "$TARGET/packages/buriti/i-educar-educacenso-import-package"

if [[ "$ALL" == "--all" ]]; then
  echo "=== Módulos Onda 2+ (esqueletos) ==="
  for pair in \
    "i-Educar/i-educar-servidor-educacional-package.git|packages/buriti/i-educar-servidor-educacional-package" \
    "i-Educar/i-educar-alimentacao-escolar-package.git|packages/buriti/i-educar-alimentacao-escolar-package" \
    "i-Educar/i-educar-contratacoes-temporarias-package.git|packages/buriti/i-educar-contratacoes-temporarias-package" \
    "i-Educar/i-educar-horario-automatico-package.git|packages/buriti/i-educar-horario-automatico-package" \
    "i-Educar/i-educar-eventos-formacao-package.git|packages/buriti/i-educar-eventos-formacao-package" \
    "i-Educar/i-educar-almoxarifado-escolar-package.git|packages/buriti/i-educar-almoxarifado-escolar-package" \
    "i-Educar/i-educar-atendimento-estudante-package.git|packages/buriti/i-educar-atendimento-estudante-package" \
    "i-Educar/i-educar-biblioteca-package.git|packages/buriti/i-educar-biblioteca-package" \
    "i-Educar/i-educar-solicitacao-servicos-package.git|packages/buriti/i-educar-solicitacao-servicos-package" \
    "i-Educar/i-educar-apps-api-package.git|packages/buriti/i-educar-apps-api-package"
  do
    git_path="${pair%%|*}"
    rel="${pair##*|}"
    clone_one "git@github.com:${git_path}" "$TARGET/$rel"
  done
fi

echo "Clone de módulos concluído."
