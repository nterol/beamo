# État d'avancement

Dernière mise à jour : 2026-11-13, sur `main`.

## Serveur : terminé pour la v1

- [x] Projet Phoenix dans `server/`, Postgres 17 en local sur le port 5434, versions fixées par mise
- [x] Auth OTP (Prelude, faux fournisseur en dev/test, numéro de démo), sessions glissantes, déconnexion, purge quotidienne des sessions expirées
- [x] Profil et réglages : nom, mode de rayon, heures silencieuses, fuseau, suppression de compte
- [x] Position arrondie
- [x] Amitiés, blocages, sourdines, matching de contacts
- [x] Push Expo via Oban, purge des tokens morts
- [x] Beams : diffusion géolocalisée avec portée auto, réponses en chaîne, « vu », rappel T-5 min, expiration, fil flouté
- [x] Anti-spam émission et réception, heures silencieuses
- [x] Communautés : invitations, invités anonymes, fil de communauté flouté
- [x] Temps réel : socket authentifié, signaux `feed_changed` / `friends_changed` / `invitations_changed` / `community_changed`
- [x] Contrat OpenAPI (`/api/openapi`) validé par les tests + client TypeScript généré (`packages/api-client`)
- [x] Release Docker testée localement, CI GitHub Actions, IP client derrière proxy
- [x] 71 tests ExUnit au vert

## À faire

1. **Choisir l'hébergeur et déployer** (voir [deploy.md](deploy.md)). Il faudra côté porteur : compte d'hébergement, clé Prelude, nom de domaine.
2. **Vérifier le premier passage de la CI** sur GitHub (workflow `server`, déclenché par la fusion dans `main`).
3. **App mobile** : en attente des maquettes Figma. Inventaire des écrans, parcours et questions de design dans [screens.md](screens.md). `apps/mobile` contient encore le template Expo. À prévoir :
   - consommer `@beamo/api-client` ;
   - écouter le canal `user:<id>` ;
   - envoyer la position à l'ouverture et avec chaque beam ;
   - enregistrer le token push ;
   - hasher les contacts en E.164 puis SHA-256.
4. Plus tard : amis d'amis (double tap), inconnus (triple tap, PostGIS), Hammer sur Redis si plusieurs nœuds.

## Questions ouvertes (pour le porteur)

- Durée du beam (2 h aujourd'hui), paliers de portée (10/25/50/illimité), seuils anti-spam : à ajuster avec l'usage.
- Communautés : tout membre peut renommer ; faut-il un administrateur ?

## Points d'attention

- `path/to/venv/` à la racine est un environnement Python créé par erreur (ignoré par git) : à supprimer.
- `apps/mobile` utilise `package-lock.json` (npm) alors que la racine est un workspace pnpm : à harmoniser au moment de reprendre le mobile.
- La CI n'a pas encore tourné sur GitHub : la première exécution validera notamment la disponibilité d'OTP 29.1.2 / Elixir 1.20.5 dans `erlef/setup-beam`.
