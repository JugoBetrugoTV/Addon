@echo off
echo ==========================================
echo   Battlefield: Python Edition - Build
echo ==========================================
echo.

:: Python finden
set PYTHON_CMD=

python --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_CMD=python
    goto :found
)

py --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_CMD=py
    goto :found
)

python3 --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON_CMD=python3
    goto :found
)

for %%P in (
    "%LOCALAPPDATA%\Programs\Python\Python314\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    "%USERPROFILE%\AppData\Local\Microsoft\WindowsApps\python.exe"
) do (
    if exist %%P (
        set PYTHON_CMD=%%P
        goto :found
    )
)

echo [FEHLER] Python nicht gefunden!
echo Installiere Python von https://python.org (Add to PATH aktivieren!)
pause
exit /b 1

:found
echo [OK] Python: %PYTHON_CMD%
echo.

echo [1/3] Installiere Abhaengigkeiten...
%PYTHON_CMD% -m pip install -r requirements.txt

if errorlevel 1 (
    echo [FEHLER] Installation fehlgeschlagen!
    pause
    exit /b 1
)

echo.
echo [2/3] Erstelle EXE...
%PYTHON_CMD% -m PyInstaller --noconfirm --onefile --windowed ^
    --name "Battlefield Python Edition" ^
    --hidden-import pygame ^
    src/battlefield.py

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
echo   EXE: dist\Battlefield Python Edition.exe
echo ==========================================
echo.
pause
