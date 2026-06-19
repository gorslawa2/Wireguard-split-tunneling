[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "domains_ru.conf"
$SubdomainsFile = Join-Path $ScriptDir "subdomains_popular.txt"
$StateFile = Join-Path $ScriptDir "find_subdomains_state.json"

# Ограничения
$MaxDomainsToCheck = 100  # Максимум доменов для проверки за один запуск
$RequestDelay = 200       # Задержка между запросами (мс)

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл domains_ru.conf не найден!" -ForegroundColor Red
    pause
    exit
}

if (-not (Test-Path $SubdomainsFile)) {
    Write-Host "Файл subdomains.txt не найден!" -ForegroundColor Red
    pause
    exit
}

Write-Host "Загрузка словаря поддоменов..." -ForegroundColor Cyan
$SubdomainList = Get-Content $SubdomainsFile | Where-Object { $_ -ne "" -and $_ -notlike "#*" } | ForEach-Object { $_.Trim() }
Write-Host "Загружено поддоменов для проверки: $($SubdomainList.Count)" -ForegroundColor Green
Write-Host ""

# Проверяем наличие сохраненного состояния
$ResumeMode = $false
$ProcessedDomains = @()
if (Test-Path $StateFile) {
    Write-Host "Найден файл состояния. Загрузка..." -ForegroundColor Yellow
    try {
        $State = Get-Content $StateFile | ConvertFrom-Json
        $ResumeMode = $true
        $ProcessedDomains = $State.ProcessedDomains
        Write-Host "Режим возобновления: уже обработано $($ProcessedDomains.Count) доменов" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка чтения файла состояния. Начинаем сначала." -ForegroundColor Red
        $ResumeMode = $false
    }
}
Write-Host ""

Write-Host "Чтение текущего списка доменов..." -ForegroundColor Cyan
$Lines = Get-Content $ConfigFile
$ExistingDomains = @{}
$NewLines = @()

# Парсим существующие домены
foreach ($Line in $Lines) {
    $TrimmedLine = $Line.Trim()
    
    if ($TrimmedLine -eq "" -or $TrimmedLine -like "#*") {
        continue
    }
    
    # Извлекаем домен 2-го уровня (например, из mail.yandex.ru -> yandex.ru)
    $Parts = $TrimmedLine.Split('.')
    if ($Parts.Count -ge 2) {
        $BaseDomain = "$($Parts[-2]).$($Parts[-1])"
        
        if (-not $ExistingDomains.ContainsKey($BaseDomain)) {
            $ExistingDomains[$BaseDomain] = @()
        }
        
        # Сохраняем существующие поддомены
        if ($Parts.Count -gt 2) {
            $Subdomain = $Parts[0]
            $ExistingDomains[$BaseDomain] += $Subdomain
        }
    }
}

Write-Host "Найдено уникальных доменов 2-го уровня: $($ExistingDomains.Count)" -ForegroundColor Green

# Ограничиваем количество доменов для проверки
$DomainsToCheck = @{}
$Count = 0
foreach ($Key in $ExistingDomains.Keys) {
    if ($Count -ge $MaxDomainsToCheck) { break }
    
    # Пропускаем уже обработанные домены в режиме возобновления
    if ($ResumeMode -and $ProcessedDomains -contains $Key) {
        continue
    }
    
    $DomainsToCheck[$Key] = $ExistingDomains[$Key]
    $Count++
}

if ($ExistingDomains.Count -gt $MaxDomainsToCheck) {
    Write-Host "Ограничено до первых $MaxDomainsToCheck доменов (всего: $($ExistingDomains.Count))" -ForegroundColor Yellow
}
Write-Host ""

$AddedCount = 0
$CheckedCount = 0
$TotalToCheck = $DomainsToCheck.Count * $SubdomainList.Count

Write-Host "Проверка поддоменов..." -ForegroundColor Cyan
Write-Host "Всего проверок: $TotalToCheck" -ForegroundColor Yellow
Write-Host "Задержка между запросами: ${RequestDelay}мс" -ForegroundColor Yellow
Write-Host ""

foreach ($BaseDomain in $DomainsToCheck.Keys) {
    $ExistingSubs = $ExistingDomains[$BaseDomain]
    $SeenIPs = @{}  # Отслеживаем уже добавленные IP для этого домена
    
    # Получаем IP базового домена 2-го уровня
    $BaseIP = $null
    try {
        $BaseIPs = [System.Net.Dns]::GetHostAddresses($BaseDomain) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        if ($BaseIPs.Count -gt 0) {
            $BaseIP = $BaseIPs[0].IPAddressToString
            $SeenIPs[$BaseIP] = $true  # Базовый IP уже "занят"
        }
    } catch {
        # Базовый домен не резолвится
    }
    
    foreach ($Subdomain in $SubdomainList) {
        # Пропускаем если поддомен уже существует
        if ($ExistingSubs -contains $Subdomain) {
            continue
        }
        
        $FullDomain = "$Subdomain.$BaseDomain"
        $CheckedCount++
        
        # Проверяем существование через DNS
        try {
            $IPs = [System.Net.Dns]::GetHostAddresses($FullDomain) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
            
            if ($IPs.Count -gt 0) {
                $IP = $IPs[0].IPAddressToString
                
                # Если IP поддомена совпадает с IP базового домена - пропускаем
                if ($BaseIP -and $IP -eq $BaseIP) {
                    Write-Host "[~] Пропущен (same as base): $FullDomain -> $IP" -ForegroundColor DarkGray
                    continue
                }
                
                # Если этот IP уже добавлен для другого поддомена - пропускаем
                if ($SeenIPs.ContainsKey($IP)) {
                    Write-Host "[~] Пропущен (duplicate IP): $FullDomain -> $IP" -ForegroundColor DarkGray
                    continue
                }
                
                # Добавляем новый поддомен в список и СРАЗУ в domains_ru.conf
                $NewLines += $FullDomain
                Add-Content -Path $ConfigFile -Value $FullDomain -Encoding UTF8
                $AddedCount++
                Write-Host "[+] Найден: $FullDomain -> $IP (добавлен в domains_ru.conf)" -ForegroundColor Green
                
                # Отмечаем IP как использованный
                $SeenIPs[$IP] = $true
                
                # Обновляем список существующих поддоменов
                $ExistingDomains[$BaseDomain] += $Subdomain
            }
        } catch {
            # Домен не существует - пропускаем
        }
        
        # Задержка чтобы не спамить DNS
        Start-Sleep -Milliseconds $RequestDelay
        
        # Прогресс
        if ($CheckedCount % 100 -eq 0) {
            Write-Host "  Проверено: $CheckedCount / $TotalToCheck" -ForegroundColor DarkGray
        }
    }
    
    # Сохраняем состояние после обработки каждого базового домена
    $ProcessedDomains += $BaseDomain
    $State = @{
        ProcessedDomains = $ProcessedDomains
        LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    $State | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
}

if ($AddedCount -gt 0) {
    Write-Host ""
    Write-Host "Добавление найденных поддоменов в файл..." -ForegroundColor Cyan
    
    # Создаём резервную копию
    $BackupFile = $ConfigFile + ".backup"
    Copy-Item $ConfigFile $BackupFile -Force
    Write-Host "Создана резервная копия: $BackupFile" -ForegroundColor Cyan
    
    # Добавляем новые домены в конец файла
    $CurrentContent = Get-Content $ConfigFile
    $CurrentContent += ""
    $CurrentContent += "# Новые поддомены найдены $(Get-Date -Format 'dd.MM.yyyy HH:mm')"
    $CurrentContent += $NewLines
    
    Set-Content -Path $ConfigFile -Value $CurrentContent -Encoding UTF8
    
    Write-Host ""
    Write-Host "Результаты:" -ForegroundColor Cyan
    Write-Host "Проверено комбинаций: $CheckedCount" -ForegroundColor White
    Write-Host "Найдено новых поддоменов: $AddedCount" -ForegroundColor Green
    Write-Host "Файл обновлён: $ConfigFile" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Новых поддоменов не найдено." -ForegroundColor Yellow
    Write-Host "Проверено комбинаций: $CheckedCount" -ForegroundColor White
}

# Удаляем файл состояния после успешного завершения
if (Test-Path $StateFile) {
    Remove-Item $StateFile -Force
    Write-Host "Файл состояния удалён: $StateFile" -ForegroundColor DarkGray
}

pause
