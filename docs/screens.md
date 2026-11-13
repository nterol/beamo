# Inventaire des écrans

Base de travail pour les maquettes Figma de l'app mobile v1. Chaque écran liste son contenu, ses actions, ses états et les endpoints qu'il consomme (voir [api.md](api.md)). Les états comptent autant que l'écran nominal : c'est là que se cachent les surprises au moment de coder.

Limites utiles pour dessiner : prénom 1–40 caractères, note de beam 140 caractères max, nom de communauté 1–40 caractères, 50 membres max par communauté.

## Navigation proposée

- **Onboarding** (pile séparée, avant connexion) : A1 → A6.
- **App connectée**, trois onglets :
  - **Fil** (B), avec le bouton principal « Lancer un beam » toujours accessible ;
  - **Communautés** (E) ;
  - **Amis** (D).
- **Profil et réglages** (F) : accessible depuis un avatar en haut du Fil.
- Les écrans de beam (C) s'ouvrent en feuille modale par-dessus le Fil, ou depuis une push.

## A. Onboarding et connexion

### A1. Bienvenue
- Contenu : logo, promesse en une phrase (« Dis à tes amis que tu es dispo »), illustration du principe.
- Action : « Commencer ».

### A2. Numéro de téléphone
- Contenu : sélecteur d'indicatif pays, champ numéro, mention légale (CGU, confidentialité).
- Action : « Recevoir le code » → `POST /auth/otp/start`.
- États : numéro invalide (côté client), envoi en cours, `too_many_requests` (« Réessaie dans N min », d'après `retry-after`), `provider_error` (« Envoi du SMS impossible, réessaie »).

### A3. Code SMS
- Contenu : rappel du numéro (avec « Modifier »), champ code, renvoi du code avec compte à rebours.
- Action : saisie complète → `POST /auth/otp/verify`.
- États : vérification en cours, `invalid_code`, `too_many_requests`, renvoi bloqué par la limite.
- Sortie : `is_new` vrai → A4, sinon → permissions manquantes puis Fil.

### A4. Prénom (nouveaux comptes)
- Contenu : champ prénom, explication « C'est ce que verront tes amis ».
- Action : « Continuer » → `PATCH /me {name}`.
- États : vide, trop long.

### A5. Permissions (trois pré-écrans, puis la demande système)
Un écran explicatif avant chaque demande système : Apple l'exige de fait, et un refus à la demande système est difficile à rattraper.
- **A5a Localisation** : « Pour prévenir seulement les amis proches ». Accordée → `PUT /me/location`.
- **A5b Notifications** : « Pour savoir quand un ami est dispo ». Accordée → `POST /push-tokens`.
- **A5c Contacts** : « Pour retrouver tes amis déjà sur Beamo ». Accordée → A6.
- États : chaque refus mène à l'écran suivant, avec une bannière de rattrapage plus tard (voir G3).

### A6. Retrouver ses amis
- Contenu : liste des contacts inscrits (`POST /contacts/match`), avec un bouton selon `relation` : `none` → « Ajouter », `outgoing` → « Demandé », `incoming` → « Accepter », `friend` → « Ami ».
- Actions : ajouter (`POST /friend-requests`), accepter, « Inviter des amis » (partage d'un lien, voir questions ouvertes), « Terminer ».
- États : chargement, aucun contact inscrit, contacts refusés (« Autoriser l'accès » + « Passer »), `too_many_requests`.

## B. Fil

### B1. Fil inactif (flouté)
L'écran le plus vu de l'app, et celui qui doit donner envie de lancer un beam.
- Contenu : fond flouté évoquant des amis, compteur `active_count` (« 3 amis sont dispo »), gros bouton « Lancer un beam ».
- Données : `GET /feed` → `{active: false, active_count}`.
- États :
  - `active_count = 0` : message neutre (« Personne pour l'instant. Lance le premier beam ? ») ;
  - aucun ami : invitation à ajouter des amis (→ D2) ;
  - localisation refusée : bannière (G3) ;
  - chargement, erreur réseau.

### B2. Fil actif
- Contenu :
  - en haut, **mon beam** : catégorie, note, temps restant, compteurs « envoyé à N », « vu par N », réponses (→ B3) ;
  - puis la liste des amis : actifs d'abord, en couleur, avec catégorie, note, distance (`distance_km`) et temps restant ; inactifs ensuite, en gris.
- Données : `GET /feed` → `{active: true, beam, friends}`, plus `GET /beams/current` pour les compteurs.
- Actions : toucher un ami actif → C2 ; toucher mon beam → B3.
- États : aucun autre ami actif, liste longue (défilement), rafraîchissement (signal `feed_changed`).

### B3. Mon beam
- Contenu : catégorie, note, temps restant, `reached` (« Envoyé à 8 amis »), `seen` (« 3 l'ont vu »), liste des réponses (`replies`, prénoms), éventuellement le beam parent si c'est une réponse.
- Données : `GET /beams/current`.
- Actions : « Arrêter mon beam » (confirmation) → `DELETE /beams/current`.
- États : `reached = 0` (« Aucun ami à portée pour l'instant », lien vers le rayon F2), aucune réponse, beam sur le point d'expirer (après la push T-5 min), beam expiré (retour à B1).

## C. Beams

### C1. Lancer un beam (feuille modale)
- Contenu : six catégories en grille (`movie`, `drink`, `coffee`, `outdoor`, `sport`, `other`), avec icône et libellé ; note libre optionnelle (compteur 140) ; rappel de la durée (« Visible 2 h »).
- Action : « Lancer » → `POST /beams` avec la position.
- États :
  - envoi en cours (récupération de la position puis appel) ;
  - succès → B2, avec un retour visuel fort (« Envoyé à N amis ») ;
  - `location_required` ou localisation refusée → écran d'explication avec lien vers les réglages du téléphone ;
  - `already_active` (cas rare, deux appareils) → afficher le beam en cours ;
  - `too_many_requests` (« Tu as lancé beaucoup de beams, réessaie dans N min »).

### C2. Beam d'un ami
Ouvert depuis le Fil ou depuis la push « Tom est dispo ».
- Contenu : prénom, catégorie, note, distance, temps restant.
- Données : `GET /beams/:id`, puis `POST /beams/:id/seen` à l'ouverture.
- Action principale : « J'en suis » → C3.
- Actions secondaires (menu) : couper les notifications de cet ami, bloquer.
- États :
  - beam terminé ou expiré (`active: false`) : « Le beam de Tom est terminé », sans bouton ;
  - `not_found` (blocage, compte supprimé) : « Ce beam n'est plus disponible » ;
  - j'ai déjà un beam actif : le bouton « J'en suis » est indisponible ou expliqué (voir questions ouvertes) ;
  - ouvert depuis une push alors que l'app était fermée : écran seul, avec retour vers le Fil.

### C3. Répondre (« J'en suis »)
- Contenu : C1 en version courte, catégorie du beam de l'ami présélectionnée, note optionnelle, rappel « Tes amis seront prévenus aussi ».
- Action : « Confirmer » → `POST /beams {category, note, lat, lng, parent_id}`.
- États : identiques à C1 ; succès → B2.

## D. Amis

### D1. Mes amis
- Contenu : demandes reçues en tête (avec badge sur l'onglet), puis la liste des amis, puis les demandes envoyées.
- Données : `GET /friends`, `GET /friend-requests`.
- Actions : accepter ou refuser une demande (`POST /friend-requests/:id/accept`, `DELETE /friend-requests/:id`), annuler une demande envoyée, « Ajouter des amis » → D2, toucher un ami → D3.
- États : aucun ami (état vide qui pousse vers D2), aucune demande.

### D2. Ajouter des amis
- Réutilise A6 (correspondance des contacts), accessible à tout moment.
- États supplémentaires : contacts refusés (lien vers les réglages du téléphone).

### D3. Actions sur un ami (feuille d'actions)
- Actions : couper ou rétablir les notifications (`POST`/`DELETE /mutes`), retirer des amis (`DELETE /friends/:id`), bloquer (`POST /blocks`).
- Chaque action destructive a sa confirmation. Le blocage est silencieux pour l'autre : le dire dans la confirmation.

## E. Communautés

### E1. Mes communautés
- Contenu : invitations en attente en tête (nom de la communauté, « Invité par Léa », boutons Accepter / Refuser), puis la liste des communautés (nom, nombre de membres).
- Données : `GET /communities`, `GET /community-invitations`.
- Actions : accepter (`POST /communities/:id/accept`), refuser (`DELETE /communities/:id/membership`), ouvrir → E3, « Créer » → E2.
- États : aucune communauté (expliquer le concept), aucune invitation.

### E2. Créer une communauté
- Contenu : champ nom, sélection multiple parmi mes amis (au moins un).
- Action : « Créer » → `POST /communities` → E3.
- États : aucun ami (impossible de créer, renvoyer vers D2), nom vide.

### E3. Fil de la communauté
- Contenu : nom, nombre de membres, puis la grille ou la liste des membres :
  - membre : prénom, et si je suis actif, son beam et sa distance ;
  - invité : place grisée sans identité, « Invité par Léa ».
- Inactif : même logique de flou que B1, avec `active_count` (« 2 membres sont dispo »).
- Données : `GET /communities/:id`.
- Actions (menu) : inviter → E4, renommer → E5, quitter (confirmation, « La communauté disparaît si tu es le dernier »).
- États : flouté ou actif, uniquement des invités en attente, communauté pleine (50).

### E4. Inviter dans la communauté
- Contenu : sélection multiple parmi mes amis, en excluant ou en grisant ceux déjà membres ou invités.
- Action : « Inviter » → `POST /communities/:id/invitations`.
- États : aucun ami invitable, limite de 50 atteinte.

### E5. Renommer
- Champ nom → `PATCH /communities/:id`.

## F. Profil et réglages

### F1. Réglages (écran principal)
- Sections : prénom (modifiable), rayon (→ F2), heures silencieuses (→ F3), amis en sourdine (→ F4), utilisateurs bloqués (→ F5), permissions (état de la localisation, des notifications et des contacts, avec lien vers les réglages du téléphone), confidentialité (lien vers la page publique), déconnexion, suppression du compte (→ F6).
- Données : `GET /me`, `PATCH /me`.

### F2. Rayon
- Trois options : **Auto** (recommandé, avec explication de l'élargissement 10 → 25 → 50 km → sans limite), **Fixe** (curseur 1–500 km), **Illimité**.
- Expliquer la règle « les deux rayons » en une phrase : on ne reçoit que les beams d'amis à portée des deux côtés.

### F3. Heures silencieuses
- Interrupteur, heure de début, heure de fin. Le fuseau est envoyé automatiquement.
- Rappel : « Les beams restent visibles dans l'app, sans notification. »

### F4. Amis en sourdine
- Liste (`GET /mutes`), « Rétablir » (`DELETE /mutes/:id`). État vide.

### F5. Utilisateurs bloqués
- Liste (`GET /blocks`), « Débloquer » (`DELETE /blocks/:id`). État vide. Débloquer ne restaure pas l'amitié : le préciser.

### F6. Supprimer mon compte
- Confirmation forte (taper « SUPPRIMER » ou équivalent), conséquences listées → `DELETE /me` → A1.

## G. Écrans et éléments transverses

- **G1. Lancement** : splash pendant la lecture du token et le premier `GET /me`.
- **G2. Session expirée** : toute réponse 401 → retour à A2, avec un message court.
- **G3. Bannières de permission** : localisation refusée (bloquante pour lancer un beam), notifications refusées (le produit perd son intérêt : la bannière doit le dire), contacts refusés (discrète).
- **G4. Hors ligne / erreur réseau** : bandeau et bouton « Réessayer ».
- **G5. Limite atteinte** : toast générique pour `too_many_requests`, avec le délai.
- **G6. Confirmations** : feuille réutilisable pour arrêter un beam, retirer un ami, bloquer, quitter une communauté, se déconnecter.
- **G7. Icônes de catégorie** : six icônes et six couleurs, à concevoir comme un petit système dès le départ ; elles apparaissent partout.

## Ouverture depuis une notification

| Push (`data.type`) | Écran ouvert |
|---|---|
| `beam` (« Tom est dispo ») | C2, beam de Tom |
| `beam_reply` (« Léa a répondu à ton beam ») | B3, mon beam |
| `beam_ending` (« Ton beam se termine dans 5 min ») | B3, mon beam |
| `community_invite` | E1, invitation en tête |

## Parcours à prototyper en priorité

1. **Premier lancement** : A1 → A2 → A3 → A4 → A5a/b/c → A6 → B1.
2. **Lancer un beam** : B1 → C1 → B2 → B3.
3. **Recevoir et répondre** : push → C2 → C3 → B2.
4. **Créer une communauté** : E1 → E2 → E3 → E4.
5. **Être invité** : push → E1 → accepter → E3.

## Questions ouvertes pour le design

Certaines demandent une évolution de l'API : à trancher avant de dessiner les écrans concernés.

1. **Photo de profil** : l'API ne connaît qu'un prénom. Des initiales colorées suffisent-elles en v1 ?
2. **Carte ou liste** : l'API ne renvoie que des distances, jamais de coordonnées. Une carte des amis n'est donc pas possible en l'état (et contredirait le choix de confidentialité). Le Fil est une liste.
3. **Ajouter un ami hors contacts** : il n'existe ni recherche par nom ni lien d'invitation. Faut-il un lien d'invitation (« Rejoins-moi sur Beamo ») ou un code ami ?
4. **Inviter un contact non inscrit** : partage d'un lien vers les stores par SMS ? Pas d'API nécessaire, mais un écran à prévoir.
5. **Répondre en ayant déjà un beam actif** : l'API refuse un second beam. Proposer « Arrêter le mien et répondre », ou griser le bouton ?
6. **Catégorie d'une réponse** : héritée automatiquement du beam de l'ami, ou modifiable ?
7. **Prolonger un beam** à la push T-5 min : pas d'API aujourd'hui. Relancer suffit-il ?
8. **« Vu par »** : on n'a qu'un compteur, pas les prénoms. Volontaire (pas de pression sociale) ou à ajouter ?
9. **Longueur du code SMS** : fixée par Prelude, à confirmer pour dessiner A3.
