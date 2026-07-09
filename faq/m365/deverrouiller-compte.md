# Déverrouiller un compte utilisateur bloqué (Microsoft 365)

## Contexte

Un compte peut être bloqué suite à plusieurs tentatives de connexion échouées, ou désactivé manuellement (`AccountEnabled = false`).

## Procédure manuelle (Centre d'admin Microsoft 365)

1. Aller sur [admin.microsoft.com](https://admin.microsoft.com).
2. **Utilisateurs > Utilisateurs actifs**, sélectionner l'utilisateur concerné.
3. Vérifier le statut du compte (icône de blocage à côté du nom).
4. Cliquer sur **···** puis **Débloquer le compte** (ou basculer le statut sur *Autoriser la connexion*).

## Via script

Voir [`scripts/m365/Unlock-UserAccount.ps1`](../../scripts/m365/Unlock-UserAccount.ps1).

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All"
.\scripts\m365\Unlock-UserAccount.ps1 -UserPrincipalName "jdupont@contoso.com"
```

## Points d'attention

- Un compte "bloqué" par tentatives échouées se débloque en général automatiquement après un délai (verrouillage Azure AD Smart Lockout) ; le script force un déblocage immédiat en repassant `AccountEnabled` à `true`.
- Vérifier qu'il n'y a pas de raison de sécurité justifiant le blocage avant de déverrouiller (compte compromis, départ de collaborateur, etc.).
