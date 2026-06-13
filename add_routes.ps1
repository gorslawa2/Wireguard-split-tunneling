[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Gateway = "192.168.3.1"
$Mask = "255.255.255.255"
$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "domains.conf"

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
        $result = route.exe add $ipStr mask $Mask $Gateway metric 1 if $IfIndex
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Ошибка добавления $ipStr : $result" -ForegroundColor Red
        } else {
            Write-Host "Добавлен маршрут: $ipStr -> $Gateway (metric 1, if $IfIndex)" -ForegroundColor Green
        }
    }
    Write-Host "Обработано: $Domain IP: $($IPs.IPAddressToString)"
}

pause