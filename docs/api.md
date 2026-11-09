# API

Base : `/api`. JSON partout. Authentification : `Authorization: Bearer <token>`, sauf pour `/auth/otp/*`.

Erreurs : `{"error": "<code>"}`, avec `details` (erreurs par champ) pour `invalid` sur un changeset.

| Code | HTTP |
|---|---|
| `unauthorized` | 401 |
| `invalid_code` | 401 |
| `not_found` | 404 (aussi renvoyé quand un blocage est en jeu) |
| `invalid`, `cannot_target_self`, `too_many_items` | 422 |
| `too_many_requests` | 429, avec l'en-tête `retry-after` en secondes |
| `provider_error` | 502 |

## Auth

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| POST | `/auth/otp/start` | `{phone}` (E.164) | 204, toujours, même pour un numéro inconnu |
| POST | `/auth/otp/verify` | `{phone, code}` | `{token, user, is_new}` |
| DELETE | `/auth/session` | — | 204 |

Limites : `start` 3 / 10 min par numéro et 10 / 10 min par IP ; `verify` 10 / 10 min par numéro et 30 / 10 min par IP.

## Moi

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| GET | `/me` | — | `user` |
| PATCH | `/me` | `name`, `radius_km` (1–500 ou `null`), `quiet_start`, `quiet_end` (`"HH:MM:SS"`, l'un ne va pas sans l'autre), `timezone` (IANA) | `user` |
| PUT | `/me/location` | `{lat, lng}` (nombres) | 204 |
| DELETE | `/me` | — | 204, compte et données supprimés |

`user` = `{id, phone, name, radius_km, quiet_start, quiet_end, timezone, located_at}`.

## Amis

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| GET | `/friends` | — | `{friends: [{id, name}]}` |
| DELETE | `/friends/:user_id` | — | 204 |
| GET | `/friend-requests` | — | `{incoming: [{id, user}], outgoing: [{id, user}]}` |
| POST | `/friend-requests` | `{user_id}` | 201 `{id, status}` ; une demande croisée passe directement en `accepted` |
| POST | `/friend-requests/:id/accept` | — | `{id, status}` (destinataire seulement) |
| DELETE | `/friend-requests/:id` | — | 204 (refuser ou annuler) |

Limite : 50 demandes par heure et par utilisateur.

## Contacts

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| POST | `/contacts/match` | `{hashes: [sha256_hex(E.164)]}` (2000 max) | `{matches: [{id, name, relation}]}` |

`relation` vaut `friend`, `outgoing`, `incoming` ou `none`. Les utilisateurs bloqués, dans un sens ou dans l'autre, sont exclus. Limite : 10 appels par heure.

## Blocages

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| GET | `/blocks` | — | `{blocked: [{id, name}]}` |
| POST | `/blocks` | `{user_id}` | 204 |
| DELETE | `/blocks/:user_id` | — | 204 |

## Push

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| POST | `/push-tokens` | `{token: "ExponentPushToken[…]", platform: "ios"\|"android"}` | 204 |
| DELETE | `/push-tokens/:token` | — | 204 (uniquement ses propres tokens) |
