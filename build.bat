@echo off
echo ==========================================
echo   SystemMonitor Pro - Build Script
echo ==========================================
echo.

:: Pruefen ob Python installiert ist
python --version >nul 2>&1
if errorlevel 1 (
    echo [FEHLER] Python ist nicht installiert!
    echo Bitte installiere Python von https://python.org
    pause
    exit /b 1
)

echo [1/3] Installiere Abhaengigkeiten...
pip install -r requirements.txt

if errorlevel 1 (
    echo [FEHLER] Installation fehlgeschlagen!
    pause
    exit /b 1
)

echo.
echo [2/3] Erstelle EXE-Datei...
pyinstaller --noconfirm --onefile --windowed ^
    --name "SystemMonitor Pro" ^
    --add-data "src;src" ^
    --hidden-import psutil ^
    --hidden-import tkinter ^
    src/system_monitor.py

if errorlevel 1 (
    echo [FEHLER] Build fehlgeschlagen!
    pause
    exit /b 1
)

echo.
echo [3/3] Aufraeumen...
rmdir /s /q build 2>nul
del /q *.spec 2>nul

echo.
echo ==========================================
echo   Build erfolgreich!
echo   EXE-Datei: dist\SystemMonitor Pro.exe
echo ==========================================
echo.
pause
