"""
Battlefield: Python Edition v1.0
A 2D top-down Conquest-mode shooter inspired by Battlefield
"""

import pygame
import math
import random
import sys
from collections import deque

# Initialize pygame
pygame.init()
pygame.mixer.init(frequency=22050, size=-16, channels=2, buffer=512)

# ============================================================================
# Constants
# ============================================================================

SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
FPS = 60
MAP_WIDTH = 3200
MAP_HEIGHT = 3200

# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (220, 50, 50)
BLUE = (50, 100, 220)
GREEN = (50, 200, 80)
YELLOW = (255, 220, 50)
ORANGE = (255, 150, 50)
GRAY = (128, 128, 128)
DARK_GRAY = (40, 40, 40)
LIGHT_GRAY = (180, 180, 180)
BROWN = (139, 90, 43)
DARK_GREEN = (30, 100, 30)
SAND = (194, 178, 128)
WATER = (50, 100, 180)

# Teams
TEAM_BLUE = 0
TEAM_RED = 1
TEAM_COLORS = {TEAM_BLUE: (80, 140, 255), TEAM_RED: (255, 80, 80)}
TEAM_NAMES = {TEAM_BLUE: "BLAU", TEAM_RED: "ROT"}

# Classes
CLASS_ASSAULT = 0
CLASS_ENGINEER = 1
CLASS_SUPPORT = 2
CLASS_RECON = 3

CLASS_DATA = {
    CLASS_ASSAULT: {
        'name': 'Sturm',
        'health': 100,
        'speed': 3.5,
        'weapon': 'Sturmgewehr',
        'damage': 18,
        'fire_rate': 8,
        'range': 400,
        'spread': 4,
        'mag_size': 30,
        'reload_time': 90,
        'bullet_speed': 14,
        'color': (80, 200, 80),
    },
    CLASS_ENGINEER: {
        'name': 'Ingenieur',
        'health': 90,
        'speed': 3.2,
        'weapon': 'SMG',
        'damage': 14,
        'fire_rate': 5,
        'range': 300,
        'spread': 6,
        'mag_size': 40,
        'reload_time': 75,
        'bullet_speed': 12,
        'has_rocket': True,
        'color': (200, 200, 80),
    },
    CLASS_SUPPORT: {
        'name': 'Unterstuetzung',
        'health': 120,
        'speed': 2.8,
        'weapon': 'LMG',
        'damage': 16,
        'fire_rate': 6,
        'range': 450,
        'spread': 7,
        'mag_size': 100,
        'reload_time': 150,
        'bullet_speed': 13,
        'color': (80, 80, 200),
    },
    CLASS_RECON: {
        'name': 'Aufklaerer',
        'health': 80,
        'speed': 3.8,
        'weapon': 'Scharfschuetze',
        'damage': 75,
        'fire_rate': 45,
        'range': 800,
        'spread': 1,
        'mag_size': 5,
        'reload_time': 120,
        'bullet_speed': 22,
        'color': (200, 80, 200),
    },
}


# ============================================================================
# Sound Generator
# ============================================================================

class SoundGen:
    """Generate simple sound effects procedurally"""

    @staticmethod
    def generate_shoot():
        samples = 2048
        buf = bytearray(samples * 2)
        for i in range(samples):
            t = i / 22050
            val = int(random.randint(-8000, 8000) * max(0, 1 - t * 15))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        sound = pygame.mixer.Sound(buffer=bytes(buf))
        sound.set_volume(0.15)
        return sound

    @staticmethod
    def generate_explosion():
        samples = 8000
        buf = bytearray(samples * 2)
        for i in range(samples):
            t = i / 22050
            val = int(random.randint(-20000, 20000) * max(0, 1 - t * 3) *
                     math.sin(t * 80))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        sound = pygame.mixer.Sound(buffer=bytes(buf))
        sound.set_volume(0.25)
        return sound

    @staticmethod
    def generate_hit():
        samples = 1024
        buf = bytearray(samples * 2)
        for i in range(samples):
            t = i / 22050
            val = int(math.sin(t * 2000) * 10000 * max(0, 1 - t * 20))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        sound = pygame.mixer.Sound(buffer=bytes(buf))
        sound.set_volume(0.2)
        return sound

    @staticmethod
    def generate_capture():
        samples = 11025
        buf = bytearray(samples * 2)
        for i in range(samples):
            t = i / 22050
            freq = 400 + t * 600
            val = int(math.sin(t * freq * 2 * math.pi) * 8000 * max(0, 1 - t * 2))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        sound = pygame.mixer.Sound(buffer=bytes(buf))
        sound.set_volume(0.2)
        return sound


# ============================================================================
# Particle System
# ============================================================================

class Particle:
    def __init__(self, x, y, vx, vy, color, lifetime, size=3):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color = color
        self.lifetime = lifetime
        self.max_lifetime = lifetime
        self.size = size

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vx *= 0.96
        self.vy *= 0.96
        self.lifetime -= 1
        return self.lifetime > 0

    def draw(self, surface, camera_x, camera_y):
        alpha = self.lifetime / self.max_lifetime
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if 0 <= sx < SCREEN_WIDTH and 0 <= sy < SCREEN_HEIGHT:
            size = max(1, int(self.size * alpha))
            color = tuple(int(c * alpha) for c in self.color)
            pygame.draw.circle(surface, color, (int(sx), int(sy)), size)


# ============================================================================
# Bullet
# ============================================================================

class Bullet:
    def __init__(self, x, y, angle, speed, damage, team, max_range):
        self.x = x
        self.y = y
        self.start_x = x
        self.start_y = y
        self.vx = math.cos(angle) * speed
        self.vy = math.sin(angle) * speed
        self.damage = damage
        self.team = team
        self.max_range = max_range
        self.alive = True

    def update(self):
        self.x += self.vx
        self.y += self.vy
        dist = math.hypot(self.x - self.start_x, self.y - self.start_y)
        if dist > self.max_range:
            self.alive = False
        if self.x < 0 or self.x > MAP_WIDTH or self.y < 0 or self.y > MAP_HEIGHT:
            self.alive = False
        return self.alive

    def draw(self, surface, camera_x, camera_y):
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if 0 <= sx < SCREEN_WIDTH and 0 <= sy < SCREEN_HEIGHT:
            color = (255, 255, 150) if self.team == TEAM_BLUE else (255, 150, 150)
            pygame.draw.circle(surface, color, (int(sx), int(sy)), 2)


# ============================================================================
# Rocket (for Engineer class)
# ============================================================================

class Rocket:
    def __init__(self, x, y, angle, team):
        self.x = x
        self.y = y
        self.angle = angle
        self.speed = 6
        self.vx = math.cos(angle) * self.speed
        self.vy = math.sin(angle) * self.speed
        self.team = team
        self.damage = 80
        self.blast_radius = 100
        self.alive = True
        self.lifetime = 180
        self.trail = []

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.lifetime -= 1
        self.trail.append((self.x, self.y))
        if len(self.trail) > 15:
            self.trail.pop(0)
        if self.lifetime <= 0 or self.x < 0 or self.x > MAP_WIDTH or self.y < 0 or self.y > MAP_HEIGHT:
            self.alive = False
        return self.alive

    def draw(self, surface, camera_x, camera_y):
        # Trail
        for i, (tx, ty) in enumerate(self.trail):
            sx = tx - camera_x + SCREEN_WIDTH // 2
            sy = ty - camera_y + SCREEN_HEIGHT // 2
            alpha = i / len(self.trail)
            color = (int(255 * alpha), int(100 * alpha), 0)
            if 0 <= sx < SCREEN_WIDTH and 0 <= sy < SCREEN_HEIGHT:
                pygame.draw.circle(surface, color, (int(sx), int(sy)), 2)
        # Rocket
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if 0 <= sx < SCREEN_WIDTH and 0 <= sy < SCREEN_HEIGHT:
            pygame.draw.circle(surface, (255, 200, 50), (int(sx), int(sy)), 4)


# ============================================================================
# Vehicle
# ============================================================================

class Vehicle:
    def __init__(self, x, y, vehicle_type='tank'):
        self.x = x
        self.y = y
        self.angle = 0
        self.speed = 0
        self.max_speed = 2.5 if vehicle_type == 'tank' else 4.0
        self.health = 500 if vehicle_type == 'tank' else 200
        self.max_health = self.health
        self.vehicle_type = vehicle_type
        self.driver = None
        self.team = None
        self.fire_cooldown = 0
        self.size = 30 if vehicle_type == 'tank' else 20
        self.respawn_timer = 0
        self.spawn_x = x
        self.spawn_y = y
        self.destroyed = False

    def update(self):
        if self.destroyed:
            self.respawn_timer -= 1
            if self.respawn_timer <= 0:
                self.destroyed = False
                self.health = self.max_health
                self.x = self.spawn_x
                self.y = self.spawn_y
                self.driver = None
                self.team = None
            return

        if self.fire_cooldown > 0:
            self.fire_cooldown -= 1

        if self.driver:
            self.x += math.cos(self.angle) * self.speed
            self.y += math.sin(self.angle) * self.speed
            self.x = max(self.size, min(MAP_WIDTH - self.size, self.x))
            self.y = max(self.size, min(MAP_HEIGHT - self.size, self.y))
            self.speed *= 0.95

    def enter(self, soldier):
        if self.destroyed:
            return False
        if self.driver is None:
            dist = math.hypot(self.x - soldier.x, self.y - soldier.y)
            if dist < 60:
                self.driver = soldier
                self.team = soldier.team
                soldier.in_vehicle = self
                return True
        return False

    def exit_vehicle(self):
        if self.driver:
            self.driver.x = self.x + math.cos(self.angle + math.pi/2) * 50
            self.driver.y = self.y + math.sin(self.angle + math.pi/2) * 50
            self.driver.in_vehicle = None
            self.driver = None
            self.speed = 0

    def take_damage(self, damage):
        self.health -= damage
        if self.health <= 0:
            self.destroyed = True
            self.respawn_timer = 600  # 10 seconds
            if self.driver:
                self.driver.take_damage(200)
                self.driver.in_vehicle = None
                self.driver = None
            return True
        return False

    def draw(self, surface, camera_x, camera_y):
        if self.destroyed:
            return
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if not (-50 <= sx < SCREEN_WIDTH + 50 and -50 <= sy < SCREEN_HEIGHT + 50):
            return

        # Vehicle body
        color = TEAM_COLORS.get(self.team, GRAY)
        if self.vehicle_type == 'tank':
            # Tank body
            points = []
            for corner_angle in [-0.4, 0.4, math.pi - 0.4, math.pi + 0.4]:
                px = sx + math.cos(self.angle + corner_angle) * self.size
                py = sy + math.sin(self.angle + corner_angle) * self.size
                points.append((px, py))
            pygame.draw.polygon(surface, color, points)
            pygame.draw.polygon(surface, WHITE, points, 1)
            # Turret
            tx = sx + math.cos(self.angle) * self.size * 0.8
            ty = sy + math.sin(self.angle) * self.size * 0.8
            pygame.draw.line(surface, WHITE, (int(sx), int(sy)), (int(tx), int(ty)), 3)
        else:
            # Jeep
            points = []
            for corner_angle in [-0.5, 0.5, math.pi - 0.5, math.pi + 0.5]:
                px = sx + math.cos(self.angle + corner_angle) * self.size
                py = sy + math.sin(self.angle + corner_angle) * self.size
                points.append((px, py))
            pygame.draw.polygon(surface, color, points)
            pygame.draw.polygon(surface, WHITE, points, 1)

        # Health bar
        if self.health < self.max_health:
            bar_w = self.size * 2
            bar_h = 4
            hp_ratio = self.health / self.max_health
            pygame.draw.rect(surface, DARK_GRAY, (sx - bar_w//2, sy - self.size - 12, bar_w, bar_h))
            pygame.draw.rect(surface, GREEN if hp_ratio > 0.5 else (YELLOW if hp_ratio > 0.25 else RED),
                           (sx - bar_w//2, sy - self.size - 12, int(bar_w * hp_ratio), bar_h))


# ============================================================================
# Soldier (Player & AI)
# ============================================================================

class Soldier:
    def __init__(self, x, y, team, soldier_class, is_player=False):
        self.x = x
        self.y = y
        self.team = team
        self.soldier_class = soldier_class
        self.is_player = is_player
        self.class_data = CLASS_DATA[soldier_class]

        self.health = self.class_data['health']
        self.max_health = self.class_data['health']
        self.speed = self.class_data['speed']
        self.angle = random.uniform(0, 2 * math.pi)
        self.alive = True
        self.respawn_timer = 0
        self.in_vehicle = None

        # Weapon
        self.ammo = self.class_data['mag_size']
        self.max_ammo = self.class_data['mag_size']
        self.fire_cooldown = 0
        self.reload_timer = 0
        self.rockets = 3 if self.class_data.get('has_rocket') else 0

        # AI
        self.ai_target = None
        self.ai_move_target = None
        self.ai_timer = 0
        self.ai_state = 'roam'

        # Stats
        self.kills = 0
        self.deaths = 0
        self.score = 0

    def respawn(self, x, y):
        self.x = x
        self.y = y
        self.health = self.max_health
        self.alive = True
        self.ammo = self.max_ammo
        self.reload_timer = 0
        self.fire_cooldown = 0
        self.in_vehicle = None
        self.angle = random.uniform(0, 2 * math.pi)

    def take_damage(self, damage):
        if not self.alive:
            return False
        self.health -= damage
        if self.health <= 0:
            self.health = 0
            self.alive = False
            self.deaths += 1
            self.respawn_timer = 180  # 3 seconds
            if self.in_vehicle:
                self.in_vehicle.driver = None
                self.in_vehicle = None
            return True
        return False

    def update(self, game):
        if not self.alive:
            self.respawn_timer -= 1
            if self.respawn_timer <= 0 and not self.is_player:
                spawn = game.get_spawn_point(self.team)
                self.respawn(spawn[0], spawn[1])
            return

        if self.in_vehicle:
            self.x = self.in_vehicle.x
            self.y = self.in_vehicle.y
            return

        if self.fire_cooldown > 0:
            self.fire_cooldown -= 1
        if self.reload_timer > 0:
            self.reload_timer -= 1
            if self.reload_timer <= 0:
                self.ammo = self.max_ammo

        if not self.is_player:
            self._ai_update(game)

    def _ai_update(self, game):
        self.ai_timer -= 1

        # Find nearest enemy
        nearest_enemy = None
        nearest_dist = float('inf')
        for soldier in game.soldiers:
            if soldier.team != self.team and soldier.alive:
                dist = math.hypot(self.x - soldier.x, self.y - soldier.y)
                if dist < nearest_dist:
                    nearest_dist = dist
                    nearest_enemy = soldier

        # State machine
        if nearest_enemy and nearest_dist < self.class_data['range'] * 0.8:
            self.ai_state = 'fight'
            self.ai_target = nearest_enemy
        elif self.ai_timer <= 0:
            self.ai_state = 'capture'
            self.ai_timer = random.randint(60, 180)
            # Move towards uncaptured flag
            best_flag = None
            best_dist = float('inf')
            for flag in game.flags:
                if flag.team != self.team:
                    dist = math.hypot(self.x - flag.x, self.y - flag.y)
                    if dist < best_dist:
                        best_dist = dist
                        best_flag = flag
            if best_flag:
                self.ai_move_target = (best_flag.x + random.randint(-80, 80),
                                      best_flag.y + random.randint(-80, 80))
            else:
                self.ai_move_target = (random.randint(200, MAP_WIDTH - 200),
                                      random.randint(200, MAP_HEIGHT - 200))

        # Execute state
        if self.ai_state == 'fight' and self.ai_target and self.ai_target.alive:
            self.angle = math.atan2(self.ai_target.y - self.y,
                                   self.ai_target.x - self.x)
            if nearest_dist > 150:
                self.x += math.cos(self.angle) * self.speed * 0.7
                self.y += math.sin(self.angle) * self.speed * 0.7
            elif nearest_dist < 80:
                self.x -= math.cos(self.angle) * self.speed * 0.5
                self.y -= math.sin(self.angle) * self.speed * 0.5

            # Shoot
            if self.fire_cooldown <= 0 and self.ammo > 0 and self.reload_timer <= 0:
                spread = self.class_data['spread']
                fire_angle = self.angle + random.uniform(-spread, spread) * 0.02
                bullet = Bullet(self.x, self.y, fire_angle,
                              self.class_data['bullet_speed'],
                              self.class_data['damage'],
                              self.team, self.class_data['range'])
                game.bullets.append(bullet)
                self.fire_cooldown = self.class_data['fire_rate']
                self.ammo -= 1
                if self.ammo <= 0:
                    self.reload_timer = self.class_data['reload_time']
        elif self.ai_move_target:
            dx = self.ai_move_target[0] - self.x
            dy = self.ai_move_target[1] - self.y
            dist = math.hypot(dx, dy)
            if dist > 20:
                self.angle = math.atan2(dy, dx)
                self.x += math.cos(self.angle) * self.speed
                self.y += math.sin(self.angle) * self.speed
            else:
                self.ai_move_target = None

        # Keep in bounds
        self.x = max(10, min(MAP_WIDTH - 10, self.x))
        self.y = max(10, min(MAP_HEIGHT - 10, self.y))

    def draw(self, surface, camera_x, camera_y):
        if not self.alive or self.in_vehicle:
            return
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if not (-20 <= sx < SCREEN_WIDTH + 20 and -20 <= sy < SCREEN_HEIGHT + 20):
            return

        # Body
        color = TEAM_COLORS[self.team]
        pygame.draw.circle(surface, color, (int(sx), int(sy)), 10)

        # Class indicator ring
        class_color = self.class_data['color']
        pygame.draw.circle(surface, class_color, (int(sx), int(sy)), 10, 2)

        # Weapon direction
        wx = sx + math.cos(self.angle) * 16
        wy = sy + math.sin(self.angle) * 16
        pygame.draw.line(surface, WHITE, (int(sx), int(sy)), (int(wx), int(wy)), 2)

        # Health bar (if damaged)
        if self.health < self.max_health:
            bar_w = 20
            bar_h = 3
            hp_ratio = self.health / self.max_health
            pygame.draw.rect(surface, DARK_GRAY, (sx - bar_w//2, sy - 18, bar_w, bar_h))
            hp_color = GREEN if hp_ratio > 0.5 else (YELLOW if hp_ratio > 0.25 else RED)
            pygame.draw.rect(surface, hp_color,
                           (sx - bar_w//2, sy - 18, int(bar_w * hp_ratio), bar_h))

        # Player indicator
        if self.is_player:
            pygame.draw.circle(surface, WHITE, (int(sx), int(sy)), 13, 1)


# ============================================================================
# Capture Flag
# ============================================================================

class CaptureFlag:
    def __init__(self, x, y, name):
        self.x = x
        self.y = y
        self.name = name
        self.team = None  # None = neutral
        self.capture_progress = 0  # -100 to 100 (neg=red, pos=blue)
        self.radius = 120
        self.contested = False

    def update(self, soldiers):
        blue_count = 0
        red_count = 0

        for soldier in soldiers:
            if not soldier.alive or soldier.in_vehicle:
                continue
            dist = math.hypot(self.x - soldier.x, self.y - soldier.y)
            if dist < self.radius:
                if soldier.team == TEAM_BLUE:
                    blue_count += 1
                else:
                    red_count += 1

        self.contested = blue_count > 0 and red_count > 0

        if not self.contested:
            if blue_count > 0:
                self.capture_progress += 0.3 * blue_count
            elif red_count > 0:
                self.capture_progress -= 0.3 * red_count
            else:
                # Slowly decay to team's side
                if self.team == TEAM_BLUE and self.capture_progress < 100:
                    self.capture_progress += 0.1
                elif self.team == TEAM_RED and self.capture_progress > -100:
                    self.capture_progress -= 0.1

        self.capture_progress = max(-100, min(100, self.capture_progress))

        # Determine ownership
        old_team = self.team
        if self.capture_progress >= 100:
            self.team = TEAM_BLUE
        elif self.capture_progress <= -100:
            self.team = TEAM_RED
        else:
            if self.capture_progress > 0 and self.team == TEAM_RED:
                self.team = None
            elif self.capture_progress < 0 and self.team == TEAM_BLUE:
                self.team = None

        return old_team != self.team and self.team is not None

    def draw(self, surface, camera_x, camera_y):
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if not (-self.radius <= sx < SCREEN_WIDTH + self.radius and
                -self.radius <= sy < SCREEN_HEIGHT + self.radius):
            return

        # Capture zone circle
        zone_color = TEAM_COLORS.get(self.team, GRAY)
        pygame.draw.circle(surface, (*zone_color, 30), (int(sx), int(sy)), self.radius, 2)

        # Flag pole
        pygame.draw.line(surface, WHITE, (int(sx), int(sy)), (int(sx), int(sy) - 30), 2)

        # Flag
        flag_color = TEAM_COLORS.get(self.team, LIGHT_GRAY)
        flag_points = [(sx, sy - 30), (sx + 20, sy - 25), (sx, sy - 20)]
        pygame.draw.polygon(surface, flag_color, flag_points)

        # Name
        font = pygame.font.SysFont('Segoe UI', 14, bold=True)
        text = font.render(self.name, True, WHITE)
        surface.blit(text, (sx - text.get_width() // 2, sy + 15))

        # Capture bar
        if -99 < self.capture_progress < 99:
            bar_w = 50
            bar_h = 6
            pygame.draw.rect(surface, DARK_GRAY, (sx - bar_w//2, sy + 32, bar_w, bar_h))
            progress = (self.capture_progress + 100) / 200
            bar_color = TEAM_COLORS.get(TEAM_BLUE if self.capture_progress > 0 else TEAM_RED, GRAY)
            pygame.draw.rect(surface, bar_color,
                           (sx - bar_w//2, sy + 32, int(bar_w * progress), bar_h))
            if self.contested:
                font_small = pygame.font.SysFont('Segoe UI', 10)
                ct = font_small.render("UMKAEMPFT", True, YELLOW)
                surface.blit(ct, (sx - ct.get_width() // 2, sy + 40))


# ============================================================================
# Map Objects
# ============================================================================

class Building:
    def __init__(self, x, y, w, h):
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.rect = pygame.Rect(x, y, w, h)

    def draw(self, surface, camera_x, camera_y):
        sx = self.x - camera_x + SCREEN_WIDTH // 2
        sy = self.y - camera_y + SCREEN_HEIGHT // 2
        if not (-self.w <= sx < SCREEN_WIDTH + self.w and
                -self.h <= sy < SCREEN_HEIGHT + self.h):
            return
        pygame.draw.rect(surface, (70, 70, 80), (sx, sy, self.w, self.h))
        pygame.draw.rect(surface, (90, 90, 100), (sx, sy, self.w, self.h), 2)
        # Windows
        for wx in range(int(sx) + 8, int(sx + self.w) - 8, 16):
            for wy in range(int(sy) + 8, int(sy + self.h) - 8, 16):
                pygame.draw.rect(surface, (40, 50, 60), (wx, wy, 8, 8))

    def collides(self, x, y, radius=10):
        closest_x = max(self.x, min(x, self.x + self.w))
        closest_y = max(self.y, min(y, self.y + self.h))
        dist = math.hypot(x - closest_x, y - closest_y)
        return dist < radius


# ============================================================================
# Game
# ============================================================================

class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption("Battlefield: Python Edition")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont('Segoe UI', 14)
        self.font_large = pygame.font.SysFont('Segoe UI', 24, bold=True)
        self.font_small = pygame.font.SysFont('Segoe UI', 11)
        self.font_title = pygame.font.SysFont('Segoe UI', 48, bold=True)

        # Sounds
        self.snd_shoot = SoundGen.generate_shoot()
        self.snd_explosion = SoundGen.generate_explosion()
        self.snd_hit = SoundGen.generate_hit()
        self.snd_capture = SoundGen.generate_capture()

        # Game state
        self.state = 'menu'  # menu, playing, gameover
        self.selected_class = CLASS_ASSAULT
        self.tickets = {TEAM_BLUE: 300, TEAM_RED: 300}
        self.kill_feed = deque(maxlen=6)
        self.particles = []
        self.bullets = []
        self.rockets_list = []

        # Initialize map
        self._generate_map()

    def _generate_map(self):
        """Generate the battlefield"""
        self.buildings = []
        self.vehicles = []
        self.soldiers = []
        self.flags = []

        # Capture flags (Conquest mode)
        flag_positions = [
            (MAP_WIDTH // 2, MAP_HEIGHT // 2, "Alpha"),
            (MAP_WIDTH // 4, MAP_HEIGHT // 4, "Bravo"),
            (3 * MAP_WIDTH // 4, MAP_HEIGHT // 4, "Charlie"),
            (MAP_WIDTH // 4, 3 * MAP_HEIGHT // 4, "Delta"),
            (3 * MAP_WIDTH // 4, 3 * MAP_HEIGHT // 4, "Echo"),
        ]
        for x, y, name in flag_positions:
            self.flags.append(CaptureFlag(x, y, name))

        # Buildings
        building_data = [
            # Center buildings
            (MAP_WIDTH//2 - 100, MAP_HEIGHT//2 - 150, 80, 60),
            (MAP_WIDTH//2 + 40, MAP_HEIGHT//2 - 150, 60, 80),
            (MAP_WIDTH//2 - 80, MAP_HEIGHT//2 + 80, 100, 50),
            # North buildings
            (MAP_WIDTH//4 - 60, MAP_HEIGHT//4 - 80, 120, 60),
            (MAP_WIDTH//4 + 80, MAP_HEIGHT//4 - 40, 60, 80),
            # East buildings
            (3*MAP_WIDTH//4 - 40, MAP_HEIGHT//4 - 60, 80, 100),
            (3*MAP_WIDTH//4 + 60, MAP_HEIGHT//4 + 20, 60, 60),
            # South buildings
            (MAP_WIDTH//4 - 80, 3*MAP_HEIGHT//4 - 40, 100, 70),
            (MAP_WIDTH//4 + 40, 3*MAP_HEIGHT//4 + 30, 70, 50),
            # West buildings
            (3*MAP_WIDTH//4 - 60, 3*MAP_HEIGHT//4 - 50, 80, 80),
            (3*MAP_WIDTH//4 + 40, 3*MAP_HEIGHT//4 - 30, 50, 60),
            # Extra cover
            (MAP_WIDTH//2 - 200, MAP_HEIGHT//2, 40, 40),
            (MAP_WIDTH//2 + 180, MAP_HEIGHT//2, 40, 40),
            (MAP_WIDTH//2, MAP_HEIGHT//2 - 250, 50, 40),
            (MAP_WIDTH//2, MAP_HEIGHT//2 + 230, 40, 50),
        ]
        for x, y, w, h in building_data:
            self.buildings.append(Building(x, y, w, h))

        # Vehicles
        self.vehicles.append(Vehicle(300, 300, 'tank'))
        self.vehicles.append(Vehicle(MAP_WIDTH - 300, MAP_HEIGHT - 300, 'tank'))
        self.vehicles.append(Vehicle(MAP_WIDTH // 2 - 200, MAP_HEIGHT // 2 - 200, 'jeep'))
        self.vehicles.append(Vehicle(MAP_WIDTH // 2 + 200, MAP_HEIGHT // 2 + 200, 'jeep'))

    def start_game(self):
        """Start a new game"""
        self.state = 'playing'
        self.tickets = {TEAM_BLUE: 300, TEAM_RED: 300}
        self.kill_feed.clear()
        self.particles.clear()
        self.bullets.clear()
        self.rockets_list.clear()
        self.soldiers.clear()

        # Reset flags
        for flag in self.flags:
            flag.team = None
            flag.capture_progress = 0

        # Reset vehicles
        for v in self.vehicles:
            v.health = v.max_health
            v.destroyed = False
            v.x = v.spawn_x
            v.y = v.spawn_y
            v.driver = None
            v.team = None

        # Create player
        self.player = Soldier(200, MAP_HEIGHT // 2, TEAM_BLUE,
                            self.selected_class, is_player=True)
        self.soldiers.append(self.player)

        # Create AI soldiers
        for i in range(15):
            cls = random.choice([CLASS_ASSAULT, CLASS_ENGINEER, CLASS_SUPPORT, CLASS_RECON])
            s = Soldier(random.randint(100, 500), random.randint(200, MAP_HEIGHT - 200),
                       TEAM_BLUE, cls)
            self.soldiers.append(s)

        for i in range(16):
            cls = random.choice([CLASS_ASSAULT, CLASS_ENGINEER, CLASS_SUPPORT, CLASS_RECON])
            s = Soldier(random.randint(MAP_WIDTH - 500, MAP_WIDTH - 100),
                       random.randint(200, MAP_HEIGHT - 200), TEAM_RED, cls)
            self.soldiers.append(s)

        # Camera
        self.camera_x = self.player.x
        self.camera_y = self.player.y

    def get_spawn_point(self, team):
        """Get a spawn point near a captured flag or base"""
        team_flags = [f for f in self.flags if f.team == team]
        if team_flags:
            flag = random.choice(team_flags)
            return (flag.x + random.randint(-80, 80),
                    flag.y + random.randint(-80, 80))
        # Base spawn
        if team == TEAM_BLUE:
            return (random.randint(100, 400), random.randint(100, MAP_HEIGHT - 100))
        return (random.randint(MAP_WIDTH - 400, MAP_WIDTH - 100),
                random.randint(100, MAP_HEIGHT - 100))

    def run(self):
        running = True
        while running:
            dt = self.clock.tick(FPS)

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        if self.state == 'playing':
                            self.state = 'menu'
                        else:
                            running = False

            if self.state == 'menu':
                self._update_menu()
                self._draw_menu()
            elif self.state == 'playing':
                self._update_game()
                self._draw_game()
            elif self.state == 'gameover':
                self._draw_gameover()
                keys = pygame.key.get_pressed()
                if keys[pygame.K_RETURN]:
                    self.state = 'menu'

            pygame.display.flip()

        pygame.quit()
        sys.exit()

    def _update_menu(self):
        keys = pygame.key.get_pressed()
        mouse = pygame.mouse.get_pressed()

        if keys[pygame.K_RETURN] or keys[pygame.K_SPACE]:
            self.start_game()

        # Class selection with number keys
        if keys[pygame.K_1]:
            self.selected_class = CLASS_ASSAULT
        elif keys[pygame.K_2]:
            self.selected_class = CLASS_ENGINEER
        elif keys[pygame.K_3]:
            self.selected_class = CLASS_SUPPORT
        elif keys[pygame.K_4]:
            self.selected_class = CLASS_RECON

    def _update_game(self):
        if not self.player.alive:
            self.player.respawn_timer -= 1
            if self.player.respawn_timer <= 0:
                spawn = self.get_spawn_point(TEAM_BLUE)
                self.player.respawn(spawn[0], spawn[1])

        self._handle_player_input()

        # Update soldiers
        for soldier in self.soldiers:
            soldier.update(self)

        # Update bullets
        for bullet in self.bullets[:]:
            if not bullet.update():
                self.bullets.remove(bullet)
                continue
            # Check hits
            for soldier in self.soldiers:
                if soldier.team == bullet.team or not soldier.alive:
                    continue
                if soldier.in_vehicle:
                    continue
                dist = math.hypot(bullet.x - soldier.x, bullet.y - soldier.y)
                if dist < 12:
                    killed = soldier.take_damage(bullet.damage)
                    self.bullets.remove(bullet)
                    if soldier == self.player:
                        self.snd_hit.play()
                    # Particles
                    for _ in range(5):
                        self.particles.append(Particle(
                            soldier.x, soldier.y,
                            random.uniform(-2, 2), random.uniform(-2, 2),
                            RED, random.randint(10, 25), 2))
                    if killed:
                        # Find killer
                        killer = None
                        for s in self.soldiers:
                            if s.team == bullet.team and s.alive:
                                killer = s
                                break
                        if killer:
                            killer.kills += 1
                            killer.score += 100
                        self.tickets[soldier.team] -= 1
                        self._add_kill_feed(killer, soldier)
                        self._spawn_death_particles(soldier.x, soldier.y)
                    break
            # Check vehicle hits
            for vehicle in self.vehicles:
                if vehicle.destroyed or vehicle.team == bullet.team:
                    continue
                dist = math.hypot(bullet.x - vehicle.x, bullet.y - vehicle.y)
                if dist < vehicle.size:
                    vehicle.take_damage(bullet.damage)
                    if bullet in self.bullets:
                        self.bullets.remove(bullet)
                    for _ in range(3):
                        self.particles.append(Particle(
                            vehicle.x, vehicle.y,
                            random.uniform(-3, 3), random.uniform(-3, 3),
                            ORANGE, random.randint(15, 30), 3))
                    break
            # Check building collisions
            for building in self.buildings:
                if building.collides(bullet.x, bullet.y, 3):
                    if bullet in self.bullets:
                        self.bullets.remove(bullet)
                    break

        # Update rockets
        for rocket in self.rockets_list[:]:
            if not rocket.update():
                self._explode(rocket.x, rocket.y, rocket.damage,
                            rocket.blast_radius, rocket.team)
                self.rockets_list.remove(rocket)
                continue
            # Check hits
            for vehicle in self.vehicles:
                if vehicle.destroyed or vehicle.team == rocket.team:
                    continue
                dist = math.hypot(rocket.x - vehicle.x, rocket.y - vehicle.y)
                if dist < vehicle.size + 10:
                    self._explode(rocket.x, rocket.y, rocket.damage,
                                rocket.blast_radius, rocket.team)
                    self.rockets_list.remove(rocket)
                    break
            for building in self.buildings:
                if building.collides(rocket.x, rocket.y, 5):
                    if rocket in self.rockets_list:
                        self._explode(rocket.x, rocket.y, rocket.damage,
                                    rocket.blast_radius, rocket.team)
                        self.rockets_list.remove(rocket)
                    break

        # Update vehicles
        for vehicle in self.vehicles:
            vehicle.update()

        # Update flags
        for flag in self.flags:
            captured = flag.update(self.soldiers)
            if captured:
                self.snd_capture.play()

        # Ticket bleed (team with fewer flags loses tickets faster)
        blue_flags = sum(1 for f in self.flags if f.team == TEAM_BLUE)
        red_flags = sum(1 for f in self.flags if f.team == TEAM_RED)
        if blue_flags > red_flags and random.random() < 0.02:
            self.tickets[TEAM_RED] -= 1
        elif red_flags > blue_flags and random.random() < 0.02:
            self.tickets[TEAM_BLUE] -= 1

        # Update particles
        self.particles = [p for p in self.particles if p.update()]

        # Camera follows player
        if self.player.alive:
            target_x = self.player.x
            target_y = self.player.y
            self.camera_x += (target_x - self.camera_x) * 0.1
            self.camera_y += (target_y - self.camera_y) * 0.1

        # Check game over
        if self.tickets[TEAM_BLUE] <= 0 or self.tickets[TEAM_RED] <= 0:
            self.state = 'gameover'
            self.winner = TEAM_BLUE if self.tickets[TEAM_BLUE] > 0 else TEAM_RED

    def _handle_player_input(self):
        if not self.player.alive:
            return

        keys = pygame.key.get_pressed()
        mx, my = pygame.mouse.get_pos()
        mouse_buttons = pygame.mouse.get_pressed()

        if self.player.in_vehicle:
            vehicle = self.player.in_vehicle
            # Vehicle controls
            if keys[pygame.K_w]:
                vehicle.speed = min(vehicle.speed + 0.1, vehicle.max_speed)
            elif keys[pygame.K_s]:
                vehicle.speed = max(vehicle.speed - 0.1, -vehicle.max_speed * 0.5)
            if keys[pygame.K_a]:
                vehicle.angle -= 0.04
            if keys[pygame.K_d]:
                vehicle.angle += 0.04
            # Exit vehicle
            if keys[pygame.K_f]:
                vehicle.exit_vehicle()
            # Vehicle shoot
            if mouse_buttons[0] and vehicle.fire_cooldown <= 0:
                if vehicle.vehicle_type == 'tank':
                    world_mx = mx + self.camera_x - SCREEN_WIDTH // 2
                    world_my = my + self.camera_y - SCREEN_HEIGHT // 2
                    angle = math.atan2(world_my - vehicle.y, world_mx - vehicle.x)
                    rocket = Rocket(vehicle.x, vehicle.y, angle, self.player.team)
                    rocket.damage = 120
                    self.rockets_list.append(rocket)
                    vehicle.fire_cooldown = 90
                    self.snd_explosion.play()
        else:
            # Movement
            dx, dy = 0, 0
            if keys[pygame.K_w]:
                dy -= 1
            if keys[pygame.K_s]:
                dy += 1
            if keys[pygame.K_a]:
                dx -= 1
            if keys[pygame.K_d]:
                dx += 1

            if dx != 0 or dy != 0:
                length = math.hypot(dx, dy)
                dx /= length
                dy /= length
                new_x = self.player.x + dx * self.player.speed
                new_y = self.player.y + dy * self.player.speed

                # Building collision
                can_move = True
                for building in self.buildings:
                    if building.collides(new_x, new_y, 10):
                        can_move = False
                        break
                if can_move:
                    self.player.x = max(10, min(MAP_WIDTH - 10, new_x))
                    self.player.y = max(10, min(MAP_HEIGHT - 10, new_y))

            # Aim
            world_mx = mx + self.camera_x - SCREEN_WIDTH // 2
            world_my = my + self.camera_y - SCREEN_HEIGHT // 2
            self.player.angle = math.atan2(world_my - self.player.y,
                                          world_mx - self.player.x)

            # Shoot
            if mouse_buttons[0]:
                if (self.player.fire_cooldown <= 0 and
                    self.player.ammo > 0 and
                    self.player.reload_timer <= 0):
                    spread = self.player.class_data['spread']
                    fire_angle = self.player.angle + random.uniform(-spread, spread) * 0.015
                    bullet = Bullet(self.player.x, self.player.y, fire_angle,
                                  self.player.class_data['bullet_speed'],
                                  self.player.class_data['damage'],
                                  self.player.team,
                                  self.player.class_data['range'])
                    self.bullets.append(bullet)
                    self.player.fire_cooldown = self.player.class_data['fire_rate']
                    self.player.ammo -= 1
                    self.snd_shoot.play()
                    if self.player.ammo <= 0:
                        self.player.reload_timer = self.player.class_data['reload_time']

            # Rocket (right click for engineer)
            if mouse_buttons[2] and self.player.rockets > 0 and self.player.fire_cooldown <= 0:
                rocket = Rocket(self.player.x, self.player.y,
                              self.player.angle, self.player.team)
                self.rockets_list.append(rocket)
                self.player.rockets -= 1
                self.player.fire_cooldown = 60
                self.snd_explosion.play()

            # Reload
            if keys[pygame.K_r] and self.player.reload_timer <= 0 and self.player.ammo < self.player.max_ammo:
                self.player.reload_timer = self.player.class_data['reload_time']

            # Enter vehicle
            if keys[pygame.K_f]:
                for vehicle in self.vehicles:
                    if vehicle.enter(self.player):
                        break

    def _explode(self, x, y, damage, radius, team):
        """Create explosion at position"""
        self.snd_explosion.play()
        # Damage nearby
        for soldier in self.soldiers:
            if not soldier.alive:
                continue
            dist = math.hypot(x - soldier.x, y - soldier.y)
            if dist < radius:
                dmg = int(damage * (1 - dist / radius))
                killed = soldier.take_damage(dmg)
                if killed:
                    self.tickets[soldier.team] -= 1
                    self._add_kill_feed(None, soldier)
                    self._spawn_death_particles(soldier.x, soldier.y)
        for vehicle in self.vehicles:
            if vehicle.destroyed:
                continue
            dist = math.hypot(x - vehicle.x, y - vehicle.y)
            if dist < radius:
                dmg = int(damage * (1 - dist / radius))
                destroyed = vehicle.take_damage(dmg)
                if destroyed:
                    self._spawn_death_particles(vehicle.x, vehicle.y)
        # Particles
        for _ in range(40):
            angle = random.uniform(0, 2 * math.pi)
            speed = random.uniform(2, 8)
            color = random.choice([RED, ORANGE, YELLOW, (200, 100, 0)])
            self.particles.append(Particle(
                x, y,
                math.cos(angle) * speed, math.sin(angle) * speed,
                color, random.randint(20, 50), random.randint(3, 6)))

    def _spawn_death_particles(self, x, y):
        for _ in range(20):
            angle = random.uniform(0, 2 * math.pi)
            speed = random.uniform(1, 5)
            self.particles.append(Particle(
                x, y,
                math.cos(angle) * speed, math.sin(angle) * speed,
                RED, random.randint(20, 40), random.randint(2, 4)))

    def _add_kill_feed(self, killer, victim):
        killer_name = "Du" if killer and killer.is_player else (
                     killer.class_data['name'] if killer else "Explosion")
        victim_name = "Du" if victim.is_player else victim.class_data['name']
        killer_team = killer.team if killer else None
        self.kill_feed.append({
            'killer': killer_name,
            'victim': victim_name,
            'killer_team': killer_team,
            'victim_team': victim.team,
            'time': pygame.time.get_ticks()
        })

    # ========================================================================
    # Drawing
    # ========================================================================

    def _draw_menu(self):
        self.screen.fill((20, 25, 35))

        # Title
        title = self.font_title.render("BATTLEFIELD", True, WHITE)
        subtitle = self.font_large.render("Python Edition", True, (150, 180, 220))
        self.screen.blit(title, (SCREEN_WIDTH//2 - title.get_width()//2, 100))
        self.screen.blit(subtitle, (SCREEN_WIDTH//2 - subtitle.get_width()//2, 160))

        # Class selection
        y = 250
        header = self.font_large.render("Klasse waehlen:", True, WHITE)
        self.screen.blit(header, (SCREEN_WIDTH//2 - header.get_width()//2, y))
        y += 50

        for cls_id, cls_data in CLASS_DATA.items():
            selected = cls_id == self.selected_class
            color = cls_data['color'] if selected else GRAY
            prefix = "> " if selected else "  "
            text = f"{prefix}[{cls_id+1}] {cls_data['name']} - {cls_data['weapon']} " \
                   f"(HP:{cls_data['health']} SPD:{cls_data['speed']} DMG:{cls_data['damage']})"
            rendered = self.font.render(text, True, color)
            self.screen.blit(rendered, (SCREEN_WIDTH//2 - 250, y))
            y += 35

        # Instructions
        y += 40
        instructions = [
            "WASD - Bewegen  |  Maus - Zielen  |  LMB - Schiessen",
            "R - Nachladen  |  F - Fahrzeug  |  RMB - Rakete (Ingenieur)",
            "ESC - Menu",
            "",
            "Druecke ENTER zum Starten"
        ]
        for line in instructions:
            text = self.font.render(line, True, LIGHT_GRAY)
            self.screen.blit(text, (SCREEN_WIDTH//2 - text.get_width()//2, y))
            y += 25

    def _draw_game(self):
        # Background
        self.screen.fill((40, 60, 40))

        # Draw ground texture (simple grid)
        for gx in range(-1, SCREEN_WIDTH // 64 + 2):
            for gy in range(-1, SCREEN_HEIGHT // 64 + 2):
                wx = (gx * 64 + int(self.camera_x) // 64 * 64) - int(self.camera_x) + SCREEN_WIDTH // 2
                wy = (gy * 64 + int(self.camera_y) // 64 * 64) - int(self.camera_y) + SCREEN_HEIGHT // 2
                world_x = gx * 64 + int(self.camera_x) // 64 * 64
                world_y = gy * 64 + int(self.camera_y) // 64 * 64
                # Vary ground color
                seed = (world_x * 7 + world_y * 13) % 100
                if seed < 20:
                    color = (50, 70, 45)
                elif seed < 40:
                    color = (45, 65, 40)
                else:
                    color = (42, 62, 38)
                pygame.draw.rect(self.screen, color, (wx, wy, 65, 65))

        # Draw buildings
        for building in self.buildings:
            building.draw(self.screen, self.camera_x, self.camera_y)

        # Draw flags
        for flag in self.flags:
            flag.draw(self.screen, self.camera_x, self.camera_y)

        # Draw vehicles
        for vehicle in self.vehicles:
            vehicle.draw(self.screen, self.camera_x, self.camera_y)

        # Draw soldiers
        for soldier in self.soldiers:
            soldier.draw(self.screen, self.camera_x, self.camera_y)

        # Draw bullets
        for bullet in self.bullets:
            bullet.draw(self.screen, self.camera_x, self.camera_y)

        # Draw rockets
        for rocket in self.rockets_list:
            rocket.draw(self.screen, self.camera_x, self.camera_y)

        # Draw particles
        for particle in self.particles:
            particle.draw(self.screen, self.camera_x, self.camera_y)

        # HUD
        self._draw_hud()

    def _draw_hud(self):
        # Tickets bar (top center)
        bar_w = 300
        bar_h = 30
        bx = SCREEN_WIDTH // 2 - bar_w // 2
        by = 10
        pygame.draw.rect(self.screen, (20, 20, 30), (bx, by, bar_w, bar_h))
        pygame.draw.rect(self.screen, TEAM_COLORS[TEAM_BLUE], (bx, by, bar_w//2, bar_h))
        pygame.draw.rect(self.screen, TEAM_COLORS[TEAM_RED], (bx + bar_w//2, by, bar_w//2, bar_h))
        pygame.draw.rect(self.screen, WHITE, (bx, by, bar_w, bar_h), 1)

        blue_text = self.font.render(str(self.tickets[TEAM_BLUE]), True, WHITE)
        red_text = self.font.render(str(self.tickets[TEAM_RED]), True, WHITE)
        self.screen.blit(blue_text, (bx + bar_w//4 - blue_text.get_width()//2, by + 6))
        self.screen.blit(red_text, (bx + 3*bar_w//4 - red_text.get_width()//2, by + 6))

        vs_text = self.font.render("VS", True, WHITE)
        self.screen.blit(vs_text, (SCREEN_WIDTH//2 - vs_text.get_width()//2, by + 6))

        # Flag status (below tickets)
        fy = by + bar_h + 5
        total_w = len(self.flags) * 30
        fx_start = SCREEN_WIDTH // 2 - total_w // 2
        for i, flag in enumerate(self.flags):
            fx = fx_start + i * 30
            color = TEAM_COLORS.get(flag.team, GRAY)
            pygame.draw.rect(self.screen, color, (fx, fy, 25, 18))
            name_text = self.font_small.render(flag.name[0], True, WHITE)
            self.screen.blit(name_text, (fx + 8, fy + 2))

        # Player HUD (bottom)
        if self.player.alive:
            # Health bar
            hx, hy = 20, SCREEN_HEIGHT - 80
            pygame.draw.rect(self.screen, (30, 30, 40), (hx, hy, 200, 20))
            hp_ratio = self.player.health / self.player.max_health
            hp_color = GREEN if hp_ratio > 0.5 else (YELLOW if hp_ratio > 0.25 else RED)
            pygame.draw.rect(self.screen, hp_color, (hx, hy, int(200 * hp_ratio), 20))
            hp_text = self.font.render(f"HP: {self.player.health}/{self.player.max_health}", True, WHITE)
            self.screen.blit(hp_text, (hx + 5, hy + 2))

            # Ammo
            ax, ay = 20, SCREEN_HEIGHT - 50
            if self.player.in_vehicle:
                ammo_text = self.font.render("Fahrzeug - LMB: Schiessen  F: Aussteigen", True, WHITE)
            elif self.player.reload_timer > 0:
                ammo_text = self.font.render("NACHLADEN...", True, YELLOW)
            else:
                ammo_text = self.font.render(
                    f"{self.player.class_data['weapon']}: {self.player.ammo}/{self.player.max_ammo}" +
                    (f"  |  Raketen: {self.player.rockets}" if self.player.rockets > 0 else ""),
                    True, WHITE)
            self.screen.blit(ammo_text, (ax, ay))

            # Class & score
            info_text = self.font_small.render(
                f"{self.player.class_data['name']}  |  Kills: {self.player.kills}  |  Score: {self.player.score}",
                True, LIGHT_GRAY)
            self.screen.blit(info_text, (20, SCREEN_HEIGHT - 25))
        else:
            # Death screen
            death_text = self.font_large.render("GEFALLEN", True, RED)
            respawn_text = self.font.render(
                f"Respawn in {max(0, self.player.respawn_timer // 60 + 1)}s", True, WHITE)
            self.screen.blit(death_text, (SCREEN_WIDTH//2 - death_text.get_width()//2, SCREEN_HEIGHT//2))
            self.screen.blit(respawn_text, (SCREEN_WIDTH//2 - respawn_text.get_width()//2, SCREEN_HEIGHT//2 + 40))

        # Kill feed (top right)
        now = pygame.time.get_ticks()
        kf_y = 50
        for entry in reversed(self.kill_feed):
            if now - entry['time'] > 5000:
                continue
            killer_color = TEAM_COLORS.get(entry['killer_team'], GRAY)
            victim_color = TEAM_COLORS.get(entry['victim_team'], GRAY)
            k_text = self.font_small.render(entry['killer'], True, killer_color)
            v_text = self.font_small.render(entry['victim'], True, victim_color)
            arrow = self.font_small.render(" >> ", True, WHITE)
            total_w = k_text.get_width() + arrow.get_width() + v_text.get_width()
            kx = SCREEN_WIDTH - total_w - 20
            self.screen.blit(k_text, (kx, kf_y))
            self.screen.blit(arrow, (kx + k_text.get_width(), kf_y))
            self.screen.blit(v_text, (kx + k_text.get_width() + arrow.get_width(), kf_y))
            kf_y += 18

        # Minimap (bottom right)
        self._draw_minimap()

        # Crosshair
        if self.player.alive and not self.player.in_vehicle:
            mx, my = pygame.mouse.get_pos()
            pygame.draw.line(self.screen, WHITE, (mx - 10, my), (mx + 10, my), 1)
            pygame.draw.line(self.screen, WHITE, (mx, my - 10), (mx, my + 10), 1)
            pygame.draw.circle(self.screen, WHITE, (mx, my), 15, 1)

    def _draw_minimap(self):
        mm_size = 160
        mm_x = SCREEN_WIDTH - mm_size - 15
        mm_y = SCREEN_HEIGHT - mm_size - 15
        scale = mm_size / MAP_WIDTH

        # Background
        pygame.draw.rect(self.screen, (20, 30, 20), (mm_x, mm_y, mm_size, mm_size))
        pygame.draw.rect(self.screen, (80, 80, 80), (mm_x, mm_y, mm_size, mm_size), 1)

        # Buildings
        for building in self.buildings:
            bx = mm_x + int(building.x * scale)
            by = mm_y + int(building.y * scale)
            bw = max(2, int(building.w * scale))
            bh = max(2, int(building.h * scale))
            pygame.draw.rect(self.screen, (60, 60, 70), (bx, by, bw, bh))

        # Flags
        for flag in self.flags:
            fx = mm_x + int(flag.x * scale)
            fy = mm_y + int(flag.y * scale)
            color = TEAM_COLORS.get(flag.team, GRAY)
            pygame.draw.circle(self.screen, color, (fx, fy), 4)

        # Soldiers
        for soldier in self.soldiers:
            if not soldier.alive:
                continue
            sx = mm_x + int(soldier.x * scale)
            sy = mm_y + int(soldier.y * scale)
            color = TEAM_COLORS[soldier.team]
            size = 3 if soldier.is_player else 2
            pygame.draw.circle(self.screen, color, (sx, sy), size)

        # Vehicles
        for vehicle in self.vehicles:
            if vehicle.destroyed:
                continue
            vx = mm_x + int(vehicle.x * scale)
            vy = mm_y + int(vehicle.y * scale)
            color = TEAM_COLORS.get(vehicle.team, GRAY)
            pygame.draw.rect(self.screen, color, (vx - 3, vy - 3, 6, 6))

        # Camera view area
        view_x = mm_x + int((self.camera_x - SCREEN_WIDTH//2) * scale)
        view_y = mm_y + int((self.camera_y - SCREEN_HEIGHT//2) * scale)
        view_w = int(SCREEN_WIDTH * scale)
        view_h = int(SCREEN_HEIGHT * scale)
        pygame.draw.rect(self.screen, WHITE, (view_x, view_y, view_w, view_h), 1)

    def _draw_gameover(self):
        self.screen.fill((20, 20, 30))
        winner_name = TEAM_NAMES[self.winner]
        winner_color = TEAM_COLORS[self.winner]

        title = self.font_title.render("SPIEL VORBEI", True, WHITE)
        winner_text = self.font_large.render(f"Team {winner_name} gewinnt!", True, winner_color)
        score_text = self.font.render(
            f"Deine Stats: {self.player.kills} Kills  |  {self.player.deaths} Tode  |  Score: {self.player.score}",
            True, LIGHT_GRAY)
        restart = self.font.render("Druecke ENTER fuer Hauptmenue", True, WHITE)

        self.screen.blit(title, (SCREEN_WIDTH//2 - title.get_width()//2, 200))
        self.screen.blit(winner_text, (SCREEN_WIDTH//2 - winner_text.get_width()//2, 280))
        self.screen.blit(score_text, (SCREEN_WIDTH//2 - score_text.get_width()//2, 350))
        self.screen.blit(restart, (SCREEN_WIDTH//2 - restart.get_width()//2, 430))


# ============================================================================
# Entry Point
# ============================================================================

def main():
    game = Game()
    game.run()


if __name__ == '__main__':
    main()
