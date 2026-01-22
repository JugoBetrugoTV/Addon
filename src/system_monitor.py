"""
SystemMonitor Pro v4.0 - Apple-inspired System Monitor
Clean, minimal design with optimized performance
"""

import tkinter as tk
from tkinter import ttk, font as tkfont
import psutil
import platform
import socket
import time
import threading
from datetime import datetime, timedelta
from collections import deque


# ============================================================================
# Configuration
# ============================================================================

class Config:
    APP_NAME = "SystemMonitor Pro"
    VERSION = "4.0.0"
    WINDOW_WIDTH = 1280
    WINDOW_HEIGHT = 820

    # Performance: Update intervals (ms)
    UPDATE_DASHBOARD = 2000
    UPDATE_PROCESSES = 3000
    UPDATE_NETWORK = 2000
    UPDATE_DISKS = 5000
    UPDATE_SYSTEM = 10000

    # Graph settings
    GRAPH_POINTS = 60  # 2 min at 2s intervals
    GRAPH_HEIGHT = 120

    # Apple-inspired color palette (macOS Sonoma Dark)
    COLORS = {
        'bg_primary': '#1c1c1e',
        'bg_secondary': '#2c2c2e',
        'bg_tertiary': '#3a3a3c',
        'bg_elevated': '#323234',
        'separator': '#48484a',
        'text_primary': '#ffffff',
        'text_secondary': '#8e8e93',
        'text_tertiary': '#636366',
        'accent_blue': '#0a84ff',
        'accent_green': '#30d158',
        'accent_orange': '#ff9f0a',
        'accent_red': '#ff453a',
        'accent_purple': '#bf5af2',
        'accent_cyan': '#64d2ff',
        'accent_yellow': '#ffd60a',
        'accent_pink': '#ff375f',
        'sidebar_bg': '#252528',
        'sidebar_active': '#0a84ff',
        'sidebar_hover': '#333336',
        'card_bg': '#2c2c2e',
        'card_border': '#3a3a3c',
        'graph_grid': '#3a3a3c',
        'graph_bg': '#252528',
    }


# ============================================================================
# Smooth Graph Widget
# ============================================================================

class SmoothGraph(tk.Canvas):
    """Lightweight, efficient graph with Apple-style aesthetics"""

    def __init__(self, parent, width=400, height=120, color='#0a84ff',
                 label='', unit='%', max_val=100, **kwargs):
        super().__init__(parent, width=width, height=height,
                        bg=Config.COLORS['graph_bg'], highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.color = color
        self.label = label
        self.unit = unit
        self.max_val = max_val
        self.data = deque([0] * Config.GRAPH_POINTS, maxlen=Config.GRAPH_POINTS)
        self.bind('<Configure>', self._on_resize)

    def _on_resize(self, event):
        self.width = event.width
        self.height = event.height
        self.redraw()

    def add_value(self, value):
        self.data.append(min(value, self.max_val))
        self.redraw()

    def redraw(self):
        self.delete('all')
        w, h = self.width, self.height
        pad_left, pad_right, pad_top, pad_bottom = 45, 15, 25, 25
        graph_w = w - pad_left - pad_right
        graph_h = h - pad_top - pad_bottom

        if graph_w < 10 or graph_h < 10:
            return

        # Grid lines and labels
        for i in range(5):
            y = pad_top + (graph_h * i / 4)
            self.create_line(pad_left, y, w - pad_right, y,
                           fill=Config.COLORS['graph_grid'], width=1, dash=(2, 4))
            val = self.max_val * (4 - i) / 4
            if self.max_val <= 100:
                label = f"{int(val)}%"
            else:
                label = self._format_value(val)
            self.create_text(pad_left - 5, y, text=label, anchor='e',
                           font=('Segoe UI', 8), fill=Config.COLORS['text_tertiary'])

        # Time labels
        for i, t in enumerate(['2m', '1m', 'now']):
            x = pad_left + (graph_w * i / 2)
            self.create_text(x, h - 8, text=t, anchor='center',
                           font=('Segoe UI', 8), fill=Config.COLORS['text_tertiary'])

        # Draw filled area and line
        points_line = []
        points_fill = []
        data_list = list(self.data)

        for i, val in enumerate(data_list):
            x = pad_left + (i / max(len(data_list) - 1, 1)) * graph_w
            y = pad_top + graph_h - (val / max(self.max_val, 0.001)) * graph_h
            points_line.append((x, y))
            points_fill.append((x, y))

        if len(points_fill) >= 2:
            # Fill area
            fill_points = list(points_fill)
            fill_points.append((pad_left + graph_w, pad_top + graph_h))
            fill_points.append((pad_left, pad_top + graph_h))
            flat_fill = [coord for point in fill_points for coord in point]
            self.create_polygon(flat_fill, fill=self._alpha_color(self.color, 0.15),
                              outline='')

            # Line
            flat_line = [coord for point in points_line for coord in point]
            self.create_line(flat_line, fill=self.color, width=1.5, smooth=True)

            # Current value dot
            if points_line:
                lx, ly = points_line[-1]
                self.create_oval(lx - 3, ly - 3, lx + 3, ly + 3,
                               fill=self.color, outline='white', width=1)

        # Label and current value
        current = self.data[-1] if self.data else 0
        if self.max_val <= 100:
            val_text = f"{current:.1f}{self.unit}"
        else:
            val_text = self._format_value(current)
        self.create_text(pad_left + 5, 10, text=self.label,
                        font=('Segoe UI', 9, 'bold'), fill=Config.COLORS['text_secondary'],
                        anchor='w')
        self.create_text(w - pad_right - 5, 10, text=val_text,
                        font=('Segoe UI', 9), fill=self.color, anchor='e')

    def _format_value(self, val):
        if val >= 1e9:
            return f"{val/1e9:.1f} GB/s"
        elif val >= 1e6:
            return f"{val/1e6:.1f} MB/s"
        elif val >= 1e3:
            return f"{val/1e3:.1f} KB/s"
        return f"{val:.0f} B/s"

    def _alpha_color(self, hex_color, alpha):
        """Create a darker version of color to simulate alpha on dark bg"""
        r = int(hex_color[1:3], 16)
        g = int(hex_color[3:5], 16)
        b = int(hex_color[5:7], 16)
        bg_r, bg_g, bg_b = 0x25, 0x25, 0x28
        r = int(bg_r + (r - bg_r) * alpha)
        g = int(bg_g + (g - bg_g) * alpha)
        b = int(bg_b + (b - bg_b) * alpha)
        return f'#{r:02x}{g:02x}{b:02x}'


# ============================================================================
# Circular Gauge (Apple-style thin ring)
# ============================================================================

class CircularGauge(tk.Canvas):
    """Thin, elegant circular gauge like Apple Watch rings"""

    def __init__(self, parent, size=90, thickness=6, color='#0a84ff',
                 label='', **kwargs):
        super().__init__(parent, width=size, height=size,
                        bg=Config.COLORS['card_bg'], highlightthickness=0, **kwargs)
        self.size = size
        self.thickness = thickness
        self.color = color
        self.label = label
        self.value = 0
        self.draw()

    def set_value(self, value):
        self.value = min(max(value, 0), 100)
        self.draw()

    def draw(self):
        self.delete('all')
        s = self.size
        pad = self.thickness + 4
        # Background ring
        self.create_arc(pad, pad, s - pad, s - pad, start=90, extent=-360,
                       style='arc', outline=Config.COLORS['bg_tertiary'],
                       width=self.thickness)
        # Value ring
        extent = -(self.value / 100) * 360
        if extent != 0:
            self.create_arc(pad, pad, s - pad, s - pad, start=90, extent=extent,
                          style='arc', outline=self.color, width=self.thickness)
        # Center text
        self.create_text(s // 2, s // 2 - 6, text=f"{self.value:.0f}%",
                        font=('Segoe UI', 13, 'bold'),
                        fill=Config.COLORS['text_primary'])
        self.create_text(s // 2, s // 2 + 12, text=self.label,
                        font=('Segoe UI', 8),
                        fill=Config.COLORS['text_secondary'])


# ============================================================================
# Main Application
# ============================================================================

class SystemMonitorApp:
    def __init__(self, root):
        self.root = root
        self.root.title(f"{Config.APP_NAME} v{Config.VERSION}")
        self.root.geometry(f"{Config.WINDOW_WIDTH}x{Config.WINDOW_HEIGHT}")
        self.root.configure(bg=Config.COLORS['bg_primary'])
        self.root.minsize(900, 600)

        # Data stores
        self.cpu_history = deque([0] * Config.GRAPH_POINTS, maxlen=Config.GRAPH_POINTS)
        self.mem_history = deque([0] * Config.GRAPH_POINTS, maxlen=Config.GRAPH_POINTS)
        self.net_down_history = deque([0] * Config.GRAPH_POINTS, maxlen=Config.GRAPH_POINTS)
        self.net_up_history = deque([0] * Config.GRAPH_POINTS, maxlen=Config.GRAPH_POINTS)
        self.last_net = psutil.net_io_counters()
        self.last_disk_io = psutil.disk_io_counters()
        self.last_update_time = time.time()
        self.current_page = 'dashboard'
        self.update_jobs = []
        self.sort_column = 'cpu'
        self.sort_reverse = True

        self._setup_styles()
        self._create_ui()
        self.show_page('dashboard')

    def _setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        c = Config.COLORS

        style.configure('TFrame', background=c['bg_primary'])
        style.configure('Card.TFrame', background=c['card_bg'])
        style.configure('Sidebar.TFrame', background=c['sidebar_bg'])

        style.configure('TLabel', background=c['bg_primary'],
                       foreground=c['text_primary'], font=('Segoe UI', 10))
        style.configure('Card.TLabel', background=c['card_bg'],
                       foreground=c['text_primary'])
        style.configure('Title.TLabel', font=('Segoe UI', 22, 'bold'),
                       foreground=c['text_primary'], background=c['bg_primary'])
        style.configure('Subtitle.TLabel', font=('Segoe UI', 11),
                       foreground=c['text_secondary'], background=c['bg_primary'])
        style.configure('CardTitle.TLabel', font=('Segoe UI', 12, 'bold'),
                       foreground=c['text_primary'], background=c['card_bg'])
        style.configure('Value.TLabel', font=('Segoe UI', 24, 'bold'),
                       foreground=c['accent_blue'], background=c['card_bg'])
        style.configure('Unit.TLabel', font=('Segoe UI', 10),
                       foreground=c['text_secondary'], background=c['card_bg'])
        style.configure('Muted.TLabel', font=('Segoe UI', 9),
                       foreground=c['text_tertiary'], background=c['card_bg'])

        # Treeview (process list)
        style.configure('Treeview',
                       background=c['bg_secondary'],
                       foreground=c['text_primary'],
                       fieldbackground=c['bg_secondary'],
                       borderwidth=0,
                       font=('Segoe UI', 9),
                       rowheight=26)
        style.configure('Treeview.Heading',
                       background=c['bg_tertiary'],
                       foreground=c['text_primary'],
                       font=('Segoe UI', 9, 'bold'),
                       borderwidth=0)
        style.map('Treeview',
                 background=[('selected', c['accent_blue'])],
                 foreground=[('selected', '#ffffff')])
        style.map('Treeview.Heading',
                 background=[('active', c['separator'])])

        # Buttons
        style.configure('Accent.TButton',
                       background=c['accent_blue'],
                       foreground='#ffffff',
                       font=('Segoe UI', 10, 'bold'),
                       padding=(15, 6))
        style.map('Accent.TButton',
                 background=[('active', '#0070e0')])
        style.configure('Danger.TButton',
                       background=c['accent_red'],
                       foreground='#ffffff',
                       font=('Segoe UI', 10, 'bold'),
                       padding=(15, 6))

        # Scrollbar
        style.configure('TScrollbar',
                       background=c['bg_secondary'],
                       troughcolor=c['bg_primary'],
                       borderwidth=0, width=8)

    def _create_ui(self):
        # Main container
        self.main_frame = ttk.Frame(self.root)
        self.main_frame.pack(fill='both', expand=True)

        # Sidebar
        self._create_sidebar()

        # Content area
        self.content_frame = ttk.Frame(self.main_frame)
        self.content_frame.pack(side='left', fill='both', expand=True, padx=(0, 0))

        # Pages
        self.pages = {}
        for page in ['dashboard', 'processes', 'network', 'disks', 'system']:
            frame = ttk.Frame(self.content_frame)
            self.pages[page] = frame

    def _create_sidebar(self):
        sidebar = ttk.Frame(self.main_frame, style='Sidebar.TFrame', width=200)
        sidebar.pack(side='left', fill='y')
        sidebar.pack_propagate(False)

        # App title
        title_frame = tk.Frame(sidebar, bg=Config.COLORS['sidebar_bg'], height=70)
        title_frame.pack(fill='x', pady=(15, 10))
        title_frame.pack_propagate(False)

        tk.Label(title_frame, text="System", font=('Segoe UI', 16, 'bold'),
                fg=Config.COLORS['text_primary'], bg=Config.COLORS['sidebar_bg']).pack(anchor='center')
        tk.Label(title_frame, text="Monitor", font=('Segoe UI', 16),
                fg=Config.COLORS['text_secondary'], bg=Config.COLORS['sidebar_bg']).pack(anchor='center')

        # Separator
        sep = tk.Frame(sidebar, bg=Config.COLORS['separator'], height=1)
        sep.pack(fill='x', padx=20, pady=10)

        # Navigation buttons
        self.nav_buttons = {}
        nav_items = [
            ('dashboard', 'Dashboard', '\u25c9'),
            ('processes', 'Prozesse', '\u2630'),
            ('network', 'Netzwerk', '\u21c5'),
            ('disks', 'Festplatten', '\u25c8'),
            ('system', 'System', '\u2699'),
        ]

        for page_id, label, icon in nav_items:
            btn = self._create_nav_button(sidebar, page_id, label, icon)
            self.nav_buttons[page_id] = btn

        # Version at bottom
        ver_label = tk.Label(sidebar, text=f"v{Config.VERSION}",
                           font=('Segoe UI', 8),
                           fg=Config.COLORS['text_tertiary'],
                           bg=Config.COLORS['sidebar_bg'])
        ver_label.pack(side='bottom', pady=10)

    def _create_nav_button(self, parent, page_id, label, icon):
        c = Config.COLORS
        frame = tk.Frame(parent, bg=c['sidebar_bg'], height=38, cursor='hand2')
        frame.pack(fill='x', padx=10, pady=2)
        frame.pack_propagate(False)

        indicator = tk.Frame(frame, bg=c['sidebar_bg'], width=3)
        indicator.pack(side='left', fill='y', padx=(0, 8))

        icon_lbl = tk.Label(frame, text=icon, font=('Segoe UI', 13),
                          fg=c['text_secondary'], bg=c['sidebar_bg'])
        icon_lbl.pack(side='left', padx=(5, 8))

        text_lbl = tk.Label(frame, text=label, font=('Segoe UI', 11),
                          fg=c['text_secondary'], bg=c['sidebar_bg'])
        text_lbl.pack(side='left')

        btn_data = {'frame': frame, 'indicator': indicator,
                   'icon': icon_lbl, 'text': text_lbl}

        for widget in [frame, icon_lbl, text_lbl]:
            widget.bind('<Button-1>', lambda e, p=page_id: self.show_page(p))
            widget.bind('<Enter>', lambda e, d=btn_data, p=page_id: self._nav_hover(d, p, True))
            widget.bind('<Leave>', lambda e, d=btn_data, p=page_id: self._nav_hover(d, p, False))

        return btn_data

    def _nav_hover(self, btn_data, page_id, entering):
        if self.current_page == page_id:
            return
        c = Config.COLORS
        bg = c['sidebar_hover'] if entering else c['sidebar_bg']
        for key in ['frame', 'icon', 'text']:
            btn_data[key].configure(bg=bg)

    def _set_nav_active(self, active_page):
        c = Config.COLORS
        for page_id, btn in self.nav_buttons.items():
            is_active = page_id == active_page
            bg = c['sidebar_active'] if is_active else c['sidebar_bg']
            fg = '#ffffff' if is_active else c['text_secondary']
            ind_bg = '#ffffff' if is_active else c['sidebar_bg']

            btn['frame'].configure(bg=bg)
            btn['icon'].configure(bg=bg, fg=fg)
            btn['text'].configure(bg=bg, fg=fg, font=('Segoe UI', 11, 'bold' if is_active else 'normal'))
            btn['indicator'].configure(bg=ind_bg)

    def show_page(self, page_id):
        # Cancel pending updates
        for job in self.update_jobs:
            try:
                self.root.after_cancel(job)
            except Exception:
                pass
        self.update_jobs.clear()

        self.current_page = page_id
        self._set_nav_active(page_id)

        # Hide all pages
        for frame in self.pages.values():
            frame.pack_forget()

        # Rebuild and show selected page
        page = self.pages[page_id]
        for child in page.winfo_children():
            child.destroy()
        page.pack(fill='both', expand=True, padx=20, pady=15)

        builders = {
            'dashboard': self._build_dashboard,
            'processes': self._build_processes,
            'network': self._build_network,
            'disks': self._build_disks,
            'system': self._build_system,
        }
        builders[page_id](page)

    # ========================================================================
    # Dashboard Page
    # ========================================================================

    def _build_dashboard(self, parent):
        self._page_header(parent, "Dashboard", "Systemuebersicht in Echtzeit")

        # Top gauges row
        gauges_frame = ttk.Frame(parent)
        gauges_frame.pack(fill='x', pady=(10, 15))

        self.dash_gauges = {}
        gauge_configs = [
            ('cpu', 'CPU', Config.COLORS['accent_blue']),
            ('memory', 'RAM', Config.COLORS['accent_green']),
            ('disk', 'Disk', Config.COLORS['accent_orange']),
            ('swap', 'Swap', Config.COLORS['accent_purple']),
        ]

        for i, (key, label, color) in enumerate(gauge_configs):
            card = self._create_card(gauges_frame)
            card.pack(side='left', fill='both', expand=True, padx=(0 if i == 0 else 5, 5))
            gauge = CircularGauge(card, size=90, thickness=5, color=color, label=label)
            gauge.pack(pady=10)
            info_label = ttk.Label(card, text="", style='Muted.TLabel')
            info_label.pack(pady=(0, 8))
            self.dash_gauges[key] = {'gauge': gauge, 'info': info_label}

        # Graphs row
        graphs_frame = ttk.Frame(parent)
        graphs_frame.pack(fill='both', expand=True, pady=(0, 10))

        # CPU Graph
        cpu_card = self._create_card(graphs_frame)
        cpu_card.pack(side='left', fill='both', expand=True, padx=(0, 5))
        self.cpu_graph = SmoothGraph(cpu_card, height=Config.GRAPH_HEIGHT,
                                    color=Config.COLORS['accent_blue'],
                                    label='CPU Usage')
        self.cpu_graph.pack(fill='both', expand=True, padx=8, pady=8)

        # Memory Graph
        mem_card = self._create_card(graphs_frame)
        mem_card.pack(side='left', fill='both', expand=True, padx=(5, 0))
        self.mem_graph = SmoothGraph(mem_card, height=Config.GRAPH_HEIGHT,
                                   color=Config.COLORS['accent_green'],
                                   label='Memory Usage')
        self.mem_graph.pack(fill='both', expand=True, padx=8, pady=8)

        # Bottom info row
        info_frame = ttk.Frame(parent)
        info_frame.pack(fill='x', pady=(0, 5))

        # Quick stats
        stats_card = self._create_card(info_frame)
        stats_card.pack(side='left', fill='both', expand=True, padx=(0, 5))
        self.dash_stats_frame = stats_card

        # Top processes
        proc_card = self._create_card(info_frame)
        proc_card.pack(side='left', fill='both', expand=True, padx=(5, 5))
        self.dash_proc_frame = proc_card

        # CPU cores
        cores_card = self._create_card(info_frame)
        cores_card.pack(side='left', fill='both', expand=True, padx=(5, 0))
        self.dash_cores_frame = cores_card

        self._update_dashboard()

    def _update_dashboard(self):
        if self.current_page != 'dashboard':
            return

        try:
            # CPU
            cpu_percent = psutil.cpu_percent(interval=0)
            self.cpu_history.append(cpu_percent)
            self.dash_gauges['cpu']['gauge'].set_value(cpu_percent)
            cpu_freq = psutil.cpu_freq()
            freq_text = f"{cpu_freq.current:.0f} MHz" if cpu_freq else "N/A"
            self.dash_gauges['cpu']['info'].config(text=freq_text)
            self.cpu_graph.data = self.cpu_history.copy()
            self.cpu_graph.redraw()

            # Memory
            mem = psutil.virtual_memory()
            self.mem_history.append(mem.percent)
            self.dash_gauges['memory']['gauge'].set_value(mem.percent)
            self.dash_gauges['memory']['info'].config(
                text=f"{mem.used / (1024**3):.1f} / {mem.total / (1024**3):.1f} GB")
            self.mem_graph.data = self.mem_history.copy()
            self.mem_graph.redraw()

            # Disk
            disk = psutil.disk_usage('/')
            self.dash_gauges['disk']['gauge'].set_value(disk.percent)
            self.dash_gauges['disk']['info'].config(
                text=f"{disk.used / (1024**3):.0f} / {disk.total / (1024**3):.0f} GB")

            # Swap
            swap = psutil.swap_memory()
            self.dash_gauges['swap']['gauge'].set_value(swap.percent)
            swap_total = swap.total / (1024**3)
            swap_used = swap.used / (1024**3)
            self.dash_gauges['swap']['info'].config(
                text=f"{swap_used:.1f} / {swap_total:.1f} GB")

            # Quick stats
            self._update_dash_stats()

            # Top processes
            self._update_dash_processes()

            # CPU cores
            self._update_dash_cores()

        except Exception:
            pass

        job = self.root.after(Config.UPDATE_DASHBOARD, self._update_dashboard)
        self.update_jobs.append(job)

    def _update_dash_stats(self):
        for w in self.dash_stats_frame.winfo_children():
            w.destroy()
        c = Config.COLORS

        ttk.Label(self.dash_stats_frame, text="System Info",
                 style='CardTitle.TLabel').pack(anchor='w', padx=12, pady=(10, 8))

        boot = datetime.fromtimestamp(psutil.boot_time())
        uptime = datetime.now() - boot
        hours, remainder = divmod(int(uptime.total_seconds()), 3600)
        mins, _ = divmod(remainder, 60)

        net = psutil.net_io_counters()
        stats = [
            ("Uptime", f"{hours}h {mins}m"),
            ("Prozesse", str(len(psutil.pids()))),
            ("Threads", str(sum(p.info['num_threads'] for p in
                              psutil.process_iter(['num_threads'])
                              if p.info['num_threads']))),
            ("Netzwerk \u2193", self._format_bytes(net.bytes_recv)),
            ("Netzwerk \u2191", self._format_bytes(net.bytes_sent)),
        ]

        for label, value in stats:
            row = tk.Frame(self.dash_stats_frame, bg=c['card_bg'])
            row.pack(fill='x', padx=12, pady=2)
            tk.Label(row, text=label, font=('Segoe UI', 9),
                   fg=c['text_secondary'], bg=c['card_bg']).pack(side='left')
            tk.Label(row, text=value, font=('Segoe UI', 9, 'bold'),
                   fg=c['text_primary'], bg=c['card_bg']).pack(side='right')

    def _update_dash_processes(self):
        for w in self.dash_proc_frame.winfo_children():
            w.destroy()
        c = Config.COLORS

        ttk.Label(self.dash_proc_frame, text="Top Prozesse",
                 style='CardTitle.TLabel').pack(anchor='w', padx=12, pady=(10, 8))

        procs = []
        for p in psutil.process_iter(['name', 'cpu_percent']):
            try:
                info = p.info
                if info['cpu_percent'] and info['cpu_percent'] > 0:
                    procs.append(info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        procs.sort(key=lambda x: x['cpu_percent'], reverse=True)

        for proc in procs[:6]:
            row = tk.Frame(self.dash_proc_frame, bg=c['card_bg'])
            row.pack(fill='x', padx=12, pady=1)
            name = proc['name'][:22]
            tk.Label(row, text=name, font=('Segoe UI', 9),
                   fg=c['text_secondary'], bg=c['card_bg']).pack(side='left')
            cpu_val = proc['cpu_percent']
            color = c['accent_red'] if cpu_val > 50 else (
                    c['accent_orange'] if cpu_val > 20 else c['accent_blue'])
            tk.Label(row, text=f"{cpu_val:.1f}%", font=('Segoe UI', 9, 'bold'),
                   fg=color, bg=c['card_bg']).pack(side='right')

    def _update_dash_cores(self):
        for w in self.dash_cores_frame.winfo_children():
            w.destroy()
        c = Config.COLORS

        ttk.Label(self.dash_cores_frame, text="CPU Kerne",
                 style='CardTitle.TLabel').pack(anchor='w', padx=12, pady=(10, 8))

        per_cpu = psutil.cpu_percent(percpu=True)
        # Show max 12 cores to avoid overflow
        display_cores = per_cpu[:12]

        for i, usage in enumerate(display_cores):
            row = tk.Frame(self.dash_cores_frame, bg=c['card_bg'], height=16)
            row.pack(fill='x', padx=12, pady=1)
            row.pack_propagate(False)

            tk.Label(row, text=f"{i}", font=('Segoe UI', 8),
                   fg=c['text_tertiary'], bg=c['card_bg'], width=3).pack(side='left')

            bar_bg = tk.Frame(row, bg=c['bg_tertiary'], height=8)
            bar_bg.pack(side='left', fill='x', expand=True, padx=(2, 5), pady=4)

            color = c['accent_red'] if usage > 80 else (
                    c['accent_orange'] if usage > 50 else c['accent_blue'])
            bar_width = max(usage / 100, 0.01)
            bar = tk.Frame(bar_bg, bg=color, height=8)
            bar.place(relx=0, rely=0, relwidth=bar_width, relheight=1)

            tk.Label(row, text=f"{usage:.0f}%", font=('Segoe UI', 8),
                   fg=c['text_secondary'], bg=c['card_bg'], width=4).pack(side='right')

        if len(per_cpu) > 12:
            tk.Label(self.dash_cores_frame,
                   text=f"+ {len(per_cpu) - 12} weitere Kerne",
                   font=('Segoe UI', 8), fg=c['text_tertiary'],
                   bg=c['card_bg']).pack(padx=12, pady=(4, 0))

    # ========================================================================
    # Processes Page
    # ========================================================================

    def _build_processes(self, parent):
        self._page_header(parent, "Prozesse", "Laufende Prozesse verwalten")

        # Toolbar
        toolbar = ttk.Frame(parent)
        toolbar.pack(fill='x', pady=(5, 10))

        # Search
        self.proc_search_var = tk.StringVar()
        self.proc_search_var.trace('w', lambda *a: self._update_processes())
        search_frame = tk.Frame(toolbar, bg=Config.COLORS['bg_tertiary'],
                               padx=8, pady=4)
        search_frame.pack(side='left')
        tk.Label(search_frame, text="\U0001f50d", bg=Config.COLORS['bg_tertiary'],
                fg=Config.COLORS['text_secondary']).pack(side='left')
        search_entry = tk.Entry(search_frame, textvariable=self.proc_search_var,
                              bg=Config.COLORS['bg_tertiary'],
                              fg=Config.COLORS['text_primary'],
                              insertbackground=Config.COLORS['text_primary'],
                              relief='flat', font=('Segoe UI', 10), width=25)
        search_entry.pack(side='left', padx=5)

        # Process count label
        self.proc_count_label = ttk.Label(toolbar, text="", style='Subtitle.TLabel')
        self.proc_count_label.pack(side='left', padx=15)

        # Buttons
        end_btn = tk.Button(toolbar, text="Beenden", font=('Segoe UI', 10, 'bold'),
                          bg=Config.COLORS['accent_red'], fg='white',
                          relief='flat', padx=12, pady=3,
                          command=self._end_process)
        end_btn.pack(side='right', padx=(5, 0))

        refresh_btn = tk.Button(toolbar, text="Aktualisieren", font=('Segoe UI', 10),
                              bg=Config.COLORS['accent_blue'], fg='white',
                              relief='flat', padx=12, pady=3,
                              command=self._update_processes)
        refresh_btn.pack(side='right')

        # Process tree
        tree_frame = ttk.Frame(parent)
        tree_frame.pack(fill='both', expand=True)

        columns = ('pid', 'name', 'status', 'cpu', 'memory', 'threads', 'user')
        self.proc_tree = ttk.Treeview(tree_frame, columns=columns,
                                     show='headings', selectmode='browse')

        headers = {
            'pid': ('PID', 65),
            'name': ('Name', 220),
            'status': ('Status', 80),
            'cpu': ('CPU %', 80),
            'memory': ('RAM %', 80),
            'threads': ('Threads', 70),
            'user': ('Benutzer', 120),
        }

        for col, (text, width) in headers.items():
            self.proc_tree.heading(col, text=text,
                                 command=lambda c=col: self._sort_processes(c))
            anchor = 'e' if col in ('cpu', 'memory', 'threads') else 'w'
            self.proc_tree.column(col, width=width, anchor=anchor)

        scrollbar = ttk.Scrollbar(tree_frame, orient='vertical',
                                 command=self.proc_tree.yview)
        self.proc_tree.configure(yscrollcommand=scrollbar.set)
        self.proc_tree.pack(side='left', fill='both', expand=True)
        scrollbar.pack(side='right', fill='y')

        self._update_processes()

    def _sort_processes(self, column):
        if self.sort_column == column:
            self.sort_reverse = not self.sort_reverse
        else:
            self.sort_column = column
            self.sort_reverse = True
        self._update_processes()

    def _update_processes(self, *args):
        if self.current_page != 'processes':
            return
        if not hasattr(self, 'proc_tree'):
            return

        search = self.proc_search_var.get().lower() if hasattr(self, 'proc_search_var') else ''

        procs = []
        for p in psutil.process_iter(['pid', 'name', 'status', 'cpu_percent',
                                      'memory_percent', 'num_threads', 'username']):
            try:
                info = p.info
                if search and search not in (info['name'] or '').lower():
                    continue
                procs.append(info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass

        # Sort
        sort_key = {
            'pid': 'pid', 'name': 'name', 'status': 'status',
            'cpu': 'cpu_percent', 'memory': 'memory_percent',
            'threads': 'num_threads', 'user': 'username'
        }.get(self.sort_column, 'cpu_percent')

        procs.sort(key=lambda x: x.get(sort_key) or 0, reverse=self.sort_reverse)

        # Update tree
        self.proc_tree.delete(*self.proc_tree.get_children())
        for info in procs[:200]:  # Limit for performance
            values = (
                info.get('pid', ''),
                info.get('name', 'N/A'),
                info.get('status', ''),
                f"{info.get('cpu_percent', 0):.1f}",
                f"{info.get('memory_percent', 0):.1f}",
                info.get('num_threads', 0),
                (info.get('username', '') or '').split('\\')[-1][:15],
            )
            self.proc_tree.insert('', 'end', values=values)

        if hasattr(self, 'proc_count_label'):
            self.proc_count_label.config(text=f"{len(procs)} Prozesse")

        job = self.root.after(Config.UPDATE_PROCESSES, self._update_processes)
        self.update_jobs.append(job)

    def _end_process(self):
        selection = self.proc_tree.selection()
        if not selection:
            return
        item = self.proc_tree.item(selection[0])
        pid = int(item['values'][0])
        try:
            p = psutil.Process(pid)
            p.terminate()
            self.root.after(500, self._update_processes)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    # ========================================================================
    # Network Page
    # ========================================================================

    def _build_network(self, parent):
        self._page_header(parent, "Netzwerk", "Netzwerkaktivitaet und Verbindungen")

        # Speed cards
        speed_frame = ttk.Frame(parent)
        speed_frame.pack(fill='x', pady=(10, 10))

        # Download card
        dl_card = self._create_card(speed_frame)
        dl_card.pack(side='left', fill='both', expand=True, padx=(0, 5))
        tk.Label(dl_card, text="\u2193", font=('Segoe UI', 18),
                fg=Config.COLORS['accent_green'], bg=Config.COLORS['card_bg']).pack(pady=(10, 0))
        tk.Label(dl_card, text="Download", font=('Segoe UI', 10),
                fg=Config.COLORS['text_secondary'], bg=Config.COLORS['card_bg']).pack()
        self.net_dl_label = tk.Label(dl_card, text="0 B/s",
                                   font=('Segoe UI', 20, 'bold'),
                                   fg=Config.COLORS['accent_green'],
                                   bg=Config.COLORS['card_bg'])
        self.net_dl_label.pack(pady=(2, 0))
        self.net_dl_total = tk.Label(dl_card, text="Total: 0 B",
                                   font=('Segoe UI', 9),
                                   fg=Config.COLORS['text_tertiary'],
                                   bg=Config.COLORS['card_bg'])
        self.net_dl_total.pack(pady=(0, 10))

        # Upload card
        ul_card = self._create_card(speed_frame)
        ul_card.pack(side='left', fill='both', expand=True, padx=(5, 5))
        tk.Label(ul_card, text="\u2191", font=('Segoe UI', 18),
                fg=Config.COLORS['accent_purple'], bg=Config.COLORS['card_bg']).pack(pady=(10, 0))
        tk.Label(ul_card, text="Upload", font=('Segoe UI', 10),
                fg=Config.COLORS['text_secondary'], bg=Config.COLORS['card_bg']).pack()
        self.net_ul_label = tk.Label(ul_card, text="0 B/s",
                                   font=('Segoe UI', 20, 'bold'),
                                   fg=Config.COLORS['accent_purple'],
                                   bg=Config.COLORS['card_bg'])
        self.net_ul_label.pack(pady=(2, 0))
        self.net_ul_total = tk.Label(ul_card, text="Total: 0 B",
                                   font=('Segoe UI', 9),
                                   fg=Config.COLORS['text_tertiary'],
                                   bg=Config.COLORS['card_bg'])
        self.net_ul_total.pack(pady=(0, 10))

        # Connections card
        conn_card = self._create_card(speed_frame)
        conn_card.pack(side='left', fill='both', expand=True, padx=(5, 0))
        tk.Label(conn_card, text="\u26a1", font=('Segoe UI', 18),
                fg=Config.COLORS['accent_cyan'], bg=Config.COLORS['card_bg']).pack(pady=(10, 0))
        tk.Label(conn_card, text="Verbindungen", font=('Segoe UI', 10),
                fg=Config.COLORS['text_secondary'], bg=Config.COLORS['card_bg']).pack()
        self.net_conn_label = tk.Label(conn_card, text="0",
                                     font=('Segoe UI', 20, 'bold'),
                                     fg=Config.COLORS['accent_cyan'],
                                     bg=Config.COLORS['card_bg'])
        self.net_conn_label.pack(pady=(2, 0))
        self.net_conn_detail = tk.Label(conn_card, text="",
                                      font=('Segoe UI', 9),
                                      fg=Config.COLORS['text_tertiary'],
                                      bg=Config.COLORS['card_bg'])
        self.net_conn_detail.pack(pady=(0, 10))

        # Graphs
        graph_frame = ttk.Frame(parent)
        graph_frame.pack(fill='both', expand=True, pady=(0, 10))

        dl_graph_card = self._create_card(graph_frame)
        dl_graph_card.pack(side='left', fill='both', expand=True, padx=(0, 5))
        self.net_dl_graph = SmoothGraph(dl_graph_card, height=130,
                                       color=Config.COLORS['accent_green'],
                                       label='Download', unit=' KB/s', max_val=1000)
        self.net_dl_graph.pack(fill='both', expand=True, padx=8, pady=8)

        ul_graph_card = self._create_card(graph_frame)
        ul_graph_card.pack(side='left', fill='both', expand=True, padx=(5, 0))
        self.net_ul_graph = SmoothGraph(ul_graph_card, height=130,
                                       color=Config.COLORS['accent_purple'],
                                       label='Upload', unit=' KB/s', max_val=1000)
        self.net_ul_graph.pack(fill='both', expand=True, padx=8, pady=8)

        # Interface table
        iface_card = self._create_card(parent)
        iface_card.pack(fill='x', pady=(0, 5))
        ttk.Label(iface_card, text="Netzwerk-Interfaces",
                 style='CardTitle.TLabel').pack(anchor='w', padx=12, pady=(10, 8))

        self.iface_frame = tk.Frame(iface_card, bg=Config.COLORS['card_bg'])
        self.iface_frame.pack(fill='x', padx=12, pady=(0, 10))

        self._update_network()

    def _update_network(self):
        if self.current_page != 'network':
            return

        try:
            now = time.time()
            dt = now - self.last_update_time
            if dt < 0.1:
                dt = Config.UPDATE_NETWORK / 1000

            net = psutil.net_io_counters()
            dl_speed = (net.bytes_recv - self.last_net.bytes_recv) / dt
            ul_speed = (net.bytes_sent - self.last_net.bytes_sent) / dt
            self.last_net = net
            self.last_update_time = now

            self.net_dl_label.config(text=self._format_speed(dl_speed))
            self.net_ul_label.config(text=self._format_speed(ul_speed))
            self.net_dl_total.config(text=f"Total: {self._format_bytes(net.bytes_recv)}")
            self.net_ul_total.config(text=f"Total: {self._format_bytes(net.bytes_sent)}")

            # Connections
            try:
                connections = psutil.net_connections(kind='inet')
                established = sum(1 for c in connections if c.status == 'ESTABLISHED')
                self.net_conn_label.config(text=str(len(connections)))
                self.net_conn_detail.config(text=f"{established} aktiv")
            except (psutil.AccessDenied, OSError):
                self.net_conn_label.config(text="N/A")

            # Update graphs
            dl_kb = dl_speed / 1024
            ul_kb = ul_speed / 1024
            self.net_down_history.append(dl_kb)
            self.net_up_history.append(ul_kb)

            # Auto-scale graphs
            max_dl = max(max(self.net_down_history), 10)
            max_ul = max(max(self.net_up_history), 10)
            self.net_dl_graph.max_val = max_dl * 1.2
            self.net_ul_graph.max_val = max_ul * 1.2
            self.net_dl_graph.data = self.net_down_history.copy()
            self.net_ul_graph.data = self.net_up_history.copy()
            self.net_dl_graph.redraw()
            self.net_ul_graph.redraw()

            # Interfaces
            self._update_interfaces()

        except Exception:
            pass

        job = self.root.after(Config.UPDATE_NETWORK, self._update_network)
        self.update_jobs.append(job)

    def _update_interfaces(self):
        for w in self.iface_frame.winfo_children():
            w.destroy()
        c = Config.COLORS

        # Header
        header = tk.Frame(self.iface_frame, bg=c['bg_tertiary'])
        header.pack(fill='x', pady=(0, 2))
        for text, w in [("Interface", 20), ("IP", 18), ("MAC", 20), ("Status", 8)]:
            tk.Label(header, text=text, font=('Segoe UI', 9, 'bold'),
                   fg=c['text_secondary'], bg=c['bg_tertiary'],
                   width=w, anchor='w').pack(side='left', padx=2)

        addrs = psutil.net_if_addrs()
        stats = psutil.net_if_stats()

        for iface, addr_list in addrs.items():
            ip = next((a.address for a in addr_list
                      if a.family.name == 'AF_INET'), 'N/A')
            mac = next((a.address for a in addr_list
                       if a.family.name in ('AF_LINK', 'AF_PACKET')), 'N/A')
            is_up = stats.get(iface, None)
            status = "Aktiv" if is_up and is_up.isup else "Inaktiv"
            status_color = c['accent_green'] if status == "Aktiv" else c['text_tertiary']

            row = tk.Frame(self.iface_frame, bg=c['card_bg'])
            row.pack(fill='x', pady=1)
            tk.Label(row, text=iface[:20], font=('Segoe UI', 9),
                   fg=c['text_primary'], bg=c['card_bg'],
                   width=20, anchor='w').pack(side='left', padx=2)
            tk.Label(row, text=ip, font=('Segoe UI', 9),
                   fg=c['text_secondary'], bg=c['card_bg'],
                   width=18, anchor='w').pack(side='left', padx=2)
            tk.Label(row, text=mac, font=('Segoe UI', 9),
                   fg=c['text_secondary'], bg=c['card_bg'],
                   width=20, anchor='w').pack(side='left', padx=2)
            tk.Label(row, text=status, font=('Segoe UI', 9, 'bold'),
                   fg=status_color, bg=c['card_bg'],
                   width=8, anchor='w').pack(side='left', padx=2)

    # ========================================================================
    # Disks Page
    # ========================================================================

    def _build_disks(self, parent):
        self._page_header(parent, "Festplatten", "Speicherplatz und I/O")

        # I/O Speed cards
        io_frame = ttk.Frame(parent)
        io_frame.pack(fill='x', pady=(10, 15))

        read_card = self._create_card(io_frame)
        read_card.pack(side='left', fill='both', expand=True, padx=(0, 5))
        tk.Label(read_card, text="Lesen", font=('Segoe UI', 11),
                fg=Config.COLORS['text_secondary'], bg=Config.COLORS['card_bg']).pack(pady=(12, 2))
        self.disk_read_label = tk.Label(read_card, text="0 B/s",
                                       font=('Segoe UI', 22, 'bold'),
                                       fg=Config.COLORS['accent_cyan'],
                                       bg=Config.COLORS['card_bg'])
        self.disk_read_label.pack()
        self.disk_read_ops = tk.Label(read_card, text="",
                                    font=('Segoe UI', 9),
                                    fg=Config.COLORS['text_tertiary'],
                                    bg=Config.COLORS['card_bg'])
        self.disk_read_ops.pack(pady=(2, 12))

        write_card = self._create_card(io_frame)
        write_card.pack(side='left', fill='both', expand=True, padx=(5, 0))
        tk.Label(write_card, text="Schreiben", font=('Segoe UI', 11),
                fg=Config.COLORS['text_secondary'], bg=Config.COLORS['card_bg']).pack(pady=(12, 2))
        self.disk_write_label = tk.Label(write_card, text="0 B/s",
                                        font=('Segoe UI', 22, 'bold'),
                                        fg=Config.COLORS['accent_orange'],
                                        bg=Config.COLORS['card_bg'])
        self.disk_write_label.pack()
        self.disk_write_ops = tk.Label(write_card, text="",
                                     font=('Segoe UI', 9),
                                     fg=Config.COLORS['text_tertiary'],
                                     bg=Config.COLORS['card_bg'])
        self.disk_write_ops.pack(pady=(2, 12))

        # Disk list with scrollbar
        disk_container = ttk.Frame(parent)
        disk_container.pack(fill='both', expand=True)

        disk_canvas = tk.Canvas(disk_container, bg=Config.COLORS['bg_primary'],
                               highlightthickness=0)
        disk_scrollbar = ttk.Scrollbar(disk_container, orient='vertical',
                                      command=disk_canvas.yview)
        self.disk_list_frame = ttk.Frame(disk_canvas)
        self.disk_list_frame.bind('<Configure>',
            lambda e: disk_canvas.configure(scrollregion=disk_canvas.bbox('all')))
        disk_canvas.create_window((0, 0), window=self.disk_list_frame, anchor='nw')
        disk_canvas.configure(yscrollcommand=disk_scrollbar.set)
        disk_canvas.pack(side='left', fill='both', expand=True)
        disk_scrollbar.pack(side='right', fill='y')

        def _on_disk_mousewheel(event):
            disk_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        disk_canvas.bind_all('<MouseWheel>', _on_disk_mousewheel)

        self._update_disks()

    def _update_disks(self):
        if self.current_page != 'disks':
            return

        try:
            # I/O speeds
            now = time.time()
            current_io = psutil.disk_io_counters()
            dt = now - self.last_update_time
            if dt < 0.1:
                dt = Config.UPDATE_DISKS / 1000

            if self.last_disk_io:
                read_speed = (current_io.read_bytes - self.last_disk_io.read_bytes) / dt
                write_speed = (current_io.write_bytes - self.last_disk_io.write_bytes) / dt
                read_ops = (current_io.read_count - self.last_disk_io.read_count) / dt
                write_ops = (current_io.write_count - self.last_disk_io.write_count) / dt
            else:
                read_speed = write_speed = read_ops = write_ops = 0

            self.last_disk_io = current_io

            self.disk_read_label.config(text=self._format_speed(read_speed))
            self.disk_write_label.config(text=self._format_speed(write_speed))
            self.disk_read_ops.config(text=f"{read_ops:.0f} ops/s")
            self.disk_write_ops.config(text=f"{write_ops:.0f} ops/s")

            # Disk partitions
            for w in self.disk_list_frame.winfo_children():
                w.destroy()

            partitions = psutil.disk_partitions()
            for part in partitions:
                try:
                    usage = psutil.disk_usage(part.mountpoint)
                    self._create_disk_card(self.disk_list_frame, part, usage)
                except (PermissionError, OSError):
                    pass

        except Exception:
            pass

        job = self.root.after(Config.UPDATE_DISKS, self._update_disks)
        self.update_jobs.append(job)

    def _create_disk_card(self, parent, partition, usage):
        c = Config.COLORS
        card = self._create_card(parent)
        card.pack(fill='x', pady=(0, 8))

        content = tk.Frame(card, bg=c['card_bg'])
        content.pack(fill='x', padx=15, pady=12)

        # Header row
        header = tk.Frame(content, bg=c['card_bg'])
        header.pack(fill='x')

        mount = partition.mountpoint
        tk.Label(header, text=mount, font=('Segoe UI', 13, 'bold'),
                fg=c['text_primary'], bg=c['card_bg']).pack(side='left')
        tk.Label(header, text=f"({partition.fstype})",
                font=('Segoe UI', 10),
                fg=c['text_tertiary'], bg=c['card_bg']).pack(side='left', padx=8)

        percent_color = c['accent_red'] if usage.percent > 90 else (
                        c['accent_orange'] if usage.percent > 75 else c['accent_blue'])
        tk.Label(header, text=f"{usage.percent:.1f}%",
                font=('Segoe UI', 13, 'bold'),
                fg=percent_color, bg=c['card_bg']).pack(side='right')

        # Progress bar
        bar_frame = tk.Frame(content, bg=c['bg_tertiary'], height=6)
        bar_frame.pack(fill='x', pady=(8, 6))
        bar_frame.pack_propagate(False)

        bar = tk.Frame(bar_frame, bg=percent_color, height=6)
        bar.place(relx=0, rely=0, relwidth=usage.percent / 100, relheight=1)

        # Details
        details = tk.Frame(content, bg=c['card_bg'])
        details.pack(fill='x')
        used_gb = usage.used / (1024**3)
        total_gb = usage.total / (1024**3)
        free_gb = usage.free / (1024**3)
        tk.Label(details, text=f"{used_gb:.1f} GB / {total_gb:.1f} GB",
                font=('Segoe UI', 9), fg=c['text_secondary'],
                bg=c['card_bg']).pack(side='left')
        tk.Label(details, text=f"{free_gb:.1f} GB frei",
                font=('Segoe UI', 9), fg=c['accent_green'],
                bg=c['card_bg']).pack(side='right')

    # ========================================================================
    # System Page
    # ========================================================================

    def _build_system(self, parent):
        self._page_header(parent, "System", "Hardware- und Softwareinformationen")

        # Scrollable frame
        canvas = tk.Canvas(parent, bg=Config.COLORS['bg_primary'],
                         highlightthickness=0)
        scrollbar = ttk.Scrollbar(parent, orient='vertical', command=canvas.yview)
        scroll_frame = ttk.Frame(canvas)

        scroll_frame.bind('<Configure>',
                        lambda e: canvas.configure(scrollregion=canvas.bbox('all')))
        canvas.create_window((0, 0), window=scroll_frame, anchor='nw')
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side='left', fill='both', expand=True, pady=(10, 0))
        scrollbar.pack(side='right', fill='y')

        # Bind mouse wheel
        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        canvas.bind_all('<MouseWheel>', _on_mousewheel)

        c = Config.COLORS

        # Hardware Info
        hw_card = self._create_card(scroll_frame)
        hw_card.pack(fill='x', pady=(0, 10), padx=(0, 10))
        ttk.Label(hw_card, text="Hardware", style='CardTitle.TLabel').pack(
            anchor='w', padx=15, pady=(12, 10))

        cpu_info = platform.processor() or "N/A"
        cpu_freq = psutil.cpu_freq()
        freq_text = f"{cpu_freq.max:.0f} MHz" if cpu_freq else "N/A"
        phys_cores = psutil.cpu_count(logical=False)
        logic_cores = psutil.cpu_count(logical=True)
        mem = psutil.virtual_memory()

        hw_data = [
            ("Prozessor", cpu_info),
            ("Architektur", platform.machine()),
            ("Max. Taktfrequenz", freq_text),
            ("Physische Kerne", str(phys_cores)),
            ("Logische Kerne", str(logic_cores)),
            ("RAM Total", f"{mem.total / (1024**3):.1f} GB"),
            ("RAM Verfuegbar", f"{mem.available / (1024**3):.1f} GB"),
        ]

        for label, value in hw_data:
            self._info_row(hw_card, label, value)
        tk.Frame(hw_card, height=10, bg=c['card_bg']).pack()

        # OS Info
        os_card = self._create_card(scroll_frame)
        os_card.pack(fill='x', pady=(0, 10), padx=(0, 10))
        ttk.Label(os_card, text="Betriebssystem", style='CardTitle.TLabel').pack(
            anchor='w', padx=15, pady=(12, 10))

        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime = datetime.now() - boot_time

        os_data = [
            ("System", platform.system()),
            ("Version", platform.version()),
            ("Build", platform.platform()),
            ("Hostname", socket.gethostname()),
            ("Gestartet", boot_time.strftime("%Y-%m-%d %H:%M:%S")),
            ("Uptime", str(timedelta(seconds=int(uptime.total_seconds())))),
            ("Python", platform.python_version()),
        ]

        for label, value in os_data:
            self._info_row(os_card, label, value)
        tk.Frame(os_card, height=10, bg=c['card_bg']).pack()

        # Memory details
        mem_card = self._create_card(scroll_frame)
        mem_card.pack(fill='x', pady=(0, 10), padx=(0, 10))
        ttk.Label(mem_card, text="Arbeitsspeicher Details", style='CardTitle.TLabel').pack(
            anchor='w', padx=15, pady=(12, 10))

        swap = psutil.swap_memory()
        mem_data = [
            ("RAM Belegt", f"{mem.used / (1024**3):.2f} GB ({mem.percent}%)"),
            ("RAM Verfuegbar", f"{mem.available / (1024**3):.2f} GB"),
            ("RAM Cached", f"{getattr(mem, 'cached', 0) / (1024**3):.2f} GB"),
            ("RAM Buffers", f"{getattr(mem, 'buffers', 0) / (1024**3):.2f} GB"),
            ("Swap Total", f"{swap.total / (1024**3):.2f} GB"),
            ("Swap Belegt", f"{swap.used / (1024**3):.2f} GB ({swap.percent}%)"),
            ("Swap Frei", f"{swap.free / (1024**3):.2f} GB"),
        ]

        for label, value in mem_data:
            self._info_row(mem_card, label, value)
        tk.Frame(mem_card, height=10, bg=c['card_bg']).pack()

        # Network info
        net_card = self._create_card(scroll_frame)
        net_card.pack(fill='x', pady=(0, 10), padx=(0, 10))
        ttk.Label(net_card, text="Netzwerk Details", style='CardTitle.TLabel').pack(
            anchor='w', padx=15, pady=(12, 10))

        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
        except Exception:
            local_ip = "N/A"

        net_io = psutil.net_io_counters()
        net_data = [
            ("Hostname", hostname),
            ("Lokale IP", local_ip),
            ("Pakete Empfangen", f"{net_io.packets_recv:,}"),
            ("Pakete Gesendet", f"{net_io.packets_sent:,}"),
            ("Bytes Empfangen", self._format_bytes(net_io.bytes_recv)),
            ("Bytes Gesendet", self._format_bytes(net_io.bytes_sent)),
            ("Fehler (Ein)", str(net_io.errin)),
            ("Fehler (Aus)", str(net_io.errout)),
            ("Drops (Ein)", str(net_io.dropin)),
            ("Drops (Aus)", str(net_io.dropout)),
        ]

        for label, value in net_data:
            self._info_row(net_card, label, value)
        tk.Frame(net_card, height=10, bg=c['card_bg']).pack()

    def _info_row(self, parent, label, value):
        c = Config.COLORS
        row = tk.Frame(parent, bg=c['card_bg'])
        row.pack(fill='x', padx=15, pady=3)
        tk.Label(row, text=label, font=('Segoe UI', 10),
                fg=c['text_secondary'], bg=c['card_bg']).pack(side='left')
        tk.Label(row, text=value, font=('Segoe UI', 10, 'bold'),
                fg=c['text_primary'], bg=c['card_bg']).pack(side='right')

    # ========================================================================
    # Helper Methods
    # ========================================================================

    def _page_header(self, parent, title, subtitle):
        c = Config.COLORS
        header = ttk.Frame(parent)
        header.pack(fill='x', pady=(0, 5))

        ttk.Label(header, text=title, style='Title.TLabel').pack(side='left')

        # Clock
        time_str = datetime.now().strftime("%H:%M:%S")
        self._clock_label = ttk.Label(header, text=time_str,
                                     font=('Segoe UI', 18),
                                     foreground=c['text_secondary'],
                                     background=c['bg_primary'])
        self._clock_label.pack(side='right')
        self._update_clock()

        ttk.Label(parent, text=subtitle, style='Subtitle.TLabel').pack(anchor='w')

    def _update_clock(self):
        if hasattr(self, '_clock_label') and self._clock_label.winfo_exists():
            self._clock_label.config(text=datetime.now().strftime("%H:%M:%S"))
            self.root.after(1000, self._update_clock)

    def _create_card(self, parent):
        c = Config.COLORS
        card = tk.Frame(parent, bg=c['card_bg'],
                       highlightbackground=c['card_border'],
                       highlightthickness=1, padx=0, pady=0)
        return card

    def _format_bytes(self, bytes_val):
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_val < 1024:
                return f"{bytes_val:.1f} {unit}"
            bytes_val /= 1024
        return f"{bytes_val:.1f} PB"

    def _format_speed(self, bytes_per_sec):
        if bytes_per_sec >= 1024**3:
            return f"{bytes_per_sec / (1024**3):.1f} GB/s"
        elif bytes_per_sec >= 1024**2:
            return f"{bytes_per_sec / (1024**2):.1f} MB/s"
        elif bytes_per_sec >= 1024:
            return f"{bytes_per_sec / 1024:.1f} KB/s"
        return f"{bytes_per_sec:.0f} B/s"


# ============================================================================
# Entry Point
# ============================================================================

def main():
    root = tk.Tk()

    # Try to set DPI awareness on Windows
    try:
        from ctypes import windll
        windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass

    app = SystemMonitorApp(root)
    root.mainloop()


if __name__ == '__main__':
    main()
