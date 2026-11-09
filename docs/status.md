# État d'avancement

Dernière mise à jour : 2026-11-09, branche `feat/phoenix-backend`.

## Fait

- [x] Projet Phoenix dans `server/`, Postgres 17 en local sur le port 5434, versions fixées par mise
- [x] Auth OTP (Prelude, faux fournisseur en dev/test, numéro de démo), sessions glissantes, déconnexion
- [x] Profil et réglages : nom, rayon, heures silencieuses, fuseau, suppression de compte
- [x] Position arrondie (`PUT /me/location`)
- [x] Amitiés : demande, acceptation, demande croisée, refus/annulation, suppression
- [x] Blocages
- [x] Matching de contacts par hash
- [x] Tokens push + envoi Expo via Oban + purge des tokens morts (tickets et receipts)
- [x] Rate limiting : OTP, contacts, demandes d'ami
- [x] 32 tests ExUnit au vert
- [x] Ancien back-end TypeScript (Hono, worker Temporal, packages partagés) supprimé

## À faire, dans l'ordre

1. **Beams**
   - Table `beams` : `user_id`, `category`, `note`, `expires_at`, `parent_beam_id` pour les réponses, `audience`, `radius_km` effectif.
   - Table des destinataires et des « vus ».
   - Création, désactivation, jobs Oban de rappel (T-5 min) et d'expiration.
   - Fan-out géolocalisé (rayons croisés, positions de moins de 7 jours, élargissement par paliers).
   - Réciprocité : la liste des amis actifs n'est accessible qu'à un utilisateur actif ; sinon, un compteur seulement.
   - Réponse et cascade.
2. **Anti-spam** : délai entre deux beams, plafond de notifications par destinataire, couper un ami, heures silencieuses appliquées au fan-out.
3. **Temps réel** : socket authentifié par token, Channel utilisateur, Presence.
4. **Contrat mobile** : spec OpenAPI (`open_api_spex`) + client TypeScript généré.
5. **Communautés** : en attente de cadrage.
6. **App mobile** : en attente des maquettes Figma ; aujourd'hui, `apps/mobile` contient encore le template Expo.
7. **Déploiement** : Dockerfile de release, CI GitHub Actions, choix de l'hébergeur, en-tête d'IP du proxy pour le rate limiting.

## Questions ouvertes (pour le porteur)

- Cascade : que voit un ami du répondant qui ne connaît pas l'émetteur d'origine ? Quelle profondeur maximale ? L'émetteur peut-il l'interdire ?
- Communautés : groupe créé par un utilisateur pour réunir des amis, ou espace éphémère né d'une cascade ?
- Amis proches : liste distincte, ou simple communauté ?
- Paliers d'élargissement du rayon, durée exacte du beam (2 h ou 3 h), seuils anti-spam.

## Points d'attention

- `path/to/venv/` à la racine est un environnement Python créé par erreur (ignoré par git) : à supprimer.
- `apps/mobile` utilise `package-lock.json` (npm) alors que la racine est un workspace pnpm : à harmoniser au moment de reprendre le mobile.
