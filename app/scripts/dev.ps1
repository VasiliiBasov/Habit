# Локальный запуск: бэкенд (Java 24, H2) + Flutter в Edge.
# Запуск:           powershell -ExecutionPolicy Bypass -File scripts/dev.ps1
# В Android-эмулятор: powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -Android
param(
    [switch]$Android           # запуск в эмуляторе Pixel 6 API 35 (AVD habit_pixel)
)
$ErrorActionPreference = 'Stop'
$backend = 'C:\Users\Vasilii\IdeaProjects\Habit'
$app = 'C:\Users\Vasilii\IdeaProjects\habit_app'

# 1) Бэкенд
$isUp = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if (-not $isUp) {
    $jar = "$backend\target\habit-backend-0.0.1-SNAPSHOT.jar"
    if (-not (Test-Path $jar)) {
        Write-Host 'Собираю бэкенд (mvn package)...' -ForegroundColor Yellow
        Push-Location $backend; mvn -q package -DskipTests; Pop-Location
    }
    Write-Host 'Стартую бэкенд на :8080 (логи: %TEMP%\habit-backend.log)' -ForegroundColor Green
    Start-Process java -ArgumentList '-jar', $jar -WorkingDirectory "$backend\target" `
        -RedirectStandardOutput "$env:TEMP\habit-backend.log" -RedirectStandardError "$env:TEMP\habit-backend-err.log"
    foreach ($i in 1..20) {
        Start-Sleep 1
        if (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue) { break }
    }
} else { Write-Host 'Бэкенд уже запущен на :8080' -ForegroundColor Green }

# 2) Flutter
$env:Path += ';C:\src\flutter\bin'
Push-Location $app
try {
    if ($Android) {
        $sdk = "$env:LOCALAPPDATA\Android\Sdk"
        $env:Path += ";$sdk\platform-tools;$sdk\emulator"
        # AVD: habit_pixel (Pixel 6, API 35, Play Store). Создан scripts C:/src/android-setup.ps1
        if (-not (adb devices | Select-String 'emulator-\d+\s+device')) {
            Write-Host 'Запускаю эмулятор habit_pixel (первая загрузка ~1-2 минуты)...' -ForegroundColor Yellow
            Start-Process "$sdk\emulator\emulator.exe" -ArgumentList '-avd', 'habit_pixel', '-no-snapshot-save'
            & "$sdk\platform-tools\adb.exe" wait-for-device
            # ждём полной загрузки Android (not bootanim/launcher)
            while (& "$sdk\platform-tools\adb.exe" shell getprop sys.boot_completed 2>$null | Select-String '1' -NotMatch) { Start-Sleep 3 }
        }
        Write-Host 'Запуск приложения на emulator-5554 (BACKEND_URL=http://10.0.2.2:8080)' -ForegroundColor Green
        flutter run -d emulator-5554 --dart-define=BACKEND_URL=http://10.0.2.2:8080
    } else {
        Write-Host 'Запуск приложения в Edge (BACKEND_URL=http://localhost:8080)' -ForegroundColor Green
        flutter run -d edge --dart-define=BACKEND_URL=http://localhost:8080
    }
} finally { Pop-Location }
