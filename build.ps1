# SystemMonitor Pro - PowerShell Build Script
# Ausfuehren: .\build.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SystemMonitor Pro - Build Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Python finden - verschiedene Methoden probieren
$pythonCmd = $null

# Methode 1: python im PATH
try {
    $null = & python --version 2>&1
    if ($LASTEXITCODE -eq 0) { $pythonCmd = "python" }
} catch {}

# Methode 2: py (Python Launcher)
if (-not $pythonCmd) {
    try {
        $null = & py --version 2>&1
        if ($LASTEXITCODE -eq 0) { $pythonCmd = "py" }
    } catch {}
}

# Methode 3: python3
if (-not $pythonCmd) {
    try {
        $null = & python3 --version 2>&1
        if ($LASTEXITCODE -eq 0) { $pythonCmd = "python3" }
    } catch {}
}

# Methode 4: Typische Installationspfade
if (-not $pythonCmd) {
    $searchPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python39\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python38\python.exe",
        "C:\Python314\python.exe",
        "C:\Python313\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe",
        "$env:ProgramFiles\Python314\python.exe",
        "$env:ProgramFiles\Python313\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "$env:ProgramFiles\Python311\python.exe",
        "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\python.exe"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $pythonCmd = $path
            break
        }
    }
}

# Pruefen ob Python gefunden wurde
if (-not $pythonCmd) {
    Write-Host "[FEHLER] Python wurde nicht gefunden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitte stelle sicher, dass Python installiert ist." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Loesung 1: Python neu installieren von https://python.org" -ForegroundColor Yellow
    Write-Host "           WICHTIG: Haken bei 'Add Python to PATH' setzen!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Loesung 2: Falls Python installiert ist, fuehre aus:" -ForegroundColor Yellow
    Write-Host '           $env:PATH = "$env:LOCALAPPDATA\Programs\Python\Python314;$env:LOCALAPPDATA\Programs\Python\Python314\Scripts;$env:PATH"' -ForegroundColor Gray
    Write-Host "           (Passe die Versionsnummer an deine Installation an)" -ForegroundColor Yellow
    exit 1
}

$pythonVersion = & $pythonCmd --version 2>&1
Write-Host "[OK] Python gefunden: $pythonCmd" -ForegroundColor Green
Write-Host "     $pythonVersion" -ForegroundColor Green
Write-Host ""

# Dependencies installieren
Write-Host "[1/3] Installiere Abhaengigkeiten..." -ForegroundColor Yellow
& $pythonCmd -m pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FEHLER] Installation fehlgeschlagen!" -ForegroundColor Red
    exit 1
}

# EXE erstellen
Write-Host ""
Write-Host "[2/3] Erstelle EXE-Datei..." -ForegroundColor Yellow
& $pythonCmd -m PyInstaller --noconfirm --onefile --windowed `
    --name "SystemMonitor Pro" `
    --hidden-import psutil `
    --hidden-import tkinter `
    src/system_monitor.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FEHLER] Build fehlgeschlagen!" -ForegroundColor Red
    exit 1
}

# Aufraeumen
Write-Host ""
Write-Host "[3/3] Aufraeumen..." -ForegroundColor Yellow
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Force *.spec -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Build erfolgreich!" -ForegroundColor Green
Write-Host "  EXE-Datei: dist\SystemMonitor Pro.exe" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
