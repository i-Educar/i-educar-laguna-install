#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

run() {
  echo
  echo "===== $* ====="
  "$@"
}

run php packages/buriti/i-educar-exportacao-unificada-package/tests/run.php
run php packages/buriti/i-educar-escolar-aderencia-package/tests/run.php
run php packages/buriti/i-educar-transporte-escolar-v2/tests/run.php
run php packages/buriti/i-educar-educacenso-import-package/tests/run.php
run php packages/portabilis/pre-matricula-digital/docs/laguna/onda-1/run-tests.php

for p in alimentacao-escolar almoxarifado-escolar servidor-educacional \
  contratacoes-temporarias horario-automatico eventos-formacao \
  atendimento-estudante biblioteca solicitacao-servicos; do
  run php "packages/buriti/i-educar-${p}-package/tests/run.php"
done
run php packages/buriti/i-educar-apps-api-package/tests/run.php

if command -v php >/dev/null && [[ -f artisan ]]; then
  php artisan exportacao:demo || echo "WARN exportacao:demo (provider?)"
  php artisan escolar:onda1-demo || echo "WARN escolar:onda1-demo (provider?)"
fi

echo
echo "Smoke Onda 0–2 concluído."
