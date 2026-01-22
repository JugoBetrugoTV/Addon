# SystemMonitor Pro - PowerShell Build Script
# Ausfuehren: .\build.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SystemMonitor Pro - Build Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Pruefen ob Python installiert ist
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] $pythonVersion gefunden" -ForegroundColor Green
} catch {
    Write-Host "[FEHLER] Python ist nicht installiert!" -ForegroundColor Red
    Write-Host "Bitte installiere Python von https://python.org" -ForegroundColor Yellow
    exit 1
}

# Dependencies installieren
Write-Host ""
Write-Host "[1/3] Installiere Abhaengigkeiten..." -ForegroundColor Yellow
pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FEHLER] Installation fehlgeschlagen!" -ForegroundColor Red
    exit 1
}

# EXE erstellen
Write-Host ""
Write-Host "[2/3] Erstelle EXE-Datei..." -ForegroundColor Yellow
pyinstaller --noconfirm --onefile --windowed `
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
