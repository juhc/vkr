param(
  [Parameter(Mandatory = $true)]
  [string]$ProxmoxApiUrl,

  [Parameter(Mandatory = $true)]
  [string]$ProxmoxNode,

  [Parameter(Mandatory = $true)]
  [string]$ApiTokenId,

  [Parameter(Mandatory = $true)]
  [string]$ApiTokenSecret,

  # где хранить скачанный qcow2 (должен быть directory storage, обычно local)
  [string]$IsoStoragePool = "local",

  # куда импортировать диск VM (обычно local-lvm / zfs / ceph и т.д.)
  [string]$DiskStoragePool = "local-lvm",

  # где хранить EFI диск (обычно тот же пул, что и DiskStoragePool)
  [string]$EfiStoragePool = "",

  [string]$Bridge = "vmbr0",

  [Parameter(Mandatory = $true)]
  [string]$TemplateName,

  # если не задан — берём /cluster/nextid
  [int]$Vmid = 0,

  # cloud image URL (Debian/Ubuntu genericcloud qcow2)
  [Parameter(Mandatory = $true)]
  [string]$CloudImageUrl,

  # имя файла, под которым сохранится cloud image на Proxmox storage (например debian-13-genericcloud-amd64.qcow2)
  [Parameter(Mandatory = $true)]
  [string]$CloudImageFilename,

  [int]$Cores = 2,
  [int]$MemoryMb = 2048,

  # cloud-init defaults (можно переопределять на клонах)
  [string]$CiUser = "ansible",
  [string]$SshPublicKeyPath = "",
  [string]$IpConfig0 = "ip=dhcp",

  [switch]$Force
)

$ErrorActionPreference = "Stop"

function CurlJson {
  param(
    [Parameter(Mandatory = $true)][ValidateSet("GET","POST","PUT","DELETE")] [string]$Method,
    [Parameter(Mandatory = $true)][string]$Url,
    [hashtable]$Form = $null
  )

  $hdrAuth = "Authorization: PVEAPIToken=$ApiTokenId=$ApiTokenSecret"
  $args = @("-sk", "-H", $hdrAuth)

  if ($Method -ne "GET") {
    $args += @("-X", $Method)
  }

  if ($Form) {
    foreach ($k in $Form.Keys) {
      $args += @("--data-urlencode", ("{0}={1}" -f $k, $Form[$k]))
    }
  }

  $args += $Url
  $out = & curl.exe @args
  if (-not $out) { return $null }
  return ($out | ConvertFrom-Json)
}

function Wait-Task {
  param([string]$Upid)
  $taskUrl = "{0}/nodes/{1}/tasks/{2}/status" -f $base, $ProxmoxNode, [uri]::EscapeDataString($Upid)
  while ($true) {
    Start-Sleep -Seconds 2
    $st = CurlJson -Method GET -Url $taskUrl
    if (-not $st -or -not $st.data) { continue }
    if ($st.data.status -eq "stopped") {
      if ($st.data.exitstatus -and $st.data.exitstatus -ne "OK") {
        throw ("Task failed: {0} exitstatus={1}" -f $Upid, $st.data.exitstatus)
      }
      return
    }
  }
}

function Normalize-ApiUrl([string]$u) {
  $t = $u.Trim()
  if ($t.EndsWith("/")) { $t = $t.TrimEnd("/") }
  if ($t -notmatch "/api2/json$") {
    $t = $t.TrimEnd("/") + "/api2/json"
  }
  return $t
}

$base = Normalize-ApiUrl $ProxmoxApiUrl

if (-not $EfiStoragePool) { $EfiStoragePool = $DiskStoragePool }

function Storage-HasVolid {
  param([string]$StorageId, [string]$Volid)
  $u = "{0}/nodes/{1}/storage/{2}/content" -f $base, $ProxmoxNode, $StorageId
  $list = CurlJson -Method GET -Url $u
  if (-not $list -or -not $list.data) { return $false }
  foreach ($item in $list.data) {
    if ($item.volid -eq $Volid) { return $true }
  }
  return $false
}

Write-Host ("Proxmox API: {0}" -f $base)
Write-Host ("Node      : {0}" -f $ProxmoxNode)
Write-Host ("Template  : {0}" -f $TemplateName)

if ($Vmid -le 0) {
  $next = CurlJson -Method GET -Url ("{0}/cluster/nextid" -f $base)
  $Vmid = [int]$next.data
}
Write-Host ("VMID      : {0}" -f $Vmid)

# 1) download cloud image to storage as content=import
# Это самый удобный вариант, потому что потом можно использовать `import-from=<storage>:import/<file>`.
$storageFilename = $CloudImageFilename
$importVolid = ("{0}:import/{1}" -f $IsoStoragePool, $storageFilename)
$already = Storage-HasVolid -StorageId $IsoStoragePool -Volid $importVolid
if ($already) {
  Write-Host ("Cloud image already present: {0}" -f $importVolid)
} else {
  $dlUrl = "{0}/nodes/{1}/storage/{2}/download-url" -f $base, $ProxmoxNode, $IsoStoragePool
  $dl = CurlJson -Method POST -Url $dlUrl -Form @{
    url      = $CloudImageUrl
    content  = "import"
    filename = $storageFilename
  }
  if (-not $dl -or -not $dl.data) {
    throw "download-url did not return UPID. Проверьте, что storage dir-based и поддерживает content=import."
  }
  Wait-Task -Upid $dl.data
  Write-Host ("Downloaded cloud image: {0}" -f $importVolid)
}

# 2) create VM (без диска) + базовая конфигурация
$createUrl = "{0}/nodes/{1}/qemu" -f $base, $ProxmoxNode
$create = CurlJson -Method POST -Url $createUrl -Form @{
  vmid    = $Vmid
  name    = $TemplateName
  cores   = $Cores
  memory  = $MemoryMb
  agent   = 1
  scsihw  = "virtio-scsi-pci"
  net0    = ("virtio,bridge={0}" -f $Bridge)
  ostype  = "l26"
  bios    = "ovmf"
  machine = "q35"
}
if ($create -and $create.data) { Wait-Task -Upid $create.data }
Write-Host "VM created"

# 3) attach disk via import-from and add cloud-init drive
$importFrom = $importVolid
$cfgUrl = "{0}/nodes/{1}/qemu/{2}/config" -f $base, $ProxmoxNode, $Vmid
$cfg = CurlJson -Method POST -Url $cfgUrl -Form @{
  scsi0     = ("{0}:0,import-from={1}" -f $DiskStoragePool, $importFrom)
  efidisk0  = ("{0}:0,efitype=4m,pre-enrolled-keys=1" -f $EfiStoragePool)
  ide2      = ("{0}:cloudinit" -f $DiskStoragePool)
  boot      = "order=scsi0;net0"
  bootdisk  = "scsi0"
  serial0   = "socket"
  # Важно: vga=serial0 часто ломает noVNC консоль (она "отваливается"). Оставляем serial0 для debug,
  # но VGA делаем обычный, чтобы консоль Proxmox стабильно открывалась.
  vga       = "std"
  ipconfig0 = $IpConfig0
  ciuser    = $CiUser
}
if ($cfg -and $cfg.data) { Wait-Task -Upid $cfg.data }

if ($SshPublicKeyPath -and (Test-Path $SshPublicKeyPath)) {
  $key = (Get-Content $SshPublicKeyPath -Raw).Trim()
  # Proxmox expects sshkeys as urlencoded string
  $cfg2 = CurlJson -Method POST -Url $cfgUrl -Form @{ sshkeys = $key }
  if ($cfg2 -and $cfg2.data) { Wait-Task -Upid $cfg2.data }
  Write-Host "SSH key applied"
}

# 5) convert to template
$tplUrl = "{0}/nodes/{1}/qemu/{2}/template" -f $base, $ProxmoxNode, $Vmid
$tpl = CurlJson -Method POST -Url $tplUrl
if ($tpl -and $tpl.data) { Wait-Task -Upid $tpl.data }

Write-Host ("Template ready: {0} (VMID {1})" -f $TemplateName, $Vmid)

