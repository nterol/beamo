# Produit

## Principe

Un utilisateur lance un **beam** : il se déclare dispo (catégorie + note libre) pour une durée limitée. Ses amis dans sa zone reçoivent une notification et peuvent **répondre** en s'activant à leur tour.

Règle centrale, à la BeReal : **on ne voit l'activité de ses amis que si l'on est actif soi-même**. Sinon, l'écran est flouté. La règle est appliquée côté serveur : un client inactif ne reçoit que des compteurs, jamais les identités, pour que le flou ne puisse pas être contourné.

L'écran principal montre uniquement les amis, en couleur quand ils sont actifs.

## Beam

- Catégories : `movie`, `drink`, `coffee`, `outdoor`, `sport`, `other`, plus une note libre optionnelle.
- Durée fixe, constante serveur modifiable sans mise à jour de l'app : 2 h pressenti, 3 h possible.
- Notification à T-5 min, puis expiration.
- Un seul beam actif à la fois par utilisateur.

## Audience

- v1 : **amis uniquement**.
- Plus tard : double tap = amis d'amis, triple tap = inconnus dans la zone (à cadrer).

## Géolocalisation

- Position mise à jour à chaque ouverture de l'app (permission « pendant l'utilisation »).
- Stockée arrondie à ~550 m, horodatée. Une position de plus de 7 jours est ignorée.
- Chacun règle un rayon : 10 km par défaut, ou pas de rayon.
- Un ami est notifié si la distance est sous **les deux** rayons, celui de l'émetteur et celui du destinataire.
- Si personne n'est dans le rayon, élargissement automatique par paliers (10 → 25 → 50 km → sans limite, à confirmer).

## Répondre à un beam

- Ouvrir la notification **n'est pas** un beam implicite. Elle ouvre le beam de l'ami avec un bouton « J'en suis ».
- L'ouverture est enregistrée comme « vu » : l'émetteur voit « 3 amis ont vu ton beam ».
- Répondre crée un beam lié au beam d'origine. Il notifie l'émetteur d'origine **et** les amis du répondant : c'est la **cascade**.
- La cascade fait se croiser des gens qui ne se connaissent pas, d'où le besoin d'**espaces de communauté** (à cadrer).

## Anti-spam et heures silencieuses

- Côté émetteur : délai minimum entre deux beams.
- Côté destinataire : plafond de notifications par heure, une seule notification par ami et par heure, possibilité de couper un ami.
- Heures silencieuses (début, fin, fuseau horaire) : pas de push, mais le beam reste visible dans l'app.

## Modération v1

Le blocage supprime l'amitié et masque les deux utilisateurs l'un à l'autre, sans que le bloqué le sache. Côté API, un bloqué reçoit la même réponse que pour un compte inexistant.

## Contraintes stores

- Apple : justifier contacts, localisation et notifications ; politique de confidentialité publique ; compte de démo (`OTP_TEST_PHONE`).
- Google Play : formulaire « Data safety » (localisation, contacts).
