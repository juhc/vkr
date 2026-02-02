param(
  # Можно передать отдельный vars-файл для server/client
  [string]$VarsFile = ""
)

$ErrorActionPreference = "Stop"

$base = Split-Path $PSScriptRoot -Parent

$common = Join-Path $base "variables.common.pkrvars.hcl"
$secrets = Join-Path $base "variables.secrets.pkrvars.hcl"

if (-not $VarsFile) {
  throw "Передайте -VarsFile (например .\\cloudinit\\variables.cloudinit.linux-server.pkrvars.hcl). Используйте create-templates.ps1 для server+client."
}

$vars = $VarsFile
if (!(Test-Path $vars)) {
  throw "Не найден vars-файл: $vars. Создайте его из соответствующего *.example."
}

function GetHcl([string]$file,[string]$key) {
  foreach($line in Get-Content $file){
    $t=$line.Trim()
    if($t -eq "" -or $t.StartsWith("#")){ continue }
    if($t -match ("^\s*{0}\s*=\s*(.+?)\s*$" -f [regex]::Escape($key))){
      return $matches[1].Trim().Trim('"').Trim("'")
    }
  }
  return $null
}

$apiUrl = GetHcl $common "proxmox_api_url"
$node = GetHcl $common "proxmox_node"
$isoPool = GetHcl $common "iso_storage_pool"
$diskPool = GetHcl $common "storage_pool"
$efiPool = GetHcl $common "efi_storage_pool"
$bridge = GetHcl $common "proxmox_bridge"

$tokenId = GetHcl $secrets "proxmox_api_token_id"
$tokenSecret = GetHcl $secrets "proxmox_api_token_secret"

$tplName = GetHcl $vars "template_name"
$imgUrl = GetHcl $vars "cloud_image_url"
$imgFile = GetHcl $vars "cloud_image_filename"
$cores = [int](GetHcl $vars "cpu_cores")
$mem = [int](GetHcl $vars "memory_mb")
$ciUser = GetHcl $vars "ci_user"
$sshKey = GetHcl $vars "ssh_public_key_path"
$ipcfg = GetHcl $vars "ipconfig0"

& (Join-Path $base "scripts\\New-ProxmoxCloudInitTemplate.ps1") `
  -ProxmoxApiUrl $apiUrl `
  -ProxmoxNode $node `
  -ApiTokenId $tokenId `
  -ApiTokenSecret $tokenSecret `
  -IsoStoragePool $isoPool `
  -DiskStoragePool $diskPool `
  -EfiStoragePool $efiPool `
  -Bridge $bridge `
  -TemplateName $tplName `
  -CloudImageUrl $imgUrl `
  -CloudImageFilename $imgFile `
  -Cores $cores `
  -MemoryMb $mem `
  -CiUser $ciUser `
  -SshPublicKeyPath $sshKey `
  -IpConfig0 $ipcfg

