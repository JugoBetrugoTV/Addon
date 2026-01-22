"""
SystemMonitor Pro v3.0 - Ultra Modern System Monitor
Ein extrem modernes Echtzeit-System-Monitoring Tool mit Glasmorphism UI
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
import math

# ============================================================================
# KONFIGURATION
# ============================================================================

class Config:
    VERSION = "3.1.0"
    APP_NAME = "SystemMonitor Pro"

    # Fenster
    WINDOW_WIDTH = 1200
    WINDOW_HEIGHT = 800
    MIN_WIDTH = 1000
    MIN_HEIGHT = 700

    # Update Intervalle
    UPDATE_INTERVAL = 1000  # ms
    GRAPH_POINTS = 60          # Mini-Graphen
    DETAILED_GRAPH_POINTS = 120  # Detaillierte Graphen (2 Minuten)

    # Themes
    THEMES = {
        'midnight': {
            'name': 'Midnight',
            'bg_gradient_start': '#0a0a0f',
            'bg_gradient_end': '#1a1a2e',
            'card_bg': '#16162a',
            'card_border': '#2a2a40',
            'card_glow': '#162844',
            'accent_primary': '#3b82f6',
            'accent_secondary': '#8b5cf6',
            'accent_success': '#10b981',
            'accent_warning': '#f59e0b',
            'accent_danger': '#ef4444',
            'accent_info': '#06b6d4',
            'text_primary': '#ffffff',
            'text_secondary': '#94a3b8',
            'text_muted': '#64748b',
            'glow_color': '#3b82f6',
        },
        'aurora': {
            'name': 'Aurora',
            'bg_gradient_start': '#0f172a',
            'bg_gradient_end': '#1e1b4b',
            'card_bg': '#1c1a38',
            'card_border': '#2e1d50',
            'card_glow': '#2a1a4a',
            'accent_primary': '#a855f7',
            'accent_secondary': '#ec4899',
            'accent_success': '#22c55e',
            'accent_warning': '#eab308',
            'accent_danger': '#f43f5e',
            'accent_info': '#0ea5e9',
            'text_primary': '#ffffff',
            'text_secondary': '#a5b4fc',
            'text_muted': '#6366f1',
            'glow_color': '#a855f7',
        },
        'cyber': {
            'name': 'Cyber',
            'bg_gradient_start': '#000000',
            'bg_gradient_end': '#0a1628',
            'card_bg': '#041a10',
            'card_border': '#0a3520',
            'card_glow': '#062a18',
            'accent_primary': '#00ff88',
            'accent_secondary': '#00d4ff',
            'accent_success': '#00ff88',
            'accent_warning': '#ffaa00',
            'accent_danger': '#ff0055',
            'accent_info': '#00d4ff',
            'text_primary': '#00ff88',
            'text_secondary': '#00d4ff',
            'text_muted': '#0088aa',
            'glow_color': '#00ff88',
        }
    }


# ============================================================================
# CUSTOM WIDGETS
# ============================================================================

class GlowingCard(tk.Canvas):
    """Karte mit Glasmorphism-Effekt und Glow"""

    def __init__(self, parent, width=200, height=150, theme=None, **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.theme = theme or Config.THEMES['midnight']
        self.glow_intensity = 0
        self.hover = False
        self.draw()

        # Hover Effekte
        self.bind('<Enter>', self.on_enter)
        self.bind('<Leave>', self.on_leave)

    def draw(self):
        self.delete('all')

        # Glow Effekt (mehrere Schichten)
        if self.glow_intensity > 0:
            for i in range(3):
                offset = (3 - i) * 4
                alpha = int(self.glow_intensity * (i + 1) * 5)
                glow_color = self.theme['glow_color'] + f'{alpha:02x}'
                self.create_rectangle(
                    offset, offset,
                    self.width - offset, self.height - offset,
                    fill='', outline=self.theme['glow_color'],
                    width=2
                )

        # Hauptkarte mit abgerundeten Ecken (simuliert)
        self.create_rectangle(
            2, 2, self.width - 2, self.height - 2,
            fill=self.theme['card_bg'],
            outline=self.theme['card_border'],
            width=1
        )

        # Top highlight für Glaseffekt
        self.create_rectangle(
            3, 3, self.width - 3, 20,
            fill='#141420', outline=''
        )

    def on_enter(self, event):
        self.hover = True
        self.animate_glow(1)

    def on_leave(self, event):
        self.hover = False
        self.animate_glow(0)

    def animate_glow(self, target):
        if self.hover and self.glow_intensity < target:
            self.glow_intensity = min(1, self.glow_intensity + 0.1)
            self.draw()
            self.after(16, lambda: self.animate_glow(target))
        elif not self.hover and self.glow_intensity > target:
            self.glow_intensity = max(0, self.glow_intensity - 0.1)
            self.draw()
            self.after(16, lambda: self.animate_glow(target))


class AnimatedRing(tk.Canvas):
    """Animierter Ring mit Gradient und Glow"""

    def __init__(self, parent, size=120, thickness=12, theme=None, **kwargs):
        super().__init__(parent, width=size, height=size,
                        highlightthickness=0, **kwargs)
        self.size = size
        self.thickness = thickness
        self.theme = theme or Config.THEMES['midnight']
        self.value = 0
        self.target_value = 0
        self.label = "0%"
        self.sub_label = ""
        self.color = self.theme['accent_primary']
        self.pulse = 0
        self.animating = False
        self.draw()

    def draw(self):
        self.delete('all')
        center = self.size // 2
        radius = (self.size - self.thickness - 10) // 2

        # Äußerer Glow
        if self.value > 70:
            for i in range(3):
                glow_radius = radius + self.thickness // 2 + i * 3
                alpha = 30 - i * 10
                self.create_oval(
                    center - glow_radius, center - glow_radius,
                    center + glow_radius, center + glow_radius,
                    outline=self.color, width=2
                )

        # Hintergrund-Ring
        self.create_arc(
            center - radius, center - radius,
            center + radius, center + radius,
            start=90, extent=-360,
            outline=self.theme['card_border'], width=self.thickness,
            style='arc'
        )

        # Fortschritts-Ring
        if self.value > 0:
            extent = (self.value / 100) * 360

            # Haupt-Arc
            self.create_arc(
                center - radius, center - radius,
                center + radius, center + radius,
                start=90, extent=-extent,
                outline=self.color, width=self.thickness,
                style='arc'
            )

            # Leuchtender Punkt am Ende
            angle = math.radians(90 - extent)
            end_x = center + radius * math.cos(angle)
            end_y = center - radius * math.sin(angle)

            dot_size = 4 + self.pulse * 2
            self.create_oval(
                end_x - dot_size, end_y - dot_size,
                end_x + dot_size, end_y + dot_size,
                fill=self.color, outline='white', width=1
            )

        # Prozent-Text
        self.create_text(center, center - 8, text=self.label,
                        font=('Segoe UI', 18, 'bold'),
                        fill=self.theme['text_primary'])

        # Sub-Label
        if self.sub_label:
            self.create_text(center, center + 18, text=self.sub_label,
                            font=('Segoe UI', 9),
                            fill=self.theme['text_muted'])

    def set_value(self, value, label=None, sub_label=None, color=None):
        self.target_value = min(100, max(0, value))
        if label:
            self.label = label
        else:
            self.label = f"{int(value)}%"
        if sub_label:
            self.sub_label = sub_label
        if color:
            self.color = color

        if not self.animating:
            self.animate()

    def animate(self):
        self.animating = True
        diff = self.target_value - self.value

        if abs(diff) > 0.5:
            self.value += diff * 0.15
            self.pulse = (self.pulse + 0.1) % 1
            self.draw()
            self.after(16, self.animate)
        else:
            self.value = self.target_value
            self.animating = False
            self.draw()

    def get_color_for_value(self, value):
        if value < 50:
            return self.theme['accent_success']
        elif value < 75:
            return self.theme['accent_warning']
        else:
            return self.theme['accent_danger']


class ModernGraph(tk.Canvas):
    """Moderner Mini-Graph mit Gradient-Fill"""

    def __init__(self, parent, width=400, height=100, theme=None,
                 color=None, show_grid=True, max_points=60, **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.theme = theme or Config.THEMES['midnight']
        self.color = color or self.theme['accent_primary']
        self.show_grid = show_grid
        self.data = deque(maxlen=max_points)
        self.draw()

    def draw(self):
        self.delete('all')

        # Hintergrund
        self.create_rectangle(0, 0, self.width, self.height,
                            fill=self.theme['card_bg'], outline='')

        # Grid
        if self.show_grid:
            for i in range(1, 4):
                y = i * (self.height // 4)
                self.create_line(0, y, self.width, y,
                               fill=self.theme['card_border'], dash=(2, 4))
            for i in range(1, 8):
                x = i * (self.width // 8)
                self.create_line(x, 0, x, self.height,
                               fill=self.theme['card_border'], dash=(2, 4))

        if len(self.data) < 2:
            self.create_text(self.width // 2, self.height // 2,
                           text="Waiting for data...",
                           font=('Segoe UI', 9),
                           fill=self.theme['text_muted'])
            return

        # Punkte berechnen
        points = []
        for i, value in enumerate(self.data):
            x = (i / (len(self.data) - 1)) * self.width if len(self.data) > 1 else 0
            y = self.height - (value / 100) * (self.height - 10) - 5
            points.extend([x, y])

        if len(points) >= 4:
            # Gradient Fill
            for layer in range(5):
                fill_points = []
                for i in range(0, len(points), 2):
                    fill_points.extend([points[i], points[i + 1] + layer * 5])
                fill_points.extend([self.width, self.height, 0, self.height])
                self.create_polygon(fill_points, fill=self.color,
                                   stipple='gray50' if layer > 0 else 'gray75', outline='')

            # Linie
            self.create_line(points, fill=self.color, width=2, smooth=True)
            self.create_line(points, fill=self.color, width=4, smooth=True, stipple='gray50')

            # Endpunkt
            last_x, last_y = points[-2], points[-1]
            self.create_oval(last_x - 4, last_y - 4, last_x + 4, last_y + 4,
                           fill=self.color, outline='white', width=2)

    def add_value(self, value):
        self.data.append(min(100, max(0, value)))
        self.draw()


class DetailedGraph(tk.Canvas):
    """Detaillierter Graph mit Achsenbeschriftung, Statistiken und feinem Grid"""

    def __init__(self, parent, width=500, height=180, theme=None,
                 color=None, title="", unit="%", max_points=120, **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.theme = theme or Config.THEMES['midnight']
        self.color = color or self.theme['accent_primary']
        self.title = title
        self.unit = unit
        self.data = deque(maxlen=max_points)
        self.max_points = max_points

        # Margins für Achsen
        self.margin_left = 45
        self.margin_right = 15
        self.margin_top = 35
        self.margin_bottom = 25

        # Graph-Bereich
        self.graph_width = self.width - self.margin_left - self.margin_right
        self.graph_height = self.height - self.margin_top - self.margin_bottom

        # Hover
        self.hover_x = None
        self.bind('<Motion>', self.on_motion)
        self.bind('<Leave>', self.on_leave)

        self.draw()

    def draw(self):
        self.delete('all')

        # Hintergrund
        self.create_rectangle(0, 0, self.width, self.height,
                            fill=self.theme['bg_gradient_end'], outline='')

        # Graph-Bereich Hintergrund
        self.create_rectangle(
            self.margin_left, self.margin_top,
            self.width - self.margin_right, self.height - self.margin_bottom,
            fill=self.theme['card_bg'], outline=self.theme['card_border']
        )

        # Titel und Statistiken
        self.draw_header()

        # Y-Achse
        self.draw_y_axis()

        # X-Achse (Zeit)
        self.draw_x_axis()

        # Grid
        self.draw_grid()

        # Daten
        if len(self.data) >= 2:
            self.draw_data()

            # Hover-Linie
            if self.hover_x is not None:
                self.draw_hover()

    def draw_header(self):
        # Titel
        self.create_text(self.margin_left, 12, text=self.title,
                        font=('Segoe UI', 11, 'bold'),
                        fill=self.theme['text_primary'], anchor='w')

        # Statistiken
        if len(self.data) > 0:
            current = self.data[-1]
            avg = sum(self.data) / len(self.data)
            min_val = min(self.data)
            max_val = max(self.data)

            stats_text = f"Current: {current:.1f}{self.unit}  │  Avg: {avg:.1f}{self.unit}  │  Min: {min_val:.1f}{self.unit}  │  Max: {max_val:.1f}{self.unit}"

            self.create_text(self.width - self.margin_right, 12, text=stats_text,
                            font=('Segoe UI', 9),
                            fill=self.theme['text_secondary'], anchor='e')

    def draw_y_axis(self):
        # Y-Achsen Beschriftungen (0%, 25%, 50%, 75%, 100%)
        labels = [0, 25, 50, 75, 100]

        for label in labels:
            y = self.margin_top + self.graph_height - (label / 100) * self.graph_height

            # Label
            self.create_text(self.margin_left - 8, y,
                           text=f"{label}{self.unit}",
                           font=('Segoe UI', 8),
                           fill=self.theme['text_muted'], anchor='e')

            # Tick
            self.create_line(self.margin_left - 3, y, self.margin_left, y,
                           fill=self.theme['text_muted'])

    def draw_x_axis(self):
        # Zeit-Labels (letzte 2 Minuten bei 120 Punkten = 1 Punkt/Sekunde)
        time_labels = ['2m', '1m30s', '1m', '30s', 'now']
        num_labels = len(time_labels)

        for i, label in enumerate(time_labels):
            x = self.margin_left + (i / (num_labels - 1)) * self.graph_width

            # Label
            self.create_text(x, self.height - 8,
                           text=label,
                           font=('Segoe UI', 8),
                           fill=self.theme['text_muted'])

            # Tick
            self.create_line(x, self.height - self.margin_bottom,
                           x, self.height - self.margin_bottom + 3,
                           fill=self.theme['text_muted'])

    def draw_grid(self):
        # Horizontale Linien (bei 25%, 50%, 75%)
        for pct in [25, 50, 75]:
            y = self.margin_top + self.graph_height - (pct / 100) * self.graph_height
            self.create_line(
                self.margin_left, y,
                self.width - self.margin_right, y,
                fill=self.theme['card_border'], dash=(2, 4)
            )

        # Vertikale Linien (alle 30 Sekunden = 30 Punkte)
        for i in range(1, 4):
            x = self.margin_left + (i / 4) * self.graph_width
            self.create_line(
                x, self.margin_top,
                x, self.height - self.margin_bottom,
                fill=self.theme['card_border'], dash=(2, 4)
            )

    def draw_data(self):
        points = []
        data_list = list(self.data)

        for i, value in enumerate(data_list):
            x = self.margin_left + (i / (self.max_points - 1)) * self.graph_width
            y = self.margin_top + self.graph_height - (value / 100) * self.graph_height
            points.extend([x, y])

        if len(points) >= 4:
            # Gradient Fill (mehrere Schichten)
            for layer in range(8):
                fill_points = []
                offset = layer * 3
                for i in range(0, len(points), 2):
                    fill_points.extend([points[i], min(points[i + 1] + offset,
                                                      self.height - self.margin_bottom)])
                fill_points.extend([
                    points[-2], self.height - self.margin_bottom,
                    points[0], self.height - self.margin_bottom
                ])

                alpha_stipple = 'gray75' if layer < 2 else 'gray50' if layer < 5 else 'gray25'
                self.create_polygon(fill_points, fill=self.color,
                                   stipple=alpha_stipple, outline='')

            # Glow-Linie (breitere, transparente Linie)
            self.create_line(points, fill=self.color, width=6,
                           smooth=True, stipple='gray50')

            # Hauptlinie
            self.create_line(points, fill=self.color, width=2, smooth=True)

            # Aktueller Wert - leuchtender Punkt
            last_x, last_y = points[-2], points[-1]

            # Äußerer Glow
            for r in range(3, 0, -1):
                size = 4 + r * 2
                self.create_oval(last_x - size, last_y - size,
                               last_x + size, last_y + size,
                               fill='', outline=self.color,
                               width=1)

            # Hauptpunkt
            self.create_oval(last_x - 5, last_y - 5, last_x + 5, last_y + 5,
                           fill=self.color, outline='white', width=2)

            # Aktueller Wert als Text neben dem Punkt
            current_value = data_list[-1]
            self.create_text(last_x - 10, last_y - 15,
                           text=f"{current_value:.1f}{self.unit}",
                           font=('Segoe UI', 9, 'bold'),
                           fill=self.color, anchor='e')

    def draw_hover(self):
        if self.hover_x is None or len(self.data) < 2:
            return

        # Berechne Index aus X-Position
        rel_x = self.hover_x - self.margin_left
        if rel_x < 0 or rel_x > self.graph_width:
            return

        index = int((rel_x / self.graph_width) * (len(self.data) - 1))
        index = max(0, min(index, len(self.data) - 1))

        value = list(self.data)[index]

        # X-Position für diese Datenpunkt
        x = self.margin_left + (index / (self.max_points - 1)) * self.graph_width
        y = self.margin_top + self.graph_height - (value / 100) * self.graph_height

        # Vertikale Linie
        self.create_line(x, self.margin_top, x, self.height - self.margin_bottom,
                        fill=self.theme['text_muted'], dash=(3, 3))

        # Horizontale Linie zum Wert
        self.create_line(self.margin_left, y, x, y,
                        fill=self.theme['text_muted'], dash=(3, 3))

        # Punkt
        self.create_oval(x - 4, y - 4, x + 4, y + 4,
                        fill='white', outline=self.color, width=2)

        # Tooltip
        tooltip_text = f"{value:.1f}{self.unit}"
        time_ago = int(((self.max_points - 1 - index) / self.max_points) * 120)
        if time_ago > 0:
            tooltip_text += f" ({time_ago}s ago)"

        # Tooltip Hintergrund
        text_width = len(tooltip_text) * 6 + 10
        tooltip_x = x + 10 if x < self.width - 80 else x - text_width - 10
        tooltip_y = y - 10 if y > 30 else y + 20

        self.create_rectangle(tooltip_x - 5, tooltip_y - 10,
                            tooltip_x + text_width, tooltip_y + 10,
                            fill=self.theme['bg_gradient_end'],
                            outline=self.theme['card_border'])

        self.create_text(tooltip_x, tooltip_y, text=tooltip_text,
                        font=('Segoe UI', 9, 'bold'),
                        fill=self.theme['text_primary'], anchor='w')

    def on_motion(self, event):
        self.hover_x = event.x
        self.draw()

    def on_leave(self, event):
        self.hover_x = None
        self.draw()

    def add_value(self, value):
        self.data.append(min(100, max(0, value)))
        self.draw()


class ModernProgressBar(tk.Canvas):
    """Moderne Progressbar mit Glow und Animation"""

    def __init__(self, parent, width=300, height=8, theme=None,
                 color=None, **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.theme = theme or Config.THEMES['midnight']
        self.color = color or self.theme['accent_primary']
        self.value = 0
        self.target_value = 0
        self.shimmer_pos = 0
        self.draw()

    def draw(self):
        self.delete('all')

        # Hintergrund
        self.create_rectangle(0, 0, self.width, self.height,
                            fill=self.theme['card_border'], outline='')

        # Fortschritt
        if self.value > 0:
            bar_width = (self.value / 100) * self.width

            # Hauptbalken
            self.create_rectangle(0, 0, bar_width, self.height,
                                fill=self.color, outline='')

            # Glanz-Effekt (Shimmer)
            shimmer_x = (self.shimmer_pos / 100) * bar_width
            if shimmer_x < bar_width:
                self.create_rectangle(
                    max(0, shimmer_x - 20), 0,
                    min(bar_width, shimmer_x + 20), self.height,
                    fill='white', stipple='gray50', outline=''
                )

    def set_value(self, value):
        self.target_value = min(100, max(0, value))
        self.animate()

    def animate(self):
        diff = self.target_value - self.value
        if abs(diff) > 0.5:
            self.value += diff * 0.2
            self.shimmer_pos = (self.shimmer_pos + 5) % 120
            self.draw()
            self.after(16, self.animate)
        else:
            self.value = self.target_value
            self.draw()


class SidebarButton(tk.Canvas):
    """Moderner Sidebar-Button mit Hover-Effekt"""

    def __init__(self, parent, text="", icon="", width=200, height=50,
                 theme=None, command=None, **kwargs):
        super().__init__(parent, width=width, height=height,
                        highlightthickness=0, cursor='hand2', **kwargs)
        self.width = width
        self.height = height
        self.text = text
        self.icon = icon
        self.theme = theme or Config.THEMES['midnight']
        self.command = command
        self.hover = False
        self.active = False
        self.hover_progress = 0
        self.draw()

        self.bind('<Enter>', self.on_enter)
        self.bind('<Leave>', self.on_leave)
        self.bind('<Button-1>', self.on_click)

    def draw(self):
        self.delete('all')

        # Hintergrund
        if self.active:
            self.create_rectangle(0, 0, self.width, self.height,
                                fill=self.theme['accent_primary'] + '30', outline='')
            # Linker Indikator
            self.create_rectangle(0, 5, 4, self.height - 5,
                                fill=self.theme['accent_primary'], outline='')
        elif self.hover_progress > 0:
            alpha = int(self.hover_progress * 20)
            self.create_rectangle(0, 0, self.width, self.height,
                                fill=self.theme['card_bg'], outline='')

        # Icon
        self.create_text(25, self.height // 2, text=self.icon,
                        font=('Segoe UI', 14),
                        fill=self.theme['accent_primary'] if self.active else self.theme['text_secondary'])

        # Text
        self.create_text(55, self.height // 2, text=self.text,
                        font=('Segoe UI', 11, 'bold' if self.active else 'normal'),
                        fill=self.theme['text_primary'] if self.active else self.theme['text_secondary'],
                        anchor='w')

    def on_enter(self, event):
        self.hover = True
        self.animate_hover(1)

    def on_leave(self, event):
        self.hover = False
        self.animate_hover(0)

    def animate_hover(self, target):
        if self.hover and self.hover_progress < target:
            self.hover_progress = min(1, self.hover_progress + 0.15)
            self.draw()
            self.after(16, lambda: self.animate_hover(target))
        elif not self.hover and self.hover_progress > target:
            self.hover_progress = max(0, self.hover_progress - 0.15)
            self.draw()
            self.after(16, lambda: self.animate_hover(target))

    def on_click(self, event):
        if self.command:
            self.command()

    def set_active(self, active):
        self.active = active
        self.draw()


class StatCard(tk.Frame):
    """Statistik-Karte mit Icon, Wert und Graph"""

    def __init__(self, parent, title="", icon="", color=None, theme=None, **kwargs):
        self.theme = theme or Config.THEMES['midnight']
        self.color = color or self.theme['accent_primary']

        super().__init__(parent, bg=self.theme['bg_gradient_start'], **kwargs)

        self.title = title
        self.icon = icon

        # Haupt-Canvas für Karte
        self.card = tk.Frame(self, bg=self.theme['card_bg'])
        self.card.pack(fill='both', expand=True, padx=2, pady=2)

        # Header
        header = tk.Frame(self.card, bg=self.theme['card_bg'])
        header.pack(fill='x', padx=15, pady=(15, 5))

        # Icon
        self.icon_label = tk.Label(header, text=icon,
                                  font=('Segoe UI', 16),
                                  bg=self.theme['card_bg'],
                                  fg=self.color)
        self.icon_label.pack(side='left')

        # Titel
        self.title_label = tk.Label(header, text=title,
                                   font=('Segoe UI', 11),
                                   bg=self.theme['card_bg'],
                                   fg=self.theme['text_secondary'])
        self.title_label.pack(side='left', padx=(10, 0))

        # Ring
        self.ring = AnimatedRing(self.card, size=100, thickness=10,
                                theme=self.theme, bg=self.theme['card_bg'])
        self.ring.color = self.color
        self.ring.pack(pady=10)

        # Details
        self.detail1 = tk.Label(self.card, text="--",
                               font=('Segoe UI', 10),
                               bg=self.theme['card_bg'],
                               fg=self.theme['text_primary'])
        self.detail1.pack()

        self.detail2 = tk.Label(self.card, text="--",
                               font=('Segoe UI', 9),
                               bg=self.theme['card_bg'],
                               fg=self.theme['text_muted'])
        self.detail2.pack(pady=(0, 5))

        # Mini Graph
        self.graph = ModernGraph(self.card, width=140, height=40,
                                theme=self.theme, color=self.color,
                                show_grid=False, bg=self.theme['card_bg'])
        self.graph.pack(pady=(0, 15))

    def set_value(self, value, label=None, detail1=None, detail2=None):
        color = self.ring.get_color_for_value(value)
        self.ring.set_value(value, label, color=color)
        self.graph.add_value(value)

        if detail1:
            self.detail1.config(text=detail1)
        if detail2:
            self.detail2.config(text=detail2)


# ============================================================================
# HAUPTANWENDUNG
# ============================================================================

class SystemMonitorPro:
    """Ultra-moderne System Monitor Anwendung"""

    def __init__(self, root):
        self.root = root
        self.root.title(f"{Config.APP_NAME} v{Config.VERSION}")
        self.root.geometry(f"{Config.WINDOW_WIDTH}x{Config.WINDOW_HEIGHT}")
        self.root.minsize(Config.MIN_WIDTH, Config.MIN_HEIGHT)

        # Theme
        self.current_theme = 'midnight'
        self.theme = Config.THEMES[self.current_theme]

        self.root.configure(bg=self.theme['bg_gradient_start'])

        # Daten
        self.cpu_history = deque(maxlen=Config.GRAPH_POINTS)
        self.ram_history = deque(maxlen=Config.GRAPH_POINTS)
        self.net_recv_prev = 0
        self.net_sent_prev = 0
        self.disk_read_prev = 0
        self.disk_write_prev = 0

        # Styles
        self.setup_styles()

        # UI
        self.create_ui()

        # Updates
        self.running = True
        self.current_page = 'dashboard'
        self.start_updates()

        # Keybindings
        self.setup_keybindings()

        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')

        # Treeview
        style.configure('Modern.Treeview',
                       background=self.theme['bg_gradient_end'],
                       foreground=self.theme['text_primary'],
                       fieldbackground=self.theme['bg_gradient_end'],
                       borderwidth=0,
                       font=('Segoe UI', 10))
        style.configure('Modern.Treeview.Heading',
                       background=self.theme['card_bg'],
                       foreground=self.theme['text_secondary'],
                       font=('Segoe UI', 10, 'bold'))
        style.map('Modern.Treeview',
                 background=[('selected', self.theme['accent_primary'])])

        # Scrollbar
        style.configure('Modern.Vertical.TScrollbar',
                       background=self.theme['card_bg'],
                       troughcolor=self.theme['bg_gradient_end'],
                       borderwidth=0, arrowsize=0)

    def create_ui(self):
        # Hauptcontainer
        self.main_container = tk.Frame(self.root, bg=self.theme['bg_gradient_start'])
        self.main_container.pack(fill='both', expand=True)

        # Sidebar
        self.create_sidebar()

        # Content Area
        self.content = tk.Frame(self.main_container, bg=self.theme['bg_gradient_start'])
        self.content.pack(side='left', fill='both', expand=True)

        # Header
        self.create_header()

        # Pages Container
        self.pages_container = tk.Frame(self.content, bg=self.theme['bg_gradient_start'])
        self.pages_container.pack(fill='both', expand=True, padx=20, pady=(0, 20))

        # Pages erstellen
        self.pages = {}
        self.create_dashboard_page()
        self.create_processes_page()
        self.create_network_page()
        self.create_disks_page()
        self.create_system_page()

        # Dashboard anzeigen
        self.show_page('dashboard')

    def create_sidebar(self):
        sidebar = tk.Frame(self.main_container, bg=self.theme['bg_gradient_end'],
                          width=220)
        sidebar.pack(side='left', fill='y')
        sidebar.pack_propagate(False)

        # Logo
        logo_frame = tk.Frame(sidebar, bg=self.theme['bg_gradient_end'])
        logo_frame.pack(fill='x', pady=20)

        logo_icon = tk.Label(logo_frame, text="◉",
                            font=('Segoe UI', 28),
                            bg=self.theme['bg_gradient_end'],
                            fg=self.theme['accent_primary'])
        logo_icon.pack()

        logo_text = tk.Label(logo_frame, text="SystemMonitor",
                            font=('Segoe UI', 14, 'bold'),
                            bg=self.theme['bg_gradient_end'],
                            fg=self.theme['text_primary'])
        logo_text.pack()

        pro_text = tk.Label(logo_frame, text="PRO",
                           font=('Segoe UI', 10, 'bold'),
                           bg=self.theme['bg_gradient_end'],
                           fg=self.theme['accent_secondary'])
        pro_text.pack()

        # Trennlinie
        tk.Frame(sidebar, bg=self.theme['card_border'], height=1).pack(fill='x', padx=20, pady=10)

        # Navigation
        nav_frame = tk.Frame(sidebar, bg=self.theme['bg_gradient_end'])
        nav_frame.pack(fill='x', pady=10)

        self.nav_buttons = {}
        nav_items = [
            ('dashboard', '◫', 'Dashboard'),
            ('processes', '☰', 'Prozesse'),
            ('network', '◎', 'Netzwerk'),
            ('disks', '◔', 'Festplatten'),
            ('system', '⚙', 'System'),
        ]

        for page_id, icon, text in nav_items:
            btn = SidebarButton(nav_frame, text=text, icon=icon,
                              width=200, height=45,
                              theme=self.theme,
                              command=lambda p=page_id: self.show_page(p),
                              bg=self.theme['bg_gradient_end'])
            btn.pack(pady=2, padx=10)
            self.nav_buttons[page_id] = btn

        # Trennlinie
        tk.Frame(sidebar, bg=self.theme['card_border'], height=1).pack(fill='x', padx=20, pady=10)

        # Theme Selector
        theme_frame = tk.Frame(sidebar, bg=self.theme['bg_gradient_end'])
        theme_frame.pack(fill='x', padx=20, pady=10)

        tk.Label(theme_frame, text="Theme",
                font=('Segoe UI', 10),
                bg=self.theme['bg_gradient_end'],
                fg=self.theme['text_muted']).pack(anchor='w')

        themes_row = tk.Frame(theme_frame, bg=self.theme['bg_gradient_end'])
        themes_row.pack(fill='x', pady=5)

        self.theme_buttons = {}
        for theme_id, theme_data in Config.THEMES.items():
            btn = tk.Button(themes_row, text="●",
                          font=('Segoe UI', 16),
                          bg=self.theme['bg_gradient_end'],
                          fg=theme_data['accent_primary'],
                          activebackground=self.theme['bg_gradient_end'],
                          activeforeground=theme_data['accent_primary'],
                          bd=0, cursor='hand2',
                          command=lambda t=theme_id: self.change_theme(t))
            btn.pack(side='left', padx=5)
            self.theme_buttons[theme_id] = btn

        # Spacer
        tk.Frame(sidebar, bg=self.theme['bg_gradient_end']).pack(fill='both', expand=True)

        # Version
        tk.Label(sidebar, text=f"v{Config.VERSION}",
                font=('Segoe UI', 9),
                bg=self.theme['bg_gradient_end'],
                fg=self.theme['text_muted']).pack(pady=20)

    def create_header(self):
        header = tk.Frame(self.content, bg=self.theme['bg_gradient_start'], height=70)
        header.pack(fill='x', padx=20, pady=(20, 10))
        header.pack_propagate(False)

        # Linke Seite - Titel
        left = tk.Frame(header, bg=self.theme['bg_gradient_start'])
        left.pack(side='left', fill='y')

        self.page_title = tk.Label(left, text="Dashboard",
                                  font=('Segoe UI', 24, 'bold'),
                                  bg=self.theme['bg_gradient_start'],
                                  fg=self.theme['text_primary'])
        self.page_title.pack(anchor='w')

        self.page_subtitle = tk.Label(left, text="System-Übersicht in Echtzeit",
                                     font=('Segoe UI', 11),
                                     bg=self.theme['bg_gradient_start'],
                                     fg=self.theme['text_muted'])
        self.page_subtitle.pack(anchor='w')

        # Rechte Seite - Status
        right = tk.Frame(header, bg=self.theme['bg_gradient_start'])
        right.pack(side='right', fill='y')

        # Zeit
        self.time_label = tk.Label(right, text="00:00:00",
                                  font=('Segoe UI', 20, 'bold'),
                                  bg=self.theme['bg_gradient_start'],
                                  fg=self.theme['text_primary'])
        self.time_label.pack(anchor='e')

        # Uptime
        self.uptime_label = tk.Label(right, text="Uptime: --:--:--",
                                    font=('Segoe UI', 10),
                                    bg=self.theme['bg_gradient_start'],
                                    fg=self.theme['text_muted'])
        self.uptime_label.pack(anchor='e')

    def create_dashboard_page(self):
        page = tk.Frame(self.pages_container, bg=self.theme['bg_gradient_start'])
        self.pages['dashboard'] = page

        # Obere Zeile - Haupt-Stats
        top_row = tk.Frame(page, bg=self.theme['bg_gradient_start'])
        top_row.pack(fill='x', pady=(0, 15))

        # CPU Card
        self.cpu_card = StatCard(top_row, title="CPU", icon="⚡",
                                color=self.theme['accent_primary'],
                                theme=self.theme)
        self.cpu_card.pack(side='left', fill='both', expand=True, padx=(0, 10))

        # RAM Card
        self.ram_card = StatCard(top_row, title="Memory", icon="▣",
                                color=self.theme['accent_success'],
                                theme=self.theme)
        self.ram_card.pack(side='left', fill='both', expand=True, padx=10)

        # Disk Card
        self.disk_card = StatCard(top_row, title="Storage", icon="◔",
                                 color=self.theme['accent_warning'],
                                 theme=self.theme)
        self.disk_card.pack(side='left', fill='both', expand=True, padx=10)

        # Network Card
        self.net_card = StatCard(top_row, title="Network", icon="◎",
                                color=self.theme['accent_secondary'],
                                theme=self.theme)
        self.net_card.pack(side='left', fill='both', expand=True, padx=(10, 0))

        # Mittlere Zeile - Detaillierte Graphen
        mid_row = tk.Frame(page, bg=self.theme['bg_gradient_start'])
        mid_row.pack(fill='x', pady=15)

        # CPU Graph - Detailliert
        cpu_graph_frame = tk.Frame(mid_row, bg=self.theme['bg_gradient_end'])
        cpu_graph_frame.pack(side='left', fill='both', expand=True, padx=(0, 10))

        self.cpu_big_graph = DetailedGraph(cpu_graph_frame,
                                          width=450, height=180,
                                          theme=self.theme,
                                          color=self.theme['accent_primary'],
                                          title="CPU Usage",
                                          unit="%",
                                          max_points=Config.DETAILED_GRAPH_POINTS,
                                          bg=self.theme['bg_gradient_end'])
        self.cpu_big_graph.pack(fill='both', expand=True, padx=5, pady=5)

        # RAM Graph - Detailliert
        ram_graph_frame = tk.Frame(mid_row, bg=self.theme['bg_gradient_end'])
        ram_graph_frame.pack(side='left', fill='both', expand=True, padx=(10, 0))

        self.ram_big_graph = DetailedGraph(ram_graph_frame,
                                          width=450, height=180,
                                          theme=self.theme,
                                          color=self.theme['accent_success'],
                                          title="Memory Usage",
                                          unit="%",
                                          max_points=Config.DETAILED_GRAPH_POINTS,
                                          bg=self.theme['bg_gradient_end'])
        self.ram_big_graph.pack(fill='both', expand=True, padx=5, pady=5)

        # Untere Zeile - System Info & Top Processes
        bottom_row = tk.Frame(page, bg=self.theme['bg_gradient_start'])
        bottom_row.pack(fill='both', expand=True, pady=(15, 0))

        # System Info
        self.create_quick_system_info(bottom_row)

        # Top Processes
        self.create_top_processes_widget(bottom_row)

        # Per-Core CPU
        self.create_per_core_widget(bottom_row)

    def create_quick_system_info(self, parent):
        frame = tk.Frame(parent, bg=self.theme['card_bg'])
        frame.pack(side='left', fill='both', expand=True, padx=(0, 10))

        tk.Label(frame, text="System Information",
                font=('Segoe UI', 11, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        info_container = tk.Frame(frame, bg=self.theme['card_bg'])
        info_container.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        hostname = socket.gethostname()
        os_info = f"{platform.system()} {platform.release()}"
        cpu_info = platform.processor()[:30] + "..." if len(platform.processor()) > 30 else platform.processor()

        infos = [
            ("◉", "Hostname", hostname, self.theme['accent_info']),
            ("◉", "OS", os_info, self.theme['accent_primary']),
            ("◉", "CPU", cpu_info, self.theme['accent_success']),
            ("◉", "Cores", f"{psutil.cpu_count(logical=False)} / {psutil.cpu_count()} logical", self.theme['accent_warning']),
            ("◉", "RAM", self.format_bytes(psutil.virtual_memory().total), self.theme['accent_secondary']),
        ]

        for icon, label, value, color in infos:
            row = tk.Frame(info_container, bg=self.theme['card_bg'])
            row.pack(fill='x', pady=4)

            tk.Label(row, text=icon, font=('Segoe UI', 10),
                    bg=self.theme['card_bg'], fg=color).pack(side='left')

            tk.Label(row, text=f"  {label}:",
                    font=('Segoe UI', 10),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_muted']).pack(side='left')

            tk.Label(row, text=f"  {value}",
                    font=('Segoe UI', 10),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_primary']).pack(side='left')

    def create_top_processes_widget(self, parent):
        frame = tk.Frame(parent, bg=self.theme['card_bg'])
        frame.pack(side='left', fill='both', expand=True, padx=10)

        tk.Label(frame, text="Top Processes",
                font=('Segoe UI', 11, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        list_frame = tk.Frame(frame, bg=self.theme['card_bg'])
        list_frame.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        self.top_process_widgets = []
        for i in range(6):
            row = tk.Frame(list_frame, bg=self.theme['card_bg'])
            row.pack(fill='x', pady=3)

            name = tk.Label(row, text="--",
                           font=('Segoe UI', 10),
                           bg=self.theme['card_bg'],
                           fg=self.theme['text_primary'],
                           width=20, anchor='w')
            name.pack(side='left')

            cpu = tk.Label(row, text="0%",
                          font=('Segoe UI', 10, 'bold'),
                          bg=self.theme['card_bg'],
                          fg=self.theme['accent_primary'],
                          width=8)
            cpu.pack(side='right')

            self.top_process_widgets.append({'name': name, 'cpu': cpu})

    def create_per_core_widget(self, parent):
        frame = tk.Frame(parent, bg=self.theme['card_bg'])
        frame.pack(side='left', fill='both', expand=True, padx=(10, 0))

        tk.Label(frame, text="CPU Cores",
                font=('Segoe UI', 11, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        cores_frame = tk.Frame(frame, bg=self.theme['card_bg'])
        cores_frame.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        self.core_bars = []
        num_cores = min(psutil.cpu_count(), 8)  # Max 8 anzeigen

        for i in range(num_cores):
            row = tk.Frame(cores_frame, bg=self.theme['card_bg'])
            row.pack(fill='x', pady=2)

            tk.Label(row, text=f"Core {i}",
                    font=('Segoe UI', 9),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_muted'],
                    width=6, anchor='w').pack(side='left')

            bar = ModernProgressBar(row, width=100, height=6,
                                   theme=self.theme,
                                   color=self.theme['accent_primary'],
                                   bg=self.theme['card_bg'])
            bar.pack(side='left', fill='x', expand=True, padx=5)

            pct = tk.Label(row, text="0%",
                          font=('Segoe UI', 9),
                          bg=self.theme['card_bg'],
                          fg=self.theme['text_secondary'],
                          width=5)
            pct.pack(side='right')

            self.core_bars.append({'bar': bar, 'label': pct})

    def create_processes_page(self):
        page = tk.Frame(self.pages_container, bg=self.theme['bg_gradient_start'])
        self.pages['processes'] = page

        # Toolbar
        toolbar = tk.Frame(page, bg=self.theme['card_bg'], height=60)
        toolbar.pack(fill='x', pady=(0, 15))
        toolbar.pack_propagate(False)

        # Suchfeld
        search_frame = tk.Frame(toolbar, bg=self.theme['card_bg'])
        search_frame.pack(side='left', padx=20, pady=15)

        tk.Label(search_frame, text="🔍",
                font=('Segoe UI', 12),
                bg=self.theme['card_bg'],
                fg=self.theme['text_muted']).pack(side='left')

        self.process_search = tk.Entry(search_frame,
                                      font=('Segoe UI', 11),
                                      bg=self.theme['bg_gradient_end'],
                                      fg=self.theme['text_primary'],
                                      insertbackground=self.theme['text_primary'],
                                      bd=0, width=30)
        self.process_search.pack(side='left', padx=10, ipady=5)
        self.process_search.bind('<KeyRelease>', self.filter_processes)

        # Buttons
        btn_frame = tk.Frame(toolbar, bg=self.theme['card_bg'])
        btn_frame.pack(side='right', padx=20, pady=15)

        refresh_btn = tk.Button(btn_frame, text="Refresh",
                               font=('Segoe UI', 10),
                               bg=self.theme['accent_primary'],
                               fg='white',
                               activebackground=self.theme['accent_secondary'],
                               bd=0, padx=20, pady=8,
                               cursor='hand2',
                               command=self.refresh_processes)
        refresh_btn.pack(side='left', padx=5)

        kill_btn = tk.Button(btn_frame, text="End Task",
                            font=('Segoe UI', 10),
                            bg=self.theme['accent_danger'],
                            fg='white',
                            activebackground='#ff6b6b',
                            bd=0, padx=20, pady=8,
                            cursor='hand2',
                            command=self.kill_process)
        kill_btn.pack(side='left', padx=5)

        # Prozessliste
        list_frame = tk.Frame(page, bg=self.theme['card_bg'])
        list_frame.pack(fill='both', expand=True)

        columns = ('pid', 'name', 'status', 'cpu', 'memory', 'threads')
        self.process_tree = ttk.Treeview(list_frame, columns=columns,
                                        show='headings', style='Modern.Treeview')

        self.process_tree.heading('pid', text='PID', command=lambda: self.sort_processes('pid'))
        self.process_tree.heading('name', text='Process Name', command=lambda: self.sort_processes('name'))
        self.process_tree.heading('status', text='Status', command=lambda: self.sort_processes('status'))
        self.process_tree.heading('cpu', text='CPU %', command=lambda: self.sort_processes('cpu'))
        self.process_tree.heading('memory', text='Memory %', command=lambda: self.sort_processes('memory'))
        self.process_tree.heading('threads', text='Threads', command=lambda: self.sort_processes('threads'))

        self.process_tree.column('pid', width=80, anchor='center')
        self.process_tree.column('name', width=300)
        self.process_tree.column('status', width=100, anchor='center')
        self.process_tree.column('cpu', width=100, anchor='center')
        self.process_tree.column('memory', width=100, anchor='center')
        self.process_tree.column('threads', width=80, anchor='center')

        scrollbar = ttk.Scrollbar(list_frame, orient='vertical',
                                 command=self.process_tree.yview,
                                 style='Modern.Vertical.TScrollbar')
        self.process_tree.configure(yscrollcommand=scrollbar.set)

        self.process_tree.pack(side='left', fill='both', expand=True, padx=15, pady=15)
        scrollbar.pack(side='right', fill='y', pady=15)

        self.process_cache = []
        self.sort_column = 'cpu'
        self.sort_reverse = True

    def create_network_page(self):
        page = tk.Frame(self.pages_container, bg=self.theme['bg_gradient_start'])
        self.pages['network'] = page

        # Obere Zeile - Geschwindigkeiten
        top_row = tk.Frame(page, bg=self.theme['bg_gradient_start'])
        top_row.pack(fill='x', pady=(0, 15))

        # Download
        dl_frame = tk.Frame(top_row, bg=self.theme['card_bg'])
        dl_frame.pack(side='left', fill='both', expand=True, padx=(0, 10))

        tk.Label(dl_frame, text="↓",
                font=('Segoe UI', 24),
                bg=self.theme['card_bg'],
                fg=self.theme['accent_success']).pack(pady=(20, 5))

        tk.Label(dl_frame, text="Download",
                font=('Segoe UI', 11),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack()

        self.download_speed_label = tk.Label(dl_frame, text="0 KB/s",
                                            font=('Segoe UI', 28, 'bold'),
                                            bg=self.theme['card_bg'],
                                            fg=self.theme['accent_success'])
        self.download_speed_label.pack(pady=10)

        self.download_total_label = tk.Label(dl_frame, text="Total: 0 MB",
                                            font=('Segoe UI', 10),
                                            bg=self.theme['card_bg'],
                                            fg=self.theme['text_muted'])
        self.download_total_label.pack(pady=(0, 20))

        # Upload
        ul_frame = tk.Frame(top_row, bg=self.theme['card_bg'])
        ul_frame.pack(side='left', fill='both', expand=True, padx=(10, 0))

        tk.Label(ul_frame, text="↑",
                font=('Segoe UI', 24),
                bg=self.theme['card_bg'],
                fg=self.theme['accent_secondary']).pack(pady=(20, 5))

        tk.Label(ul_frame, text="Upload",
                font=('Segoe UI', 11),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack()

        self.upload_speed_label = tk.Label(ul_frame, text="0 KB/s",
                                          font=('Segoe UI', 28, 'bold'),
                                          bg=self.theme['card_bg'],
                                          fg=self.theme['accent_secondary'])
        self.upload_speed_label.pack(pady=10)

        self.upload_total_label = tk.Label(ul_frame, text="Total: 0 MB",
                                          font=('Segoe UI', 10),
                                          bg=self.theme['card_bg'],
                                          fg=self.theme['text_muted'])
        self.upload_total_label.pack(pady=(0, 20))

        # Netzwerk Graphen
        graph_row = tk.Frame(page, bg=self.theme['bg_gradient_start'])
        graph_row.pack(fill='x', pady=(0, 15))

        # Download Graph
        dl_graph_frame = tk.Frame(graph_row, bg=self.theme['bg_gradient_end'])
        dl_graph_frame.pack(side='left', fill='both', expand=True, padx=(0, 10))

        self.download_graph = DetailedGraph(dl_graph_frame,
                                           width=450, height=150,
                                           theme=self.theme,
                                           color=self.theme['accent_success'],
                                           title="Download Speed",
                                           unit=" KB/s",
                                           max_points=Config.DETAILED_GRAPH_POINTS,
                                           bg=self.theme['bg_gradient_end'])
        self.download_graph.pack(fill='both', expand=True, padx=5, pady=5)

        # Upload Graph
        ul_graph_frame = tk.Frame(graph_row, bg=self.theme['bg_gradient_end'])
        ul_graph_frame.pack(side='left', fill='both', expand=True, padx=(10, 0))

        self.upload_graph = DetailedGraph(ul_graph_frame,
                                         width=450, height=150,
                                         theme=self.theme,
                                         color=self.theme['accent_secondary'],
                                         title="Upload Speed",
                                         unit=" KB/s",
                                         max_points=Config.DETAILED_GRAPH_POINTS,
                                         bg=self.theme['bg_gradient_end'])
        self.upload_graph.pack(fill='both', expand=True, padx=5, pady=5)

        # Network Interfaces
        interfaces_frame = tk.Frame(page, bg=self.theme['card_bg'])
        interfaces_frame.pack(fill='both', expand=True)

        tk.Label(interfaces_frame, text="Network Interfaces",
                font=('Segoe UI', 11, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        columns = ('name', 'ip', 'mac', 'status')
        self.net_tree = ttk.Treeview(interfaces_frame, columns=columns,
                                    show='headings', style='Modern.Treeview', height=10)

        self.net_tree.heading('name', text='Interface')
        self.net_tree.heading('ip', text='IP Address')
        self.net_tree.heading('mac', text='MAC Address')
        self.net_tree.heading('status', text='Status')

        self.net_tree.column('name', width=200)
        self.net_tree.column('ip', width=180)
        self.net_tree.column('mac', width=200)
        self.net_tree.column('status', width=100, anchor='center')

        self.net_tree.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        self.load_network_interfaces()

    def create_disks_page(self):
        page = tk.Frame(self.pages_container, bg=self.theme['bg_gradient_start'])
        self.pages['disks'] = page

        # I/O Anzeige
        io_row = tk.Frame(page, bg=self.theme['bg_gradient_start'])
        io_row.pack(fill='x', pady=(0, 15))

        # Read
        read_frame = tk.Frame(io_row, bg=self.theme['card_bg'])
        read_frame.pack(side='left', fill='both', expand=True, padx=(0, 10))

        tk.Label(read_frame, text="Read Speed",
                font=('Segoe UI', 11),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(pady=(20, 5))

        self.disk_read_label = tk.Label(read_frame, text="0 MB/s",
                                       font=('Segoe UI', 24, 'bold'),
                                       bg=self.theme['card_bg'],
                                       fg=self.theme['accent_info'])
        self.disk_read_label.pack(pady=(0, 20))

        # Write
        write_frame = tk.Frame(io_row, bg=self.theme['card_bg'])
        write_frame.pack(side='left', fill='both', expand=True, padx=(10, 0))

        tk.Label(write_frame, text="Write Speed",
                font=('Segoe UI', 11),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(pady=(20, 5))

        self.disk_write_label = tk.Label(write_frame, text="0 MB/s",
                                        font=('Segoe UI', 24, 'bold'),
                                        bg=self.theme['card_bg'],
                                        fg=self.theme['accent_warning'])
        self.disk_write_label.pack(pady=(0, 20))

        # Partitionen
        partitions_frame = tk.Frame(page, bg=self.theme['card_bg'])
        partitions_frame.pack(fill='both', expand=True)

        tk.Label(partitions_frame, text="Storage Devices",
                font=('Segoe UI', 11, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        self.partitions_container = tk.Frame(partitions_frame, bg=self.theme['card_bg'])
        self.partitions_container.pack(fill='both', expand=True, padx=15, pady=(0, 15))

        self.load_partitions()

    def create_system_page(self):
        page = tk.Frame(self.pages_container, bg=self.theme['bg_gradient_start'])
        self.pages['system'] = page

        # Scrollable
        canvas = tk.Canvas(page, bg=self.theme['bg_gradient_start'], highlightthickness=0)
        scrollbar = ttk.Scrollbar(page, orient='vertical', command=canvas.yview)
        scrollable = tk.Frame(canvas, bg=self.theme['bg_gradient_start'])

        scrollable.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scrollable, anchor='nw')
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side='left', fill='both', expand=True)
        scrollbar.pack(side='right', fill='y')

        # Hardware
        hw_frame = tk.Frame(scrollable, bg=self.theme['card_bg'])
        hw_frame.pack(fill='x', pady=(0, 15), padx=(0, 15))

        tk.Label(hw_frame, text="Hardware Information",
                font=('Segoe UI', 12, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        hw_info = [
            ("Processor", platform.processor() or "Unknown"),
            ("Architecture", platform.machine()),
            ("Physical Cores", str(psutil.cpu_count(logical=False))),
            ("Logical Cores", str(psutil.cpu_count())),
            ("Total RAM", self.format_bytes(psutil.virtual_memory().total)),
        ]

        for label, value in hw_info:
            row = tk.Frame(hw_frame, bg=self.theme['card_bg'])
            row.pack(fill='x', padx=15, pady=4)

            tk.Label(row, text=f"{label}:",
                    font=('Segoe UI', 10),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_muted'],
                    width=20, anchor='w').pack(side='left')

            tk.Label(row, text=value,
                    font=('Segoe UI', 10),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_primary']).pack(side='left')

        tk.Frame(hw_frame, bg=self.theme['card_bg'], height=15).pack()

        # Software
        sw_frame = tk.Frame(scrollable, bg=self.theme['card_bg'])
        sw_frame.pack(fill='x', pady=(0, 15), padx=(0, 15))

        tk.Label(sw_frame, text="Software Information",
                font=('Segoe UI', 12, 'bold'),
                bg=self.theme['card_bg'],
                fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

        boot_time = datetime.fromtimestamp(psutil.boot_time())

        sw_info = [
            ("Operating System", platform.system()),
            ("OS Version", platform.release()),
            ("OS Build", platform.version()[:50]),
            ("Hostname", socket.gethostname()),
            ("Boot Time", boot_time.strftime("%Y-%m-%d %H:%M:%S")),
            ("Python Version", platform.python_version()),
        ]

        for label, value in sw_info:
            row = tk.Frame(sw_frame, bg=self.theme['card_bg'])
            row.pack(fill='x', padx=15, pady=4)

            tk.Label(row, text=f"{label}:",
                    font=('Segoe UI', 10),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_muted'],
                    width=20, anchor='w').pack(side='left')

            tk.Label(row, text=value,
                    font=('Segoe UI', 10),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_primary']).pack(side='left')

        tk.Frame(sw_frame, bg=self.theme['card_bg'], height=15).pack()

        # Battery (if available)
        battery = psutil.sensors_battery()
        if battery:
            bat_frame = tk.Frame(scrollable, bg=self.theme['card_bg'])
            bat_frame.pack(fill='x', pady=(0, 15), padx=(0, 15))

            tk.Label(bat_frame, text="Battery Status",
                    font=('Segoe UI', 12, 'bold'),
                    bg=self.theme['card_bg'],
                    fg=self.theme['text_secondary']).pack(anchor='w', padx=15, pady=(15, 10))

            bat_container = tk.Frame(bat_frame, bg=self.theme['card_bg'])
            bat_container.pack(fill='x', padx=15, pady=(0, 15))

            self.battery_ring = AnimatedRing(bat_container, size=80, thickness=8,
                                            theme=self.theme,
                                            bg=self.theme['card_bg'])
            self.battery_ring.color = self.theme['accent_success']
            self.battery_ring.pack(side='left', padx=(0, 20))

            bat_info = tk.Frame(bat_container, bg=self.theme['card_bg'])
            bat_info.pack(side='left', fill='both', expand=True)

            self.battery_status_label = tk.Label(bat_info, text="--",
                                                font=('Segoe UI', 11),
                                                bg=self.theme['card_bg'],
                                                fg=self.theme['text_primary'])
            self.battery_status_label.pack(anchor='w')

            self.battery_time_label = tk.Label(bat_info, text="--",
                                              font=('Segoe UI', 10),
                                              bg=self.theme['card_bg'],
                                              fg=self.theme['text_muted'])
            self.battery_time_label.pack(anchor='w')

    def show_page(self, page_id):
        # Alle Seiten verstecken
        for pid, page in self.pages.items():
            page.pack_forget()

        # Buttons aktualisieren
        for btn_id, btn in self.nav_buttons.items():
            btn.set_active(btn_id == page_id)

        # Seite anzeigen
        self.pages[page_id].pack(fill='both', expand=True)
        self.current_page = page_id

        # Titel aktualisieren
        titles = {
            'dashboard': ('Dashboard', 'Real-time system overview'),
            'processes': ('Processes', 'Manage running processes'),
            'network': ('Network', 'Network activity and interfaces'),
            'disks': ('Storage', 'Disk usage and I/O'),
            'system': ('System', 'Hardware and software information'),
        }

        title, subtitle = titles.get(page_id, ('', ''))
        self.page_title.config(text=title)
        self.page_subtitle.config(text=subtitle)

        # Prozesse laden wenn Prozess-Tab
        if page_id == 'processes':
            self.refresh_processes()

    def change_theme(self, theme_id):
        self.current_theme = theme_id
        self.theme = Config.THEMES[theme_id]
        # Neustart erforderlich für Theme-Wechsel
        messagebox.showinfo("Theme", f"Theme '{self.theme['name']}' wird beim nächsten Start aktiviert.")

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
                elif addr.family.name in ('AF_LINK', 'AF_PACKET'):
                    mac = addr.address

            status = "Active" if stats.get(interface) and stats[interface].isup else "Inactive"
            self.net_tree.insert('', 'end', values=(interface, ip, mac, status))

    def load_partitions(self):
        for widget in self.partitions_container.winfo_children():
            widget.destroy()

        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)

                part_frame = tk.Frame(self.partitions_container, bg=self.theme['bg_gradient_end'])
                part_frame.pack(fill='x', pady=5)

                info = tk.Frame(part_frame, bg=self.theme['bg_gradient_end'])
                info.pack(fill='x', padx=10, pady=10)

                # Header
                header = tk.Frame(info, bg=self.theme['bg_gradient_end'])
                header.pack(fill='x')

                tk.Label(header, text=partition.device,
                        font=('Segoe UI', 11, 'bold'),
                        bg=self.theme['bg_gradient_end'],
                        fg=self.theme['text_primary']).pack(side='left')

                tk.Label(header, text=f"  ({partition.fstype})",
                        font=('Segoe UI', 9),
                        bg=self.theme['bg_gradient_end'],
                        fg=self.theme['text_muted']).pack(side='left')

                tk.Label(header, text=f"{usage.percent}%",
                        font=('Segoe UI', 11, 'bold'),
                        bg=self.theme['bg_gradient_end'],
                        fg=self.theme['accent_warning']).pack(side='right')

                # Progress Bar
                bar = ModernProgressBar(info, width=400, height=8,
                                       theme=self.theme,
                                       color=self.theme['accent_warning'],
                                       bg=self.theme['bg_gradient_end'])
                bar.pack(fill='x', pady=(8, 0))
                bar.set_value(usage.percent)

                # Details
                tk.Label(info,
                        text=f"{self.format_bytes(usage.used)} / {self.format_bytes(usage.total)} ({self.format_bytes(usage.free)} free)",
                        font=('Segoe UI', 9),
                        bg=self.theme['bg_gradient_end'],
                        fg=self.theme['text_muted']).pack(anchor='w', pady=(5, 0))

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
        self.root.after(Config.UPDATE_INTERVAL, self.start_updates)

    def update_stats(self):
        try:
            # Zeit
            self.time_label.config(text=datetime.now().strftime("%H:%M:%S"))

            # Uptime
            uptime = time.time() - psutil.boot_time()
            hours, remainder = divmod(int(uptime), 3600)
            minutes, seconds = divmod(remainder, 60)
            self.uptime_label.config(text=f"Uptime: {hours:02d}:{minutes:02d}:{seconds:02d}")

            # CPU
            cpu_percent = psutil.cpu_percent(interval=0)
            self.cpu_card.set_value(cpu_percent,
                                   detail1=f"{psutil.cpu_freq().current:.0f} MHz" if psutil.cpu_freq() else "--",
                                   detail2=f"{psutil.cpu_count()} cores")
            self.cpu_big_graph.add_value(cpu_percent)

            # Per-Core CPU
            per_cpu = psutil.cpu_percent(percpu=True)
            for i, (bar_data, pct) in enumerate(zip(self.core_bars, per_cpu[:len(self.core_bars)])):
                bar_data['bar'].set_value(pct)
                bar_data['label'].config(text=f"{pct:.0f}%")

            # RAM
            mem = psutil.virtual_memory()
            self.ram_card.set_value(mem.percent,
                                   detail1=self.format_bytes(mem.used),
                                   detail2=f"of {self.format_bytes(mem.total)}")
            self.ram_big_graph.add_value(mem.percent)

            # Disk
            disk = psutil.disk_usage('/')
            self.disk_card.set_value(disk.percent,
                                    detail1=self.format_bytes(disk.used),
                                    detail2=f"of {self.format_bytes(disk.total)}")

            # Disk I/O
            disk_io = psutil.disk_io_counters()
            if disk_io:
                read_speed = disk_io.read_bytes - self.disk_read_prev
                write_speed = disk_io.write_bytes - self.disk_write_prev
                self.disk_read_prev = disk_io.read_bytes
                self.disk_write_prev = disk_io.write_bytes

                if hasattr(self, 'disk_read_label'):
                    self.disk_read_label.config(text=self.format_speed(read_speed))
                    self.disk_write_label.config(text=self.format_speed(write_speed))

            # Network
            net = psutil.net_io_counters()
            recv_speed = net.bytes_recv - self.net_recv_prev
            sent_speed = net.bytes_sent - self.net_sent_prev
            self.net_recv_prev = net.bytes_recv
            self.net_sent_prev = net.bytes_sent

            total_speed = recv_speed + sent_speed
            speed_pct = min(100, (total_speed / (10 * 1024 * 1024)) * 100)
            self.net_card.set_value(speed_pct,
                                   label=self.format_speed(total_speed),
                                   detail1=f"↓ {self.format_speed(recv_speed)}",
                                   detail2=f"↑ {self.format_speed(sent_speed)}")

            if hasattr(self, 'download_speed_label'):
                self.download_speed_label.config(text=self.format_speed(recv_speed))
                self.upload_speed_label.config(text=self.format_speed(sent_speed))
                self.download_total_label.config(text=f"Total: {self.format_bytes(net.bytes_recv)}")
                self.upload_total_label.config(text=f"Total: {self.format_bytes(net.bytes_sent)}")

            # Netzwerk Graphen (in KB/s, max 1000 KB/s = 100%)
            if hasattr(self, 'download_graph'):
                dl_kb = recv_speed / 1024  # Bytes zu KB
                ul_kb = sent_speed / 1024
                # Skaliere auf 0-100 (max 1 MB/s = 100%)
                self.download_graph.add_value(min(100, dl_kb / 10))
                self.upload_graph.add_value(min(100, ul_kb / 10))

            # Top Processes
            self.update_top_processes()

            # Battery
            if hasattr(self, 'battery_ring'):
                battery = psutil.sensors_battery()
                if battery:
                    self.battery_ring.set_value(battery.percent)
                    status = "Charging" if battery.power_plugged else "On Battery"
                    self.battery_status_label.config(text=f"Status: {status} ({battery.percent}%)")
                    if battery.secsleft > 0 and not battery.power_plugged:
                        h, m = divmod(battery.secsleft // 60, 60)
                        self.battery_time_label.config(text=f"Time remaining: {int(h)}h {int(m)}m")
                    else:
                        self.battery_time_label.config(text="")

        except Exception as e:
            print(f"Update error: {e}")

    def update_top_processes(self):
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
            try:
                pinfo = proc.info
                if pinfo['cpu_percent'] and pinfo['cpu_percent'] > 0:
                    processes.append(pinfo)
            except:
                pass

        processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)

        for i, widget in enumerate(self.top_process_widgets):
            if i < len(processes):
                proc = processes[i]
                widget['name'].config(text=proc['name'][:20] if proc['name'] else '--')
                widget['cpu'].config(text=f"{proc['cpu_percent']:.1f}%")
            else:
                widget['name'].config(text='--')
                widget['cpu'].config(text='0%')

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
            except:
                pass
        self.display_processes()

    def display_processes(self):
        self.process_cache.sort(
            key=lambda x: x[self.sort_column] if self.sort_column != 'name' else x[self.sort_column].lower(),
            reverse=self.sort_reverse
        )

        search = self.process_search.get().lower()

        for item in self.process_tree.get_children():
            self.process_tree.delete(item)

        for proc in self.process_cache:
            if search and search not in proc['name'].lower():
                continue
            self.process_tree.insert('', 'end', values=(
                proc['pid'], proc['name'][:45], proc['status'],
                f"{proc['cpu']:.1f}", f"{proc['memory']:.1f}", proc['threads']
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
            messagebox.showwarning("Warning", "Please select a process.")
            return

        item = self.process_tree.item(selected[0])
        pid, name = item['values'][0], item['values'][1]

        if messagebox.askyesno("End Task", f"End process '{name}' (PID: {pid})?"):
            try:
                psutil.Process(pid).terminate()
                self.root.after(500, self.refresh_processes)
                messagebox.showinfo("Success", f"Process '{name}' terminated.")
            except psutil.NoSuchProcess:
                messagebox.showerror("Error", "Process no longer exists.")
            except psutil.AccessDenied:
                messagebox.showerror("Error", "Access denied.")

    def setup_keybindings(self):
        self.root.bind('<F5>', lambda e: self.refresh_processes())
        self.root.bind('<Escape>', lambda e: self.on_close())

    def on_close(self):
        self.running = False
        self.root.destroy()


# ============================================================================
# MAIN
# ============================================================================

def main():
    root = tk.Tk()

    try:
        if sys.platform == 'win32':
            root.iconbitmap('icon.ico')
    except:
        pass

    app = SystemMonitorPro(root)
    root.mainloop()


if __name__ == "__main__":
    main()
