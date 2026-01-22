# SystemMonitor Pro

Ein modernes Echtzeit-System-Monitoring Tool für Windows 11 mit schönem Dark-Mode UI.

![Windows 11](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![Python](https://img.shields.io/badge/Python-3.8+-yellow?logo=python)

## Features

- **CPU-Monitoring** - Echtzeit CPU-Auslastung mit Frequenzanzeige
- **RAM-Überwachung** - Speicherverbrauch mit detaillierten Infos
- **Festplatten-Status** - Belegter und freier Speicherplatz
- **Netzwerk-Statistiken** - Gesendete und empfangene Daten
- **Prozess-Manager** - Top 10 Prozesse nach CPU-Auslastung
- **System-Informationen** - Host, OS, CPU-Details

## Screenshot

```
┌─────────────────────────────────────────────────────────────┐
│  SystemMonitor Pro                              12:34:56    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ CPU     45.2%   │  │ RAM     62.8%   │                   │
│  │ ███████░░░░░░░░ │  │ ██████████░░░░░ │                   │
│  └─────────────────┘  └─────────────────┘                   │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ Disk    73.1%   │  │ Network         │                   │
│  │ ███████████░░░░ │  │ 1.2 GB total    │                   │
│  └─────────────────┘  └─────────────────┘                   │
├─────────────────────────────────────────────────────────────┤
│  Top Prozesse                                               │
│  PID    Name                    CPU%    RAM%                │
│  1234   chrome.exe              12.5    8.2                 │
│  5678   code.exe                8.3     5.1                 │
└─────────────────────────────────────────────────────────────┘
```

## Installation

### Voraussetzungen

- Windows 10/11
- Python 3.8 oder höher
- pip (Python Package Manager)

### Schnellstart

1. **Repository klonen:**
   ```bash
   git clone https://github.com/JugoBetrugoTV/Addon.git
   cd Addon
   ```

2. **Dependencies installieren:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Direkt ausführen:**
   ```bash
   python src/system_monitor.py
   ```

## EXE erstellen

### Option 1: Build-Skript (empfohlen)

**Mit Batch-Datei:**
```cmd
build.bat
```

**Mit PowerShell:**
```powershell
.\build.ps1
```

### Option 2: Manuell

```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name "SystemMonitor Pro" src/system_monitor.py
```

Die fertige EXE findest du im `dist/` Ordner.

## Projektstruktur

```
Addon/
├── src/
│   └── system_monitor.py   # Hauptanwendung
├── requirements.txt        # Python Dependencies
├── build.bat              # Windows Build-Skript
├── build.ps1              # PowerShell Build-Skript
└── README.md              # Diese Datei
```

## Technologien

- **Python 3** - Programmiersprache
- **Tkinter** - GUI Framework (in Python integriert)
- **psutil** - System-Informationen
- **PyInstaller** - EXE-Erstellung

## Lizenz

MIT License - Frei verwendbar
