#!/usr/bin/env bash
# Funções compartilhadas pelos scripts Laguna install.

laguna_git_url() {
  local slug="$1" # org/repo
  local proto="${LAGUNA_GIT_PROTOCOL:-ssh}"
  if [[ "$proto" == "https" ]]; then
    echo "https://github.com/${slug}.git"
  else
    echo "git@github.com:${slug}.git"
  fi
}

laguna_clone_one() {
  local slug="$1"
  local dest="$2"
  local branch="${3:-}"
  local fallback="${4:-}"

  if [[ -d "$dest/.git" ]]; then
    echo "OK  já existe: $dest"
    git -C "$dest" fetch --quiet 2>/dev/null || true
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  local url
  url="$(laguna_git_url "$slug")"
  echo ">> clonando $url → $dest"
  if [[ -n "$branch" ]]; then
    if git clone --depth 1 -b "$branch" "$url" "$dest" 2>/dev/null; then
      return 0
    fi
  else
    if git clone --depth 1 "$url" "$dest" 2>/dev/null; then
      return 0
    fi
  fi

  if [[ -n "$fallback" ]]; then
    echo "WARN falhou $slug — tentando fallback $fallback"
    url="$(laguna_git_url "$fallback")"
    if [[ -n "$branch" ]]; then
      git clone --depth 1 -b "$branch" "$url" "$dest"
    else
      git clone --depth 1 "$url" "$dest"
    fi
    return $?
  fi

  echo "FAIL não foi possível clonar $slug"
  return 1
}

laguna_in_docker() {
  local root="$1"
  if [[ -f "$root/docker-compose.yml" ]] && docker compose -f "$root/docker-compose.yml" ps --status running 2>/dev/null | grep -qiE 'php|app'; then
    return 0
  fi
  return 1
}

laguna_php() {
  local root="$1"
  shift
  if laguna_in_docker "$root"; then
    (cd "$root" && docker compose exec -T php "$@")
  else
    (cd "$root" && "$@")
  fi
}
