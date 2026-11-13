# Documentation Beamo

À lire en début de session, dans cet ordre :

1. [status.md](status.md) : ce qui est fait, ce qui reste, les questions ouvertes. **À mettre à jour à chaque fin de tâche.**
2. [product.md](product.md) : le produit et ses règles métier.
3. [architecture.md](architecture.md) : stack, organisation du code, modèle de données, conventions.
4. [api.md](api.md) : les endpoints exposés au mobile.
5. [decisions.md](decisions.md) : journal des décisions et de leurs raisons.
6. [deploy.md](deploy.md) : mise en production.
7. [screens.md](screens.md) : inventaire des écrans de l'app mobile, base des maquettes Figma.

## Conventions de travail

- Le porteur du projet ne code pas : l'implémentation est entièrement déléguée.
- Commits préfixés par un gitmoji, push direct sur une branche de feature, sans demander.
- Pas de commentaires ni de docstrings dans le code : les explications vivent ici.
- Avant de committer côté serveur : `cd server && mise exec -- mix precommit`.
