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

if command -v php >/dev/null && [[ -f artisan ]]; then
  php artisan exportacao:demo || echo "WARN exportacao:demo (provider?)"
  php artisan escolar:onda1-demo || echo "WARN escolar:onda1-demo (provider?)"
fi

echo
echo "Smoke Onda 0–1 concluído."
