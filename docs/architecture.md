# Architecture

## Vue d'ensemble

```
Expo (iOS/Android) ──HTTP JSON──▶ Phoenix (server/) ──▶ PostgreSQL
        ▲            ──WebSocket (à venir)──▶   │
        │                                       ├──▶ Prelude Verify (OTP SMS)
        └────────── APNs / FCM ◀── Expo Push ◀──┘ (via jobs Oban)
```

Un seul service applicatif. Oban tourne dans le même processus que l'API et stocke ses jobs dans Postgres.

## Outillage

- Erlang 29.1.2 / Elixir 1.20.5, fixés par `mise.toml` (`mise exec -- mix …`).
- Postgres 17 via `infrastructure/docker-compose.yml`, sur **localhost:5434** (le 5432 est pris par un autre projet local).
- Phoenix 1.8 généré en `--no-html --binary-id` : API seule, UUID partout.
- Dépendances ajoutées : `oban`, `req` (HTTP), `hammer` (rate limiting ETS), `tz` (fuseaux horaires).

## Organisation du code (`server/lib`)

| Module | Rôle |
|---|---|
| `Beamo.Accounts` | Login OTP, sessions, réglages, position, suppression de compte |
| `Beamo.Accounts.OTP` | Behaviour `start/1`, `check/2` + court-circuit du numéro de démo |
| `Beamo.Accounts.OTP.Prelude` / `.Fake` | Fournisseur réel (prod) / code `000000` (dev, test) |
| `Beamo.Social` | Amitiés, blocages, sourdines, matching de contacts ; `circle_ids/1` = qui je vois |
| `Beamo.Beams` | Cycle de vie des beams, diffusion, anti-spam, fil, « vu » |
| `Beamo.Beams.FanoutWorker` / `ReminderWorker` | Jobs Oban : diffusion juste après la création, rappel à T-5 min |
| `Beamo.Geo` | Distance haversine |
| `Beamo.Push` | Tokens Expo, `notify/2` qui met en file les envois |
| `Beamo.Push.Expo` | Client HTTP Expo Push |
| `Beamo.Push.SendWorker` / `ReceiptsWorker` | Jobs Oban : envoi par lots de 100, puis lecture des receipts à +15 min |
| `Beamo.RateLimit` | Hammer en ETS (un seul nœud) |
| `BeamoWeb.Plugs.Auth` | `Authorization: Bearer <token>` → `conn.assigns.current_user` / `:session` |
| `BeamoWeb.Plugs.RateLimit` | Limite par `:ip`, `:user` ou `{:param, "phone"}` |
| `BeamoWeb.FallbackController` | Traduit les `{:error, …}` des contextes en réponses HTTP |

Les contrôleurs renvoient du JSON avec `json/2`. La sérialisation des utilisateurs passe par `BeamoWeb.UserJSON` : `me/1` pour soi-même, `public/1` pour les autres (`id`, `name`).

## Modèle de données

| Table | Colonnes clés | Notes |
|---|---|---|
| `users` | `phone` (E.164, unique), `phone_hash` (SHA-256 hex, unique), `name`, `radius_mode` (`auto`/`fixed`/`unlimited`), `radius_km` (seulement en `fixed`), `quiet_start`/`quiet_end` (time), `timezone`, `lat`/`lng` (arrondis), `located_at` | `name` nul = onboarding à faire (`is_new`) |
| `sessions` | `token_hash` (SHA-256 binaire, unique), `expires_at` | Le token n'est jamais stocké en clair ; prolongé à 90 j quand il reste moins de 60 j |
| `friendships` | `requester_id`, `addressee_id`, `status` (`pending`/`accepted`) | Index unique sur la paire non ordonnée (`LEAST`/`GREATEST`) |
| `blocks` | `blocker_id`, `blocked_id` | Bloquer supprime l'amitié |
| `beams` | `user_id`, `parent_id` (beam auquel on répond), `category`, `note`, `lat`/`lng` (copie de la position à la création), `reach_km` (portée effective, `nil` = sans limite), `expires_at`, `ended_at` | Index unique partiel : un seul beam avec `ended_at` nul par utilisateur. Actif = `ended_at` nul et `expires_at` dans le futur ; les beams expirés sont clos à la création suivante |
| `beam_recipients` | `beam_id`, `user_id`, `notified_at` (nul si push retenue), `seen_at` | Sert au « vu », aux stats et aux plafonds anti-spam |
| `mutes` | `user_id`, `muted_id` | |
| `push_tokens` | `token` (unique), `platform` (`ios`/`android`) | Ré-enregistrer un token le rattache au nouvel utilisateur |
| `oban_jobs` | — | Tables Oban (migration v14) |

Suppression de compte : tout est en `on_delete: :delete_all` sur `users`.

## Diffusion d'un beam (`Beams.fan_out/1`)

1. Ignore un beam inactif ou déjà diffusé (idempotent).
2. Candidats : le cercle de l'émetteur, avec une position de moins de 7 jours, sans l'auteur du beam parent.
3. On garde ceux qui acceptent la distance (rayon `fixed` respecté), puis on applique la portée de l'émetteur par paliers jusqu'à trouver quelqu'un.
4. L'auteur du beam parent est ajouté s'il est toujours dans le cercle, quelle que soit la distance.
5. Une push n'est pas envoyée en heures silencieuses (fuseau du destinataire), en cas de sourdine, si l'émetteur a déjà notifié ce destinataire dans l'heure, ou au-delà de 5 notifications par heure.
6. Les lignes `beam_recipients` et les jobs push sont écrits dans la même transaction.

## Tests

- `mix test` : ExUnit contre la vraie base `beamo_test` (sandbox SQL, `async: true`).
- Appels HTTP externes simulés avec `Req.Test` (`config/test.exs` branche les stubs `Beamo.Push.Expo` et `Beamo.Accounts.OTP.Prelude`).
- Oban en `testing: :manual` : `assert_enqueued` / `perform_job`.
- Helpers : `Beamo.Fixtures` (`user_fixture`, `user_with_token`, `befriend`, `unique_phone`) et `authed/2` dans `ConnCase`. Chaque test a une IP aléatoire, pour que les limites par IP ne débordent pas d'un test à l'autre.

## Configuration production (`config/runtime.exs`)

`DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `PRELUDE_API_KEY` (obligatoires) ; `EXPO_ACCESS_TOKEN`, `OTP_TEST_PHONE`, `OTP_TEST_CODE` (optionnels).

Derrière un reverse proxy, `conn.remote_ip` devra être réécrit depuis l'en-tête du proxy, sinon les limites par IP s'appliquent à l'IP du proxy.
