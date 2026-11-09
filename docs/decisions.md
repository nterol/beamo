# Décisions

Journal antichronologique. Chaque entrée : décision, raison, alternatives écartées.

## 2026-11-09 — Pas de beam implicite à l'ouverture d'une notification
Ouvrir une notification relève de la curiosité, pas de la disponibilité. Un beam implicite diffuserait statut et position sans consentement, et produirait des faux positifs. À la place : bouton « J'en suis » à un tap + signal « vu ».

## 2026-11-09 — Cascade de réponses retenue
Répondre à un beam notifie aussi les amis du répondant. Effet viral voulu par le produit. Conséquences à cadrer : visibilité de l'émetteur d'origine pour des non-amis, profondeur maximale, espaces de communauté.

## 2026-11-09 — Rayon : celui des deux
Un ami est notifié si la distance est sous le rayon de l'émetteur **et** sous celui du destinataire. Chacun garde le contrôle.

## 2026-11-09 — Position arrondie, péremption à 7 jours
Grille d'environ 550 m : suffisant pour un rayon, trop grossier pour situer un domicile. Mise à jour à l'ouverture de l'app seulement : la localisation en arrière-plan exige la permission « Toujours », que les stores examinent de près et que beaucoup d'utilisateurs refusent.

## 2026-11-09 — Elixir/Phoenix plutôt que Node/Hono
Le porteur ne code pas, donc l'argument « une seule langue pour le porteur » disparaît. Le temps réel est désormais souhaité : Channels et Presence le donnent sans Redis. L'envoi massif de notifications profite des processus légers. Perte assumée : le client RPC typé de Hono, compensé plus tard par une spec OpenAPI et un client TypeScript généré. Écartés : Go (pas d'avantage décisif), Supabase (logique éclatée entre RLS et fonctions).

## 2026-11-09 — Oban plutôt que Temporal
Le besoin se résume à des tâches différées (rappel, expiration, receipts Expo) et à des envois avec réessais. Oban stocke tout dans Postgres, sans service supplémentaire. Temporal ajoutait un worker séparé et un cluster (ou un abonnement Cloud) pour deux minuteries par beam.

## 2026-11-09 — Hébergement non tranché
Fly.io est le mieux intégré à Elixir. Railway convient aussi pour un seul nœud. Choix au moment du déploiement ; le code reste portable (release Docker). L'app mobile, elle, passe par les stores ; seule une page de politique de confidentialité est à héberger.

## Reprises du plan initial (toujours valides)
- OTP SMS via Prelude, derrière un behaviour interchangeable ; aucune table OTP chez nous.
- Session opaque hachée en base plutôt qu'un JWT ; révocation = suppression de la ligne.
- `POST /auth/otp/start` répond toujours 204 : impossible de sonder qui est inscrit.
- Contacts envoyés sous forme de hash SHA-256 de numéros E.164 ; la vraie protection contre l'énumération est le rate limiting.
