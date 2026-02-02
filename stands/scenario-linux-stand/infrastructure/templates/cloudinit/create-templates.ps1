$ErrorActionPreference = "Stop"

$here = $PSScriptRoot
$varsServer = Join-Path $here "variables.cloudinit.linux-server.pkrvars.hcl"
$varsClient = Join-Path $here "variables.cloudinit.linux-client.pkrvars.hcl"

if (!(Test-Path $varsServer)) {
  throw "Создайте $varsServer из variables.cloudinit.linux-server.pkrvars.hcl.example"
}
if (!(Test-Path $varsClient)) {
  throw "Создайте $varsClient из variables.cloudinit.linux-client.pkrvars.hcl.example"
}

Write-Host "== Create linux-server cloud-init template ==" -ForegroundColor Cyan
& (Join-Path $here "create-template.ps1") -VarsFile $varsServer

Write-Host "== Create linux-client cloud-init template ==" -ForegroundColor Cyan
& (Join-Path $here "create-template.ps1") -VarsFile $varsClient

