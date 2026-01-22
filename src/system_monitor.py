"""
SystemMonitor Pro v2.0 - Windows 11 System Monitor Tool
Ein modernes Echtzeit-System-Monitoring Tool mit schönem UI
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import psutil
import platform
import socket
import threading
import time
from datetime import datetime
from collections import deque
import json
import csv
import os
import sys

# Versuche wmi für erweiterte Windows-Infos
try:
    import wmi
    WMI_AVAILABLE = True
except ImportError:
    WMI_AVAILABLE = False


class AnimatedProgressBar(tk.Canvas):
    """Animierte Fortschrittsanzeige mit Gradient"""

    def __init__(self, parent, width=200, height=8, colors=None, **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.colors = colors or ['#3742fa', '#5352ed']
        self.value = 0
        self.target_value = 0
        self.draw()

    def draw(self):
        self.delete('all')
        # Hintergrund
        self.create_rectangle(0, 0, self.width, self.height,
                            fill='#1e1e2e', outline='')
        # Fortschritt mit Gradient-Effekt
        if self.value > 0:
            bar_width = (self.value / 100) * self.width
            # Hauptbalken
            self.create_rectangle(0, 0, bar_width, self.height,
                                fill=self.colors[0], outline='')
            # Glanz-Effekt
            self.create_rectangle(0, 0, bar_width, self.height // 2,
                                fill=self.colors[1], outline='')

    def set_value(self, value):
        self.target_value = min(100, max(0, value))
        self.animate()

    def animate(self):
        if abs(self.value - self.target_value) > 0.5:
            self.value += (self.target_value - self.value) * 0.3
            self.draw()
            self.after(16, self.animate)
        else:
            self.value = self.target_value
            self.draw()


class CircularProgress(tk.Canvas):
    """Kreisförmige Fortschrittsanzeige"""

    def __init__(self, parent, size=100, thickness=10, colors=None, **kwargs):
        super().__init__(parent, width=size, height=size,
                        highlightthickness=0, **kwargs)
        self.size = size
        self.thickness = thickness
        self.colors = colors or {'bg': '#1e1e2e', 'fg': '#3742fa', 'text': '#ffffff'}
        self.value = 0
        self.target_value = 0
        self.label_text = "0%"
        self.draw()

    def draw(self):
        self.delete('all')
        center = self.size // 2
        radius = (self.size - self.thickness) // 2

        # Hintergrund-Kreis
        self.create_oval(
            self.thickness // 2, self.thickness // 2,
            self.size - self.thickness // 2, self.size - self.thickness // 2,
            outline=self.colors['bg'], width=self.thickness
        )

        # Fortschritts-Bogen
        if self.value > 0:
            extent = (self.value / 100) * 360
            self.create_arc(
                self.thickness // 2, self.thickness // 2,
                self.size - self.thickness // 2, self.size - self.thickness // 2,
                start=90, extent=-extent,
                outline=self.colors['fg'], width=self.thickness, style='arc'
            )

        # Prozentzahl in der Mitte
        self.create_text(center, center, text=self.label_text,
                        font=('Segoe UI', 14, 'bold'), fill=self.colors['text'])

    def set_value(self, value, label=None):
        self.target_value = min(100, max(0, value))
        self.label_text = label or f"{int(value)}%"
        self.animate()

    def animate(self):
        if abs(self.value - self.target_value) > 0.5:
            self.value += (self.target_value - self.value) * 0.2
            self.draw()
            self.after(16, self.animate)
        else:
            self.value = self.target_value
            self.draw()


class MiniGraph(tk.Canvas):
    """Mini-Verlaufsgraph"""

    def __init__(self, parent, width=150, height=50, color='#3742fa', **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.color = color
        self.data = deque(maxlen=50)
        self.draw()

    def draw(self):
        self.delete('all')

        # Hintergrund
        self.create_rectangle(0, 0, self.width, self.height,
                            fill='#1e1e2e', outline='#2d2d3d')

        # Gitterlinien
        for i in range(1, 4):
            y = i * (self.height // 4)
            self.create_line(0, y, self.width, y, fill='#2d2d3d', dash=(2, 4))

        if len(self.data) < 2:
            return

        # Datenpunkte zeichnen
        points = []
        for i, value in enumerate(self.data):
            x = (i / (len(self.data) - 1)) * self.width if len(self.data) > 1 else 0
            y = self.height - (value / 100) * (self.height - 4) - 2
            points.extend([x, y])

        # Gefüllter Bereich unter der Linie
        if len(points) >= 4:
            fill_points = points.copy()
            fill_points.extend([self.width, self.height, 0, self.height])
            self.create_polygon(fill_points, fill=self.color + '40', outline='')

            # Linie
            self.create_line(points, fill=self.color, width=2, smooth=True)

    def add_value(self, value):
        self.data.append(min(100, max(0, value)))
        self.draw()


class SystemMonitorPro:
    """Hauptanwendung"""

    VERSION = "2.0.0"

    def __init__(self, root):
        self.root = root
        self.root.title(f"SystemMonitor Pro v{self.VERSION}")
        self.root.geometry("1000x700")
        self.root.minsize(900, 600)

        # Farbschema - Modernes Dark Theme
        self.colors = {
            'bg_primary': '#0f0f17',
            'bg_secondary': '#1a1a2e',
            'bg_card': '#16213e',
            'bg_hover': '#1f2b47',
            'accent_blue': '#3742fa',
            'accent_cyan': '#00d4ff',
            'accent_green': '#00d26a',
            'accent_yellow': '#ffc107',
            'accent_orange': '#ff9500',
            'accent_red': '#ff4757',
            'accent_purple': '#a855f7',
            'accent_pink': '#e94560',
            'text_primary': '#ffffff',
            'text_secondary': '#a0aec0',
            'text_dim': '#6b7280',
            'border': '#2d3748'
        }

        self.root.configure(bg=self.colors['bg_primary'])

        # Verlaufsdaten
        self.cpu_history = deque(maxlen=60)
        self.ram_history = deque(maxlen=60)
        self.net_sent_prev = 0
        self.net_recv_prev = 0
        self.disk_read_prev = 0
        self.disk_write_prev = 0

        # Styles einrichten
        self.setup_styles()

        # UI erstellen
        self.create_ui()

        # Update-Thread starten
        self.running = True
        self.update_interval = 1000  # ms
        self.start_updates()

        # Tastenkürzel
        self.setup_keybindings()

        # Beim Schließen aufräumen
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')

        # Notebook (Tabs) Style
        style.configure('Custom.TNotebook', background=self.colors['bg_primary'])
        style.configure('Custom.TNotebook.Tab',
                       background=self.colors['bg_secondary'],
                       foreground=self.colors['text_secondary'],
                       padding=[20, 10],
                       font=('Segoe UI', 10))
        style.map('Custom.TNotebook.Tab',
                 background=[('selected', self.colors['bg_card'])],
                 foreground=[('selected', self.colors['text_primary'])])

        # Treeview Style
        style.configure('Custom.Treeview',
                       background=self.colors['bg_secondary'],
                       foreground=self.colors['text_primary'],
                       fieldbackground=self.colors['bg_secondary'],
                       borderwidth=0,
                       font=('Segoe UI', 9))
        style.configure('Custom.Treeview.Heading',
                       background=self.colors['bg_card'],
                       foreground=self.colors['text_secondary'],
                       font=('Segoe UI', 9, 'bold'))
        style.map('Custom.Treeview',
                 background=[('selected', self.colors['accent_blue'])],
                 foreground=[('selected', self.colors['text_primary'])])

        # Scrollbar Style
        style.configure('Custom.Vertical.TScrollbar',
                       background=self.colors['bg_card'],
                       troughcolor=self.colors['bg_secondary'],
                       borderwidth=0,
                       arrowsize=0)

    def create_ui(self):
        # Header erstellen
        self.create_header()

        # Notebook (Tabs) erstellen
        self.notebook = ttk.Notebook(self.root, style='Custom.TNotebook')
        self.notebook.pack(fill='both', expand=True, padx=10, pady=(0, 10))

        # Tabs erstellen
        self.create_dashboard_tab()
        self.create_processes_tab()
        self.create_network_tab()
        self.create_disks_tab()
        self.create_system_tab()

    def create_header(self):
        header = tk.Frame(self.root, bg=self.colors['bg_card'], height=60)
        header.pack(fill='x', padx=10, pady=10)
        header.pack_propagate(False)

        # Logo/Titel
        title_frame = tk.Frame(header, bg=self.colors['bg_card'])
        title_frame.pack(side='left', padx=20, pady=10)

        title = tk.Label(title_frame, text="SystemMonitor",
                        font=('Segoe UI', 20, 'bold'),
                        bg=self.colors['bg_card'], fg=self.colors['text_primary'])
        title.pack(side='left')

        pro_label = tk.Label(title_frame, text=" PRO",
                           font=('Segoe UI', 20, 'bold'),
                           bg=self.colors['bg_card'], fg=self.colors['accent_cyan'])
        pro_label.pack(side='left')

        version = tk.Label(title_frame, text=f"  v{self.VERSION}",
                          font=('Segoe UI', 10),
                          bg=self.colors['bg_card'], fg=self.colors['text_dim'])
        version.pack(side='left', pady=(8, 0))

        # Rechte Seite - Zeit und Buttons
        right_frame = tk.Frame(header, bg=self.colors['bg_card'])
        right_frame.pack(side='right', padx=20, pady=10)

        # Export Button
        self.export_btn = tk.Button(right_frame, text="Export",
                                   font=('Segoe UI', 9),
                                   bg=self.colors['accent_blue'],
                                   fg=self.colors['text_primary'],
                                   activebackground=self.colors['accent_cyan'],
                                   bd=0, padx=15, pady=5,
                                   cursor='hand2',
                                   command=self.export_data)
        self.export_btn.pack(side='right', padx=(10, 0))

        # Uptime
        self.uptime_label = tk.Label(right_frame, text="Uptime: --:--:--",
                                    font=('Segoe UI', 10),
                                    bg=self.colors['bg_card'],
                                    fg=self.colors['text_secondary'])
        self.uptime_label.pack(side='right', padx=(0, 20))

        # Zeit
        self.time_label = tk.Label(right_frame, text="00:00:00",
                                  font=('Segoe UI', 14),
                                  bg=self.colors['bg_card'],
                                  fg=self.colors['text_primary'])
        self.time_label.pack(side='right', padx=(0, 20))

    def create_dashboard_tab(self):
        tab = tk.Frame(self.notebook, bg=self.colors['bg_primary'])
        self.notebook.add(tab, text='  Dashboard  ')

        # Obere Zeile - Haupt-Metriken mit Kreisen
        top_frame = tk.Frame(tab, bg=self.colors['bg_primary'])
        top_frame.pack(fill='x', padx=10, pady=10)

        # CPU Card
        self.cpu_card = self.create_metric_card(top_frame, "CPU",
                                               self.colors['accent_blue'],
                                               self.colors['accent_cyan'])
        self.cpu_card['frame'].pack(side='left', fill='both', expand=True, padx=(0, 5))

        # RAM Card
        self.ram_card = self.create_metric_card(top_frame, "RAM",
                                               self.colors['accent_green'],
                                               self.colors['accent_cyan'])
        self.ram_card['frame'].pack(side='left', fill='both', expand=True, padx=5)

        # Disk Card
        self.disk_card = self.create_metric_card(top_frame, "Disk",
                                                self.colors['accent_yellow'],
                                                self.colors['accent_orange'])
        self.disk_card['frame'].pack(side='left', fill='both', expand=True, padx=5)

        # Network Card
        self.net_card = self.create_metric_card(top_frame, "Network",
                                               self.colors['accent_pink'],
                                               self.colors['accent_purple'])
        self.net_card['frame'].pack(side='left', fill='both', expand=True, padx=(5, 0))

        # Mittlere Zeile - Verlaufsgraphen
        mid_frame = tk.Frame(tab, bg=self.colors['bg_primary'])
        mid_frame.pack(fill='x', padx=10, pady=5)

        # CPU Verlauf
        cpu_graph_card = self.create_graph_card(mid_frame, "CPU Verlauf",
                                               self.colors['accent_blue'])
        cpu_graph_card['frame'].pack(side='left', fill='both', expand=True, padx=(0, 5))
        self.cpu_graph = cpu_graph_card['graph']

        # RAM Verlauf
        ram_graph_card = self.create_graph_card(mid_frame, "RAM Verlauf",
                                               self.colors['accent_green'])
        ram_graph_card['frame'].pack(side='left', fill='both', expand=True, padx=(5, 0))
        self.ram_graph = ram_graph_card['graph']

        # Untere Zeile - Zusätzliche Infos
        bottom_frame = tk.Frame(tab, bg=self.colors['bg_primary'])
        bottom_frame.pack(fill='both', expand=True, padx=10, pady=5)

        # Schnelle System-Info
        self.create_quick_info(bottom_frame)

        # Top Prozesse Mini-Liste
        self.create_top_processes(bottom_frame)

    def create_metric_card(self, parent, title, color1, color2):
        frame = tk.Frame(parent, bg=self.colors['bg_card'])
        frame.configure(highlightbackground=self.colors['border'],
                       highlightthickness=1)

        # Titel
        title_label = tk.Label(frame, text=title,
                              font=('Segoe UI', 11, 'bold'),
                              bg=self.colors['bg_card'],
                              fg=self.colors['text_secondary'])
        title_label.pack(pady=(15, 5))

        # Kreisförmige Anzeige
        circle = CircularProgress(frame, size=90, thickness=8,
                                 colors={'bg': self.colors['bg_secondary'],
                                        'fg': color1,
                                        'text': self.colors['text_primary']},
                                 bg=self.colors['bg_card'])
        circle.pack(pady=5)

        # Details
        detail1 = tk.Label(frame, text="--",
                          font=('Segoe UI', 9),
                          bg=self.colors['bg_card'],
                          fg=self.colors['text_secondary'])
        detail1.pack()

        detail2 = tk.Label(frame, text="--",
                          font=('Segoe UI', 9),
                          bg=self.colors['bg_card'],
                          fg=self.colors['text_dim'])
        detail2.pack(pady=(0, 15))

        # Mini Graph
        mini_graph = MiniGraph(frame, width=120, height=35, color=color1,
                              bg=self.colors['bg_card'])
        mini_graph.pack(pady=(0, 15))

        return {
            'frame': frame,
            'circle': circle,
            'detail1': detail1,
            'detail2': detail2,
            'mini_graph': mini_graph
        }

    def create_graph_card(self, parent, title, color):
        frame = tk.Frame(parent, bg=self.colors['bg_card'], height=120)
        frame.configure(highlightbackground=self.colors['border'],
                       highlightthickness=1)
        frame.pack_propagate(False)

        # Titel
        title_label = tk.Label(frame, text=title,
                              font=('Segoe UI', 10, 'bold'),
                              bg=self.colors['bg_card'],
                              fg=self.colors['text_secondary'])
        title_label.pack(anchor='w', padx=15, pady=(10, 5))

        # Graph
        graph = MiniGraph(frame, width=400, height=70, color=color,
                         bg=self.colors['bg_card'])
        graph.pack(fill='x', padx=15, pady=(0, 10))

        return {'frame': frame, 'graph': graph}

    def create_quick_info(self, parent):
        frame = tk.Frame(parent, bg=self.colors['bg_card'])
        frame.configure(highlightbackground=self.colors['border'],
                       highlightthickness=1)
        frame.pack(side='left', fill='both', expand=True, padx=(0, 5))

        title = tk.Label(frame, text="System Info",
                        font=('Segoe UI', 11, 'bold'),
                        bg=self.colors['bg_card'],
                        fg=self.colors['text_secondary'])
        title.pack(anchor='w', padx=15, pady=(15, 10))

        # Info Grid
        info_frame = tk.Frame(frame, bg=self.colors['bg_card'])
        info_frame.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        # System Infos
        hostname = socket.gethostname()
        os_info = f"{platform.system()} {platform.release()}"

        try:
            cpu_name = platform.processor()
            if len(cpu_name) > 35:
                cpu_name = cpu_name[:35] + "..."
        except:
            cpu_name = "Unknown"

        boot_time = datetime.fromtimestamp(psutil.boot_time())

        infos = [
            ("Hostname", hostname, self.colors['accent_cyan']),
            ("Betriebssystem", os_info, self.colors['accent_blue']),
            ("Prozessor", cpu_name, self.colors['accent_green']),
            ("CPU Kerne", f"{psutil.cpu_count(logical=False)} physisch / {psutil.cpu_count()} logisch", self.colors['accent_yellow']),
            ("Boot Zeit", boot_time.strftime("%d.%m.%Y %H:%M"), self.colors['accent_purple']),
            ("Python", platform.python_version(), self.colors['accent_pink'])
        ]

        for i, (label, value, color) in enumerate(infos):
            row = tk.Frame(info_frame, bg=self.colors['bg_card'])
            row.pack(fill='x', pady=3)

            # Farbiger Indikator
            indicator = tk.Frame(row, bg=color, width=3, height=16)
            indicator.pack(side='left', padx=(0, 10))

            lbl = tk.Label(row, text=f"{label}:",
                          font=('Segoe UI', 9),
                          bg=self.colors['bg_card'],
                          fg=self.colors['text_dim'])
            lbl.pack(side='left')

            val = tk.Label(row, text=value,
                          font=('Segoe UI', 9),
                          bg=self.colors['bg_card'],
                          fg=self.colors['text_primary'])
            val.pack(side='left', padx=(10, 0))

    def create_top_processes(self, parent):
        frame = tk.Frame(parent, bg=self.colors['bg_card'])
        frame.configure(highlightbackground=self.colors['border'],
                       highlightthickness=1)
        frame.pack(side='left', fill='both', expand=True, padx=(5, 0))

        title = tk.Label(frame, text="Top Prozesse",
                        font=('Segoe UI', 11, 'bold'),
                        bg=self.colors['bg_card'],
                        fg=self.colors['text_secondary'])
        title.pack(anchor='w', padx=15, pady=(15, 10))

        # Mini Prozessliste
        list_frame = tk.Frame(frame, bg=self.colors['bg_card'])
        list_frame.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        self.top_process_labels = []
        for i in range(5):
            row = tk.Frame(list_frame, bg=self.colors['bg_card'])
            row.pack(fill='x', pady=2)

            name_lbl = tk.Label(row, text="--",
                               font=('Segoe UI', 9),
                               bg=self.colors['bg_card'],
                               fg=self.colors['text_primary'],
                               width=25, anchor='w')
            name_lbl.pack(side='left')

            cpu_lbl = tk.Label(row, text="0%",
                              font=('Segoe UI', 9, 'bold'),
                              bg=self.colors['bg_card'],
                              fg=self.colors['accent_blue'],
                              width=8)
            cpu_lbl.pack(side='right')

            self.top_process_labels.append({'name': name_lbl, 'cpu': cpu_lbl})

    def create_processes_tab(self):
        tab = tk.Frame(self.notebook, bg=self.colors['bg_primary'])
        self.notebook.add(tab, text='  Prozesse  ')

        # Toolbar
        toolbar = tk.Frame(tab, bg=self.colors['bg_card'], height=50)
        toolbar.pack(fill='x', padx=10, pady=10)
        toolbar.pack_propagate(False)

        # Suchfeld
        search_frame = tk.Frame(toolbar, bg=self.colors['bg_card'])
        search_frame.pack(side='left', padx=15, pady=10)

        search_label = tk.Label(search_frame, text="Suchen:",
                               font=('Segoe UI', 10),
                               bg=self.colors['bg_card'],
                               fg=self.colors['text_secondary'])
        search_label.pack(side='left', padx=(0, 10))

        self.process_search = tk.Entry(search_frame,
                                      font=('Segoe UI', 10),
                                      bg=self.colors['bg_secondary'],
                                      fg=self.colors['text_primary'],
                                      insertbackground=self.colors['text_primary'],
                                      bd=0, width=30)
        self.process_search.pack(side='left', ipady=5, ipadx=10)
        self.process_search.bind('<KeyRelease>', self.filter_processes)

        # Buttons
        btn_frame = tk.Frame(toolbar, bg=self.colors['bg_card'])
        btn_frame.pack(side='right', padx=15, pady=10)

        refresh_btn = tk.Button(btn_frame, text="Aktualisieren",
                               font=('Segoe UI', 9),
                               bg=self.colors['accent_blue'],
                               fg=self.colors['text_primary'],
                               activebackground=self.colors['accent_cyan'],
                               bd=0, padx=15, pady=5,
                               cursor='hand2',
                               command=self.refresh_processes)
        refresh_btn.pack(side='left', padx=5)

        kill_btn = tk.Button(btn_frame, text="Beenden",
                            font=('Segoe UI', 9),
                            bg=self.colors['accent_red'],
                            fg=self.colors['text_primary'],
                            activebackground='#ff6b7a',
                            bd=0, padx=15, pady=5,
                            cursor='hand2',
                            command=self.kill_process)
        kill_btn.pack(side='left', padx=5)

        # Prozessliste
        list_frame = tk.Frame(tab, bg=self.colors['bg_secondary'])
        list_frame.pack(fill='both', expand=True, padx=10, pady=(0, 10))

        columns = ('pid', 'name', 'status', 'cpu', 'memory', 'threads')
        self.process_tree = ttk.Treeview(list_frame, columns=columns,
                                        show='headings', style='Custom.Treeview')

        self.process_tree.heading('pid', text='PID', command=lambda: self.sort_processes('pid'))
        self.process_tree.heading('name', text='Name', command=lambda: self.sort_processes('name'))
        self.process_tree.heading('status', text='Status', command=lambda: self.sort_processes('status'))
        self.process_tree.heading('cpu', text='CPU %', command=lambda: self.sort_processes('cpu'))
        self.process_tree.heading('memory', text='RAM %', command=lambda: self.sort_processes('memory'))
        self.process_tree.heading('threads', text='Threads', command=lambda: self.sort_processes('threads'))

        self.process_tree.column('pid', width=70, anchor='center')
        self.process_tree.column('name', width=250)
        self.process_tree.column('status', width=100, anchor='center')
        self.process_tree.column('cpu', width=80, anchor='center')
        self.process_tree.column('memory', width=80, anchor='center')
        self.process_tree.column('threads', width=70, anchor='center')

        scrollbar = ttk.Scrollbar(list_frame, orient='vertical',
                                 command=self.process_tree.yview,
                                 style='Custom.Vertical.TScrollbar')
        self.process_tree.configure(yscrollcommand=scrollbar.set)

        self.process_tree.pack(side='left', fill='both', expand=True)
        scrollbar.pack(side='right', fill='y')

        # Prozess-Cache für Sortierung
        self.process_cache = []
        self.sort_column = 'cpu'
        self.sort_reverse = True

    def create_network_tab(self):
        tab = tk.Frame(self.notebook, bg=self.colors['bg_primary'])
        self.notebook.add(tab, text='  Netzwerk  ')

        # Obere Zeile - Geschwindigkeiten
        top_frame = tk.Frame(tab, bg=self.colors['bg_primary'])
        top_frame.pack(fill='x', padx=10, pady=10)

        # Download Card
        download_card = tk.Frame(top_frame, bg=self.colors['bg_card'])
        download_card.configure(highlightbackground=self.colors['border'],
                               highlightthickness=1)
        download_card.pack(side='left', fill='both', expand=True, padx=(0, 5))

        tk.Label(download_card, text="Download",
                font=('Segoe UI', 11, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(pady=(15, 5))

        self.download_speed = tk.Label(download_card, text="0 KB/s",
                                       font=('Segoe UI', 24, 'bold'),
                                       bg=self.colors['bg_card'],
                                       fg=self.colors['accent_green'])
        self.download_speed.pack()

        self.download_total = tk.Label(download_card, text="Gesamt: 0 MB",
                                       font=('Segoe UI', 9),
                                       bg=self.colors['bg_card'],
                                       fg=self.colors['text_dim'])
        self.download_total.pack(pady=(5, 15))

        # Upload Card
        upload_card = tk.Frame(top_frame, bg=self.colors['bg_card'])
        upload_card.configure(highlightbackground=self.colors['border'],
                             highlightthickness=1)
        upload_card.pack(side='left', fill='both', expand=True, padx=(5, 0))

        tk.Label(upload_card, text="Upload",
                font=('Segoe UI', 11, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(pady=(15, 5))

        self.upload_speed = tk.Label(upload_card, text="0 KB/s",
                                     font=('Segoe UI', 24, 'bold'),
                                     bg=self.colors['bg_card'],
                                     fg=self.colors['accent_pink'])
        self.upload_speed.pack()

        self.upload_total = tk.Label(upload_card, text="Gesamt: 0 MB",
                                     font=('Segoe UI', 9),
                                     bg=self.colors['bg_card'],
                                     fg=self.colors['text_dim'])
        self.upload_total.pack(pady=(5, 15))

        # Netzwerk-Interfaces
        interfaces_frame = tk.Frame(tab, bg=self.colors['bg_card'])
        interfaces_frame.configure(highlightbackground=self.colors['border'],
                                  highlightthickness=1)
        interfaces_frame.pack(fill='both', expand=True, padx=10, pady=(0, 10))

        tk.Label(interfaces_frame, text="Netzwerk-Interfaces",
                font=('Segoe UI', 11, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        # Interface Liste
        columns = ('name', 'ip', 'mac', 'status')
        self.net_tree = ttk.Treeview(interfaces_frame, columns=columns,
                                    show='headings', style='Custom.Treeview', height=8)

        self.net_tree.heading('name', text='Interface')
        self.net_tree.heading('ip', text='IP-Adresse')
        self.net_tree.heading('mac', text='MAC-Adresse')
        self.net_tree.heading('status', text='Status')

        self.net_tree.column('name', width=150)
        self.net_tree.column('ip', width=150)
        self.net_tree.column('mac', width=180)
        self.net_tree.column('status', width=100, anchor='center')

        self.net_tree.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        # Interfaces laden
        self.load_network_interfaces()

    def create_disks_tab(self):
        tab = tk.Frame(self.notebook, bg=self.colors['bg_primary'])
        self.notebook.add(tab, text='  Festplatten  ')

        # Disk I/O Anzeige
        io_frame = tk.Frame(tab, bg=self.colors['bg_primary'])
        io_frame.pack(fill='x', padx=10, pady=10)

        # Read Card
        read_card = tk.Frame(io_frame, bg=self.colors['bg_card'])
        read_card.configure(highlightbackground=self.colors['border'],
                           highlightthickness=1)
        read_card.pack(side='left', fill='both', expand=True, padx=(0, 5))

        tk.Label(read_card, text="Lesen",
                font=('Segoe UI', 11, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(pady=(15, 5))

        self.disk_read_speed = tk.Label(read_card, text="0 MB/s",
                                        font=('Segoe UI', 20, 'bold'),
                                        bg=self.colors['bg_card'],
                                        fg=self.colors['accent_cyan'])
        self.disk_read_speed.pack(pady=(0, 15))

        # Write Card
        write_card = tk.Frame(io_frame, bg=self.colors['bg_card'])
        write_card.configure(highlightbackground=self.colors['border'],
                            highlightthickness=1)
        write_card.pack(side='left', fill='both', expand=True, padx=(5, 0))

        tk.Label(write_card, text="Schreiben",
                font=('Segoe UI', 11, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(pady=(15, 5))

        self.disk_write_speed = tk.Label(write_card, text="0 MB/s",
                                         font=('Segoe UI', 20, 'bold'),
                                         bg=self.colors['bg_card'],
                                         fg=self.colors['accent_orange'])
        self.disk_write_speed.pack(pady=(0, 15))

        # Partitionen
        partitions_frame = tk.Frame(tab, bg=self.colors['bg_card'])
        partitions_frame.configure(highlightbackground=self.colors['border'],
                                  highlightthickness=1)
        partitions_frame.pack(fill='both', expand=True, padx=10, pady=(0, 10))

        tk.Label(partitions_frame, text="Partitionen",
                font=('Segoe UI', 11, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        # Partition Cards Container
        self.partitions_container = tk.Frame(partitions_frame, bg=self.colors['bg_card'])
        self.partitions_container.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        self.load_partitions()

    def create_system_tab(self):
        tab = tk.Frame(self.notebook, bg=self.colors['bg_primary'])
        self.notebook.add(tab, text='  System  ')

        # Scrollable Frame
        canvas = tk.Canvas(tab, bg=self.colors['bg_primary'], highlightthickness=0)
        scrollbar = ttk.Scrollbar(tab, orient='vertical', command=canvas.yview)
        scrollable_frame = tk.Frame(canvas, bg=self.colors['bg_primary'])

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor='nw')
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side='left', fill='both', expand=True, padx=10, pady=10)
        scrollbar.pack(side='right', fill='y', pady=10)

        # Hardware Info
        hw_frame = tk.Frame(scrollable_frame, bg=self.colors['bg_card'])
        hw_frame.configure(highlightbackground=self.colors['border'],
                          highlightthickness=1)
        hw_frame.pack(fill='x', pady=(0, 10))

        tk.Label(hw_frame, text="Hardware",
                font=('Segoe UI', 12, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        hw_info = self.get_hardware_info()
        for label, value in hw_info:
            row = tk.Frame(hw_frame, bg=self.colors['bg_card'])
            row.pack(fill='x', padx=15, pady=3)

            tk.Label(row, text=f"{label}:",
                    font=('Segoe UI', 10),
                    bg=self.colors['bg_card'],
                    fg=self.colors['text_dim'],
                    width=20, anchor='w').pack(side='left')

            tk.Label(row, text=value,
                    font=('Segoe UI', 10),
                    bg=self.colors['bg_card'],
                    fg=self.colors['text_primary']).pack(side='left')

        tk.Frame(hw_frame, bg=self.colors['bg_card'], height=15).pack()

        # Software Info
        sw_frame = tk.Frame(scrollable_frame, bg=self.colors['bg_card'])
        sw_frame.configure(highlightbackground=self.colors['border'],
                          highlightthickness=1)
        sw_frame.pack(fill='x', pady=(0, 10))

        tk.Label(sw_frame, text="Software",
                font=('Segoe UI', 12, 'bold'),
                bg=self.colors['bg_card'],
                fg=self.colors['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        sw_info = self.get_software_info()
        for label, value in sw_info:
            row = tk.Frame(sw_frame, bg=self.colors['bg_card'])
            row.pack(fill='x', padx=15, pady=3)

            tk.Label(row, text=f"{label}:",
                    font=('Segoe UI', 10),
                    bg=self.colors['bg_card'],
                    fg=self.colors['text_dim'],
                    width=20, anchor='w').pack(side='left')

            tk.Label(row, text=value,
                    font=('Segoe UI', 10),
                    bg=self.colors['bg_card'],
                    fg=self.colors['text_primary']).pack(side='left')

        tk.Frame(sw_frame, bg=self.colors['bg_card'], height=15).pack()

        # Batterie (falls vorhanden)
        battery = psutil.sensors_battery()
        if battery:
            bat_frame = tk.Frame(scrollable_frame, bg=self.colors['bg_card'])
            bat_frame.configure(highlightbackground=self.colors['border'],
                               highlightthickness=1)
            bat_frame.pack(fill='x', pady=(0, 10))

            tk.Label(bat_frame, text="Batterie",
                    font=('Segoe UI', 12, 'bold'),
                    bg=self.colors['bg_card'],
                    fg=self.colors['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

            # Batterie-Anzeige
            bat_container = tk.Frame(bat_frame, bg=self.colors['bg_card'])
            bat_container.pack(fill='x', padx=15, pady=(0, 15))

            self.battery_circle = CircularProgress(bat_container, size=80, thickness=8,
                                                   colors={'bg': self.colors['bg_secondary'],
                                                          'fg': self.colors['accent_green'],
                                                          'text': self.colors['text_primary']},
                                                   bg=self.colors['bg_card'])
            self.battery_circle.pack(side='left', padx=(0, 20))

            bat_info_frame = tk.Frame(bat_container, bg=self.colors['bg_card'])
            bat_info_frame.pack(side='left', fill='both', expand=True)

            self.battery_status = tk.Label(bat_info_frame, text="--",
                                          font=('Segoe UI', 10),
                                          bg=self.colors['bg_card'],
                                          fg=self.colors['text_primary'])
            self.battery_status.pack(anchor='w')

            self.battery_time = tk.Label(bat_info_frame, text="--",
                                        font=('Segoe UI', 10),
                                        bg=self.colors['bg_card'],
                                        fg=self.colors['text_dim'])
            self.battery_time.pack(anchor='w')

    def get_hardware_info(self):
        info = []

        # CPU
        info.append(("Prozessor", platform.processor() or "Unknown"))
        info.append(("CPU Kerne (physisch)", str(psutil.cpu_count(logical=False))))
        info.append(("CPU Kerne (logisch)", str(psutil.cpu_count())))

        # RAM
        mem = psutil.virtual_memory()
        info.append(("RAM Gesamt", self.format_bytes(mem.total)))

        # Architektur
        info.append(("Architektur", platform.machine()))

        return info

    def get_software_info(self):
        info = []

        info.append(("Betriebssystem", platform.system()))
        info.append(("OS Version", platform.release()))
        info.append(("OS Build", platform.version()))
        info.append(("Hostname", socket.gethostname()))
        info.append(("Python Version", platform.python_version()))

        # Benutzer
        try:
            import getpass
            info.append(("Benutzer", getpass.getuser()))
        except:
            pass

        return info

    def load_network_interfaces(self):
        for item in self.net_tree.get_children():
            self.net_tree.delete(item)

        addrs = psutil.net_if_addrs()
        stats = psutil.net_if_stats()

        for interface, addresses in addrs.items():
            ip = "N/A"
            mac = "N/A"

            for addr in addresses:
                if addr.family.name == 'AF_INET':
                    ip = addr.address
                elif addr.family.name == 'AF_LINK' or addr.family.name == 'AF_PACKET':
                    mac = addr.address

            status = "Aktiv" if stats.get(interface, None) and stats[interface].isup else "Inaktiv"

            self.net_tree.insert('', 'end', values=(interface, ip, mac, status))

    def load_partitions(self):
        # Alte Widgets entfernen
        for widget in self.partitions_container.winfo_children():
            widget.destroy()

        partitions = psutil.disk_partitions()

        for i, partition in enumerate(partitions):
            try:
                usage = psutil.disk_usage(partition.mountpoint)

                part_frame = tk.Frame(self.partitions_container, bg=self.colors['bg_secondary'])
                part_frame.pack(fill='x', pady=5)

                # Info
                info_frame = tk.Frame(part_frame, bg=self.colors['bg_secondary'])
                info_frame.pack(fill='x', padx=10, pady=10)

                # Name und Typ
                name_frame = tk.Frame(info_frame, bg=self.colors['bg_secondary'])
                name_frame.pack(fill='x')

                tk.Label(name_frame, text=partition.device,
                        font=('Segoe UI', 10, 'bold'),
                        bg=self.colors['bg_secondary'],
                        fg=self.colors['text_primary']).pack(side='left')

                tk.Label(name_frame, text=f"  ({partition.fstype})",
                        font=('Segoe UI', 9),
                        bg=self.colors['bg_secondary'],
                        fg=self.colors['text_dim']).pack(side='left')

                tk.Label(name_frame, text=f"{usage.percent}%",
                        font=('Segoe UI', 10, 'bold'),
                        bg=self.colors['bg_secondary'],
                        fg=self.colors['accent_yellow']).pack(side='right')

                # Progressbar
                progress = AnimatedProgressBar(info_frame, width=400, height=6,
                                              colors=[self.colors['accent_yellow'],
                                                     self.colors['accent_orange']],
                                              bg=self.colors['bg_secondary'])
                progress.pack(fill='x', pady=(5, 0))
                progress.set_value(usage.percent)

                # Details
                details = tk.Label(info_frame,
                                  text=f"{self.format_bytes(usage.used)} / {self.format_bytes(usage.total)} ({self.format_bytes(usage.free)} frei)",
                                  font=('Segoe UI', 9),
                                  bg=self.colors['bg_secondary'],
                                  fg=self.colors['text_dim'])
                details.pack(anchor='w', pady=(5, 0))

            except (PermissionError, OSError):
                continue

    def format_bytes(self, bytes_val):
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_val < 1024:
                return f"{bytes_val:.1f} {unit}"
            bytes_val /= 1024
        return f"{bytes_val:.1f} PB"

    def format_speed(self, bytes_per_sec):
        if bytes_per_sec < 1024:
            return f"{bytes_per_sec:.0f} B/s"
        elif bytes_per_sec < 1024 * 1024:
            return f"{bytes_per_sec / 1024:.1f} KB/s"
        else:
            return f"{bytes_per_sec / (1024 * 1024):.2f} MB/s"

    def start_updates(self):
        self.update_stats()
        self.root.after(self.update_interval, self.start_updates)

    def update_stats(self):
        try:
            # Zeit aktualisieren
            self.time_label.config(text=datetime.now().strftime("%H:%M:%S"))

            # Uptime
            boot_time = psutil.boot_time()
            uptime_seconds = time.time() - boot_time
            hours, remainder = divmod(int(uptime_seconds), 3600)
            minutes, seconds = divmod(remainder, 60)
            self.uptime_label.config(text=f"Uptime: {hours:02d}:{minutes:02d}:{seconds:02d}")

            # CPU
            cpu_percent = psutil.cpu_percent(interval=0)
            self.cpu_card['circle'].set_value(cpu_percent)
            self.cpu_card['mini_graph'].add_value(cpu_percent)
            self.cpu_graph.add_value(cpu_percent)

            freq = psutil.cpu_freq()
            if freq:
                self.cpu_card['detail1'].config(text=f"{freq.current:.0f} MHz")
            self.cpu_card['detail2'].config(text=f"{psutil.cpu_count()} Kerne")

            # RAM
            mem = psutil.virtual_memory()
            self.ram_card['circle'].set_value(mem.percent)
            self.ram_card['mini_graph'].add_value(mem.percent)
            self.ram_graph.add_value(mem.percent)
            self.ram_card['detail1'].config(text=f"{self.format_bytes(mem.used)}")
            self.ram_card['detail2'].config(text=f"von {self.format_bytes(mem.total)}")

            # Disk
            disk = psutil.disk_usage('/')
            self.disk_card['circle'].set_value(disk.percent)
            self.disk_card['mini_graph'].add_value(disk.percent)
            self.disk_card['detail1'].config(text=f"{self.format_bytes(disk.used)}")
            self.disk_card['detail2'].config(text=f"von {self.format_bytes(disk.total)}")

            # Disk I/O
            disk_io = psutil.disk_io_counters()
            if disk_io:
                read_speed = disk_io.read_bytes - self.disk_read_prev
                write_speed = disk_io.write_bytes - self.disk_write_prev
                self.disk_read_prev = disk_io.read_bytes
                self.disk_write_prev = disk_io.write_bytes

                if hasattr(self, 'disk_read_speed'):
                    self.disk_read_speed.config(text=self.format_speed(read_speed))
                    self.disk_write_speed.config(text=self.format_speed(write_speed))

            # Netzwerk
            net = psutil.net_io_counters()

            # Geschwindigkeit berechnen
            recv_speed = net.bytes_recv - self.net_recv_prev
            sent_speed = net.bytes_sent - self.net_sent_prev
            self.net_recv_prev = net.bytes_recv
            self.net_sent_prev = net.bytes_sent

            # Network Card (Dashboard)
            total_speed = recv_speed + sent_speed
            speed_percent = min(100, (total_speed / (10 * 1024 * 1024)) * 100)  # Max 10 MB/s = 100%
            self.net_card['circle'].set_value(speed_percent, self.format_speed(total_speed))
            self.net_card['mini_graph'].add_value(speed_percent)
            self.net_card['detail1'].config(text=f"↓ {self.format_speed(recv_speed)}")
            self.net_card['detail2'].config(text=f"↑ {self.format_speed(sent_speed)}")

            # Network Tab
            if hasattr(self, 'download_speed'):
                self.download_speed.config(text=self.format_speed(recv_speed))
                self.upload_speed.config(text=self.format_speed(sent_speed))
                self.download_total.config(text=f"Gesamt: {self.format_bytes(net.bytes_recv)}")
                self.upload_total.config(text=f"Gesamt: {self.format_bytes(net.bytes_sent)}")

            # Top Prozesse
            self.update_top_processes()

            # Batterie
            if hasattr(self, 'battery_circle'):
                battery = psutil.sensors_battery()
                if battery:
                    self.battery_circle.set_value(battery.percent)
                    status = "Lädt" if battery.power_plugged else "Batterie"
                    self.battery_status.config(text=f"Status: {status}")
                    if battery.secsleft > 0 and not battery.power_plugged:
                        hours, remainder = divmod(battery.secsleft, 3600)
                        minutes, _ = divmod(remainder, 60)
                        self.battery_time.config(text=f"Verbleibend: {int(hours)}h {int(minutes)}m")
                    else:
                        self.battery_time.config(text="")

        except Exception as e:
            print(f"Update error: {e}")

    def update_top_processes(self):
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
            try:
                pinfo = proc.info
                if pinfo['cpu_percent'] is not None and pinfo['cpu_percent'] > 0:
                    processes.append(pinfo)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass

        processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)

        for i, label_set in enumerate(self.top_process_labels):
            if i < len(processes):
                proc = processes[i]
                name = proc['name'][:22] if proc['name'] else 'N/A'
                label_set['name'].config(text=name)
                label_set['cpu'].config(text=f"{proc['cpu_percent']:.1f}%")
            else:
                label_set['name'].config(text="--")
                label_set['cpu'].config(text="0%")

    def refresh_processes(self):
        self.process_cache = []

        for proc in psutil.process_iter(['pid', 'name', 'status', 'cpu_percent',
                                         'memory_percent', 'num_threads']):
            try:
                pinfo = proc.info
                self.process_cache.append({
                    'pid': pinfo['pid'],
                    'name': pinfo['name'] or 'N/A',
                    'status': pinfo['status'] or 'N/A',
                    'cpu': pinfo['cpu_percent'] or 0,
                    'memory': pinfo['memory_percent'] or 0,
                    'threads': pinfo['num_threads'] or 0
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass

        self.display_processes()

    def display_processes(self):
        # Sortieren
        self.process_cache.sort(
            key=lambda x: x[self.sort_column] if self.sort_column != 'name' else x[self.sort_column].lower(),
            reverse=self.sort_reverse
        )

        # Filter anwenden
        search_term = self.process_search.get().lower()

        # Anzeigen
        for item in self.process_tree.get_children():
            self.process_tree.delete(item)

        for proc in self.process_cache:
            if search_term and search_term not in proc['name'].lower():
                continue

            self.process_tree.insert('', 'end', values=(
                proc['pid'],
                proc['name'][:40],
                proc['status'],
                f"{proc['cpu']:.1f}",
                f"{proc['memory']:.1f}",
                proc['threads']
            ))

    def sort_processes(self, column):
        if self.sort_column == column:
            self.sort_reverse = not self.sort_reverse
        else:
            self.sort_column = column
            self.sort_reverse = True

        self.display_processes()

    def filter_processes(self, event=None):
        self.display_processes()

    def kill_process(self):
        selected = self.process_tree.selection()
        if not selected:
            messagebox.showwarning("Warnung", "Bitte wähle einen Prozess aus.")
            return

        item = self.process_tree.item(selected[0])
        pid = item['values'][0]
        name = item['values'][1]

        if messagebox.askyesno("Prozess beenden",
                              f"Möchtest du den Prozess '{name}' (PID: {pid}) beenden?"):
            try:
                proc = psutil.Process(pid)
                proc.terminate()
                self.root.after(500, self.refresh_processes)
                messagebox.showinfo("Erfolg", f"Prozess '{name}' wurde beendet.")
            except psutil.NoSuchProcess:
                messagebox.showerror("Fehler", "Prozess existiert nicht mehr.")
            except psutil.AccessDenied:
                messagebox.showerror("Fehler", "Keine Berechtigung zum Beenden dieses Prozesses.")

    def export_data(self):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        filename = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV Dateien", "*.csv"), ("JSON Dateien", "*.json")],
            initialfilename=f"systemmonitor_export_{timestamp}"
        )

        if not filename:
            return

        try:
            # Daten sammeln
            data = {
                'timestamp': datetime.now().isoformat(),
                'cpu_percent': psutil.cpu_percent(),
                'memory': dict(psutil.virtual_memory()._asdict()),
                'disk': dict(psutil.disk_usage('/')._asdict()),
                'network': dict(psutil.net_io_counters()._asdict()),
                'processes': []
            }

            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    data['processes'].append(proc.info)
                except:
                    pass

            if filename.endswith('.json'):
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, default=str)
            else:
                with open(filename, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.writer(f)
                    writer.writerow(['Metrik', 'Wert'])
                    writer.writerow(['Zeitstempel', data['timestamp']])
                    writer.writerow(['CPU %', data['cpu_percent']])
                    writer.writerow(['RAM %', data['memory']['percent']])
                    writer.writerow(['RAM Gesamt', self.format_bytes(data['memory']['total'])])
                    writer.writerow(['Disk %', data['disk']['percent']])
                    writer.writerow(['Disk Gesamt', self.format_bytes(data['disk']['total'])])

            messagebox.showinfo("Export", f"Daten wurden exportiert nach:\n{filename}")

        except Exception as e:
            messagebox.showerror("Fehler", f"Export fehlgeschlagen: {e}")

    def setup_keybindings(self):
        self.root.bind('<F5>', lambda e: self.refresh_processes())
        self.root.bind('<Control-e>', lambda e: self.export_data())
        self.root.bind('<Escape>', lambda e: self.on_close())

    def on_close(self):
        self.running = False
        self.root.destroy()


def main():
    root = tk.Tk()

    # Versuche, ein Icon zu setzen
    try:
        if sys.platform == 'win32':
            root.iconbitmap('icon.ico')
    except:
        pass

    app = SystemMonitorPro(root)

    # Initial Prozesse laden
    root.after(100, app.refresh_processes)

    root.mainloop()


if __name__ == "__main__":
    main()
