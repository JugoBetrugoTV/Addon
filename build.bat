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
echo [3/4] Packaging with Electron Packager...
call npx electron-packager . "Codex Mortis" --platform=win32 --arch=x64 --out=release --overwrite --ignore="(src|\.git|node_modules/(typescript|ts-loader|webpack|html-webpack-plugin|@types))" --asar
if errorlevel 1 (
    echo [WARNING] Packaging failed. You can still run the game with:
    echo   npx electron dist/main.js
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   BUILD COMPLETE!
echo.
echo   EXE: release\Codex Mortis-win32-x64\Codex Mortis.exe
echo.
echo   Or run directly: npx electron dist/main.js
echo ========================================
echo.
pause
