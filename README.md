# SystemMonitor Pro v2.0

Ein professionelles Echtzeit-System-Monitoring Tool für Windows 11 mit modernem Dark-Mode UI, animierten Graphen und umfangreichen Features.

![Windows 11](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![Python](https://img.shields.io/badge/Python-3.8+-yellow?logo=python)
![Version](https://img.shields.io/badge/Version-2.0.0-green)

## Features

### Dashboard
- **CPU-Monitoring** - Echtzeit CPU-Auslastung mit animierter Kreisanzeige und Verlaufsgraph
- **RAM-Überwachung** - Speicherverbrauch mit detaillierten Infos und Mini-Graph
- **Festplatten-Status** - Belegter Speicherplatz mit Visualisierung
- **Netzwerk-Statistiken** - Live Download/Upload Geschwindigkeit
- **Top Prozesse** - Die 5 aktivsten Prozesse auf einen Blick

### Prozesse Tab
- Vollständige Prozessliste mit PID, Name, Status, CPU%, RAM%, Threads
- **Suchfunktion** - Prozesse schnell finden
- **Sortierung** - Klicke auf Spaltenheader zum Sortieren
- **Prozess beenden** - Ausgewählte Prozesse terminieren

### Netzwerk Tab
- **Download/Upload Geschwindigkeit** - Live-Anzeige in Echtzeit
- **Gesamt-Traffic** - Übersicht über übertragene Daten
- **Interface-Liste** - Alle Netzwerkadapter mit IP, MAC und Status

### Festplatten Tab
- **Disk I/O** - Lese-/Schreibgeschwindigkeit in Echtzeit
- **Partitionen** - Alle Laufwerke mit Belegung und animierten Fortschrittsbalken

### System Tab
- **Hardware-Info** - CPU, RAM, Architektur
- **Software-Info** - OS, Hostname, Python-Version
- **Batterie-Status** - Ladezustand und verbleibende Zeit (bei Laptops)

### Weitere Features
- **Export** - Systemdaten als CSV oder JSON exportieren
- **Tastenkürzel** - F5 (Aktualisieren), Ctrl+E (Export), Esc (Beenden)
- **Dark Theme** - Modernes, augenfreundliches Design
- **Animierte UI** - Sanfte Übergänge und Animationen
- **System-Uptime** - Anzeige der Laufzeit seit Boot

## Screenshot

```
┌─────────────────────────────────────────────────────────────────────┐
│  SystemMonitor PRO  v2.0.0          12:34:56  Uptime: 02:15:30      │
├─────────────────────────────────────────────────────────────────────┤
│  Dashboard │ Prozesse │ Netzwerk │ Festplatten │ System             │
├─────────────────────────────────────────────────────────────────────┤
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐                     │
│  │  CPU   │  │  RAM   │  │  Disk  │  │Network │                     │
│  │ ╭──╮   │  │ ╭──╮   │  │ ╭──╮   │  │ ╭──╮   │                     │
│  │ │45│%  │  │ │62│%  │  │ │73│%  │  │ │2.1│  │                     │
│  │ ╰──╯   │  │ ╰──╯   │  │ ╰──╯   │  │ ╰──╯MB │                     │
│  │▁▃▅▇▅▃▁ │  │▂▄▆▇▆▄▂ │  │▇▇▇▇▇▇▇ │  │▁▂▃▄▃▂▁ │                     │
│  └────────┘  └────────┘  └────────┘  └────────┘                     │
│                                                                      │
│  ┌─ CPU Verlauf ──────────────┐  ┌─ RAM Verlauf ──────────────┐     │
│  │ ▁▂▃▄▅▆▇▆▅▄▃▂▁▂▃▄▅▆▇▆▅▄▃▂▁ │  │ ▃▃▃▄▄▅▅▆▆▇▇▆▆▅▅▄▄▃▃▃▃▃▃▃▃ │     │
│  └────────────────────────────┘  └────────────────────────────┘     │
│                                                                      │
│  ┌─ System Info ──────────────┐  ┌─ Top Prozesse ─────────────┐     │
│  │ ● Hostname: DESKTOP-PC     │  │ chrome.exe          12.5%  │     │
│  │ ● OS: Windows 11           │  │ code.exe             8.3%  │     │
│  │ ● CPU: Intel Core i7       │  │ explorer.exe         3.2%  │     │
│  │ ● Kerne: 8 / 16 logisch    │  │ python.exe           2.1%  │     │
│  └────────────────────────────┘  └────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

## Installation

### Voraussetzungen

- Windows 10/11 (auch auf Linux/Mac lauffähig)
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

**Mit Batch-Datei (Windows CMD):**
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

## Tastenkürzel

| Taste | Funktion |
|-------|----------|
| `F5` | Prozessliste aktualisieren |
| `Ctrl+E` | Daten exportieren |
| `Esc` | Anwendung beenden |

## Projektstruktur

```
Addon/
├── src/
│   └── system_monitor.py   # Hauptanwendung (~1300 Zeilen)
├── requirements.txt        # Python Dependencies
├── build.bat              # Windows Batch Build-Skript
├── build.ps1              # PowerShell Build-Skript
├── .gitignore
└── README.md              # Diese Datei
```

## Technologien

- **Python 3** - Programmiersprache
- **Tkinter** - GUI Framework (in Python integriert)
- **psutil** - System-Informationen und Prozess-Management
- **PyInstaller** - EXE-Erstellung

## Neue Features in v2.0

- Komplett neues UI-Design mit Dark Theme
- Animierte Kreisförmige Fortschrittsanzeigen
- Echtzeit-Verlaufsgraphen für CPU und RAM
- Tab-basierte Navigation (Dashboard, Prozesse, Netzwerk, Festplatten, System)
- Prozess-Suchfunktion und Sortierung
- Prozess beenden Funktion
- Disk I/O Monitoring
- Netzwerk-Interface Übersicht
- Batterie-Monitoring (bei Laptops)
- Export-Funktion (CSV/JSON)
- Tastenkürzel-Support
- System-Uptime Anzeige

## Changelog

### v2.0.0
- Komplettes UI-Redesign
- Neue Tab-Navigation
- Animierte Widgets
- Verlaufsgraphen
- Export-Funktion
- Prozess-Management
- Netzwerk-Details
- Batterie-Status

### v1.0.0
- Initiale Version
- Basis-Monitoring

## Lizenz

MIT License - Frei verwendbar

---

**Made with Python**
