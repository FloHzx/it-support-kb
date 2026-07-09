#Requires -Modules M365-Assess

<#
.SYNOPSIS
    Lance un audit de conformité/sécurité du tenant Microsoft 365 via le module M365-Assess.

.DESCRIPTION
    Wrapper autour de la commande Invoke-M365Assessment du module M365-Assess :
    https://github.com/Galvnyz/M365-Assess

    Génère un export CSV, un rapport HTML autonome et une matrice de conformité XLSX
    couvrant plusieurs référentiels (CIS, NIST, SOC 2, HIPAA, ISO 27001, ...).

    Le module doit déjà être installé (Install-Module M365-Assess -Scope CurrentUser)
    et vous devez disposer des permissions Microsoft 365 nécessaires.

.PARAMETER TenantId
    Le tenant Microsoft 365 cible (ex: contoso.onmicrosoft.com).

.PARAMETER Section
    Sections à auditer (ex: Identity, Email). Si omis, toutes les sections sont exécutées.

.EXAMPLE
    .\Invoke-M365Assessment.ps1 -TenantId "contoso.onmicrosoft.com"

.EXAMPLE
    .\Invoke-M365Assessment.ps1 -TenantId "contoso.onmicrosoft.com" -Section Identity, Email
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string[]]$Section
)

Import-Module M365-Assess

if ($Section) {
    Invoke-M365Assessment -TenantId $TenantId -Section $Section
}
else {
    Invoke-M365Assessment -TenantId $TenantId
}
