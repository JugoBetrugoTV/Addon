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

# Package with Electron Packager
Write-Host "`n[3/4] Packaging with Electron Packager..." -ForegroundColor Yellow
npx electron-packager . "Codex Mortis" --platform=win32 --arch=x64 --out=release --overwrite --ignore="(src|\.git|node_modules/(typescript|ts-loader|webpack|html-webpack-plugin|@types))" --asar
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Packaging failed. You can still run:" -ForegroundColor Yellow
    Write-Host "  npx electron dist/main.js" -ForegroundColor White
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "  EXE: release\Codex Mortis-win32-x64\Codex Mortis.exe" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "  Or run directly: npx electron dist/main.js" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Read-Host "`nPress Enter to exit"
