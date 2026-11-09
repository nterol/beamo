# Déploiement

Le serveur est une release Elixir dans une image Docker (`server/Dockerfile`), déployable sur n'importe quel hébergeur de conteneurs. L'hébergeur n'est pas encore choisi : Fly.io est le mieux intégré à Elixir, Railway convient aussi pour un seul nœud.

## Ce qu'il faut

- Une base PostgreSQL 17.
- Un conteneur construit depuis `server/` (port interne 4000).
- Les variables d'environnement ci-dessous.

| Variable | Obligatoire | Rôle |
|---|---|---|
| `DATABASE_URL` | oui | `ecto://user:pass@host:5432/db` |
| `SECRET_KEY_BASE` | oui | `mix phx.gen.secret` |
| `PHX_HOST` | oui | Domaine public, ex. `api.beamo.app` |
| `PRELUDE_API_KEY` | oui | Clé Prelude Verify |
| `CLIENT_IP_HEADER` | fortement conseillé | En-tête portant l'IP client : `fly-client-ip` sur Fly, `x-forwarded-for` sur Railway. Sans lui, les limites par IP visent le proxy |
| `EXPO_ACCESS_TOKEN` | non | Si la sécurité d'envoi push est activée côté Expo |
| `OTP_TEST_PHONE` / `OTP_TEST_CODE` | non | Compte de démo pour la review Apple/Google |
| `POOL_SIZE` | non | 10 par défaut |
| `PORT` | non | 4000 par défaut |

`PHX_SERVER=true` est déjà fixé dans l'image.

## Commandes de la release

- Migrations : `/app/bin/migrate`, à lancer à chaque déploiement, avant le démarrage (« release command » sur Fly, « pre-deploy command » sur Railway).
- Démarrage : `/app/bin/server` (commande par défaut de l'image).
- Console distante : `/app/bin/beamo remote`.

## Fly.io (esquisse)

```sh
cd server
fly launch --no-deploy                 # détecte le Dockerfile, crée fly.toml
fly mpg create                         # Postgres managé, puis attacher DATABASE_URL
fly secrets set SECRET_KEY_BASE=... PRELUDE_API_KEY=... PHX_HOST=... CLIENT_IP_HEADER=fly-client-ip
# fly.toml : [deploy] release_command = "/app/bin/migrate"
fly deploy
```

## Railway (esquisse)

1. Nouveau service depuis le dépôt GitHub, racine `server/` (Dockerfile détecté).
2. Ajouter un Postgres et référencer son URL dans `DATABASE_URL`.
3. Variables ci-dessus, avec `CLIENT_IP_HEADER=x-forwarded-for`.
4. Pre-deploy command : `/app/bin/migrate`.

## Vérification

- `GET /api/health` doit répondre `{"status":"ok"}`.
- `GET /api/openapi` sert la spec.
- Testé en local : image construite, migrations jouées contre Postgres 17, `/api/health` répond 200 et `/api/me` 401 sans token.

## Points d'attention

- Le rate limiting (Hammer, ETS) est en mémoire : avec **plusieurs nœuds**, chaque nœud a ses propres compteurs. Passer au backend Redis de Hammer ou rester sur un seul nœud.
- Les WebSockets passent par le même port ; les proxys de Fly et Railway les gèrent nativement.
- Prelude : limiter les pays autorisés à la France dans le dashboard (anti-SMS pumping).
- Expo : configurer les credentials APNs/FCM via EAS (côté mobile).
