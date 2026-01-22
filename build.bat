@echo off
echo ========================================
echo   CODEX MORTIS - Build Script
echo   Vampire Survivors-like Game
echo ========================================
echo.

:: Check for Node.js
where node >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js not found! Please install from https://nodejs.org
    pause
    exit /b 1
)

echo [1/4] Installing dependencies...
call npm install
if errorlevel 1 (
    echo [ERROR] npm install failed!
    pause
    exit /b 1
)

echo.
echo [2/4] Building TypeScript...
call npx webpack --config webpack.config.js
if errorlevel 1 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo [3/4] Packaging with Electron...
call npx electron-builder --win portable
if errorlevel 1 (
    echo [WARNING] Electron builder failed. Trying dir target...
    call npx electron-builder --win dir
    if errorlevel 1 (
        echo [ERROR] Packaging failed!
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo   BUILD COMPLETE!
echo   Output: dist/ folder
echo ========================================
echo.
pause
