# IT Support KB

Base de connaissances FAQ et scripts pour le support IT, avec un focus sur l'administration Microsoft 365.

## Structure

- `faq/` : fiches pratiques par thème (ex. `faq/m365/`), format Markdown.
- `scripts/` : scripts PowerShell associés aux fiches FAQ (ex. `scripts/m365/`).
- `launcher/` : interface web locale pour parcourir et lancer les scripts.
- `Lancer.bat` : point d'entrée à double-cliquer pour ouvrir l'interface.

## Lanceur de scripts (interface web locale)

**Pour l'utiliser : double-cliquez sur [`Lancer.bat`](Lancer.bat)** à la racine du dépôt. Cela :

1. met à jour silencieusement le dépôt (`git pull`), sans que vous ayez besoin de taper une commande git,
2. démarre un petit serveur local (accessible uniquement depuis ce poste, sur `http://localhost`),
3. ouvre l'interface dans votre navigateur par défaut : une page avec vos scripts présentés en cartes, classées par catégorie (un sous-dossier de `scripts/` = une catégorie).

Cliquez sur un script pour ouvrir sa fiche : description, champs de paramètres (les champs marqués `*` sont obligatoires), puis :

- **Lancer dans une nouvelle fenêtre PowerShell** : exécute le script dans une fenêtre séparée, pour garder les prompts interactifs (ex. `Connect-MgGraph`) et la sortie console.
- **Copier la commande** : copie la commande équivalente dans le presse-papiers si vous préférez l'exécuter vous-même.

Pour fermer l'interface, fermez simplement la fenêtre de console ouverte par `Lancer.bat`.

Vous pouvez aussi lancer le serveur manuellement (ex. pour changer le port) :

```powershell
.\launcher\Start-WebLauncher.ps1 -Port 8734
```

Le lanceur n'installe ni n'importe aucun module : chaque script gère ses propres prérequis.

## Prérequis pour les scripts M365

Les scripts s'appuient sur le module officiel **Microsoft Graph PowerShell SDK** :

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "User.ReadWrite.All"
```

Chaque script attend une session déjà authentifiée (`Connect-MgGraph`) et ne stocke jamais d'identifiants ou de secrets. Adaptez les scopes Graph aux droits réellement nécessaires.

## Contribuer

1. Créez une branche pour votre ajout (`git checkout -b faq/nom-du-sujet`).
2. Ajoutez la fiche FAQ dans `faq/<theme>/` et, si pertinent, le script associé dans `scripts/<theme>/`.
3. Ouvrez une Pull Request.
