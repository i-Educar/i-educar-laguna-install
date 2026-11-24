# i-Educar Laguna — Instalação

Scripts e tutorial para instalar o **core i-Educar 2.12** e os **módulos necessários à PoC Laguna (PE-77/2026)**.

| Documento | Conteúdo |
| --- | --- |
| [`TUTORIAL.md`](./TUTORIAL.md) | Passo a passo completo (Docker) |
| [`scripts/`](./scripts/) | Clone, instalação, checagem de ambiente |
| [`manifest/modules.yml`](./manifest/modules.yml) | Lista canônica de módulos |

## Início rápido

```bash
git clone git@github.com:i-Educar/i-educar-laguna-install.git
cd i-educar-laguna-install
./scripts/install.sh ~/ieducar-laguna
```

O script clona o core (`i-Educar/i-educar` branch `2.12`), baixa os pacotes Buriti/Portabilis, sobe Postgres/Redis e roda a checagem.

## Relacionados

- Manifesto do core: https://github.com/i-Educar/i-educar-laguna-core  
- Core: https://github.com/i-Educar/i-educar  

## Licença

GPL-2.0-or-later
