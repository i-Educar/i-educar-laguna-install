# Tutorial de instalação — i-Educar Laguna (PE-77/2026)

Objetivo: ambiente homologável com core **2.12** + módulos das **Ondas 0–3** + infra Laguna (`laguna:setup` / `laguna:check`) + i-Diário (opcional).

## 1. Pré-requisitos

- Git, Docker Engine + Compose v2  
- PHP **≥ 8.3** no host (para `artisan` / testes fora do container)  
- Extensões PHP: `pdo_pgsql`, `pgsql`, `gd`, `zip`, `xml`, `mbstring`  
- Composer 2.x  
- Acesso à org [i-Educar](https://github.com/i-Educar) (SSH ou HTTPS)

```bash
php -v
docker compose version
composer -V
```

## 2. Instalação automática (recomendado)

```bash
git clone git@github.com:i-Educar/i-educar-laguna-install.git
cd i-educar-laguna-install
chmod +x scripts/*.sh scripts/wire-composer.php
./scripts/install.sh ~/ieducar-laguna
```

Variantes:

```bash
# HTTPS em vez de SSH
./scripts/install.sh ~/ieducar-laguna --https

# Inclui i-Diário
./scripts/install.sh ~/ieducar-laguna --with-diario

# Só clona + composer (sem Docker/carga/testes)
./scripts/install.sh ~/ieducar-laguna --skip-docker --skip-carga --skip-tests
```

O que o `install.sh` faz:

1. Clona `i-Educar/i-educar` (`2.12`)  
2. `clone-modules.sh` — **todos** os pacotes do manifesto (não só Onda 0–1)  
3. `wire-composer.php` — path repositories + `require @dev`  
4. Copia `.env.example` → `.env`  
5. Sobe `postgres` + `redis`  
6. `composer update` / `dump-autoload`  
7. Banco novo (`composer new-install` + seed) ou `migrate`  
8. **Carga:** `php artisan laguna:setup`  
9. **Testes:** `scripts/run-tests.sh`  
10. `check-ambiente.sh`

## 3. Instalação manual (equivalente)

### 3.1 Core

```bash
git clone -b 2.12 git@github.com:i-Educar/i-educar.git ~/ieducar-laguna
cd ~/ieducar-laguna
cp .env.example .env
# Ajuste DB_* e REDIS_* (localhost se usar Compose do próprio projeto)
```

### 3.2 Módulos

```bash
./scripts/clone-modules.sh ~/ieducar-laguna
# opcional:
# ./scripts/clone-modules.sh ~/ieducar-laguna --with-diario
```

Pacotes vão para `packages/buriti/` e `packages/portabilis/`.

### 3.3 Composer

```bash
php ./scripts/wire-composer.php ~/ieducar-laguna
cd ~/ieducar-laguna
composer update --no-interaction
composer dump-autoload -o
php artisan package:discover
```

> Se `composer update` falhar por security-advisories × PHP, use path + symlink + `dump-autoload` (já garantido pelo `wire-composer.php`).

### 3.4 Infra

```bash
docker compose up -d postgres redis
# stack completa (opcional):
# docker compose up -d --build
```

### 3.5 Banco + carga

```bash
# instalação nova:
docker compose exec php composer new-install
docker compose exec php php artisan db:seed --force

# carga Laguna (cidade média + demos dos módulos):
php artisan laguna:setup
# atalho check + setup:
php artisan laguna:ensaiar
```

Ou:

```bash
./scripts/run-carga.sh ~/ieducar-laguna
```

## 4. Validar (testes)

```bash
./scripts/run-tests.sh ~/ieducar-laguna
```

Equivalente manual:

```bash
cd ~/ieducar-laguna

# Todos os tests/run.php dos pacotes Buriti
find packages/buriti -path '*/tests/run.php' -print0 | xargs -0 -n1 php

# Pré-matrícula
php packages/portabilis/pre-matricula-digital/docs/laguna/onda-1/run-tests.php

# Auditoria Laguna
php artisan laguna:check
```

Demos úteis:

```bash
php artisan exportacao:demo
php artisan escolar:onda1-demo
php artisan alimentacao:demo
php artisan transporte:passagem-empenho-demo
php artisan act:demo
```

## 5. O que deve estar testável após instalar

| Módulo | Teste mínimo |
| --- | --- |
| Core | Login SME; escolas/turmas/alunos |
| Infra Laguna | `laguna:check` verde; painel `/configuracoes` / ambiente |
| 4.x Export | Formatos em `storage/app/exportacao-*` |
| 5.3 Escolar | Matrícula → diário → boletim |
| 5.8 Fila | Processos abertos + protocolo |
| 5.4 Transporte | Rota → viagem → gasto → portal família |
| 5.15 ACT | Editais + portal candidato + cargos/vagas |
| 5.13/5.14 Apps | `GET /api/apps/v1/catalogo` · Sanctum |

Logins PoC (após `laguna:setup`): **CPF = senha** (ex.: `42091020001` admin SME).

## 6. Problemas comuns

| Sintoma | Ação |
| --- | --- |
| `Connection refused` :5432 | `docker compose up -d postgres` |
| Redis offline | `docker compose up -d redis` |
| Classe de pacote não encontrada | `php wire-composer.php` + `composer dump-autoload -o` + `package:discover` |
| `laguna:setup` não existe | Confirme clone de `i-educar-laguna-ambiente-package` e `setup-package` |
| Clone SSH falha | `LAGUNA_GIT_PROTOCOL=https ./scripts/install.sh … --https` |
| Permissão em `storage/` | `HOST_UID`/`HOST_GID` no `.env` + rebuild |

## 7. Módulos clonados por padrão

Ver [`manifest/modules.yml`](./manifest/modules.yml): exportação, escolar, transporte, pré-matrícula, censo, alimentação, almoxarifado, servidor, ACT, horário, eventos, atendimento, biblioteca, solicitação, apps-api, busca ativa, RH, **laguna-ambiente**, **setup**, setup-município-base (+ assinatura opcional).

## 8. Pós-PoC

Seguir docs em `packages/buriti/docs/` (ondas 4+) e o manifesto `i-educar-laguna-core`.
