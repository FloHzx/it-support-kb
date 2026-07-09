#Requires -Version 5.1

<#
.SYNOPSIS
    Interface graphique listant les scripts du dossier scripts/, classés par catégorie, avec lancement direct.

.DESCRIPTION
    Parcourt scripts/<categorie>/*.ps1, affiche un arbre catégorie > script, et pour le script
    sélectionné génère un formulaire à partir de son bloc de paramètres. Le script choisi est
    lancé dans une nouvelle fenêtre PowerShell (pour garder les prompts interactifs, ex. Connect-MgGraph,
    et la sortie console habituelle).

    N'installe ni n'importe aucun module : chaque script gère ses propres prérequis (#Requires).

.EXAMPLE
    .\launcher\Show-ScriptLauncher.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptsRoot = Join-Path $repoRoot "scripts"
$psExecutable = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }

function Get-ScriptCatalog {
    $categories = [ordered]@{}
    if (-not (Test-Path $scriptsRoot)) { return $categories }

    Get-ChildItem -Path $scriptsRoot -Directory | Sort-Object Name | ForEach-Object {
        $category = $_.Name
        $scripts = Get-ChildItem -Path $_.FullName -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
            $help = Get-Help -Name $_.FullName -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                Name     = $_.BaseName
                Path     = $_.FullName
                Synopsis = if ($help.Synopsis) { $help.Synopsis.Trim() } else { "" }
            }
        }
        if ($scripts) { $categories[$category] = $scripts }
    }
    return $categories
}

$catalog = Get-ScriptCatalog

# --- Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "IT Support KB - Lanceur de scripts"
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"

$tree = New-Object System.Windows.Forms.TreeView
$tree.Dock = "Left"
$tree.Width = 280
$form.Controls.Add($tree)

foreach ($category in $catalog.Keys) {
    $categoryNode = New-Object System.Windows.Forms.TreeNode($category)
    foreach ($scriptInfo in $catalog[$category]) {
        $scriptNode = New-Object System.Windows.Forms.TreeNode($scriptInfo.Name)
        $scriptNode.Tag = $scriptInfo
        $categoryNode.Nodes.Add($scriptNode) | Out-Null
    }
    $tree.Nodes.Add($categoryNode) | Out-Null
}
$tree.ExpandAll()

$detailPanel = New-Object System.Windows.Forms.Panel
$detailPanel.Dock = "Fill"
$form.Controls.Add($detailPanel)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.Size = New-Object System.Drawing.Size(560, 25)
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$detailPanel.Controls.Add($lblTitle)

$lblSynopsis = New-Object System.Windows.Forms.Label
$lblSynopsis.Location = New-Object System.Drawing.Point(20, 50)
$lblSynopsis.Size = New-Object System.Drawing.Size(560, 40)
$detailPanel.Controls.Add($lblSynopsis)

$paramsPanel = New-Object System.Windows.Forms.Panel
$paramsPanel.Location = New-Object System.Drawing.Point(20, 100)
$paramsPanel.Size = New-Object System.Drawing.Size(560, 340)
$paramsPanel.AutoScroll = $true
$paramsPanel.BorderStyle = "FixedSingle"
$detailPanel.Controls.Add($paramsPanel)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "* champ obligatoire"
$lblHint.Location = New-Object System.Drawing.Point(20, 445)
$lblHint.Size = New-Object System.Drawing.Size(300, 20)
$lblHint.ForeColor = [System.Drawing.Color]::Gray
$detailPanel.Controls.Add($lblHint)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Lancer dans une nouvelle fenêtre PowerShell"
$btnRun.Location = New-Object System.Drawing.Point(20, 470)
$btnRun.Size = New-Object System.Drawing.Size(320, 35)
$btnRun.Enabled = $false
$detailPanel.Controls.Add($btnRun)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Copier la commande"
$btnCopy.Location = New-Object System.Drawing.Point(350, 470)
$btnCopy.Size = New-Object System.Drawing.Size(180, 35)
$btnCopy.Enabled = $false
$detailPanel.Controls.Add($btnCopy)

$script:selectedScript = $null
$script:paramInputs = @{}
$script:mandatoryParams = @()

function Build-ArgumentString {
    $parts = @()
    foreach ($key in $script:paramInputs.Keys) {
        $value = $script:paramInputs[$key].Text
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        $escaped = $value -replace "'", "''"
        $parts += "-$key '$escaped'"
    }
    return ($parts -join " ")
}

function Test-MandatoryFilled {
    foreach ($key in $script:mandatoryParams) {
        if ([string]::IsNullOrWhiteSpace($script:paramInputs[$key].Text)) {
            return $false
        }
    }
    return $true
}

$tree.Add_AfterSelect({
    param($sender, $e)

    $paramsPanel.Controls.Clear()
    $script:paramInputs = @{}
    $script:mandatoryParams = @()

    $node = $e.Node
    if (-not $node.Tag) {
        $script:selectedScript = $null
        $btnRun.Enabled = $false
        $btnCopy.Enabled = $false
        $lblTitle.Text = ""
        $lblSynopsis.Text = ""
        return
    }

    $script:selectedScript = $node.Tag
    $lblTitle.Text = $script:selectedScript.Name
    $lblSynopsis.Text = $script:selectedScript.Synopsis

    $cmd = Get-Command -Name $script:selectedScript.Path -ErrorAction SilentlyContinue
    $y = 0
    if ($cmd) {
        $commonParams = @([System.Management.Automation.PSCmdlet]::CommonParameters) + @([System.Management.Automation.PSCmdlet]::OptionalCommonParameters)
        foreach ($paramName in $cmd.Parameters.Keys) {
            if ($commonParams -contains $paramName) { continue }
            $paramInfo = $cmd.Parameters[$paramName]
            $isMandatory = $false
            foreach ($attr in $paramInfo.Attributes) {
                if ($attr -is [System.Management.Automation.ParameterAttribute] -and $attr.Mandatory) {
                    $isMandatory = $true
                }
            }

            $lbl = New-Object System.Windows.Forms.Label
            $labelText = if ($isMandatory) { "$paramName *" } else { $paramName }
            $lbl.Text = $labelText
            $lbl.Location = New-Object System.Drawing.Point(10, $y)
            $lbl.Size = New-Object System.Drawing.Size(300, 20)
            $paramsPanel.Controls.Add($lbl)

            $txt = New-Object System.Windows.Forms.TextBox
            $txt.Location = New-Object System.Drawing.Point(10, $y + 20)
            $txt.Size = New-Object System.Drawing.Size(500, 20)
            $paramsPanel.Controls.Add($txt)

            $script:paramInputs[$paramName] = $txt
            if ($isMandatory) { $script:mandatoryParams += $paramName }
            $y += 50
        }
    }

    $btnRun.Enabled = $true
    $btnCopy.Enabled = $true
})

$btnRun.Add_Click({
    if (-not $script:selectedScript) { return }
    if (-not (Test-MandatoryFilled)) {
        [System.Windows.Forms.MessageBox]::Show("Merci de renseigner tous les champs obligatoires (*).", "Champ manquant", "OK", "Warning") | Out-Null
        return
    }
    $argString = Build-ArgumentString
    $scriptPath = $script:selectedScript.Path
    $command = "& '$scriptPath' $argString"
    Start-Process -FilePath $psExecutable -ArgumentList @("-NoExit", "-Command", $command)
})

$btnCopy.Add_Click({
    if (-not $script:selectedScript) { return }
    $argString = Build-ArgumentString
    $command = "& '$($script:selectedScript.Path)' $argString"
    [System.Windows.Forms.Clipboard]::SetText($command)
    [System.Windows.Forms.MessageBox]::Show("Commande copiée dans le presse-papiers.", "IT Support KB") | Out-Null
})

[void]$form.ShowDialog()
