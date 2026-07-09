# IT Support KB

Base de connaissances FAQ et scripts pour le support IT, avec un focus sur l'administration Microsoft 365.

## Structure

- `faq/` : fiches pratiques par thème (ex. `faq/m365/`), format Markdown.
- `scripts/` : scripts PowerShell associés aux fiches FAQ (ex. `scripts/m365/`).

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
