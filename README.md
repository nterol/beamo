# Beamo

App mobile où l'on se déclare dispo (un *beam*) pour prévenir ses amis autour de soi.

## Dossiers

- `server/` : API JSON et temps réel en Elixir/Phoenix, tâches différées avec Oban
- `apps/mobile/` : app Expo (iOS + Android)
- `infrastructure/` : Postgres local (Docker Compose) et variables d'environnement

## Démarrage

```sh
brew install mise && mise install      # Erlang + Elixir, versions dans mise.toml
pnpm dev:infra                         # Postgres sur localhost:5434
cd server && mise exec -- mix setup    # dépendances + base + migrations
pnpm dev:server                        # http://localhost:4000/api
pnpm test:server
```

En dev, l'OTP est simulé : n'importe quel numéro E.164 accepte le code `000000`.

Voir [docs/](docs/README.md) pour le produit, l'architecture, l'API et l'état d'avancement.
