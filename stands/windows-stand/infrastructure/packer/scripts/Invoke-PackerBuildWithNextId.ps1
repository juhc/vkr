$ErrorActionPreference = "Stop"

param(
  # Папка шаблона packer: windows-10 / windows-11 / windows-server / domain-controller
  [Parameter(Mandatory = $true)]
  [ValidateSet("windows-10","windows-11","windows-server","domain-controller")]
  [string]$Target,

  # Путь к common vars (НЕсекретные)
  [string]$CommonVars = (Join-Path $PSScriptRoot "..\\variables.common.pkrvars.hcl"),

  # Путь к secrets vars (СЕКРЕТЫ)
  [string]$SecretsVars = (Join-Path $PSScriptRoot "..\\variables.secrets.pkrvars.hcl"),

  # Путь к vars конкретной ОС
  [string]$OsVars = $null
)

function Get-HclValue {
  param([string]$File, [string]$Key)
  if (-not (Test-Path $File)) { return $null }
  $content = Get-Content $File -Raw
  if ($content -match ("(?m)^\s*{0}\s*=\s*[""']?([^""'\r\n#]+)[""']?\s*$" -f [Regex]::Escape($Key))) {
    return $matches[1].Trim()
  }
  return $null
}

if (-not $OsVars) {
  $OsVars = Join-Path (Join-Path $PSScriptRoot "..") (Join-Path $Target "variables.pkrvars.hcl")
}

foreach ($f in @($CommonVars,$SecretsVars,$OsVars)) {
  if (-not (Test-Path $f)) { throw "Не найден var-file: $f" }
}

$api = Get-HclValue -File $CommonVars -Key "proxmox_api_url"
$tokenId = Get-HclValue -File $SecretsVars -Key "proxmox_api_token_id"
$tokenSecret = Get-HclValue -File $SecretsVars -Key "proxmox_api_token_secret"

if (-not $api) { throw "В $CommonVars нет proxmox_api_url" }
if (-not $tokenId -or -not $tokenSecret) { throw "В $SecretsVars нет proxmox_api_token_id/proxmox_api_token_secret" }

# Разрешаем self-signed
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$base = $api.TrimEnd("/")
$nextidUrl = "$base/cluster/nextid"
$authHeader = "PVEAPIToken=$tokenId=$tokenSecret"

Write-Host "Proxmox API: $base" -ForegroundColor Cyan
Write-Host "NextID URL : $nextidUrl" -ForegroundColor Cyan
Write-Host "Target     : $Target" -ForegroundColor Cyan

$resp = Invoke-RestMethod -Method Get -Uri $nextidUrl -Headers @{ Authorization = $authHeader }
$nextid = [int]$resp.data

Write-Host "Свободный VMID: $nextid" -ForegroundColor Green

$targetDir = Join-Path (Join-Path $PSScriptRoot "..") $Target
Push-Location $targetDir
try {
  & packer init . | Out-Host
  & packer build -var-file="..\variables.common.pkrvars.hcl" -var-file="..\variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" -var "vm_id=$nextid" . | Out-Host
} finally {
  Pop-Location
}

