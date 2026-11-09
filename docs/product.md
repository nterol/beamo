# Produit

## Principe

Un utilisateur lance un **beam** : il se déclare dispo (catégorie + note libre) pour une durée limitée. Ses amis dans sa zone reçoivent une notification et peuvent **répondre** en s'activant à leur tour.

Règle centrale, à la BeReal : **on ne voit l'activité de ses amis que si l'on est actif soi-même**. Sinon, l'écran est flouté. La règle est appliquée côté serveur : un client inactif ne reçoit que des compteurs, jamais les identités, pour que le flou ne puisse pas être contourné.

L'écran principal montre uniquement les amis, en couleur quand ils sont actifs. Inactif, on ne reçoit que le nombre d'amis actifs (de quoi afficher un écran flouté).

## Beam

- Catégories : `movie`, `drink`, `coffee`, `outdoor`, `sport`, `other`, plus une note libre optionnelle.
- Durée fixe, constante serveur (`:beam_duration_minutes`, 120 aujourd'hui) modifiable sans mise à jour de l'app.
- Notification à T-5 min, puis expiration.
- Un seul beam actif à la fois par utilisateur.

## Audience

- v1 : **amis uniquement**.
- Plus tard : double tap = amis d'amis, triple tap = inconnus dans la zone (à cadrer).

## Géolocalisation

- Position mise à jour à chaque ouverture de l'app (permission « pendant l'utilisation »).
- Stockée arrondie à ~550 m, horodatée. Une position de plus de 7 jours est ignorée.
- Un beam exige une position récente : l'app l'envoie avec le beam.
- Chacun choisit un mode de rayon :
  - **auto** (défaut) : comme émetteur, 10 km, élargi à 25, 50 km puis sans limite tant que personne n'est atteint ; comme destinataire, on accepte ce que l'élargissement atteint.
  - **fixe** (N km) : limite stricte dans les deux rôles, sans élargissement.
  - **illimité**.
- Un ami est notifié seulement s'il est dans la portée de l'émetteur **et** dans son propre rayon.

## Répondre à un beam : les feux de Gondor

- Ouvrir la notification **n'est pas** un beam implicite. Elle ouvre le beam de l'ami avec un bouton « J'en suis ».
- L'ouverture est enregistrée comme « vu » : l'émetteur voit « 3 amis ont vu ton beam ».
- Répondre, c'est lancer **son propre beam**, lié à celui reçu. Seul un destinataire peut répondre.
- Exemple : Tom lance un beam. Léa le reçoit et répond.
  - Tom reçoit « Léa a répondu à ton beam ».
  - Les amis de Léa reçoivent « Léa est dispo ».
  - Max, ami de Léa mais pas de Tom, voit Léa, jamais Tom.
  - Si Max répond, ce sont les amis de Max qui sont prévenus, et ainsi de suite.
- La chaîne se propage de proche en proche, sans limite de profondeur. Chacun ne voit jamais que ses propres amis : il n'y a pas de logique de « cascade » à part.

## Communautés (à construire)

- Un utilisateur qui connaît plusieurs personnes peut créer une communauté avec elles. Exemple : Léa réunit Tom et Max.
- Les membres d'une communauté se voient mutuellement, comme des amis, même s'ils ne le sont pas.
- Sans communauté, les cercles restent séparés.
- Dans le code, la visibilité passe par `Social.circle_ids/1` (aujourd'hui, les amis seulement) : les communautés s'y brancheront.

## Anti-spam et heures silencieuses

- Côté émetteur : 6 beams par heure au maximum.
- Côté destinataire : 5 notifications de beam par heure au maximum, une seule par ami et par heure, possibilité de couper un ami (sourdine).
- Les beams non notifiés restent enregistrés et visibles dans l'app.
- Heures silencieuses (début, fin, fuseau horaire) : pas de push, mais le beam reste visible dans l'app.

## Modération v1

Le blocage supprime l'amitié et masque les deux utilisateurs l'un à l'autre, sans que le bloqué le sache. Côté API, un bloqué reçoit la même réponse que pour un compte inexistant.

## Contraintes stores

- Apple : justifier contacts, localisation et notifications ; politique de confidentialité publique ; compte de démo (`OTP_TEST_PHONE`).
- Google Play : formulaire « Data safety » (localisation, contacts).
