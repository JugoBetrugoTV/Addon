"""
SystemMonitor Pro - Windows 11 System Monitor Tool
Ein modernes Echtzeit-System-Monitoring Tool für Windows 11
"""

import tkinter as tk
from tkinter import ttk
import psutil
import platform
import socket
import threading
import time
from datetime import datetime
import os

class SystemMonitor:
    def __init__(self, root):
        self.root = root
        self.root.title("SystemMonitor Pro")
        self.root.geometry("800x600")
        self.root.minsize(700, 500)

        # Dark Theme Farben
        self.colors = {
            'bg_dark': '#1a1a2e',
            'bg_card': '#16213e',
            'accent': '#0f3460',
            'highlight': '#e94560',
            'text': '#ffffff',
            'text_dim': '#a0a0a0',
            'green': '#00d26a',
            'yellow': '#ffc107',
            'red': '#ff4757',
            'blue': '#3742fa'
        }

        self.root.configure(bg=self.colors['bg_dark'])

        # Stil konfigurieren
        self.setup_styles()

        # UI erstellen
        self.create_ui()

        # Update starten
        self.running = True
        self.update_thread = threading.Thread(target=self.update_loop, daemon=True)
        self.update_thread.start()

        # Bei Schließen aufräumen
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')

        # Progressbar Stile
        style.configure("CPU.Horizontal.TProgressbar",
                       background=self.colors['blue'],
                       troughcolor=self.colors['bg_card'])
        style.configure("RAM.Horizontal.TProgressbar",
                       background=self.colors['green'],
                       troughcolor=self.colors['bg_card'])
        style.configure("DISK.Horizontal.TProgressbar",
                       background=self.colors['yellow'],
                       troughcolor=self.colors['bg_card'])
        style.configure("NET.Horizontal.TProgressbar",
                       background=self.colors['highlight'],
                       troughcolor=self.colors['bg_card'])

    def create_ui(self):
        # Header
        header = tk.Frame(self.root, bg=self.colors['bg_card'], height=60)
        header.pack(fill='x', padx=10, pady=10)
        header.pack_propagate(False)

        title = tk.Label(header, text="SystemMonitor Pro",
                        font=('Segoe UI', 18, 'bold'),
                        bg=self.colors['bg_card'], fg=self.colors['text'])
        title.pack(side='left', padx=20, pady=15)

        self.time_label = tk.Label(header, text="",
                                   font=('Segoe UI', 12),
                                   bg=self.colors['bg_card'], fg=self.colors['text_dim'])
        self.time_label.pack(side='right', padx=20, pady=15)

        # Hauptbereich
        main_frame = tk.Frame(self.root, bg=self.colors['bg_dark'])
        main_frame.pack(fill='both', expand=True, padx=10, pady=5)

        # Obere Reihe - CPU & RAM
        top_row = tk.Frame(main_frame, bg=self.colors['bg_dark'])
        top_row.pack(fill='x', pady=5)

        self.cpu_card = self.create_card(top_row, "CPU", "CPU.Horizontal.TProgressbar")
        self.cpu_card['frame'].pack(side='left', fill='both', expand=True, padx=(0,5))

        self.ram_card = self.create_card(top_row, "RAM", "RAM.Horizontal.TProgressbar")
        self.ram_card['frame'].pack(side='left', fill='both', expand=True, padx=(5,0))

        # Mittlere Reihe - Disk & Netzwerk
        mid_row = tk.Frame(main_frame, bg=self.colors['bg_dark'])
        mid_row.pack(fill='x', pady=5)

        self.disk_card = self.create_card(mid_row, "Festplatte", "DISK.Horizontal.TProgressbar")
        self.disk_card['frame'].pack(side='left', fill='both', expand=True, padx=(0,5))

        self.net_card = self.create_card(mid_row, "Netzwerk", "NET.Horizontal.TProgressbar")
        self.net_card['frame'].pack(side='left', fill='both', expand=True, padx=(5,0))

        # Unterer Bereich - System Info
        self.create_system_info(main_frame)

        # Prozess-Liste
        self.create_process_list(main_frame)

    def create_card(self, parent, title, style):
        frame = tk.Frame(parent, bg=self.colors['bg_card'], height=120)
        frame.pack_propagate(False)

        # Titel
        title_label = tk.Label(frame, text=title,
                              font=('Segoe UI', 12, 'bold'),
                              bg=self.colors['bg_card'], fg=self.colors['text'])
        title_label.pack(anchor='w', padx=15, pady=(15,5))

        # Wert
        value_label = tk.Label(frame, text="0%",
                              font=('Segoe UI', 24, 'bold'),
                              bg=self.colors['bg_card'], fg=self.colors['text'])
        value_label.pack(anchor='w', padx=15)

        # Progressbar
        progress = ttk.Progressbar(frame, length=200, mode='determinate', style=style)
        progress.pack(fill='x', padx=15, pady=(5,10))

        # Detail
        detail_label = tk.Label(frame, text="",
                               font=('Segoe UI', 9),
                               bg=self.colors['bg_card'], fg=self.colors['text_dim'])
        detail_label.pack(anchor='w', padx=15)

        return {
            'frame': frame,
            'value': value_label,
            'progress': progress,
            'detail': detail_label
        }

    def create_system_info(self, parent):
        frame = tk.Frame(parent, bg=self.colors['bg_card'], height=80)
        frame.pack(fill='x', pady=5)
        frame.pack_propagate(False)

        title = tk.Label(frame, text="System Information",
                        font=('Segoe UI', 12, 'bold'),
                        bg=self.colors['bg_card'], fg=self.colors['text'])
        title.pack(anchor='w', padx=15, pady=(10,5))

        info_frame = tk.Frame(frame, bg=self.colors['bg_card'])
        info_frame.pack(fill='x', padx=15)

        # System Infos sammeln
        hostname = socket.gethostname()
        os_info = f"{platform.system()} {platform.release()}"
        cpu_info = platform.processor()[:40] + "..." if len(platform.processor()) > 40 else platform.processor()

        infos = [
            f"Host: {hostname}",
            f"OS: {os_info}",
            f"CPU: {cpu_info}",
            f"Kerne: {psutil.cpu_count(logical=False)} ({psutil.cpu_count()} logisch)"
        ]

        for i, info in enumerate(infos):
            label = tk.Label(info_frame, text=info,
                           font=('Segoe UI', 9),
                           bg=self.colors['bg_card'], fg=self.colors['text_dim'])
            label.pack(side='left', padx=(0, 30))

    def create_process_list(self, parent):
        frame = tk.Frame(parent, bg=self.colors['bg_card'])
        frame.pack(fill='both', expand=True, pady=5)

        title = tk.Label(frame, text="Top Prozesse (nach CPU)",
                        font=('Segoe UI', 12, 'bold'),
                        bg=self.colors['bg_card'], fg=self.colors['text'])
        title.pack(anchor='w', padx=15, pady=(10,5))

        # Treeview für Prozesse
        tree_frame = tk.Frame(frame, bg=self.colors['bg_card'])
        tree_frame.pack(fill='both', expand=True, padx=15, pady=(0,15))

        columns = ('pid', 'name', 'cpu', 'memory')
        self.process_tree = ttk.Treeview(tree_frame, columns=columns, show='headings', height=6)

        self.process_tree.heading('pid', text='PID')
        self.process_tree.heading('name', text='Name')
        self.process_tree.heading('cpu', text='CPU %')
        self.process_tree.heading('memory', text='RAM %')

        self.process_tree.column('pid', width=70)
        self.process_tree.column('name', width=300)
        self.process_tree.column('cpu', width=80)
        self.process_tree.column('memory', width=80)

        scrollbar = ttk.Scrollbar(tree_frame, orient='vertical', command=self.process_tree.yview)
        self.process_tree.configure(yscrollcommand=scrollbar.set)

        self.process_tree.pack(side='left', fill='both', expand=True)
        scrollbar.pack(side='right', fill='y')

    def format_bytes(self, bytes_val):
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_val < 1024:
                return f"{bytes_val:.1f} {unit}"
            bytes_val /= 1024
        return f"{bytes_val:.1f} PB"

    def update_stats(self):
        # Zeit aktualisieren
        self.time_label.config(text=datetime.now().strftime("%H:%M:%S"))

        # CPU
        cpu_percent = psutil.cpu_percent(interval=0)
        self.cpu_card['value'].config(text=f"{cpu_percent:.1f}%")
        self.cpu_card['progress']['value'] = cpu_percent
        freq = psutil.cpu_freq()
        if freq:
            self.cpu_card['detail'].config(text=f"Frequenz: {freq.current:.0f} MHz")

        # RAM
        mem = psutil.virtual_memory()
        self.ram_card['value'].config(text=f"{mem.percent:.1f}%")
        self.ram_card['progress']['value'] = mem.percent
        self.ram_card['detail'].config(
            text=f"{self.format_bytes(mem.used)} / {self.format_bytes(mem.total)}"
        )

        # Disk
        disk = psutil.disk_usage('/')
        self.disk_card['value'].config(text=f"{disk.percent:.1f}%")
        self.disk_card['progress']['value'] = disk.percent
        self.disk_card['detail'].config(
            text=f"{self.format_bytes(disk.used)} / {self.format_bytes(disk.total)}"
        )

        # Netzwerk
        net = psutil.net_io_counters()
        self.net_card['value'].config(text=f"{self.format_bytes(net.bytes_sent + net.bytes_recv)}")
        self.net_card['detail'].config(
            text=f"Gesendet: {self.format_bytes(net.bytes_sent)} | Empfangen: {self.format_bytes(net.bytes_recv)}"
        )

        # Prozesse aktualisieren
        self.update_processes()

    def update_processes(self):
        # Alte Einträge löschen
        for item in self.process_tree.get_children():
            self.process_tree.delete(item)

        # Top Prozesse nach CPU holen
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                pinfo = proc.info
                if pinfo['cpu_percent'] is not None:
                    processes.append(pinfo)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass

        # Nach CPU sortieren und Top 10 anzeigen
        processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)
        for proc in processes[:10]:
            self.process_tree.insert('', 'end', values=(
                proc['pid'],
                proc['name'][:35] if proc['name'] else 'N/A',
                f"{proc['cpu_percent']:.1f}" if proc['cpu_percent'] else "0.0",
                f"{proc['memory_percent']:.1f}" if proc['memory_percent'] else "0.0"
            ))

    def update_loop(self):
        while self.running:
            try:
                self.root.after(0, self.update_stats)
                time.sleep(1)
            except:
                break

    def on_close(self):
        self.running = False
        self.root.destroy()


def main():
    root = tk.Tk()

    # Icon setzen (falls vorhanden)
    try:
        root.iconbitmap('icon.ico')
    except:
        pass

    app = SystemMonitor(root)
    root.mainloop()


if __name__ == "__main__":
    main()
