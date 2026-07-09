#Requires -Modules Microsoft.Graph.Users

<#
.SYNOPSIS
    Réinitialise le mot de passe d'un utilisateur Microsoft 365 via Microsoft Graph.

.DESCRIPTION
    Génère un mot de passe temporaire et force son changement à la prochaine connexion.
    Nécessite une session Microsoft Graph déjà authentifiée (Connect-MgGraph -Scopes "User.ReadWrite.All").

.PARAMETER UserPrincipalName
    L'UPN (adresse e-mail) de l'utilisateur cible.

.EXAMPLE
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    .\Reset-UserPassword.ps1 -UserPrincipalName "jdupont@contoso.com"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)

$temporaryPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })

$passwordProfile = @{
    ForceChangePasswordNextSignIn = $true
    Password                      = $temporaryPassword
}

Update-MgUser -UserId $UserPrincipalName -PasswordProfile $passwordProfile

Write-Host "Mot de passe temporaire pour ${UserPrincipalName}: $temporaryPassword"
Write-Host "L'utilisateur devra le changer à sa prochaine connexion."
