[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "domains_ru.conf"

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл domains_ru.conf не найден!" -ForegroundColor Red
    pause
    exit
}

Write-Host "Проверка доменов..." -ForegroundColor Cyan
Write-Host ""

$Lines = Get-Content $ConfigFile
$NewLines = @()
$CheckedCount = 0
$InvalidCount = 0

foreach ($Line in $Lines) {
    $TrimmedLine = $Line.Trim()
    
    # Пропускаем пустые строки и комментарии
    if ($TrimmedLine -eq "" -or $TrimmedLine -like "#*") {
        $NewLines += $Line
        continue
    }
    
    $Domain = $TrimmedLine
    $CheckedCount++
    
    # Проверяем существование через DNS-резолвинг
    try {
        $IPs = [System.Net.Dns]::GetHostAddresses($Domain) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        
        if ($IPs.Count -gt 0) {
            $NewLines += $Line
            Write-Host "[OK] $Domain -> $($IPs[0].IPAddressToString)" -ForegroundColor Green
        } else {
            $NewLines += "# НЕДОСТУПЕН: $Line"
            $InvalidCount++
            Write-Host "[FAIL] $Domain - нет IPv4 адресов" -ForegroundColor Yellow
        }
    } catch {
        $NewLines += "# НЕДОСТУПЕН: $Line"
        $InvalidCount++
        Write-Host "[FAIL] $Domain - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Небольшая задержка чтобы не спамить DNS
    Start-Sleep -Milliseconds 100
}

# Сохраняем результат
$BackupFile = $ConfigFile + ".backup"
Copy-Item $ConfigFile $BackupFile -Force
Write-Host ""
Write-Host "Создана резервная копия: $BackupFile" -ForegroundColor Cyan

Set-Content -Path $ConfigFile -Value $NewLines -Encoding UTF8

Write-Host ""
Write-Host "Проверка завершена." -ForegroundColor Cyan
Write-Host "Проверено: $CheckedCount" -ForegroundColor White
Write-Host "Недоступно: $InvalidCount" -ForegroundColor Red
Write-Host "Результат сохранён в: $ConfigFile" -ForegroundColor Green
pause
