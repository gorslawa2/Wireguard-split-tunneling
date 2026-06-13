[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Gateway = "192.168.3.1"
$Mask = "255.255.255.255"
$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "domains.conf"

# Проверка параметра -p (постоянные маршруты)
$Persistent = $false
if ($args -contains '-p' -or $args -contains '/p') {
    $Persistent = $true
    Write-Host "Режим: Постоянные маршруты (-p)" -ForegroundColor Cyan
}

# Автоматическое определение индекса активного сетевого интерфейса
$IfIndex = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Where-Object { $_.NextHop -ne '0.0.0.0' }).ifIndex

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл domains.conf не найден!" -ForegroundColor Red
    pause
    exit
}

$Domains = Get-Content $ConfigFile | Where-Object { $_ -ne "" -and $_ -notlike "#*" }

foreach ($Domain in $Domains) {
    $Domain = $Domain.Trim()
    try {
        $IPs = [System.Net.Dns]::GetHostAddresses($Domain) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
    } catch {
        Write-Host "Не удалось найти IP для $Domain" -ForegroundColor Yellow
        continue
    }

    foreach ($IP in $IPs) {
        $ipStr = $IP.IPAddressToString
        route.exe delete $ipStr 2>$null
        
        # Формируем команду с учетом параметра -p
        if ($Persistent) {
            $result = route.exe add -p $ipStr mask $Mask $Gateway metric 1 if $IfIndex
        } else {
            $result = route.exe add $ipStr mask $Mask $Gateway metric 1 if $IfIndex
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Ошибка добавления $ipStr : $result" -ForegroundColor Red
        } else {
            $persistentText = if ($Persistent) { " (постоянный)" } else { "" }
            Write-Host "Добавлен маршрут: $ipStr -> $Gateway (metric 1, if $IfIndex)$persistentText" -ForegroundColor Green
        }
    }
    Write-Host "Обработано: $Domain IP: $($IPs.IPAddressToString)"
}

pause