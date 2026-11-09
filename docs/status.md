# État d'avancement

Dernière mise à jour : 2026-11-09, branche `feat/phoenix-backend`.

## Fait

- [x] Projet Phoenix dans `server/`, Postgres 17 en local sur le port 5434, versions fixées par mise
- [x] Auth OTP (Prelude, faux fournisseur en dev/test, numéro de démo), sessions glissantes, déconnexion
- [x] Profil et réglages : nom, mode de rayon, heures silencieuses, fuseau, suppression de compte
- [x] Position arrondie (`PUT /me/location`)
- [x] Amitiés : demande, acceptation, demande croisée, refus/annulation, suppression
- [x] Blocages, sourdines
- [x] Matching de contacts par hash
- [x] Tokens push + envoi Expo via Oban + purge des tokens morts (tickets et receipts)
- [x] **Beams** : création et arrêt, durée côté serveur, diffusion géolocalisée avec portée auto par paliers, réponses en chaîne, « vu », rappel T-5 min, fil flouté tant qu'on est inactif
- [x] Anti-spam : 6 beams/h en émission ; en réception, heures silencieuses, sourdine, 1 push par émetteur et par heure, 5 pushes/h
- [x] Rate limiting : OTP, contacts, demandes d'ami, beams
- [x] 55 tests ExUnit au vert

## À faire, dans l'ordre

1. **Communautés** (règle actée dans [product.md](product.md), détails en attente) : tables, invitations, branchement dans `Social.circle_ids/1`.
2. **Temps réel** : socket authentifié par token, Channel utilisateur, événements « ami actif / inactif », Presence.
3. **Contrat mobile** : spec OpenAPI (`open_api_spex`) + client TypeScript généré.
4. **Déploiement** : Dockerfile de release, CI GitHub Actions, choix de l'hébergeur, en-tête d'IP du proxy pour le rate limiting.
5. **App mobile** : en attente des maquettes Figma ; aujourd'hui, `apps/mobile` contient encore le template Expo.
6. Plus tard : amis d'amis (double tap), inconnus (triple tap, PostGIS).

## Questions ouvertes (pour le porteur)

- Communautés :
  - faut-il être ami avec tous les membres pour les ajouter ?
  - les invités doivent-ils accepter ?
  - un membre peut-il en ajouter d'autres, ou quitter ?
  - les membres reçoivent-ils les notifications de beam les uns des autres, ou se voient-ils seulement dans le fil ?
- L'émetteur d'origine doit-il recevoir, en plus de « X a répondu », les beams de ses amis qui répondent ? Aujourd'hui : uniquement « X a répondu ».
- Durée du beam (2 h aujourd'hui), paliers de portée (10/25/50/illimité), seuils anti-spam : à ajuster avec l'usage.

## Points d'attention

- `path/to/venv/` à la racine est un environnement Python créé par erreur (ignoré par git) : à supprimer.
- `apps/mobile` utilise `package-lock.json` (npm) alors que la racine est un workspace pnpm : à harmoniser au moment de reprendre le mobile.
