# Auditer la conformité/sécurité du tenant (Microsoft 365)

## Contexte

Besoin d'un état des lieux régulier du tenant (identité, licences, e-mail, sécurité, etc.) mappé sur des référentiels de conformité (CIS, NIST, SOC 2, HIPAA, ISO 27001, ...).

## Outil utilisé

Ce script s'appuie sur le module externe [**M365-Assess**](https://github.com/Galvnyz/M365-Assess) (MIT), qui exécute ~292 contrôles automatisés en lecture seule et génère :

- un export CSV,
- un rapport HTML autonome consultable hors ligne,
- une matrice de conformité XLSX.

## Prérequis

```powershell
Install-Module M365-Assess -Scope CurrentUser
```

## Via script

Voir [`scripts/m365/Invoke-M365Assessment.ps1`](../../scripts/m365/Invoke-M365Assessment.ps1).

```powershell
.\scripts\m365\Invoke-M365Assessment.ps1 -TenantId "contoso.onmicrosoft.com"

# Audit ciblé sur certaines sections uniquement
.\scripts\m365\Invoke-M365Assessment.ps1 -TenantId "contoso.onmicrosoft.com" -Section Identity, Email
```

## Points d'attention

- Opération en lecture seule, aucune donnée n'est exfiltrée (voir la documentation du module).
- Les permissions Microsoft 365 requises varient selon les sections auditées — consulter la documentation du module pour le détail par section.
- Exécuté sans paramètres, le module propose un assistant interactif pour guider la configuration.
