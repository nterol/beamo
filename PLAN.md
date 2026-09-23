# Plan — "Disponibilité entre amis"

> Résumé du plan de développement complet. Source intégrale : `~/.claude/plans/ou-mets-on-les-foamy-canyon.md`.
> Ceci n'est pas une implémentation figée, mais une base de discussion — à challenger avant/pendant le code.

## Contexte

App mobile où un utilisateur se déclare "actif" (dispo pour une sortie), ce qui notifie ses amis. Règle centrale : on ne voit ses amis actifs que si on est soi-même actif (réciprocité). V1 = amis enregistrés uniquement, matchmaking inconnus repoussé en v2 sans refonte de modèle. Porteur solo, profil backend, objectif MVP en quelques semaines, priorité simplicité/infra minimale.

## Décisions actées

| Sujet | Choix |
|---|---|
| Backend | NestJS (adapter `platform-fastify`) |
| Mobile | Expo managed, iOS + Android |
| Source des amis | Sync contacts (numéro hashé) + demande/acceptation in-app |
| Temps réel | Aucun — polling client + push comme vrai signal |
| Auth | Téléphone + OTP SMS (Prelude Verify, fournisseur interchangeable) + session opaque en DB |
| Hébergement | Railway, déploiement Docker |
| Dev local | Docker Compose (API + Postgres) |
| State client | TanStack Query (server state) + Jotai (state léger) |
| BDD | PostgreSQL |
| Statut actif | Catégorie prédéfinie + message libre optionnel |
| Expiration statut | Automatique 3h, non paramétrable, pilotée par workflow Temporal (notif T-5min + expiration) |
| Modération v1 | Blocage d'ami uniquement |
| Repo | Monorepo pnpm workspaces |

## Architecture

4 composants, HTTP synchrone uniquement (pas de temps réel) :
- **Mobile Expo** : consomme l'API REST, auth en secure storage, reçoit les push, polling léger.
- **API NestJS** : seul accès DB, toute la logique sensible (réciprocité, expiration, blocage) y vit.
- **PostgreSQL managé** : source de vérité unique, pas de Redis/broker nécessaire au stade MVP.
- **Tiers** : Expo Push Notification Service (relai APNs/FCM) + Prelude Verify (OTP).

Aucun serveur temps réel à opérer (pas de websocket) — simplifie la maintenance solo.

## Stack et arbitrages clés

- **NestJS + `@nestjs/platform-fastify`** : choix assumé pour la valeur CV malgré le surcoût de boilerplate vs Fastify brut ; garde perf/plomberie Fastify sous la structure Nest (modules/DI/guards/pipes `class-validator`).
- **Prisma** plutôt que Drizzle : migrations zéro-friction, Prisma Studio, pas de souci de cold-start serverless (process persistant).
- **Expo Push Notification Service** : token → backend → API Expo Push (lots de 100) → APNs/FCM. Piège : traiter les *receipts* pour purger les tokens `DeviceNotRegistered`, sinon échecs silencieux. Push non testables sur simulateur iOS / Expo Go limité sur Android récent → dev client EAS sur device physique dès les tests push.
- **Prelude Verify** pour l'OTP plutôt que fait maison ou Twilio : ≈0,06 €/vérif en France (0,032 € + SMS au coût opérateur) contre ≈0,13 $ chez Twilio Verify (0,05 $ + 0,0798 $/SMS FR, tarifs relevés en sept. 2026). À <1 000 inscriptions/an l'écart est négligeable ; choix fait sur la DX, la localisation UE (RGPD) et l'anti-fraude de base incluse. Le fournisseur reste interchangeable (voir « Auth »). À protéger impérativement par rate limiting (risque SMS pumping).
- **Railway** (Docker natif, Postgres managé un clic) — Render écarté (UI jugée peu intuitive), Fly.io/Coolify écartés (sur/sous-dimensionnés).
- **Temporal (Temporal Cloud)** pour le cycle de vie du statut actif, plutôt qu'un `node-cron` : un vrai effet de bord déclenché (notifs pré/à expiration) a besoin d'un timer durable qui survit aux redémarrages. Un worker process dédié reste à opérer en continu (service Railway séparé de l'API) — c'est le vrai coût ajouté. En local : `temporal server start-dev` (CLI seule, pas de conteneurisation nécessaire).
- **Expo Router** (routing fichiers, deep linking pour invitations).
- **TanStack Query** (server state, polling natif) + **Jotai** (state léger non-serveur) — Redux évité.

## Modèle de données (conceptuel)

- **User** : numéro de téléphone vérifié (clé de matching), nom, avatar.
- **Friendship** : relation à deux users, statut `pending`/`accepted` + initiateur (une seule table).
- **Block** : bloqueur → bloqué, retire l'amitié effective en requête (pas de suppression physique), bloque notifs/visibilité.
- **ActiveStatus** : catégorie + message libre optionnel + `expires_at` calculé serveur (`created_at` + 3h fixe, **jamais fourni par le client**).
- **PushToken** : token Expo lié à user + device/plateforme, purgé sur `DeviceNotRegistered`.

**Expiration — deux mécanismes complémentaires** : la vérité d'accès reste `expires_at > now`, calculée à la volée (robuste même si le worker Temporal est down). Temporal ne déclenche que les *effets de bord* (notifs + finalisation), jamais l'autorisation.

**Réciprocité = règle serveur**, pas d'affichage client : l'endpoint "amis actifs" vérifie d'abord que l'appelant a lui-même un statut actif non expiré, sinon refuse la liste.

**Extensibilité v2** : `ActiveStatus` n'a aucune dépendance structurelle à `Friendship` — le filtrage "amis uniquement" vit dans la couche service, pas le schéma.

## Flux clés

1. **Onboarding** : téléphone → OTP (voir « Auth ») → token de session (`expo-secure-store`) → si `isNew`, écran prénom (`PATCH /users/me`) → écran d'explication avant permission contacts → lecture contacts, normalisation E.164, hash client, upload batch → matching serveur → suggestions (jamais d'ajout auto).
2. **Ajout d'ami** : suggestions matching ou recherche in-app, flux demande/acceptation. Invitation non-inscrit via partage natif du lien (pas de SMS backend).
3. **Passage actif** : catégorie+message → upsert `ActiveStatus` (un seul actif à la fois), `expires_at`=+3h → fanout push amis acceptés non-bloqués (sync fire-and-forget) → start workflow `ActiveStatusLifecycle` (workflowId déterministe).
4. **Consultation amis actifs** : polling TanStack Query (~30-60s + refetch foreground) + pull-to-refresh, réciprocité serveur.
5. **Désactivation manuelle** : finalise `ActiveStatus` en base + cancel/signal au workflow correspondant.
6. **Expiration auto** : notif T-5min, puis notif expiration + finalisation à T+3h, piloté par Temporal ; lectures toujours correctes via `expires_at`.
7. **Blocage** : entrée `Block`, retrait silencieux bidirectionnel, exclu des fanouts/listes, sans notifier le bloqué.

## Auth (v1 : OTP SMS uniquement, email en v2)

**Sign up = login** : un seul flow, le numéro E.164 est l'identité. Pas d'endpoint `register`.

```
Mobile                          API                                  Fournisseur OTP
  │── POST /auth/otp/start ─────▶│ rate limit (numéro + IP)            │
  │   { phone }                  │── otp.start(phone) ────────────────▶│ envoie le SMS
  │◀──────── 204 ────────────────│ toujours 204 (pas d'énumération)    │
  │── POST /auth/otp/verify ────▶│── otp.check(phone, code) ──────────▶│
  │   { phone, code }            │◀── approved / rejected ─────────────│
  │                              │ upsert User by phone                │
  │                              │ crée Session                        │
  │◀─ { token, user, isNew } ────│                                     │
  │ isNew → écran prénom → PATCH /users/me { name }
  │── DELETE /auth/session ─────▶│ logout = suppression de la Session
```

- **Fournisseur interchangeable** : un provider Nest `OTP_PROVIDER` exposant uniquement `start(phone)` et `check(phone, code): Promise<boolean>`. Implémentation v1 : Prelude (appels HTTP via `fetch`, pas de SDK). Changer de fournisseur (Twilio Verify, Vonage…) = écrire une nouvelle implémentation de ces 2 méthodes et changer le binding dans `AuthModule`. Aucune table OTP chez nous : génération, expiration et nombre d'essais sont gérés par le fournisseur.
- **Session opaque en DB, pas de JWT** : table `Session { id, userID, tokenHash @unique, createdAt, expiresAt }`. Token = `crypto.randomBytes(32)` renvoyé une seule fois, stocké hashé (SHA-256). Guard Nest : `Authorization: Bearer <token>` → lookup → `req.user`. Expiration longue et glissante (~90 j) pour limiter le nombre d'OTP (= coût). Révocation = delete. Passer en JWT + refresh seulement si la requête DB par appel devient un problème.
- **Modèle `User`** : `phoneVerified` à supprimer (le user n'est créé qu'après vérification). `name` nullable = flag « onboarding à faire » (`isNew`).
- **Numéro de test** : `OTP_TEST_PHONE` + `OTP_TEST_CODE` en env, court-circuitent le fournisseur (compte démo exigé par la review Apple/Google, dev sans coût).
- **Anti-fraude** : pays autorisés limités à la France chez le fournisseur ; cooldown de renvoi côté mobile (30-60 s) ; rate limit serveur (ex. 3 `start` / 10 min par numéro + limite par IP).
- **Reporté v2** : email, changement de numéro, recyclage de numéros par les opérateurs, liste des sessions côté user.


## Sécurité et vie privée

- Numéros E.164 puis hashés SHA-256 avant upload (protection réelle = rate limiting sur le matching, pas le hash seul).
- Rate limiting : OTP (numéro+IP), matching contacts (anti-énumération), activation statut (anti-spam notifs). `@fastify/rate-limit` en mémoire suffit pour une instance unique.
- Permissions contacts/notifs demandées au moment pertinent avec explication préalable (review Apple).
- Jamais d'endpoint public "ce numéro est-il inscrit ?" hors flux de matching batché/authentifié/rate-limité.
- Token de session en `expo-secure-store` (jamais `AsyncStorage` clair), stocké hashé côté serveur.
- Endpoint de suppression complète de compte (RGPD).

## Déploiement

- **Local** : Docker Compose (`postgres` + `api`, code monté + hot-reload `tsx watch`), même `Dockerfile` que la prod.
- **Backend** : GitHub Actions (lint/typecheck/tests) + déploiement continu Railway depuis main. Migrations via `prisma migrate deploy` en release. Secrets en env vars Railway.
- **Mobile** : EAS Build (profils `development`/`preview`/`production`), EAS Submit (App Store + Play Console). Expo Updates (OTA) pour patchs JS ; tout changement natif exige un nouveau build/review complète.

## Roadmap (solo, ~27-37 jours-personne)

1. Setup projet (3-4j) — repo, Expo, backend Nest+Fastify+Prisma, docker-compose, CI.
2. Auth téléphone/OTP (3-5j) — Prelude Verify derrière `OTP_PROVIDER`, session opaque + guard Nest, stockage sécurisé.
3. Modèle de données & API cœur (4-5j) — schéma Prisma complet, modules Nest par domaine (`AuthModule`, `FriendshipModule`, `ActiveStatusModule`), endpoints amis, profil.
4. Intégration contacts (3-4j) — permission, E.164, hash, upload, matching, UI suggestions.
5. Statut actif & push (4-6j, point de friction principal) — credentials APNs/FCM via EAS, tokens, activation+fanout, endpoint amis actifs+réciprocité, expiration.
6. UI mobile complète (4-6j) — onboarding, contacts, liste amis, activation, feed, profil, blocage.
7. Tests & durcissement (3-4j) — rate limiting, cas limites, QA device physique iOS/Android.
8. Déploiement & soumission stores (4-7j + délai review) — prod backend, builds EAS prod, fiches store, soumission.

## Risques à anticiper

- Review Apple : justifier accès contacts/notifs, politique de confidentialité publique obligatoire.
- Google Play : formulaire "Data safety" précis.
- Config APNs/FCM : privilégier credentials managés EAS, format FCM V1 (server key legacy dépréciée).
- Push non testables sur simulateur iOS ; dev client EAS device physique requis tôt.
- Purger les tokens push invalides via les receipts Expo.
- Coût variable principal = OTP SMS (push Expo gratuits) → rate limiting impératif.
- E.164 rigoureux côté client sinon faux négatifs de matching.
- Ne jamais faire confiance à une durée envoyée par le client — 3h = constante serveur.

## Premiers emplacements structurants

- `apps/api/docker-compose` — env dev local (déjà en place dans `infrastructure/`)
- `packages/db/prisma/schema.prisma` — modèle central (`User`, `Friendship`, `Block`, `ActiveStatus`, `PushToken`) — **à réécrire, actuellement un schéma générique sans rapport avec le domaine**
- `apps/api/src/main.ts` — bootstrap Nest sur `platform-fastify` (fait)
- `active-status` module (controller+service) — activation + réciprocité + fanout push + démarrage workflow Temporal (cœur métier, **pas encore implémenté**)
- `push` module — intégration Expo Push API (envoi + receipts, **pas encore implémenté**)
- `mobile/app/_layout.tsx` — racine Expo Router (**app Expo pas encore scaffoldée**)
- `mobile/eas.json` — profils de build

## Où on en est (scaffold actuel vs plan)

- ✅ Monorepo pnpm (`apps/api`, `apps/worker`, `apps/mobile`, `packages/*`)
- ✅ Backend NestJS + `@nestjs/platform-fastify` (migré depuis Hono)
- ✅ Prisma + PostgreSQL, worker Temporal séparé, Docker Compose local
- ❌ Modèle de données : encore `User(email)`/`DeviceToken`/`NotificationPreference` générique — **`Friendship`, `Block`, `ActiveStatus` à créer**
- ❌ Auth téléphone/OTP/session — inexistante, `userId` passé en clair (flow défini, voir « Auth »)
- ❌ Workflow `ActiveStatusLifecycle` — le worker n'a qu'un `onboardingWorkflow` générique (rappel 48h)
- ❌ App mobile Expo — `apps/mobile` est un placeholder vide

## Prochaines étapes

1. Réécrire `packages/db/prisma/schema.prisma` avec le vrai modèle (`User` phone, `Friendship`, `Block`, `ActiveStatus`, `PushToken`).
2. Module User (`GET`/`PATCH /users/me`), puis Auth OTP Prelude + table `Session` + guard Nest.
3. Module `ActiveStatusModule` + workflow Temporal `ActiveStatusLifecycle`.
4. Scaffolder `apps/mobile` en Expo (Router, TanStack Query, Jotai) une fois l'auth + modèle de base en place.
