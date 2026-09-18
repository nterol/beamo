# beamo monorepo

Monorepo pnpm pour app mobile React Native + backend NestJS (adapter Fastify)/Temporal/Prisma.

## Dossiers

- `apps/api`: API HTTP NestJS (`@nestjs/platform-fastify`)
- `apps/worker`: worker Temporal (workflows + activities)
- `apps/mobile`: app React Native
- `packages/db`: Prisma schema + client
- `packages/contracts`: schémas/types partagés
- `packages/notifications`: provider push notifications
- `infrastructure`: Docker Compose local (Postgres + Temporal)

## Démarrage rapide

1. Copier `infrastructure/env/.env.example` vers `.env` à la racine.
2. Lancer l'infra locale: `pnpm dev:infra`
3. Installer les dépendances: `pnpm install`
4. Générer Prisma: `pnpm db:generate`
5. Lancer API + worker: `pnpm dev`
