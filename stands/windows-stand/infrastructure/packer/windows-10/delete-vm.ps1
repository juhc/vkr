# Скрипт для удаления VM из Proxmox через API
# Использование: .\delete-vm.ps1 -VMID 9001

param(
    [Parameter(Mandatory=$true)]
    [int]$VMID,
    
    [string]$ProxmoxURL = "https://127.0.0.1:8006",
    [string]$Node = "pve"
)

# Загружаем секреты из общего файла variables.secrets.pkrvars.hcl
$secretsFile = Join-Path (Split-Path $PSScriptRoot -Parent) "variables.secrets.pkrvars.hcl"

# Простой парсинг HCL файла (базовый)
function Get-HCLValue {
    param([string]$File, [string]$Key)
    $content = Get-Content $File -Raw
    if ($content -match "${Key}\s*=\s*[""']?([^""'\s]+)[""']?") {
        return $matches[1]
    }
    return $null
}

# Получаем токен из secrets файла
$tokenId = Get-HCLValue -File $secretsFile -Key "proxmox_api_token_id"
$tokenSecret = Get-HCLValue -File $secretsFile -Key "proxmox_api_token_secret"

if (-not $tokenId -or -not $tokenSecret) {
    Write-Host "Ошибка: Не удалось найти proxmox_api_token_id или proxmox_api_token_secret в $secretsFile" -ForegroundColor Red
    exit 1
}

Write-Host "=== Удаление VM $VMID из Proxmox ===" -ForegroundColor Cyan
Write-Host "Proxmox URL: $ProxmoxURL" -ForegroundColor Gray
Write-Host "Node: $Node" -ForegroundColor Gray
Write-Host "Token ID: $tokenId" -ForegroundColor Gray

# Игнорируем ошибки SSL сертификата
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Получаем ticket для аутентификации
$authUrl = "$ProxmoxURL/api2/json/access/ticket"
$authBody = @{
    username = $tokenId
    password = $tokenSecret
} | ConvertTo-Json

try {
    $authResponse = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/json" -SkipCertificateCheck
    $ticket = $authResponse.data.ticket
    $CSRFPreventionToken = $authResponse.data.CSRFPreventionToken
    
    if (-not $ticket) {
        Write-Host "Ошибка: Не удалось получить ticket. Проверьте токен." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Аутентификация успешна" -ForegroundColor Green
    
    # Удаляем VM
    $deleteUrl = "$ProxmoxURL/api2/json/nodes/$Node/qemu/$VMID"
    $headers = @{
        "Cookie" = "PVEAuthCookie=$ticket"
        "CSRFPreventionToken" = $CSRFPreventionToken
    }
    
    Write-Host "Удаление VM $VMID..." -ForegroundColor Yellow
    $deleteResponse = Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers -SkipCertificateCheck
    
    Write-Host "VM $VMID успешно удалена!" -ForegroundColor Green
    Write-Host "Ответ: $($deleteResponse | ConvertTo-Json)" -ForegroundColor Gray
    
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "VM $VMID не найдена (возможно, уже удалена)" -ForegroundColor Yellow
    } else {
        Write-Host "Ошибка при удалении VM: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Детали: $($_.Exception)" -ForegroundColor Red
        exit 1
    }
}
