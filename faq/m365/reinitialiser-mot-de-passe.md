# Réinitialiser le mot de passe d'un utilisateur (Microsoft 365)

## Contexte

Un utilisateur a oublié son mot de passe ou son compte doit être réinitialisé suite à un incident de sécurité.

## Procédure manuelle (Centre d'admin Microsoft 365)

1. Aller sur [admin.microsoft.com](https://admin.microsoft.com).
2. **Utilisateurs > Utilisateurs actifs**, sélectionner l'utilisateur concerné.
3. Cliquer sur **Réinitialiser le mot de passe**.
4. Choisir entre un mot de passe généré automatiquement ou personnalisé.
5. Cocher **Exiger le changement de mot de passe à la prochaine connexion**.
6. Communiquer le mot de passe temporaire à l'utilisateur par un canal sécurisé (jamais par e-mail en clair).

## Via script

Voir [`scripts/m365/Reset-UserPassword.ps1`](../../scripts/m365/Reset-UserPassword.ps1) pour réinitialiser en ligne de commande via Microsoft Graph.

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All"
.\scripts\m365\Reset-UserPassword.ps1 -UserPrincipalName "jdupont@contoso.com"
```

## Points d'attention

- Nécessite le rôle **Administrateur des utilisateurs** (ou supérieur) sur le tenant.
- Ne jamais transmettre un mot de passe temporaire par un canal non sécurisé.
- Toujours forcer le changement de mot de passe à la prochaine connexion.
