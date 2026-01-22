@echo off
echo ==========================================
echo   SystemMonitor Pro - Build Script
echo ==========================================
echo.

:: Python finden - verschiedene Methoden probieren
set PYTHON_CMD=

:: Methode 1: python
python --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_CMD=python
    goto :found
)

:: Methode 2: py (Python Launcher fuer Windows)
py --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_CMD=py
    goto :found
)

:: Methode 3: python3
python3 --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_CMD=python3
    goto :found
)

:: Methode 4: Typische Installationspfade pruefen
for %%P in (
    "%LOCALAPPDATA%\Programs\Python\Python314\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python39\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python38\python.exe"
    "C:\Python314\python.exe"
    "C:\Python313\python.exe"
    "C:\Python312\python.exe"
    "C:\Python311\python.exe"
    "C:\Python310\python.exe"
    "C:\Python39\python.exe"
    "C:\Python38\python.exe"
    "%ProgramFiles%\Python314\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%USERPROFILE%\AppData\Local\Microsoft\WindowsApps\python.exe"
) do (
    if exist %%P (
        set PYTHON_CMD=%%P
        goto :found
    )
)

:: Python nicht gefunden
echo [FEHLER] Python wurde nicht gefunden!
echo.
echo Bitte stelle sicher, dass Python installiert ist und im PATH liegt.
echo.
echo Loesung 1: Python neu installieren von https://python.org
echo            WICHTIG: Haken bei "Add Python to PATH" setzen!
echo.
echo Loesung 2: Falls Python installiert ist, oeffne eine neue CMD und tippe:
echo            set PATH=%%LOCALAPPDATA%%\Programs\Python\Python314;%%LOCALAPPDATA%%\Programs\Python\Python314\Scripts;%%PATH%%
echo            (Passe die Versionsnummer an deine Installation an)
echo.
echo Loesung 3: Starte diese Datei aus der Python-Umgebung:
echo            Oeffne "Python 3.x" im Startmenue, dann tippe:
echo            import subprocess; subprocess.run(['cmd', '/c', 'build.bat'])
echo.
pause
exit /b 1

:found
echo [OK] Python gefunden: %PYTHON_CMD%
for /f "tokens=*" %%V in ('%PYTHON_CMD% --version 2^>^&1') do echo      %%V
echo.

:: pip Pfad bestimmen
set PIP_CMD=%PYTHON_CMD% -m pip

echo [1/3] Installiere Abhaengigkeiten...
%PIP_CMD% install -r requirements.txt

if errorlevel 1 (
    echo [FEHLER] Installation fehlgeschlagen!
    pause
    exit /b 1
)

echo.
echo [2/3] Erstelle EXE-Datei...
%PYTHON_CMD% -m PyInstaller --noconfirm --onefile --windowed ^
    --name "SystemMonitor Pro" ^
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
