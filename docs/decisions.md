# Décisions

Journal antichronologique. Chaque entrée : décision, raison, alternatives écartées.

## 2026-11-09 — Communautés : visibilité sans notifications
Les membres se voient dans le fil de la communauté uniquement ; les notifications de beam restent réservées aux amis. Création avec au moins un ami, puis chaque membre invite ses propres amis. Invitation à accepter, invité anonyme tant qu'il n'a pas accepté. `circle_ids/1` reste donc limité aux amis.

## 2026-11-09 — L'auteur d'origine reçoit seulement « X a répondu »
Quand on répond à son beam, l'auteur reçoit la notification de réponse, pas en plus l'annonce ordinaire du beam du répondant.

## 2026-11-09 — Trois modes de rayon
Avec un rayon de 10 km par défaut des deux côtés et la règle « les deux rayons », l'élargissement automatique n'atteignait jamais personne. D'où trois modes :
- `auto` (défaut) : élargit comme émetteur et accepte comme destinataire ;
- `fixed` : limite stricte dans les deux rôles ;
- `unlimited`.

## 2026-11-09 — La cascade est une chaîne de beams indépendants
Image des feux de Gondor. Répondre = lancer son propre beam (lié au parent), diffusé à ses propres amis. Personne ne voit les amis de ses amis. Les communautés seront le seul moyen de rendre visibles des non-amis. La visibilité est centralisée dans `Social.circle_ids/1`.

## 2026-11-09 — Un beam exige une position récente
Sans position, la règle de rayon n'a pas de sens. L'app envoie la position avec le beam ; `location_required` sinon.

## 2026-11-09 — Fil flouté = compteur seulement
Un client inactif reçoit `active_count`, jamais les identités : le flou ne peut pas être contourné en lisant la réponse de l'API.

## 2026-11-09 — Seuils anti-spam initiaux
6 beams par heure en émission ; en réception, 5 pushes par heure et une seule par émetteur et par heure. Ce sont des constantes de `Beamo.Beams` et des limites de contrôleur, à ajuster avec les données d'usage.

## 2026-11-09 — Pas de beam implicite à l'ouverture d'une notification
Ouvrir une notification relève de la curiosité, pas de la disponibilité. Un beam implicite diffuserait statut et position sans consentement, et produirait des faux positifs. À la place : bouton « J'en suis » à un tap + signal « vu ».

## 2026-11-09 — Rayon : celui des deux
Un ami est notifié s'il est dans la portée de l'émetteur **et** dans son propre rayon. Chacun garde le contrôle.

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
