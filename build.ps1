Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CODEX MORTIS - Build Script" -ForegroundColor Cyan
Write-Host "  Vampire Survivors-like Game" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for Node.js
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js $nodeVersion found" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js not found! Install from https://nodejs.org" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install dependencies
Write-Host "`n[1/4] Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] npm install failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Build TypeScript
Write-Host "`n[2/4] Building TypeScript..." -ForegroundColor Yellow
npx webpack --config webpack.config.js
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Package
Write-Host "`n[3/4] Packaging with Electron..." -ForegroundColor Yellow
npx electron-builder --win portable
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Trying dir target..." -ForegroundColor Yellow
    npx electron-builder --win dir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Packaging failed!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "  Output: dist/ folder" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Read-Host "`nPress Enter to exit"
