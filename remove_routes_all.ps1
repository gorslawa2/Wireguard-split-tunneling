[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Gateway = "192.168.3.1"
$ConfigFile = Join-Path $PSScriptRoot "domains.conf"

# Проверка параметра -p (постоянные маршруты)
$Persistent = $false
if ($args -contains '-p' -or $args -contains '/p') {
    $Persistent = $true
    Write-Host "Режим: Удаление постоянных маршрутов (-p)" -ForegroundColor Cyan
}

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл domains.conf не найден!" -ForegroundColor Red
    pause
    exit
}

# Получаем все маршруты через шлюз
$Routes = route.exe print | Select-String $Gateway

Write-Host "Поиск маршрутов для удаления..." -ForegroundColor Cyan

$DeletedCount = 0

foreach ($Route in $Routes) {
    $RouteLine = $Route.Line.Trim()
    
    # Парсим IP-адрес из строки маршрута
    if ($RouteLine -match '^\s*(\d+\.\d+\.\d+\.\d+)\s+') {
        $IP = $Matches[1]
        
        $Deleted = $false
        
        # Удаляем маршрут в зависимости от режима
        if ($Persistent) {
            route.exe delete -p $IP 2>$null
            if ($LASTEXITCODE -eq 0) { $Deleted = $true }
        } else {
            route.exe delete $IP 2>$null
            if ($LASTEXITCODE -eq 0) { $Deleted = $true }
            
            # Если не удалился временный, пробуем удалить постоянный
            if (-not $Deleted) {
                route.exe delete -p $IP 2>$null
                if ($LASTEXITCODE -eq 0) { $Deleted = $true }
            }
        }
        
        if ($Deleted) {
            $persistentText = if ($Persistent) { " (постоянный)" } else { "" }
            Write-Host "Удалён маршрут: $IP$persistentText" -ForegroundColor Green
            $DeletedCount++
        }
    }
}

Write-Host "`nВсего удалено маршрутов: $DeletedCount" -ForegroundColor Cyan
pause
