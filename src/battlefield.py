"""
Battlefield 3D - First Person Shooter
Raycasting-based FPS engine (Wolfenstein 3D / DOOM style)
"""

import pygame
import math
import random
import sys
from collections import deque

pygame.init()
pygame.mixer.init(frequency=22050, size=-16, channels=2, buffer=512)
pygame.mouse.set_visible(False)
pygame.event.set_grab(True)

# ============================================================================
# Constants
# ============================================================================

WIDTH = 1280
HEIGHT = 720
FPS = 60
HALF_W = WIDTH // 2
HALF_H = HEIGHT // 2

# Raycasting
FOV = math.pi / 3  # 60 degrees
HALF_FOV = FOV / 2
NUM_RAYS = WIDTH // 2  # One ray per 2 pixels for performance
DELTA_ANGLE = FOV / NUM_RAYS
MAX_DEPTH = 20
TILE_SIZE = 64
SCALE = WIDTH // NUM_RAYS

# Player
PLAYER_SPEED = 3.0
PLAYER_ROT_SPEED = 0.003
PLAYER_SIZE = 0.3

# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (200, 50, 50)
GREEN = (50, 200, 50)
BLUE = (50, 100, 200)
YELLOW = (255, 220, 50)
GRAY = (128, 128, 128)
DARK_GRAY = (40, 40, 40)


# ============================================================================
# Maps
# ============================================================================

MAPS = [
    # Level 1 - Training
    {
        'name': 'Trainingsgelaende',
        'grid': [
            "1111111111111111",
            "1..............1",
            "1..111..111....1",
            "1..1.....1.....1",
            "1..1.....1..1111",
            "1........1.....1",
            "1..111...1.....1",
            "1..............1",
            "1....1111......1",
            "1..............1",
            "1....11...111..1",
            "1.....1........1",
            "1111..1...1....1",
            "1.........1....1",
            "1..............1",
            "1111111111111111",
        ],
        'player_pos': (2.5, 2.5),
        'player_angle': 0,
        'enemies': [(5, 5), (10, 3), (7, 8), (12, 10), (4, 12), (13, 5)],
        'pickups': [
            (3, 7, 'health'), (8, 2, 'ammo'), (11, 8, 'health'),
            (6, 12, 'ammo'), (13, 13, 'armor'),
        ],
    },
    # Level 2 - Warehouse
    {
        'name': 'Lagerhalle',
        'grid': [
            "2222222222222222222",
            "2.................2",
            "2.222..222..222...2",
            "2.2......2....2...2",
            "2.2......2....2...2",
            "2........2........2",
            "2.222..222..222...2",
            "2.................2",
            "2...22222222......2",
            "2...2......2......2",
            "2...2......2..222.2",
            "2...2......2......2",
            "2..............2..2",
            "2.222..222.....2..2",
            "2..............2..2",
            "2.................2",
            "2.222..222..222...2",
            "2.................2",
            "2222222222222222222",
        ],
        'player_pos': (2.5, 2.5),
        'player_angle': 0.5,
        'enemies': [(5, 4), (8, 8), (14, 3), (4, 10), (10, 14),
                   (15, 9), (7, 15), (12, 6), (16, 16)],
        'pickups': [
            (3, 5, 'health'), (10, 2, 'ammo'), (15, 15, 'health'),
            (5, 14, 'ammo'), (14, 7, 'armor'), (8, 11, 'health'),
        ],
    },
    # Level 3 - Fortress
    {
        'name': 'Festung',
        'grid': [
            "33333333333333333333",
            "3..................3",
            "3.333..33..33..333.3",
            "3.3..........3...3.3",
            "3.3..333..3..3...3.3",
            "3....3..........33.3",
            "3.3..3..33..3......3",
            "3.3.....3...3..33..3",
            "3.333...3...3......3",
            "3...................3",
            "3..33..3333..33....3",
            "3......3..........33",
            "3..33..3..33..33...3",
            "3......3..3........3",
            "3..33.....3..33..3.3",
            "3.........3......3.3",
            "3..333..333..333.3.3",
            "3................3.3",
            "3.333..333..333....3",
            "33333333333333333333",
        ],
        'player_pos': (1.5, 1.5),
        'player_angle': 0.8,
        'enemies': [(5, 3), (10, 5), (15, 3), (3, 8), (8, 10),
                   (14, 8), (5, 14), (10, 16), (16, 14), (12, 12),
                   (7, 6), (17, 17)],
        'pickups': [
            (2, 9, 'health'), (9, 1, 'ammo'), (17, 9, 'health'),
            (5, 17, 'ammo'), (14, 14, 'armor'), (10, 9, 'health'),
            (16, 5, 'ammo'),
        ],
    },
]

# Wall colors per wall type
WALL_COLORS = {
    '1': (100, 100, 120),  # Gray stone
    '2': (120, 90, 60),    # Brown wood
    '3': (80, 80, 100),    # Dark blue stone
}


# ============================================================================
# Weapons
# ============================================================================

WEAPONS = {
    'pistol': {
        'name': 'Pistole',
        'damage': 25,
        'fire_rate': 20,
        'range': 10,
        'spread': 0.02,
        'ammo': -1,  # Infinite
        'mag_size': 12,
        'reload_time': 45,
        'auto': False,
        'color': YELLOW,
    },
    'rifle': {
        'name': 'Sturmgewehr',
        'damage': 20,
        'fire_rate': 6,
        'range': 15,
        'spread': 0.04,
        'ammo': 120,
        'mag_size': 30,
        'reload_time': 75,
        'auto': True,
        'color': (200, 200, 100),
    },
    'shotgun': {
        'name': 'Schrotflinte',
        'damage': 15,
        'fire_rate': 35,
        'range': 6,
        'spread': 0.12,
        'ammo': 40,
        'mag_size': 8,
        'reload_time': 90,
        'auto': False,
        'pellets': 6,
        'color': GRAY,
    },
    'sniper': {
        'name': 'Scharfschuetze',
        'damage': 90,
        'fire_rate': 50,
        'range': 20,
        'spread': 0.005,
        'ammo': 20,
        'mag_size': 5,
        'reload_time': 90,
        'auto': False,
        'color': (150, 200, 255),
    },
}


# ============================================================================
# Sound Generator
# ============================================================================

class SoundGen:
    @staticmethod
    def shoot():
        buf = bytearray(3000)
        for i in range(1500):
            t = i / 22050
            val = int(random.randint(-12000, 12000) * max(0, 1 - t * 12))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        snd = pygame.mixer.Sound(buffer=bytes(buf))
        snd.set_volume(0.12)
        return snd

    @staticmethod
    def shotgun_sound():
        buf = bytearray(5000)
        for i in range(2500):
            t = i / 22050
            val = int(random.randint(-20000, 20000) * max(0, 1 - t * 8))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        snd = pygame.mixer.Sound(buffer=bytes(buf))
        snd.set_volume(0.15)
        return snd

    @staticmethod
    def hit():
        buf = bytearray(1500)
        for i in range(750):
            t = i / 22050
            val = int(math.sin(t * 3000) * 8000 * max(0, 1 - t * 25))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        snd = pygame.mixer.Sound(buffer=bytes(buf))
        snd.set_volume(0.15)
        return snd

    @staticmethod
    def enemy_die():
        buf = bytearray(8000)
        for i in range(4000):
            t = i / 22050
            val = int(math.sin(t * (800 - t * 2000)) * 10000 * max(0, 1 - t * 5))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        snd = pygame.mixer.Sound(buffer=bytes(buf))
        snd.set_volume(0.15)
        return snd

    @staticmethod
    def pickup():
        buf = bytearray(6000)
        for i in range(3000):
            t = i / 22050
            val = int(math.sin(t * (600 + t * 3000) * 2 * math.pi) * 6000 * max(0, 1 - t * 7))
            val = max(-32767, min(32767, val))
            buf[i*2] = val & 0xFF
            buf[i*2+1] = (val >> 8) & 0xFF
        snd = pygame.mixer.Sound(buffer=bytes(buf))
        snd.set_volume(0.12)
        return snd


# ============================================================================
# Enemy
# ============================================================================

class Enemy:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.health = 100
        self.max_health = 100
        self.alive = True
        self.speed = 1.5 + random.random() * 0.5
        self.damage = 8
        self.attack_range = 8
        self.attack_cooldown = 0
        self.attack_rate = 40
        self.state = 'idle'  # idle, chase, attack
        self.alert_range = 6
        self.angle = random.uniform(0, 2 * math.pi)
        self.pain_timer = 0
        self.size = 0.4
        self.anim_frame = 0
        self.move_timer = random.randint(0, 60)

    def update(self, player, game_map, dt=1):
        if not self.alive:
            return

        if self.pain_timer > 0:
            self.pain_timer -= 1
            return

        if self.attack_cooldown > 0:
            self.attack_cooldown -= 1

        self.anim_frame = (self.anim_frame + 0.05) % 2

        dx = player.x - self.x
        dy = player.y - self.y
        dist = math.hypot(dx, dy)
        angle_to_player = math.atan2(dy, dx)

        # State transitions
        if dist < self.alert_range:
            # Check line of sight
            if self._can_see_player(player, game_map):
                if dist < 2.0:
                    self.state = 'attack'
                else:
                    self.state = 'chase'
            else:
                self.state = 'idle'
        else:
            self.state = 'idle'

        # State behavior
        if self.state == 'chase':
            self.angle = angle_to_player
            move_x = math.cos(self.angle) * self.speed * 0.02
            move_y = math.sin(self.angle) * self.speed * 0.02
            new_x = self.x + move_x
            new_y = self.y + move_y
            if not self._collides(new_x, new_y, game_map):
                self.x = new_x
                self.y = new_y

        elif self.state == 'attack':
            self.angle = angle_to_player
            if self.attack_cooldown <= 0:
                self.attack_cooldown = self.attack_rate
                return True  # Signal: attack player

        elif self.state == 'idle':
            self.move_timer -= 1
            if self.move_timer <= 0:
                self.angle = random.uniform(0, 2 * math.pi)
                self.move_timer = random.randint(60, 180)
            move_x = math.cos(self.angle) * self.speed * 0.008
            move_y = math.sin(self.angle) * self.speed * 0.008
            new_x = self.x + move_x
            new_y = self.y + move_y
            if not self._collides(new_x, new_y, game_map):
                self.x = new_x
                self.y = new_y

        return False

    def take_damage(self, damage):
        self.health -= damage
        self.pain_timer = 10
        if self.health <= 0:
            self.alive = False
            return True
        return False

    def _can_see_player(self, player, game_map):
        dx = player.x - self.x
        dy = player.y - self.y
        dist = math.hypot(dx, dy)
        if dist < 0.1:
            return True
        steps = int(dist * 4)
        for i in range(steps):
            t = i / max(steps, 1)
            cx = self.x + dx * t
            cy = self.y + dy * t
            if game_map[int(cy)][int(cx)] != '.':
                return False
        return True

    def _collides(self, x, y, game_map):
        margin = self.size
        checks = [(x + margin, y), (x - margin, y),
                  (x, y + margin), (x, y - margin)]
        for cx, cy in checks:
            ix, iy = int(cx), int(cy)
            if iy < 0 or iy >= len(game_map) or ix < 0 or ix >= len(game_map[0]):
                return True
            if game_map[iy][ix] != '.':
                return True
        return False


# ============================================================================
# Pickup
# ============================================================================

class Pickup:
    def __init__(self, x, y, pickup_type):
        self.x = x + 0.5
        self.y = y + 0.5
        self.type = pickup_type
        self.alive = True
        self.bob = random.uniform(0, math.pi * 2)

    def update(self):
        self.bob += 0.05


# ============================================================================
# Player
# ============================================================================

class Player:
    def __init__(self, x, y, angle):
        self.x = x
        self.y = y
        self.angle = angle
        self.health = 100
        self.max_health = 100
        self.armor = 0
        self.speed = PLAYER_SPEED
        self.weapons = ['pistol', 'rifle', 'shotgun', 'sniper']
        self.current_weapon = 1  # rifle
        self.ammo = {'rifle': 120, 'shotgun': 40, 'sniper': 20}
        self.mag = {'pistol': 12, 'rifle': 30, 'shotgun': 8, 'sniper': 5}
        self.fire_cooldown = 0
        self.reload_timer = 0
        self.kills = 0
        self.damage_flash = 0
        self.weapon_bob = 0
        self.is_moving = False
        self.shooting_flash = 0

    def get_weapon(self):
        return WEAPONS[self.weapons[self.current_weapon]]

    def get_weapon_name(self):
        return self.weapons[self.current_weapon]


# ============================================================================
# Raycasting Engine
# ============================================================================

class Raycaster:
    def __init__(self):
        # Pre-calculate
        self.z_buffer = [0] * NUM_RAYS

    def cast_rays(self, player, game_map):
        """Cast rays and return wall slices"""
        walls = []
        ray_angle = player.angle - HALF_FOV

        for ray in range(NUM_RAYS):
            sin_a = math.sin(ray_angle)
            cos_a = math.cos(ray_angle)

            # DDA raycasting
            depth, wall_type, hit_vertical = self._dda(
                player.x, player.y, sin_a, cos_a, game_map)

            # Fix fisheye
            depth *= math.cos(player.angle - ray_angle)
            self.z_buffer[ray] = depth

            # Wall height
            if depth > 0.001:
                wall_height = min(int(TILE_SIZE * HEIGHT / depth), HEIGHT * 3)
            else:
                wall_height = HEIGHT * 3

            # Shading based on depth and side
            shade = max(0.2, 1.0 - depth / MAX_DEPTH)
            if hit_vertical:
                shade *= 0.7  # Darker for vertical walls

            base_color = WALL_COLORS.get(wall_type, (100, 100, 100))
            color = tuple(int(c * shade) for c in base_color)

            walls.append({
                'ray': ray,
                'depth': depth,
                'height': wall_height,
                'color': color,
                'wall_type': wall_type,
            })

            ray_angle += DELTA_ANGLE

        return walls

    def _dda(self, px, py, sin_a, cos_a, game_map):
        """Digital Differential Analysis for raycasting"""
        # Avoid division by zero
        if abs(cos_a) < 1e-6:
            cos_a = 1e-6
        if abs(sin_a) < 1e-6:
            sin_a = 1e-6

        # Horizontal intersections
        h_depth = MAX_DEPTH
        h_wall = '1'
        if sin_a > 0:
            y_step = 1
            y = int(py) + 1
        else:
            y_step = -1
            y = int(py) - 1e-6

        depth_h = (y - py) / sin_a
        x = px + depth_h * cos_a

        delta_depth = y_step / sin_a
        dx = delta_depth * cos_a

        for _ in range(MAX_DEPTH):
            ix, iy = int(x), int(y)
            if 0 <= iy < len(game_map) and 0 <= ix < len(game_map[0]):
                if game_map[iy][ix] != '.':
                    h_depth = math.hypot(x - px, y - py)
                    h_wall = game_map[iy][ix]
                    break
            x += dx
            y += y_step
            if abs(y - py) > MAX_DEPTH:
                break

        # Vertical intersections
        v_depth = MAX_DEPTH
        v_wall = '1'
        if cos_a > 0:
            x_step = 1
            x = int(px) + 1
        else:
            x_step = -1
            x = int(px) - 1e-6

        depth_v = (x - px) / cos_a
        y = py + depth_v * sin_a

        delta_depth = x_step / cos_a
        dy = delta_depth * sin_a

        for _ in range(MAX_DEPTH):
            ix, iy = int(x), int(y)
            if 0 <= iy < len(game_map) and 0 <= ix < len(game_map[0]):
                if game_map[iy][ix] != '.':
                    v_depth = math.hypot(x - px, y - py)
                    v_wall = game_map[iy][ix]
                    break
            x += x_step
            y += dy
            if abs(x - px) > MAX_DEPTH:
                break

        if h_depth < v_depth:
            return h_depth, h_wall, False
        else:
            return v_depth, v_wall, True


# ============================================================================
# Game
# ============================================================================

class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("Battlefield 3D - FPS")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont('Segoe UI', 16)
        self.font_large = pygame.font.SysFont('Segoe UI', 28, bold=True)
        self.font_small = pygame.font.SysFont('Segoe UI', 12)
        self.font_title = pygame.font.SysFont('Segoe UI', 52, bold=True)
        self.font_hud = pygame.font.SysFont('Segoe UI', 20, bold=True)

        # Sounds
        self.snd_shoot = SoundGen.shoot()
        self.snd_shotgun = SoundGen.shotgun_sound()
        self.snd_hit = SoundGen.hit()
        self.snd_enemy_die = SoundGen.enemy_die()
        self.snd_pickup = SoundGen.pickup()

        # Engine
        self.raycaster = Raycaster()
        self.state = 'menu'
        self.current_level = 0
        self.player = None
        self.enemies = []
        self.pickups = []
        self.game_map = []
        self.messages = deque(maxlen=5)
        self.mouse_captured = True
        self.was_mouse_pressed = False

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
                            pygame.mouse.set_visible(True)
                            pygame.event.set_grab(False)
                        else:
                            running = False
                    if self.state == 'gameover' and event.key == pygame.K_RETURN:
                        self.state = 'menu'
                    if self.state == 'win' and event.key == pygame.K_RETURN:
                        self.current_level += 1
                        if self.current_level >= len(MAPS):
                            self.state = 'victory'
                        else:
                            self._load_level(self.current_level)
                    if self.state == 'victory' and event.key == pygame.K_RETURN:
                        self.state = 'menu'

            if self.state == 'menu':
                self._update_menu()
                self._draw_menu()
            elif self.state == 'playing':
                self._update_game()
                self._draw_game()
            elif self.state == 'gameover':
                self._draw_gameover()
            elif self.state == 'win':
                self._draw_win()
            elif self.state == 'victory':
                self._draw_victory()

            pygame.display.flip()

        pygame.quit()
        sys.exit()

    def _load_level(self, level_idx):
        level = MAPS[level_idx]
        self.game_map = list(level['grid'])
        px, py = level['player_pos']
        self.player = Player(px, py, level['player_angle'])
        self.enemies = [Enemy(ex, ey) for ex, ey in level['enemies']]
        self.pickups = [Pickup(px, py, pt) for px, py, pt in level['pickups']]
        self.messages.clear()
        self.messages.append(f"Level {level_idx + 1}: {level['name']}")
        self.state = 'playing'
        pygame.mouse.set_visible(False)
        pygame.event.set_grab(True)

    def _update_menu(self):
        keys = pygame.key.get_pressed()
        if keys[pygame.K_RETURN] or keys[pygame.K_SPACE]:
            self.current_level = 0
            self._load_level(0)

    def _update_game(self):
        player = self.player
        if player.health <= 0:
            self.state = 'gameover'
            pygame.mouse.set_visible(True)
            pygame.event.set_grab(False)
            return

        # Mouse look
        mouse_rel = pygame.mouse.get_rel()
        player.angle += mouse_rel[0] * PLAYER_ROT_SPEED

        # Timers
        if player.fire_cooldown > 0:
            player.fire_cooldown -= 1
        if player.reload_timer > 0:
            player.reload_timer -= 1
            if player.reload_timer <= 0:
                wep_name = player.get_weapon_name()
                wep = player.get_weapon()
                if wep['ammo'] == -1:
                    player.mag[wep_name] = wep['mag_size']
                else:
                    needed = wep['mag_size'] - player.mag.get(wep_name, 0)
                    available = player.ammo.get(wep_name, 0)
                    refill = min(needed, available)
                    player.mag[wep_name] = player.mag.get(wep_name, 0) + refill
                    if wep_name in player.ammo:
                        player.ammo[wep_name] -= refill
        if player.damage_flash > 0:
            player.damage_flash -= 1
        if player.shooting_flash > 0:
            player.shooting_flash -= 1

        # Movement
        keys = pygame.key.get_pressed()
        dx, dy = 0, 0
        cos_a = math.cos(player.angle)
        sin_a = math.sin(player.angle)

        if keys[pygame.K_w]:
            dx += cos_a
            dy += sin_a
        if keys[pygame.K_s]:
            dx -= cos_a
            dy -= sin_a
        if keys[pygame.K_a]:
            dx += math.cos(player.angle - math.pi/2)
            dy += math.sin(player.angle - math.pi/2)
        if keys[pygame.K_d]:
            dx += math.cos(player.angle + math.pi/2)
            dy += math.sin(player.angle + math.pi/2)

        player.is_moving = dx != 0 or dy != 0
        if player.is_moving:
            player.weapon_bob += 0.15
            length = math.hypot(dx, dy)
            dx /= length
            dy /= length
            speed = player.speed * 0.03
            new_x = player.x + dx * speed
            new_y = player.y + dy * speed

            # Collision with walls (sliding)
            if not self._wall_at(new_x, player.y):
                player.x = new_x
            if not self._wall_at(player.x, new_y):
                player.y = new_y

        # Weapon switch
        if keys[pygame.K_1]:
            player.current_weapon = 0
        elif keys[pygame.K_2]:
            player.current_weapon = 1
        elif keys[pygame.K_3]:
            player.current_weapon = 2
        elif keys[pygame.K_4]:
            player.current_weapon = 3

        # Shoot
        mouse_buttons = pygame.mouse.get_pressed()
        wep = player.get_weapon()
        wep_name = player.get_weapon_name()
        can_shoot = (player.fire_cooldown <= 0 and player.reload_timer <= 0 and
                    player.mag.get(wep_name, wep['mag_size']) > 0)

        if mouse_buttons[0] and can_shoot:
            if wep['auto'] or not self.was_mouse_pressed:
                self._player_shoot()
        self.was_mouse_pressed = mouse_buttons[0]

        # Reload
        if keys[pygame.K_r] and player.reload_timer <= 0:
            wep_name = player.get_weapon_name()
            wep = player.get_weapon()
            current_mag = player.mag.get(wep_name, 0)
            if current_mag < wep['mag_size']:
                if wep['ammo'] == -1 or player.ammo.get(wep_name, 0) > 0:
                    player.reload_timer = wep['reload_time']

        # Update enemies
        for enemy in self.enemies:
            if enemy.alive:
                attacked = enemy.update(player, self.game_map)
                if attacked:
                    # Enemy attacks player
                    actual_damage = enemy.damage
                    if player.armor > 0:
                        armor_absorb = min(player.armor, actual_damage // 2)
                        player.armor -= armor_absorb
                        actual_damage -= armor_absorb
                    player.health -= actual_damage
                    player.damage_flash = 15
                    self.snd_hit.play()

        # Update pickups
        for pickup in self.pickups:
            if not pickup.alive:
                continue
            pickup.update()
            dist = math.hypot(player.x - pickup.x, player.y - pickup.y)
            if dist < 0.6:
                if pickup.type == 'health' and player.health < player.max_health:
                    player.health = min(player.max_health, player.health + 25)
                    pickup.alive = False
                    self.snd_pickup.play()
                    self.messages.append("+25 HP")
                elif pickup.type == 'ammo':
                    for w in player.ammo:
                        player.ammo[w] += 20
                    pickup.alive = False
                    self.snd_pickup.play()
                    self.messages.append("+20 Munition")
                elif pickup.type == 'armor':
                    player.armor = min(100, player.armor + 50)
                    pickup.alive = False
                    self.snd_pickup.play()
                    self.messages.append("+50 Ruestung")

        # Check win condition (all enemies dead)
        if all(not e.alive for e in self.enemies):
            self.state = 'win'
            pygame.mouse.set_visible(True)
            pygame.event.set_grab(False)

    def _player_shoot(self):
        player = self.player
        wep = player.get_weapon()
        wep_name = player.get_weapon_name()

        player.fire_cooldown = wep['fire_rate']
        player.shooting_flash = 5

        # Reduce mag
        if wep_name in player.mag:
            player.mag[wep_name] -= 1
        else:
            player.mag[wep_name] = wep['mag_size'] - 1

        # Auto reload if empty
        if player.mag.get(wep_name, 0) <= 0:
            if wep['ammo'] == -1 or player.ammo.get(wep_name, 0) > 0:
                player.reload_timer = wep['reload_time']

        # Sound
        if wep_name == 'shotgun':
            self.snd_shotgun.play()
        else:
            self.snd_shoot.play()

        # Hit detection
        pellets = wep.get('pellets', 1)
        for _ in range(pellets):
            spread = wep['spread']
            ray_angle = player.angle + random.uniform(-spread, spread)
            self._shoot_ray(ray_angle, wep['damage'], wep['range'])

    def _shoot_ray(self, angle, damage, max_range):
        """Trace a shot ray and check enemy hits"""
        player = self.player
        sin_a = math.sin(angle)
        cos_a = math.cos(angle)

        # Check enemies sorted by distance
        hits = []
        for enemy in self.enemies:
            if not enemy.alive:
                continue
            dx = enemy.x - player.x
            dy = enemy.y - player.y
            dist = math.hypot(dx, dy)
            if dist > max_range:
                continue

            # Check if enemy is in the direction of the ray
            enemy_angle = math.atan2(dy, dx)
            angle_diff = abs((enemy_angle - angle + math.pi) % (2 * math.pi) - math.pi)

            # Hit box based on distance (closer = easier to hit)
            hit_threshold = max(0.08, enemy.size / max(dist, 0.5))
            if angle_diff < hit_threshold:
                # Check if wall is blocking
                wall_dist = self._ray_to_wall(player.x, player.y, sin_a, cos_a)
                if dist < wall_dist:
                    hits.append((dist, enemy))

        if hits:
            hits.sort(key=lambda h: h[0])
            dist, enemy = hits[0]
            # Damage falloff
            falloff = max(0.3, 1 - dist / max_range)
            actual_damage = int(damage * falloff)
            killed = enemy.take_damage(actual_damage)
            if killed:
                self.player.kills += 1
                self.snd_enemy_die.play()
                self.messages.append(f"Feind eliminiert! ({self.player.kills} Kills)")
            else:
                self.snd_hit.play()

    def _ray_to_wall(self, px, py, sin_a, cos_a):
        """Get distance to nearest wall in direction"""
        if abs(cos_a) < 1e-6:
            cos_a = 1e-6
        if abs(sin_a) < 1e-6:
            sin_a = 1e-6

        for i in range(1, int(MAX_DEPTH * 4)):
            t = i * 0.25
            x = px + cos_a * t
            y = py + sin_a * t
            ix, iy = int(x), int(y)
            if iy < 0 or iy >= len(self.game_map) or ix < 0 or ix >= len(self.game_map[0]):
                return t
            if self.game_map[iy][ix] != '.':
                return t
        return MAX_DEPTH

    def _wall_at(self, x, y):
        margin = PLAYER_SIZE
        for ox in [-margin, 0, margin]:
            for oy in [-margin, 0, margin]:
                ix = int(x + ox)
                iy = int(y + oy)
                if iy < 0 or iy >= len(self.game_map) or ix < 0 or ix >= len(self.game_map[0]):
                    return True
                if self.game_map[iy][ix] != '.':
                    return True
        return False

    # ========================================================================
    # Drawing
    # ========================================================================

    def _draw_game(self):
        player = self.player

        # Sky and floor
        sky_color = (30, 40, 60)
        floor_color = (50, 45, 40)
        self.screen.fill(sky_color)
        pygame.draw.rect(self.screen, floor_color, (0, HALF_H, WIDTH, HALF_H))

        # Cast rays and draw walls
        walls = self.raycaster.cast_rays(player, self.game_map)
        for wall in walls:
            x = wall['ray'] * SCALE
            h = wall['height']
            y = HALF_H - h // 2
            pygame.draw.rect(self.screen, wall['color'], (x, y, SCALE + 1, h))

        # Draw sprites (enemies and pickups)
        self._draw_sprites()

        # Shooting flash
        if player.shooting_flash > 0:
            flash_alpha = player.shooting_flash / 5.0
            flash_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            flash_surf.fill((255, 200, 50, int(30 * flash_alpha)))
            self.screen.blit(flash_surf, (0, 0))

        # Damage flash
        if player.damage_flash > 0:
            alpha = int(100 * player.damage_flash / 15)
            damage_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            damage_surf.fill((200, 0, 0, alpha))
            self.screen.blit(damage_surf, (0, 0))

        # HUD
        self._draw_hud()

        # Weapon
        self._draw_weapon()

        # Crosshair
        cx, cy = HALF_W, HALF_H
        pygame.draw.line(self.screen, (200, 255, 200), (cx - 12, cy), (cx - 4, cy), 2)
        pygame.draw.line(self.screen, (200, 255, 200), (cx + 4, cy), (cx + 12, cy), 2)
        pygame.draw.line(self.screen, (200, 255, 200), (cx, cy - 12), (cx, cy - 4), 2)
        pygame.draw.line(self.screen, (200, 255, 200), (cx, cy + 4), (cx, cy + 12), 2)

        # Minimap
        self._draw_minimap()

    def _draw_sprites(self):
        """Draw enemies and pickups as billboarded sprites"""
        player = self.player
        sprites = []

        # Enemies
        for enemy in self.enemies:
            if not enemy.alive:
                continue
            dx = enemy.x - player.x
            dy = enemy.y - player.y
            dist = math.hypot(dx, dy)
            if dist < 0.3 or dist > MAX_DEPTH:
                continue
            angle = math.atan2(dy, dx) - player.angle
            # Normalize angle
            while angle > math.pi:
                angle -= 2 * math.pi
            while angle < -math.pi:
                angle += 2 * math.pi
            # Check if in FOV
            if abs(angle) < HALF_FOV + 0.2:
                sprites.append(('enemy', dist, angle, enemy))

        # Pickups
        for pickup in self.pickups:
            if not pickup.alive:
                continue
            dx = pickup.x - player.x
            dy = pickup.y - player.y
            dist = math.hypot(dx, dy)
            if dist < 0.3 or dist > MAX_DEPTH:
                continue
            angle = math.atan2(dy, dx) - player.angle
            while angle > math.pi:
                angle -= 2 * math.pi
            while angle < -math.pi:
                angle += 2 * math.pi
            if abs(angle) < HALF_FOV + 0.2:
                sprites.append(('pickup', dist, angle, pickup))

        # Sort by distance (far first)
        sprites.sort(key=lambda s: s[1], reverse=True)

        for sprite_type, dist, angle, obj in sprites:
            # Project to screen
            sx = int(HALF_W + angle * WIDTH / FOV)
            size = min(int(HEIGHT / dist), HEIGHT)

            if sprite_type == 'enemy':
                enemy = obj
                # Enemy body
                half_size = size // 2
                sy = HALF_H - half_size // 2

                # Check z-buffer for occlusion
                ray_idx = int((sx / WIDTH) * NUM_RAYS)
                if 0 <= ray_idx < NUM_RAYS:
                    if dist > self.raycaster.z_buffer[ray_idx]:
                        continue

                # Shading
                shade = max(0.3, 1 - dist / MAX_DEPTH)

                # Body color (red for enemies)
                body_color = tuple(int(c * shade) for c in
                                  ((180, 50, 50) if enemy.pain_timer == 0 else (255, 255, 255)))

                # Draw enemy as a simple shape
                body_w = max(4, size // 3)
                head_size = max(3, size // 6)

                # Body
                pygame.draw.rect(self.screen, body_color,
                               (sx - body_w // 2, sy + head_size * 2, body_w, size // 2))
                # Head
                pygame.draw.circle(self.screen, body_color,
                                 (sx, sy + head_size), head_size)
                # Eyes
                if size > 20:
                    eye_color = (255, 200, 0)
                    pygame.draw.circle(self.screen, eye_color,
                                     (sx - head_size // 3, sy + head_size - 2),
                                     max(1, head_size // 4))
                    pygame.draw.circle(self.screen, eye_color,
                                     (sx + head_size // 3, sy + head_size - 2),
                                     max(1, head_size // 4))

                # Health bar
                if enemy.health < enemy.max_health and size > 15:
                    bar_w = body_w + 10
                    bar_h = 3
                    hp_ratio = enemy.health / enemy.max_health
                    pygame.draw.rect(self.screen, DARK_GRAY,
                                   (sx - bar_w // 2, sy - 5, bar_w, bar_h))
                    hp_color = GREEN if hp_ratio > 0.5 else (YELLOW if hp_ratio > 0.25 else RED)
                    pygame.draw.rect(self.screen, hp_color,
                                   (sx - bar_w // 2, sy - 5, int(bar_w * hp_ratio), bar_h))

            elif sprite_type == 'pickup':
                pickup = obj
                half_size = size // 4
                sy = HALF_H + size // 4 + int(math.sin(pickup.bob) * 5)

                ray_idx = int((sx / WIDTH) * NUM_RAYS)
                if 0 <= ray_idx < NUM_RAYS:
                    if dist > self.raycaster.z_buffer[ray_idx]:
                        continue

                shade = max(0.4, 1 - dist / MAX_DEPTH)
                if pickup.type == 'health':
                    color = tuple(int(c * shade) for c in (50, 220, 50))
                elif pickup.type == 'ammo':
                    color = tuple(int(c * shade) for c in (220, 220, 50))
                else:
                    color = tuple(int(c * shade) for c in (50, 150, 255))

                pickup_size = max(4, half_size)
                pygame.draw.rect(self.screen, color,
                               (sx - pickup_size // 2, sy - pickup_size // 2,
                                pickup_size, pickup_size))
                # Symbol
                if pickup_size > 8:
                    symbol = '+' if pickup.type == 'health' else ('A' if pickup.type == 'ammo' else 'R')
                    sym_text = self.font_small.render(symbol, True, WHITE)
                    self.screen.blit(sym_text, (sx - sym_text.get_width() // 2,
                                              sy - sym_text.get_height() // 2))

    def _draw_weapon(self):
        """Draw weapon at bottom of screen"""
        player = self.player
        wep = player.get_weapon()

        # Weapon bob
        bob_x = math.sin(player.weapon_bob) * 8 if player.is_moving else 0
        bob_y = abs(math.cos(player.weapon_bob)) * 5 if player.is_moving else 0

        # Recoil
        recoil_y = 0
        if player.shooting_flash > 0:
            recoil_y = player.shooting_flash * 3

        wx = HALF_W + int(bob_x) + 50
        wy = HEIGHT - 120 + int(bob_y) + int(recoil_y)

        # Weapon body (simple rectangle representation)
        wep_color = wep['color']
        pygame.draw.rect(self.screen, wep_color, (wx, wy, 80, 25))
        pygame.draw.rect(self.screen, DARK_GRAY, (wx + 60, wy - 15, 15, 30))
        # Grip
        pygame.draw.rect(self.screen, (60, 50, 40), (wx + 20, wy + 20, 15, 30))

        # Muzzle flash
        if player.shooting_flash > 3:
            flash_size = 20
            pygame.draw.circle(self.screen, (255, 255, 100),
                             (wx + 75, wy + 5), flash_size)
            pygame.draw.circle(self.screen, (255, 200, 50),
                             (wx + 75, wy + 5), flash_size // 2)

    def _draw_hud(self):
        player = self.player
        wep = player.get_weapon()
        wep_name = player.get_weapon_name()

        # Health bar (bottom left)
        hx, hy = 20, HEIGHT - 55
        bar_w, bar_h = 200, 22

        pygame.draw.rect(self.screen, (20, 20, 30), (hx - 2, hy - 2, bar_w + 4, bar_h + 4))
        hp_ratio = player.health / player.max_health
        hp_color = GREEN if hp_ratio > 0.5 else (YELLOW if hp_ratio > 0.25 else RED)
        pygame.draw.rect(self.screen, hp_color, (hx, hy, int(bar_w * hp_ratio), bar_h))
        hp_text = self.font_hud.render(f"{player.health}", True, WHITE)
        self.screen.blit(hp_text, (hx + 5, hy + 1))
        hp_label = self.font_small.render("HP", True, (200, 200, 200))
        self.screen.blit(hp_label, (hx + bar_w - 20, hy + 5))

        # Armor bar
        if player.armor > 0:
            ay = hy - 18
            armor_w = int(bar_w * player.armor / 100)
            pygame.draw.rect(self.screen, (20, 20, 30), (hx - 2, ay - 2, bar_w + 4, 14))
            pygame.draw.rect(self.screen, (80, 140, 255), (hx, ay, armor_w, 10))
            ar_text = self.font_small.render(f"Ruestung: {player.armor}", True, (150, 200, 255))
            self.screen.blit(ar_text, (hx, ay - 14))

        # Ammo (bottom right)
        ax = WIDTH - 220
        ay = HEIGHT - 55
        current_mag = player.mag.get(wep_name, wep['mag_size'])
        reserve = player.ammo.get(wep_name, 0) if wep['ammo'] != -1 else '\u221e'

        if player.reload_timer > 0:
            ammo_text = self.font_hud.render("NACHLADEN...", True, YELLOW)
        else:
            ammo_text = self.font_hud.render(f"{current_mag} | {reserve}", True, WHITE)
        self.screen.blit(ammo_text, (ax, ay))

        wep_label = self.font_small.render(f"[{player.current_weapon + 1}] {wep['name']}", True, wep['color'])
        self.screen.blit(wep_label, (ax, ay + 25))

        # Kill counter (top left)
        kills_text = self.font.render(f"Kills: {player.kills}", True, WHITE)
        self.screen.blit(kills_text, (20, 15))

        # Level name
        level_name = MAPS[self.current_level]['name']
        level_text = self.font_small.render(f"Level {self.current_level + 1}: {level_name}", True, GRAY)
        self.screen.blit(level_text, (20, 35))

        # Enemies remaining
        alive = sum(1 for e in self.enemies if e.alive)
        enemy_text = self.font.render(f"Feinde: {alive}", True,
                                     RED if alive > 0 else GREEN)
        self.screen.blit(enemy_text, (WIDTH // 2 - 40, 15))

        # Messages
        msg_y = HEIGHT - 130
        now = pygame.time.get_ticks()
        for msg in reversed(self.messages):
            text = self.font_small.render(msg, True, (200, 255, 200))
            self.screen.blit(text, (HALF_W - text.get_width() // 2, msg_y))
            msg_y -= 18

        # FPS
        fps_text = self.font_small.render(f"FPS: {int(self.clock.get_fps())}", True, GRAY)
        self.screen.blit(fps_text, (WIDTH - 80, HEIGHT - 20))

    def _draw_minimap(self):
        mm_scale = 5
        mm_x = WIDTH - 15
        mm_y = 15
        map_h = len(self.game_map)
        map_w = len(self.game_map[0]) if map_h > 0 else 0
        mm_w = map_w * mm_scale
        mm_h = map_h * mm_scale
        mm_x -= mm_w

        # Background
        mm_surf = pygame.Surface((mm_w, mm_h), pygame.SRCALPHA)
        mm_surf.fill((0, 0, 0, 150))

        # Walls
        for y, row in enumerate(self.game_map):
            for x, cell in enumerate(row):
                if cell != '.':
                    color = (*WALL_COLORS.get(cell, (100, 100, 100))[:3], 200)
                    pygame.draw.rect(mm_surf, color,
                                   (x * mm_scale, y * mm_scale, mm_scale, mm_scale))

        # Enemies
        for enemy in self.enemies:
            if enemy.alive:
                ex = int(enemy.x * mm_scale)
                ey = int(enemy.y * mm_scale)
                pygame.draw.circle(mm_surf, (255, 50, 50, 200), (ex, ey), 2)

        # Player
        px = int(self.player.x * mm_scale)
        py = int(self.player.y * mm_scale)
        pygame.draw.circle(mm_surf, (50, 255, 50, 255), (px, py), 3)
        # Direction
        dx = int(px + math.cos(self.player.angle) * 8)
        dy = int(py + math.sin(self.player.angle) * 8)
        pygame.draw.line(mm_surf, (50, 255, 50, 255), (px, py), (dx, dy), 1)

        self.screen.blit(mm_surf, (mm_x, mm_y))

    def _draw_menu(self):
        self.screen.fill((15, 20, 30))

        title = self.font_title.render("BATTLEFIELD 3D", True, WHITE)
        sub = self.font_large.render("First Person Shooter", True, (150, 180, 220))
        self.screen.blit(title, (HALF_W - title.get_width() // 2, 120))
        self.screen.blit(sub, (HALF_W - sub.get_width() // 2, 185))

        y = 270
        lines = [
            ("STEUERUNG", WHITE, True),
            ("", WHITE, False),
            ("WASD - Bewegen", GRAY, False),
            ("Maus - Umsehen", GRAY, False),
            ("LMB - Schiessen", GRAY, False),
            ("R - Nachladen", GRAY, False),
            ("1-4 - Waffe wechseln", GRAY, False),
            ("ESC - Menu", GRAY, False),
            ("", WHITE, False),
            ("WAFFEN", WHITE, True),
            ("", WHITE, False),
            ("[1] Pistole - Praezise, unendlich Munition", (200, 200, 100), False),
            ("[2] Sturmgewehr - Vollautomatisch", (200, 200, 100), False),
            ("[3] Schrotflinte - Nahkampf, 6 Kugeln", (200, 200, 100), False),
            ("[4] Scharfschuetze - Hoher Schaden", (200, 200, 100), False),
            ("", WHITE, False),
            ("Druecke ENTER zum Starten", (100, 255, 100), True),
        ]

        for text, color, bold in lines:
            if text:
                font = self.font_large if bold else self.font
                rendered = font.render(text, True, color)
                self.screen.blit(rendered, (HALF_W - rendered.get_width() // 2, y))
            y += 28 if bold else 22

    def _draw_gameover(self):
        self.screen.fill((40, 10, 10))
        title = self.font_title.render("GEFALLEN", True, RED)
        stats = self.font_large.render(f"Kills: {self.player.kills}", True, WHITE)
        restart = self.font.render("Druecke ENTER fuer Hauptmenue", True, GRAY)
        self.screen.blit(title, (HALF_W - title.get_width() // 2, 250))
        self.screen.blit(stats, (HALF_W - stats.get_width() // 2, 340))
        self.screen.blit(restart, (HALF_W - restart.get_width() // 2, 420))

    def _draw_win(self):
        self.screen.fill((10, 30, 10))
        title = self.font_title.render("LEVEL GESCHAFFT!", True, GREEN)
        stats = self.font_large.render(f"Kills: {self.player.kills}", True, WHITE)
        next_text = "Druecke ENTER fuer naechstes Level"
        if self.current_level + 1 >= len(MAPS):
            next_text = "Druecke ENTER - Finale Siegesseite"
        cont = self.font.render(next_text, True, GRAY)
        self.screen.blit(title, (HALF_W - title.get_width() // 2, 250))
        self.screen.blit(stats, (HALF_W - stats.get_width() // 2, 340))
        self.screen.blit(cont, (HALF_W - cont.get_width() // 2, 420))

    def _draw_victory(self):
        self.screen.fill((10, 10, 40))
        title = self.font_title.render("SIEG!", True, YELLOW)
        sub = self.font_large.render("Alle Level abgeschlossen!", True, WHITE)
        stats = self.font.render(f"Gesamt-Kills: {self.player.kills}", True, GRAY)
        cont = self.font.render("Druecke ENTER fuer Hauptmenue", True, GRAY)
        self.screen.blit(title, (HALF_W - title.get_width() // 2, 220))
        self.screen.blit(sub, (HALF_W - sub.get_width() // 2, 300))
        self.screen.blit(stats, (HALF_W - stats.get_width() // 2, 370))
        self.screen.blit(cont, (HALF_W - cont.get_width() // 2, 430))


# ============================================================================
# Entry Point
# ============================================================================

def main():
    game = Game()
    game.run()


if __name__ == '__main__':
    main()
