# WireGuard Split Tunneling - Разбор кода

## add_routes.ps1

```powershell
# Строка 1: UTF-8 кодировка для вывода кириллицы
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Строка 2: IP локального шлюза (заменить на свой)
$Gateway = "192.168.3.1"

# Строка 3: Маска /32 для отдельных хостов
$Mask = "255.255.255.255"

# Строка 4: Директория скрипта
$ScriptDir = $PSScriptRoot

# Строка 6: Файл со списком доменов
$ConfigFile = Join-Path $ScriptDir "domains_ru.conf"

# Строки 9-13: Проверка флага -p
# Без -p: маршруты временные (удаляются после перезагрузки)
# С -p: постоянные (сохраняются в реестре)
$Persistent = $false
if ($args -contains '-p' -or $args -contains '/p') {
    $Persistent = $true
}

# Строки 15-19: Проверка существования файла
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл не найден!" -ForegroundColor Red
    pause
    exit
}

# Строки 21-23: Чтение списка доменов
$Domains = Get-Content $ConfigFile | Where-Object { $_ -ne "" -and $_ -notlike "#*" }

Write-Host "Добавление маршрутов..." -ForegroundColor Cyan

# Строки 27-50: Обработка каждого домена
foreach ($Domain in $Domains) {
    try {
        # DNS-резолвинг: получаем IPv4 адреса
        $IPs = [System.Net.Dns]::GetHostAddresses($Domain) | \
            Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        
        if ($IPs.Count -gt 0) {
            foreach ($IP in $IPs) {
                $IPAddress = $IP.IPAddressToString
                
                # Удаляем старый маршрут (если есть)
                route.exe delete $IPAddress 2>$null
                
                # Добавляем новый маршрут через локальный шлюз
                if ($Persistent) {
                    route.exe add -p $IPAddress mask $Mask $Gateway metric 1
                } else {
                    route.exe add $IPAddress mask $Mask $Gateway metric 1
                }
                
                Write-Host "[OK] $Domain -> $IPAddress" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[FAIL] $Domain - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Готово." -ForegroundColor Cyan
pause
```

---

## remove_routes_all.ps1

```powershell
# Строка 1: UTF-8 кодировка
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Строка 2: IP шлюза (должен совпадать с add_routes.ps1)
$Gateway = "192.168.3.1"

# Строки 5-10: Проверка флага -p
$Persistent = $false
if ($args -contains '-p' -or $args -contains '/p') {
    $Persistent = $true
}

# Строки 12-16: Проверка файла domains.conf
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл не найден!" -ForegroundColor Red
    pause
    exit
}

# Строка 19: Сканируем таблицу маршрутизации
# Ищем все строки с IP шлюза
$Routes = route.exe print | Select-String $Gateway

$DeletedCount = 0

# Строки 25-55: Парсим и удаляем каждый маршрут
foreach ($Route in $Routes) {
    $RouteLine = $Route.Line.Trim()
    
    # Регулярка: извлекаем IP из строки маршрута
    if ($RouteLine -match '^\s*(\d+\.\d+\.\d+\.\d+)\s+') {
        $IP = $Matches[1]
        
        $Deleted = $false
        
        # Режим -p: удаляем только постоянный маршрут
        if ($Persistent) {
            route.exe delete -p $IP 2>$null
            if ($LASTEXITCODE -eq 0) { $Deleted = $true }
        } else {
            # Без -p: сначала пробуем временный
            route.exe delete $IP 2>$null
            if ($LASTEXITCODE -eq 0) { $Deleted = $true }
            
            # Если не вышло — пробуем постоянный
            if (-not $Deleted) {
                route.exe delete -p $IP 2>$null
                if ($LASTEXITCODE -eq 0) { $Deleted = $true }
            }
        }
        
        if ($Deleted) {
            Write-Host "Удалён: $IP" -ForegroundColor Green
            $DeletedCount++
        }
    }
}

Write-Host "Всего удалено: $DeletedCount" -ForegroundColor Cyan
pause
```

---

## check_domains.ps1

```powershell
# Строка 1: UTF-8 кодировка
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Строка 3: Файл для проверки
$ConfigFile = Join-Path $PSScriptRoot "domains_ru.conf"

# Строки 5-9: Проверка существования файла
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Файл не найден!" -ForegroundColor Red
    pause
    exit
}

# Строка 14: Читаем все строки файла
$Lines = Get-Content $ConfigFile
$NewLines = @()
$CheckedCount = 0
$InvalidCount = 0

# Строки 19-51: Проверяем каждый домен
foreach ($Line in $Lines) {
    $TrimmedLine = $Line.Trim()
    
    # Пропускаем пустые строки и комментарии
    if ($TrimmedLine -eq "" -or $TrimmedLine -like "#*") {
        $NewLines += $Line
        continue
    }
    
    $Domain = $TrimmedLine
    $CheckedCount++
    
    # DNS-резолвинг: проверяем доступность домена
    try {
        $IPs = [System.Net.Dns]::GetHostAddresses($Domain) | \
            Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        
        if ($IPs.Count -gt 0) {
            # Домен доступен — оставляем как есть
            $NewLines += $Line
            Write-Host "[OK] $Domain -> $($IPs[0].IPAddressToString)" -ForegroundColor Green
        } else {
            # Нет IPv4 адресов — комментируем
            $NewLines += "# НЕДОСТУПЕН: $Line"
            $InvalidCount++
        }
    } catch {
        # Ошибка DNS — комментируем
        $NewLines += "# НЕДОСТУПЕН: $Line"
        $InvalidCount++
    }
    
    # Задержка 100мс чтобы не перегружать DNS
    Start-Sleep -Milliseconds 100
}

# Строки 54-55: Создаём бекап перед записью
$BackupFile = $ConfigFile + ".backup"
Copy-Item $ConfigFile $BackupFile -Force

# Строка 59: Перезаписываем файл с результатами
Set-Content -Path $ConfigFile -Value $NewLines -Encoding UTF8

Write-Host "Проверено: $CheckedCount" -ForegroundColor White
Write-Host "Недоступно: $InvalidCount" -ForegroundColor Red
pause
```

---

## find_subdomains.ps1

```powershell
# Строка 1: UTF-8 кодировка
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Строки 2-5: Пути к файлам
$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "domains_ru.conf"
$SubdomainsFile = Join-Path $ScriptDir "subdomains_popular.txt"
$StateFile = Join-Path $ScriptDir "find_subdomains_state.json"

# Строки 8-9: Ограничения
$MaxDomainsToCheck = 100  # Максимум базовых доменов за один запуск
$RequestDelay = 200       # Задержка между DNS-запросами (мс)

# Строки 11-21: Проверка файлов
if (-not (Test-Path $ConfigFile)) { exit }
if (-not (Test-Path $SubdomainsFile)) { exit }

# Строка 24: Загружаем словарь поддоменов
$SubdomainList = Get-Content $SubdomainsFile | \
    Where-Object { $_ -ne "" -and $_ -notlike "#*" } | \
    ForEach-Object { $_.Trim() }

# Строки 28-42: Проверяем сохранённое состояние (возобновление)
$ResumeMode = $false
$ProcessedDomains = @()
if (Test-Path $StateFile) {
    try {
        $State = Get-Content $StateFile | ConvertFrom-Json
        $ResumeMode = $true
        $ProcessedDomains = $State.ProcessedDomains
    } catch {
        $ResumeMode = $false
    }
}

# Строки 46-73: Парсим domains_ru.conf
$Lines = Get-Content $ConfigFile
$ExistingDomains = @{}  # Хэш-таблица: базовый домен → список поддоменов

foreach ($Line in $Lines) {
    $TrimmedLine = $Line.Trim()
    
    # Пропускаем комментарии и пустые строки
    if ($TrimmedLine -eq "" -or $TrimmedLine -like "#*") {
        continue
    }
    
    # Извлекаем домен 2-го уровня
    # mail.yandex.ru → yandex.ru
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

# Строки 77-90: Ограничиваем количество доменов для проверки
$DomainsToCheck = @{}
$Count = 0
foreach ($Key in $ExistingDomains.Keys) {
    if ($Count -ge $MaxDomainsToCheck) { break }
    
    # Пропускаем уже обработанные (режим возобновления)
    if ($ResumeMode -and $ProcessedDomains -contains $Key) {
        continue
    }
    
    $DomainsToCheck[$Key] = $ExistingDomains[$Key]
    $Count++
}

$AddedCount = 0
$CheckedCount = 0
$TotalToCheck = $DomainsToCheck.Count * $SubdomainList.Count

# Строки 106-182: Основной цикл проверки
foreach ($BaseDomain in $DomainsToCheck.Keys) {
    $ExistingSubs = $ExistingDomains[$BaseDomain]
    $SeenIPs = @{}  # Отслеживаем добавленные IP для этого домена
    
    # Получаем IP базового домена
    $BaseIP = $null
    try {
        $BaseIPs = [System.Net.Dns]::GetHostAddresses($BaseDomain) | \
            Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        if ($BaseIPs.Count -gt 0) {
            $BaseIP = $BaseIPs[0].IPAddressToString
            $SeenIPs[$BaseIP] = $true  # Базовый IP уже занят
        }
    } catch {}
    
    # Перебираем поддомены из словаря
    foreach ($Subdomain in $SubdomainList) {
        # Пропускаем если поддомен уже есть в файле
        if ($ExistingSubs -contains $Subdomain) {
            continue
        }
        
        $FullDomain = "$Subdomain.$BaseDomain"
        $CheckedCount++
        
        # DNS-резолвинг поддомена
        try {
            $IPs = [System.Net.Dns]::GetHostAddresses($FullDomain) | \
                Where-Object { $_.AddressFamily -eq 'InterNetwork' }
            
            if ($IPs.Count -gt 0) {
                $IP = $IPs[0].IPAddressToString
                
                # Фильтр 1: пропускаем если IP совпадает с базовым доменом
                # (wildcard DNS или www-поддомены)
                if ($BaseIP -and $IP -eq $BaseIP) {
                    continue
                }
                
                # Фильтр 2: пропускаем дубликаты IP
                # (несколько поддоменов на одном сервере)
                if ($SeenIPs.ContainsKey($IP)) {
                    continue
                }
                
                # Добавляем поддомен СРАЗУ в файл
                Add-Content -Path $ConfigFile -Value $FullDomain -Encoding UTF8
                $AddedCount++
                
                # Отмечаем IP как использованный
                $SeenIPs[$IP] = $true
                $ExistingDomains[$BaseDomain] += $Subdomain
            }
        } catch {
            # Поддомен не существует
        }
        
        # Задержка чтобы не спамить DNS
        Start-Sleep -Milliseconds $RequestDelay
    }
    
    # Сохраняем состояние после каждого базового домена
    $ProcessedDomains += $BaseDomain
    $State = @{
        ProcessedDomains = $ProcessedDomains
        LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    $State | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
}

# Строки 212-216: Удаляем файл состояния после завершения
if (Test-Path $StateFile) {
    Remove-Item $StateFile -Force
}

pause
```
