#!/usr/bin/env bash
# Compat: redireciona para o runner completo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run-tests.sh" "${1:-.}"
