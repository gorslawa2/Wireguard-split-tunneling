[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Gateway = "192.168.3.1"
$ConfigFile = Join-Path $PSScriptRoot "domains.conf"

$Domains = Get-Content $ConfigFile | Where-Object { $_ -ne "" -and $_ -notlike "#*" }

foreach ($Domain in $Domains) {
    $Domain = $Domain.Trim()
    $IPs = [System.Net.Dns]::GetHostAddresses($Domain) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }

    foreach ($IP in $IPs) {
        $ipStr = $IP.IPAddressToString
        route.exe delete $ipStr
    }
    Write-Host "Удалено: $Domain"
}

Write-Host "Маршруты удалены"
pause