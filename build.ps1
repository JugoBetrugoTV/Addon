# Battlefield: Python Edition - Build Script

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Battlefield: Python Edition - Build" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$pythonCmd = $null
foreach ($cmd in @("python", "py", "python3")) {
    try {
        $null = & $cmd --version 2>&1
        if ($LASTEXITCODE -eq 0) { $pythonCmd = $cmd; break }
    } catch {}
}

if (-not $pythonCmd) {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe"
    )
    foreach ($p in $paths) { if (Test-Path $p) { $pythonCmd = $p; break } }
}

if (-not $pythonCmd) {
    Write-Host "[FEHLER] Python nicht gefunden!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Python: $pythonCmd" -ForegroundColor Green

Write-Host "`n[1/3] Installiere Abhaengigkeiten..." -ForegroundColor Yellow
& $pythonCmd -m pip install -r requirements.txt

Write-Host "`n[2/3] Erstelle EXE..." -ForegroundColor Yellow
& $pythonCmd -m PyInstaller --noconfirm --onefile --windowed `
    --name "Battlefield Python Edition" `
    --hidden-import pygame `
    src/battlefield.py

Write-Host "`n[3/3] Aufraeumen..." -ForegroundColor Yellow
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Force *.spec -ErrorAction SilentlyContinue

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "  EXE: dist\Battlefield Python Edition.exe" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
