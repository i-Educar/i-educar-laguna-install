# Tutorial de instalação — i-Educar Laguna (PE-77/2026)

Objetivo: ambiente homologável com core **2.12** + módulos das **Ondas 0 e 1** (e esqueletos da Onda 2).

## 1. Pré-requisitos

- Git, Docker Engine + Compose v2  
- PHP **≥ 8.3** no host (para `artisan` / testes fora do container)  
- Extensões PHP: `pdo_pgsql`, `pgsql`, `gd`, `zip`, `xml`, `mbstring`, `redis` (ou predis)  
- Composer 2.x  
- SSH configurado no GitHub (org [i-Educar](https://github.com/i-Educar))

```bash
php -v
docker compose version
composer -V
```

## 2. Instalação automática

```bash
git clone git@github.com:i-Educar/i-educar-laguna-install.git
cd i-educar-laguna-install
chmod +x scripts/*.sh
./scripts/install.sh ~/ieducar-laguna
```

O que o `install.sh` faz:

1. Clona `i-Educar/i-educar` (`2.12`) no destino  
2. Executa `clone-modules.sh` (Buriti + pré-matrícula)  
3. Copia `.env.example` → `.env` se necessário  
4. Sobe `postgres` + `redis`  
5. Roda `check-ambiente.sh`  

## 3. Instalação manual (equivalente)

### 3.1 Core

```bash
git clone -b 2.12 git@github.com:i-Educar/i-educar.git ~/ieducar-laguna
cd ~/ieducar-laguna
cp .env.example .env
# Ajuste DB_* e REDIS_* para localhost se for Docker Compose do próprio projeto
```

### 3.2 Módulos

```bash
# a partir deste repositório de install:
./scripts/clone-modules.sh ~/ieducar-laguna
```

Pacotes vão para `packages/buriti/` e `packages/portabilis/pre-matricula-digital`.

Registre path repositories + require no `composer.json` / `packages/plug-and-play.json` conforme o manifesto Laguna (`i-educar-laguna-core`).

```bash
cd ~/ieducar-laguna
composer dump-autoload -o
# ou, quando o lock permitir:
# composer plug-and-play
```

### 3.3 Infra

```bash
docker compose up -d postgres redis
# opcional stack completa:
# docker compose up -d --build
```

### 3.4 Banco

Em instalação **nova**:

```bash
docker compose exec php composer new-install
docker compose exec php php artisan db:seed
```

Em instalação **já populada** (homolog): apenas confira contagens:

```bash
./scripts/check-ambiente.sh ~/ieducar-laguna
```

## 4. Validar Onda 0 e Onda 1

```bash
cd ~/ieducar-laguna

# Onda 0 — exportação
php packages/buriti/i-educar-exportacao-unificada-package/tests/run.php
php artisan exportacao:demo

# Onda 1 — escolar / transporte / censo / fila
php packages/buriti/i-educar-escolar-aderencia-package/tests/run.php
php artisan escolar:onda1-demo
php packages/buriti/i-educar-transporte-escolar-v2/tests/run.php
php packages/buriti/i-educar-educacenso-import-package/tests/run.php
php packages/portabilis/pre-matricula-digital/docs/laguna/onda-1/run-tests.php
```

Roteiro UI da 1ª rodada: no monorepo, `packages/buriti/docs/onda-1/ROTEIRO-TESTES-R1.md`.

## 5. O que deve estar testável após instalar

| Módulo | Teste mínimo |
| --- | --- |
| Core | Login SME; listar escolas/turmas/alunos |
| 4.x Export | 10 formatos em `storage/app/exportacao-onda0/` |
| 5.3 Escolar | Matrícula → diário → boletim; demo uniforme/gabarito/marca d’água |
| 5.8 Fila | Processos abertos + consulta de protocolo |
| 5.4 Transporte | Rota → viagem → gasto → carteirinha |
| 5.10 Censo | Formatos 2025/2026 no import |

## 6. Problemas comuns

| Sintoma | Ação |
| --- | --- |
| `Connection refused` :5432 | `docker compose up -d postgres` |
| Redis offline | `docker compose up -d redis` |
| Classe de pacote não encontrada | `composer dump-autoload -o` + provider em `config/app.php` / `bootstrap/cache/packages.php` |
| `composer plug-and-play` falha (security-advisories × PHP) | Use path + symlink + dump-autoload (como Onda 0) |
| Permissão em `storage/` | Ajuste `HOST_UID`/`HOST_GID` no `.env` e rebuild |

## 7. Próximos passos (Onda 2)

Após a 1ª rodada de testes, seguir `ORDEM-DESENVOLVIMENTO-LAGUNA.md` no monorepo: alimentação, RH/ACT, horário, eventos, etc.
