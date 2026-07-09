#Requires -Version 5.1

<#
.SYNOPSIS
    Interface web locale listant les scripts du dépôt par catégorie, avec lancement direct.

.DESCRIPTION
    Met à jour silencieusement le dépôt (git pull), démarre un petit serveur HTTP local
    (accessible uniquement depuis ce poste, http://localhost) et ouvre l'interface dans
    le navigateur par défaut. Les scripts sélectionnés sont lancés dans une nouvelle
    fenêtre PowerShell, pour garder les prompts interactifs (Connect-MgGraph, etc.) et
    l'affichage console habituel.

    N'installe ni n'importe aucun module : chaque script gère ses propres prérequis (#Requires).

.PARAMETER Port
    Port local utilisé par le serveur (8734 par défaut).

.EXAMPLE
    .\launcher\Start-WebLauncher.ps1
#>

param(
    [int]$Port = 8734
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptsRoot = Join-Path $repoRoot "scripts"
$psExecutable = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }

Write-Host "IT Support KB - lanceur web"
Write-Host "Dossier du dépôt : $repoRoot"

# Mise à jour silencieuse du dépôt, sans jamais bloquer le lancement si ça échoue (pas de réseau, pas de git, etc.)
if (Test-Path (Join-Path $repoRoot ".git")) {
    try {
        Push-Location $repoRoot
        $pullOutput = git pull --ff-only 2>&1
        Write-Host "Mise à jour du dépôt : OK"
    }
    catch {
        Write-Host "Mise à jour du dépôt ignorée (pas de réseau ou modifications locales) : $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

function Get-ScriptCatalog {
    $categories = @()
    if (-not (Test-Path $scriptsRoot)) { return $categories }

    $commonParams = @([System.Management.Automation.PSCmdlet]::CommonParameters) + @([System.Management.Automation.PSCmdlet]::OptionalCommonParameters)

    Get-ChildItem -Path $scriptsRoot -Directory | Sort-Object Name | ForEach-Object {
        $category = $_.Name
        $scripts = @(Get-ChildItem -Path $_.FullName -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
            $help = Get-Help -Name $_.FullName -ErrorAction SilentlyContinue
            $cmd = Get-Command -Name $_.FullName -ErrorAction SilentlyContinue

            $params = @()
            if ($cmd) {
                foreach ($paramName in $cmd.Parameters.Keys) {
                    if ($commonParams -contains $paramName) { continue }
                    $paramInfo = $cmd.Parameters[$paramName]
                    $isMandatory = $false
                    foreach ($attr in $paramInfo.Attributes) {
                        if ($attr -is [System.Management.Automation.ParameterAttribute] -and $attr.Mandatory) { $isMandatory = $true }
                    }
                    $params += [PSCustomObject]@{ Name = $paramName; Mandatory = $isMandatory }
                }
            }

            [PSCustomObject]@{
                Name     = $_.BaseName
                Path     = $_.FullName
                Synopsis = if ($help.Synopsis) { $help.Synopsis.Trim() } else { "" }
                Params   = @($params)
            }
        })
        $categories += [PSCustomObject]@{ Category = $category; Scripts = $scripts }
    }
    return $categories
}

$html = @'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>IT Support KB - Lanceur de scripts</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #f4f5f7;
    --card-bg: #ffffff;
    --text: #1c1f24;
    --muted: #6b7280;
    --accent: #2563eb;
    --accent-contrast: #ffffff;
    --border: #e5e7eb;
    --danger: #dc2626;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #14161a;
      --card-bg: #1f2228;
      --text: #f2f3f5;
      --muted: #9aa1ad;
      --accent: #5b8def;
      --accent-contrast: #0b0d10;
      --border: #2c3038;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: "Segoe UI", system-ui, sans-serif;
    background: var(--bg);
    color: var(--text);
  }
  header {
    padding: 28px 32px 12px;
  }
  header h1 { margin: 0 0 4px; font-size: 22px; }
  header p { margin: 0; color: var(--muted); font-size: 14px; }
  main { padding: 12px 32px 40px; max-width: 1100px; margin: 0 auto; }
  .category { margin-top: 28px; }
  .category h2 {
    font-size: 15px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: var(--muted);
    margin-bottom: 12px;
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 14px;
  }
  .card {
    background: var(--card-bg);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 16px;
    cursor: pointer;
    transition: transform 0.08s ease, border-color 0.08s ease;
  }
  .card:hover { border-color: var(--accent); transform: translateY(-2px); }
  .card h3 { margin: 0 0 6px; font-size: 15px; }
  .card p { margin: 0; font-size: 13px; color: var(--muted); line-height: 1.4; min-height: 34px; }
  .empty { color: var(--muted); padding: 40px; text-align: center; }

  .overlay {
    display: none;
    position: fixed; inset: 0;
    background: rgba(0,0,0,0.45);
    align-items: center; justify-content: center;
    z-index: 10;
  }
  .overlay.open { display: flex; }
  .modal {
    background: var(--card-bg);
    border-radius: 12px;
    width: min(480px, 90vw);
    max-height: 85vh;
    overflow-y: auto;
    padding: 24px;
    border: 1px solid var(--border);
  }
  .modal h2 { margin: 0 0 6px; font-size: 18px; }
  .modal .synopsis { color: var(--muted); font-size: 13px; margin-bottom: 18px; }
  .field { margin-bottom: 14px; }
  .field label { display: block; font-size: 13px; margin-bottom: 4px; }
  .field label .req { color: var(--danger); }
  .field input {
    width: 100%;
    padding: 8px 10px;
    border-radius: 6px;
    border: 1px solid var(--border);
    background: var(--bg);
    color: var(--text);
    font-size: 14px;
  }
  .no-params { color: var(--muted); font-size: 13px; margin-bottom: 14px; }
  .actions { display: flex; gap: 10px; margin-top: 18px; }
  button {
    border: none;
    border-radius: 8px;
    padding: 10px 16px;
    font-size: 14px;
    cursor: pointer;
  }
  .btn-primary { background: var(--accent); color: var(--accent-contrast); flex: 1; }
  .btn-secondary { background: var(--bg); color: var(--text); border: 1px solid var(--border); }
  .btn-close { background: transparent; color: var(--muted); float: right; font-size: 18px; padding: 0 6px; }

  .toast {
    position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);
    background: var(--accent); color: var(--accent-contrast);
    padding: 10px 18px; border-radius: 8px; font-size: 14px;
    opacity: 0; pointer-events: none; transition: opacity 0.2s ease;
  }
  .toast.show { opacity: 1; }
</style>
</head>
<body>
<header>
  <h1>IT Support KB</h1>
  <p>Sélectionnez un script pour le lancer directement.</p>
</header>
<main id="main">
  <p class="empty">Chargement...</p>
</main>

<div class="overlay" id="overlay">
  <div class="modal">
    <button class="btn-close" id="closeModal">✕</button>
    <h2 id="modalTitle"></h2>
    <p class="synopsis" id="modalSynopsis"></p>
    <div id="modalFields"></div>
    <div class="actions">
      <button class="btn-primary" id="runBtn">Lancer dans une nouvelle fenêtre PowerShell</button>
      <button class="btn-secondary" id="copyBtn">Copier la commande</button>
    </div>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
let currentScript = null;

function toast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  setTimeout(() => el.classList.remove('show'), 2500);
}

function openModal(script) {
  currentScript = script;
  document.getElementById('modalTitle').textContent = script.Name;
  document.getElementById('modalSynopsis').textContent = script.Synopsis || '';
  const fieldsEl = document.getElementById('modalFields');
  fieldsEl.innerHTML = '';

  const params = Array.isArray(script.Params) ? script.Params : (script.Params ? [script.Params] : []);
  if (params.length === 0) {
    fieldsEl.innerHTML = '<p class="no-params">Aucun paramètre requis.</p>';
  } else {
    params.forEach(p => {
      const wrap = document.createElement('div');
      wrap.className = 'field';
      wrap.innerHTML = `
        <label for="p_${p.Name}">${p.Name}${p.Mandatory ? ' <span class="req">*</span>' : ''}</label>
        <input type="text" id="p_${p.Name}" data-param="${p.Name}" data-mandatory="${p.Mandatory}">
      `;
      fieldsEl.appendChild(wrap);
    });
  }

  document.getElementById('overlay').classList.add('open');
}

function closeModal() {
  document.getElementById('overlay').classList.remove('open');
  currentScript = null;
}

function collectParams() {
  const inputs = document.querySelectorAll('#modalFields input');
  const values = {};
  let missing = false;
  inputs.forEach(input => {
    const val = input.value.trim();
    if (val) values[input.dataset.param] = val;
    if (input.dataset.mandatory === 'true' && !val) missing = true;
  });
  return { values, missing };
}

function buildCommandPreview(values) {
  const parts = Object.entries(values).map(([k, v]) => `-${k} '${v.replace(/'/g, "''")}'`);
  return `& '${currentScript.Path}' ${parts.join(' ')}`.trim();
}

document.getElementById('closeModal').addEventListener('click', closeModal);
document.getElementById('overlay').addEventListener('click', (e) => {
  if (e.target.id === 'overlay') closeModal();
});

document.getElementById('runBtn').addEventListener('click', async () => {
  const { values, missing } = collectParams();
  if (missing) { toast('Merci de renseigner les champs obligatoires (*)'); return; }

  try {
    const res = await fetch('/api/run', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ path: currentScript.Path, params: values })
    });
    const data = await res.json();
    if (data.ok) {
      toast('Script lancé dans une nouvelle fenêtre PowerShell');
      closeModal();
    } else {
      toast('Erreur : ' + (data.error || 'échec du lancement'));
    }
  } catch (err) {
    toast('Erreur de connexion au serveur local');
  }
});

document.getElementById('copyBtn').addEventListener('click', async () => {
  const { values } = collectParams();
  const cmd = buildCommandPreview(values);
  try {
    await navigator.clipboard.writeText(cmd);
    toast('Commande copiée dans le presse-papiers');
  } catch (err) {
    toast('Impossible de copier automatiquement : ' + cmd);
  }
});

async function loadCatalog() {
  const main = document.getElementById('main');
  try {
    const res = await fetch('/api/catalog');
    const data = await res.json();
    const categories = Array.isArray(data) ? data : (data ? [data] : []);

    if (categories.length === 0) {
      main.innerHTML = '<p class="empty">Aucun script trouvé dans le dossier scripts/.</p>';
      return;
    }

    main.innerHTML = '';
    categories.forEach(cat => {
      const scripts = Array.isArray(cat.Scripts) ? cat.Scripts : (cat.Scripts ? [cat.Scripts] : []);
      const section = document.createElement('section');
      section.className = 'category';
      section.innerHTML = `<h2>${cat.Category}</h2>`;
      const grid = document.createElement('div');
      grid.className = 'grid';
      scripts.forEach(script => {
        const card = document.createElement('div');
        card.className = 'card';
        card.innerHTML = `<h3>${script.Name}</h3><p>${script.Synopsis || ''}</p>`;
        card.addEventListener('click', () => openModal(script));
        grid.appendChild(card);
      });
      section.appendChild(grid);
      main.appendChild(section);
    });
  } catch (err) {
    main.innerHTML = '<p class="empty">Impossible de charger la liste des scripts.</p>';
  }
}

loadCatalog();
</script>
</body>
</html>
'@

function Start-KbHttpListener {
    param([int]$StartPort)

    for ($p = $StartPort; $p -lt $StartPort + 10; $p++) {
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$p/")
        try {
            $listener.Start()
            return @{ Listener = $listener; Port = $p }
        }
        catch {
            continue
        }
    }
    throw "Impossible de démarrer le serveur local (ports $StartPort à $($StartPort + 9) indisponibles)."
}

$server = Start-KbHttpListener -StartPort $Port
$listener = $server.Listener
$actualPort = $server.Port

Write-Host "Interface disponible sur http://localhost:$actualPort/"
Write-Host "Fermez cette fenêtre pour arrêter le serveur."

Start-Process "http://localhost:$actualPort/"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            if ($request.Url.AbsolutePath -eq "/") {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentType = "text/html; charset=utf-8"
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            elseif ($request.Url.AbsolutePath -eq "/api/catalog") {
                $catalog = @(Get-ScriptCatalog)
                if ($catalog.Count -eq 0) {
                    $json = "[]"
                }
                else {
                    $json = $catalog | ConvertTo-Json -Depth 8
                    if ($json.TrimStart().StartsWith("{")) { $json = "[$json]" }
                }
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentType = "application/json; charset=utf-8"
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            elseif ($request.Url.AbsolutePath -eq "/api/run" -and $request.HttpMethod -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream)
                $body = $reader.ReadToEnd() | ConvertFrom-Json

                $resolved = $null
                try { $resolved = (Resolve-Path -Path $body.path -ErrorAction Stop).Path } catch { }

                if ($resolved -and $resolved.StartsWith($scriptsRoot, [System.StringComparison]::OrdinalIgnoreCase) -and $resolved.EndsWith(".ps1")) {
                    $argParts = @()
                    if ($body.params) {
                        foreach ($prop in $body.params.PSObject.Properties) {
                            $value = [string]$prop.Value
                            if ([string]::IsNullOrWhiteSpace($value)) { continue }
                            $escaped = $value -replace "'", "''"
                            $argParts += "-$($prop.Name) '$escaped'"
                        }
                    }
                    $argString = $argParts -join " "
                    $command = "& '$resolved' $argString"
                    Start-Process -FilePath $psExecutable -ArgumentList @("-NoExit", "-Command", $command)
                    $result = @{ ok = $true } | ConvertTo-Json
                }
                else {
                    $response.StatusCode = 400
                    $result = @{ ok = $false; error = "Chemin de script invalide" } | ConvertTo-Json
                }

                $bytes = [System.Text.Encoding]::UTF8.GetBytes($result)
                $response.ContentType = "application/json; charset=utf-8"
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            else {
                $response.StatusCode = 404
            }
        }
        finally {
            $response.OutputStream.Close()
        }
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
