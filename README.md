# i-Educar Laguna — Instalação

Scripts e tutorial para instalar o **core i-Educar 2.12**, clonar **todos os módulos Laguna (PE-77/2026)**, acoplar o Composer, rodar **carga de dados** e **smoke tests**.

| Documento / pasta | Conteúdo |
| --- | --- |
| [`TUTORIAL.md`](./TUTORIAL.md) | Passo a passo completo |
| [`scripts/install.sh`](./scripts/install.sh) | Pipeline ponta a ponta |
| [`scripts/clone-modules.sh`](./scripts/clone-modules.sh) | Clone de pacotes Buriti/Portabilis |
| [`scripts/wire-composer.php`](./scripts/wire-composer.php) | Path repos + `require @dev` |
| [`scripts/run-carga.sh`](./scripts/run-carga.sh) | `laguna:setup` / demos |
| [`scripts/run-tests.sh`](./scripts/run-tests.sh) | Smoke `tests/run.php` de cada módulo |
| [`manifest/modules.yml`](./manifest/modules.yml) | Lista canônica de módulos |

## Início rápido

```bash
git clone git@github.com:i-Educar/i-educar-laguna-install.git
cd i-educar-laguna-install
chmod +x scripts/*.sh
./scripts/install.sh ~/ieducar-laguna
```

Sem SSH no GitHub:

```bash
LAGUNA_GIT_PROTOCOL=https ./scripts/install.sh ~/ieducar-laguna --https
```

O `install.sh` faz, nesta ordem:

1. Clona o core (`i-Educar/i-educar` branch `2.12`)
2. Clona **todos** os módulos (ondas 0–3 + infra: ambiente, setup, busca-ativa, RH…)
3. Ajusta `composer.json` (path + require)
4. Sobe Postgres/Redis (Docker Compose do core)
5. `composer update` / `dump-autoload`
6. Instalação de banco (`new-install`/`migrate` + seed) se necessário
7. **Carga** via `php artisan laguna:setup`
8. **Testes** smoke de cada pacote (`tests/run.php`)

Pule etapas com `--skip-carga`, `--skip-tests` ou `--skip-docker`.

## Relacionados

- Manifesto do core: https://github.com/i-Educar/i-educar-laguna-core  
- Core: https://github.com/i-Educar/i-educar  
- Lista de repos: org [i-Educar](https://github.com/i-Educar)

## Licença

GPL-2.0-or-later
