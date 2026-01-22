# SystemMonitor Pro v3.0

Ein **ultra-modernes** Echtzeit-System-Monitoring Tool für Windows 11 mit Glasmorphism UI, animierten Widgets und professionellem Design.

![Windows 11](https://img.shields.io/badge/Windows-11-0078D4?style=for-the-badge&logo=windows11)
![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Version](https://img.shields.io/badge/Version-3.0.0-10B981?style=for-the-badge)

## Highlights

- **Ultra-Modern UI** - Glasmorphism Design mit Glow-Effekten
- **3 Themes** - Midnight (Blau), Aurora (Lila), Cyber (Grün/Matrix)
- **Animierte Widgets** - Smooth Animationen überall
- **Sidebar Navigation** - Moderne App-ähnliche Navigation
- **Per-Core CPU** - Individuelle Auslastung pro CPU-Kern
- **Live Graphen** - Echtzeit-Verlaufsgraphen mit Gradient-Fill

## Features

### Dashboard
```
┌─────────────────────────────────────────────────────────────────┐
│  ◉ SystemMonitor PRO                    │   14:32:18            │
│                                         │   Uptime: 05:23:41    │
├──────────┬──────────────────────────────┴───────────────────────┤
│          │                                                       │
│  ◫ Dash  │   ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐            │
│  ☰ Procs │   │ CPU  │  │ RAM  │  │ Disk │  │ Net  │            │
│  ◎ Net   │   │ ╭─╮  │  │ ╭─╮  │  │ ╭─╮  │  │ ╭─╮  │            │
│  ◔ Disks │   │ │45│% │  │ │62│% │  │ │73│% │  │2.1MB│            │
│  ⚙ Sys   │   │ ╰─╯  │  │ ╰─╯  │  │ ╰─╯  │  │ ╰─╯  │            │
│          │   │▁▃▅▇▅▃│  │▂▄▆▇▆▄│  │▇▇▇▇▇▇│  │▁▂▃▄▃▂│            │
│ ────────│   └──────┘  └──────┘  └──────┘  └──────┘            │
│  Theme   │                                                       │
│  ● ● ●   │   ┌─ CPU History ─────────┐┌─ RAM History ─────────┐ │
│          │   │ ▁▂▃▄▅▆▇▆▅▄▃▂▁▂▃▄▅▆▇▆ ││ ▃▃▄▄▅▅▆▆▇▇▆▆▅▅▄▄▃▃▃▃ │ │
│          │   └───────────────────────┘└───────────────────────┘ │
│          │                                                       │
│  v3.0.0  │   ┌─ System Info ─┐┌─ Top Procs ─┐┌─ CPU Cores ────┐ │
│          │   │ ◉ Host: PC    ││ chrome  12% ││ Core 0 ███░ 45%│ │
│          │   │ ◉ OS: Win 11  ││ code     8% ││ Core 1 ██░░ 32%│ │
└──────────┴───┴───────────────┴┴─────────────┴┴────────────────┴─┘
```

### Animierte Widgets

- **AnimatedRing** - Kreisförmige Fortschrittsanzeige mit Glow und pulsierendem Endpunkt
- **ModernGraph** - Verlaufsgraph mit Gradient-Fill und animiertem Datenpunkt
- **ModernProgressBar** - Progressbar mit Shimmer-Animation
- **SidebarButton** - Buttons mit Hover-Animation und Active-Indikator
- **StatCard** - Kombinierte Karte mit Ring, Details und Mini-Graph

### Themes

| Theme | Akzentfarbe | Beschreibung |
|-------|-------------|--------------|
| **Midnight** | Blau | Klassisches dunkles Theme |
| **Aurora** | Lila/Pink | Lebendige Farben |
| **Cyber** | Neon-Grün | Matrix/Hacker Style |

### Pages

| Seite | Features |
|-------|----------|
| **Dashboard** | 4 Stat-Cards, 2 große Graphen, System-Info, Top Prozesse, Per-Core CPU |
| **Prozesse** | Suchfunktion, Sortierung, Task beenden |
| **Netzwerk** | Download/Upload Speed, Interface-Liste |
| **Festplatten** | Read/Write I/O, Partitionen mit Balken |
| **System** | Hardware-Info, Software-Info, Batterie |

## Installation

### Voraussetzungen

- Windows 10/11 (auch Linux/Mac kompatibel)
- Python 3.8+

### Schnellstart

```bash
# Repository klonen
git clone https://github.com/JugoBetrugoTV/Addon.git
cd Addon

# Dependencies installieren
pip install -r requirements.txt

# Starten
python src/system_monitor.py
```

## EXE erstellen

### Windows (CMD)
```cmd
build.bat
```

### PowerShell
```powershell
.\build.ps1
```

### Manuell
```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name "SystemMonitor Pro" src/system_monitor.py
```

Die EXE findest du in `dist/SystemMonitor Pro.exe`

## Projektstruktur

```
Addon/
├── src/
│   └── system_monitor.py   # Hauptanwendung (~1700 Zeilen)
├── requirements.txt        # psutil, pyinstaller
├── build.bat              # Windows Build
├── build.ps1              # PowerShell Build
└── README.md
```

## Custom Widgets

Das Tool enthält mehrere selbst entwickelte Widgets:

```python
# Animierter Ring mit Glow
ring = AnimatedRing(parent, size=120, thickness=12, theme=theme)
ring.set_value(75)  # Animiert zum Wert

# Moderner Graph mit Gradient
graph = ModernGraph(parent, width=400, height=100, color='#3b82f6')
graph.add_value(45)  # Fügt Datenpunkt hinzu

# Progress Bar mit Shimmer
bar = ModernProgressBar(parent, width=300, height=8)
bar.set_value(60)  # Animiert mit Shimmer-Effekt
```

## Changelog

### v3.0.0 (Aktuell)
- Komplett neues Ultra-Modern UI
- Sidebar-Navigation
- 3 Themes (Midnight, Aurora, Cyber)
- Animierte Ring-Widgets mit Glow
- Per-Core CPU Monitoring
- Gradient-Graphen
- Hover-Animationen
- Glasmorphism Design

### v2.0.0
- Tab-basierte Navigation
- Export-Funktion
- Prozess-Management

### v1.0.0
- Basis-Monitoring

## Technologien

- **Python 3** mit Tkinter
- **psutil** für System-Daten
- **PyInstaller** für EXE

## Lizenz

MIT License

---

**Made with Python**
