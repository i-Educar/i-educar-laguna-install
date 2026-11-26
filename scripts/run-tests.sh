#!/usr/bin/env bash
# Smoke tests de todos os módulos Laguna presentes.
set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
cd "$ROOT"

ok=0
fail=0
skip=0

run_one() {
  local label="$1"
  shift
  if [[ ! -f "$1" && "$1" == *.php ]]; then
    echo "SKIP $label (arquivo ausente)"
    skip=$((skip + 1))
    return
  fi
  echo
  echo "===== $label ====="
  if "$@"; then
    ok=$((ok + 1))
  else
    echo "FAIL $label"
    fail=$((fail + 1))
  fi
}

echo "=== Smoke tests Laguna em $ROOT ==="

# Pacotes com tests/run.php
while IFS= read -r -d '' f; do
  rel="${f#"$ROOT"/}"
  run_one "$rel" php "$f"
done < <(find packages/buriti -path '*/tests/run.php' -print0 2>/dev/null | sort -z)

# Pré-matrícula (runner Laguna Onda 1)
PM_TEST="packages/portabilis/pre-matricula-digital/docs/laguna/onda-1/run-tests.php"
if [[ -f "$PM_TEST" ]]; then
  run_one "pre-matricula onda-1" php "$PM_TEST"
else
  echo "SKIP $PM_TEST"
  skip=$((skip + 1))
fi

# Artisan demos / check (avisos — não derrubam o smoke dos pacotes)
if [[ -f artisan ]]; then
  for cmd in exportacao:demo escolar:onda1-demo; do
    if php artisan list --raw 2>/dev/null | grep -q "^${cmd%%:*}"; then
      echo
      echo "===== artisan $cmd ====="
      php artisan "$cmd" && ok=$((ok + 1)) || { echo "WARN $cmd"; skip=$((skip + 1)); }
    fi
  done

  if php artisan list --raw 2>/dev/null | grep -q '^laguna:check'; then
    echo
    echo "===== artisan laguna:check ====="
    if php artisan laguna:check; then
      ok=$((ok + 1))
    else
      echo "WARN laguna:check incompleto — rode: php artisan laguna:setup"
      skip=$((skip + 1))
    fi
  fi
fi

echo
echo "Resumo testes: $ok ok · $fail falha(s) · $skip skip/warn"
[[ "$fail" -eq 0 ]] || exit 1
