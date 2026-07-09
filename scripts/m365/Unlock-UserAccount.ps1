#Requires -Modules Microsoft.Graph.Users

<#
.SYNOPSIS
    Réactive un compte utilisateur Microsoft 365 via Microsoft Graph.

.DESCRIPTION
    Repasse le champ AccountEnabled à $true pour lever un blocage manuel.
    Nécessite une session Microsoft Graph déjà authentifiée (Connect-MgGraph -Scopes "User.ReadWrite.All").

.PARAMETER UserPrincipalName
    L'UPN (adresse e-mail) de l'utilisateur cible.

.EXAMPLE
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    .\Unlock-UserAccount.ps1 -UserPrincipalName "jdupont@contoso.com"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)

Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$true

Write-Host "Compte ${UserPrincipalName} réactivé (AccountEnabled = true)."
