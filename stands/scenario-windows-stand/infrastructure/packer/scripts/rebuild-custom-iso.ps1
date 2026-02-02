$ErrorActionPreference = "Stop"

param(
  # Папка с распакованным ISO (внутри должны быть boot\, efi\microsoft\boot\ и т.д.)
  [Parameter(Mandatory = $true)]
  [string]$SourceDir,

  # Путь к выходному ISO
  [Parameter(Mandatory = $true)]
  [string]$OutputIso
)

function Find-Oscdimg {
  $candidates = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
  )
  foreach ($p in $candidates) {
    if (Test-Path $p) { return $p }
  }
  throw "oscdimg.exe не найден. Установите Windows ADK (Deployment Tools -> Oscdimg)."
}

$SourceDir = (Resolve-Path $SourceDir).Path
$outDir = Split-Path -Parent $OutputIso
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$etfsboot = Join-Path $SourceDir "boot\etfsboot.com"
$efisys   = Join-Path $SourceDir "efi\microsoft\boot\efisys.bin"

if (-not (Test-Path $etfsboot)) { throw "Не найден boot\etfsboot.com в $SourceDir" }
if (-not (Test-Path $efisys)) { throw "Не найден efi\microsoft\boot\efisys.bin в $SourceDir" }

$oscdimg = Find-Oscdimg

Write-Host "SourceDir : $SourceDir" -ForegroundColor Cyan
Write-Host "OutputIso : $OutputIso" -ForegroundColor Cyan
Write-Host "Oscdimg   : $oscdimg" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $OutputIso) { Remove-Item $OutputIso -Force }

# UEFI + BIOS bootable ISO
$bootData = "-bootdata:2#p0,e,b`"$etfsboot`"#pEF,e,b`"$efisys`""

& $oscdimg -m -o -u2 -udfver102 $bootData $SourceDir $OutputIso

Write-Host ""
Write-Host "Готово: $OutputIso" -ForegroundColor Green
Get-FileHash -Algorithm SHA256 $OutputIso | Format-List

