import * as PIXI from 'pixi.js';
import {
  createWorld, addEntity, removeEntity, addComponent,
  hasComponent, defineQuery, enterQuery, exitQuery,
  IWorld,
} from 'bitecs';
import {
  Position, Velocity, Health, Collision, Player, Enemy,
  Weapon, Projectile, XPGem, SpriteComponent, Lifetime,
  Particle, AreaEffect, PlayerTag, EnemyTag, ProjectileTag,
  XPGemTag, ParticleTag, WeaponTag, AreaEffectTag, FlashEffect,
} from './ecs/components';
import { WEAPONS, WEAPON_TYPES, getWeaponDef } from './data/weapons';
import { ENEMIES, ENEMY_TYPES, getEnemyDef, WAVES, WaveConfig } from './data/enemies';
import { PASSIVE_UPGRADES, PlayerStats, BASE_STATS, XP_TABLE } from './data/upgrades';

// ============================================================
// GAME STATE
// ============================================================

interface GameState {
  world: IWorld;
  playerEid: number;
  stats: PlayerStats;
  passiveLevels: number[];
  weaponLevels: Map<number, number>; // weaponType -> level
  gameTime: number;
  paused: boolean;
  levelUpActive: boolean;
  levelUpChoices: LevelUpChoice[];
  gameOver: boolean;
  cameraX: number;
  cameraY: number;
  keys: Set<string>;
  entitySprites: Map<number, PIXI.Container>;
  currentWaveIndex: number;
  waveSpawnTimers: Map<number, { config: WaveConfig; spawned: number; timer: number }>;
  enemyCount: number;
  maxEnemies: number;
  screenShake: number;
  killCount: number;
  damageNumbers: DamageNumber[];
}

interface LevelUpChoice {
  type: 'weapon' | 'passive';
  index: number;
  name: string;
  description: string;
  color: number;
  level: number;
  maxLevel: number;
}

interface DamageNumber {
  x: number;
  y: number;
  value: number;
  timer: number;
  vy: number;
  color: number;
}

// ============================================================
// CONSTANTS
// ============================================================

const WORLD_SIZE = 4000;
const MAGNET_BASE_RANGE = 80;
const MAX_ENEMIES = 300;
const SPAWN_DISTANCE = 500;
const MAP_TILE_SIZE = 64;

// ============================================================
// MAIN GAME CLASS
// ============================================================

class Game {
  private app!: PIXI.Application;
  private gameContainer!: PIXI.Container;
  private uiContainer!: PIXI.Container;
  private bgContainer!: PIXI.Container;
  private entityContainer!: PIXI.Container;
  private particleContainer!: PIXI.Container;
  private hudGraphics!: PIXI.Graphics;
  private levelUpContainer!: PIXI.Container;
  private minimapGraphics!: PIXI.Graphics;
  private state!: GameState;
  private lastTime: number = 0;
  private titleScreen: boolean = true;
  private titleContainer!: PIXI.Container;
  private gameOverContainer!: PIXI.Container;

  async init(): Promise<void> {
    this.app = new PIXI.Application();
    await this.app.init({
      width: window.innerWidth,
      height: window.innerHeight,
      backgroundColor: 0x0a0a0f,
      antialias: false,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
    });

    const loadingEl = document.getElementById('loading');
    if (loadingEl) loadingEl.remove();

    document.body.appendChild(this.app.canvas as HTMLCanvasElement);

    window.addEventListener('resize', () => {
      this.app.renderer.resize(window.innerWidth, window.innerHeight);
    });

    this.setupContainers();
    this.showTitle();

    window.addEventListener('keydown', (e) => {
      if (this.titleScreen) {
        this.titleScreen = false;
        this.titleContainer.visible = false;
        this.startGame();
        return;
      }
      if (this.state?.gameOver) {
        this.gameOverContainer.visible = false;
        this.startGame();
        return;
      }
      if (this.state) {
        this.state.keys.add(e.key.toLowerCase());
      }
    });
    window.addEventListener('keyup', (e) => {
      if (this.state) {
        this.state.keys.delete(e.key.toLowerCase());
      }
    });

    this.app.ticker.add(() => this.update());
  }

  private setupContainers(): void {
    this.bgContainer = new PIXI.Container();
    this.gameContainer = new PIXI.Container();
    this.entityContainer = new PIXI.Container();
    this.particleContainer = new PIXI.Container();
    this.uiContainer = new PIXI.Container();

    this.gameContainer.addChild(this.bgContainer);
    this.gameContainer.addChild(this.entityContainer);
    this.gameContainer.addChild(this.particleContainer);

    this.app.stage.addChild(this.gameContainer);
    this.app.stage.addChild(this.uiContainer);

    this.hudGraphics = new PIXI.Graphics();
    this.uiContainer.addChild(this.hudGraphics);

    this.minimapGraphics = new PIXI.Graphics();
    this.uiContainer.addChild(this.minimapGraphics);

    this.levelUpContainer = new PIXI.Container();
    this.levelUpContainer.visible = false;
    this.uiContainer.addChild(this.levelUpContainer);

    this.titleContainer = new PIXI.Container();
    this.app.stage.addChild(this.titleContainer);

    this.gameOverContainer = new PIXI.Container();
    this.gameOverContainer.visible = false;
    this.app.stage.addChild(this.gameOverContainer);
  }

  private showTitle(): void {
    this.titleContainer.removeChildren();
    const w = window.innerWidth;
    const h = window.innerHeight;

    const bg = new PIXI.Graphics();
    bg.rect(0, 0, w, h).fill({ color: 0x0a0a0f });
    this.titleContainer.addChild(bg);

    const title = new PIXI.Text({
      text: 'CODEX MORTIS',
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 72,
        fontWeight: 'bold',
        fill: 0xc4a0ff,
        dropShadow: true,
        dropShadowColor: 0x8b5cf6,
        dropShadowBlur: 20,
        dropShadowDistance: 0,
      },
    });
    title.anchor.set(0.5);
    title.position.set(w / 2, h / 2 - 80);
    this.titleContainer.addChild(title);

    const subtitle = new PIXI.Text({
      text: 'Survive the endless hordes of darkness',
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 20,
        fill: 0x8b8b9a,
      },
    });
    subtitle.anchor.set(0.5);
    subtitle.position.set(w / 2, h / 2);
    this.titleContainer.addChild(subtitle);

    const start = new PIXI.Text({
      text: 'Press any key to start',
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 18,
        fill: 0xc4a0ff,
      },
    });
    start.anchor.set(0.5);
    start.position.set(w / 2, h / 2 + 80);
    this.titleContainer.addChild(start);

    const controls = new PIXI.Text({
      text: 'WASD - Move  |  Weapons auto-attack  |  Survive!',
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 14,
        fill: 0x555566,
      },
    });
    controls.anchor.set(0.5);
    controls.position.set(w / 2, h - 60);
    this.titleContainer.addChild(controls);
  }

  private startGame(): void {
    // Clean up previous game
    this.entityContainer.removeChildren();
    this.particleContainer.removeChildren();
    this.bgContainer.removeChildren();
    this.levelUpContainer.visible = false;
    this.gameOverContainer.visible = false;

    const world = createWorld();

    // Create player
    const playerEid = addEntity(world);
    addComponent(world, Position, playerEid);
    addComponent(world, Velocity, playerEid);
    addComponent(world, Health, playerEid);
    addComponent(world, Collision, playerEid);
    addComponent(world, Player, playerEid);
    addComponent(world, PlayerTag, playerEid);
    addComponent(world, SpriteComponent, playerEid);

    Position.x[playerEid] = WORLD_SIZE / 2;
    Position.y[playerEid] = WORLD_SIZE / 2;
    Health.current[playerEid] = 100;
    Health.max[playerEid] = 100;
    Collision.radius[playerEid] = 14;
    Player.speed[playerEid] = 150;
    Player.level[playerEid] = 1;
    Player.xpToNext[playerEid] = XP_TABLE[0];
    SpriteComponent.scaleX[playerEid] = 1;
    SpriteComponent.scaleY[playerEid] = 1;
    SpriteComponent.alpha[playerEid] = 1;

    this.state = {
      world,
      playerEid,
      stats: { ...BASE_STATS },
      passiveLevels: new Array(PASSIVE_UPGRADES.length).fill(0),
      weaponLevels: new Map(),
      gameTime: 0,
      paused: false,
      levelUpActive: false,
      levelUpChoices: [],
      gameOver: false,
      cameraX: Position.x[playerEid],
      cameraY: Position.y[playerEid],
      keys: new Set(),
      entitySprites: new Map(),
      currentWaveIndex: 0,
      waveSpawnTimers: new Map(),
      enemyCount: 0,
      maxEnemies: MAX_ENEMIES,
      screenShake: 0,
      killCount: 0,
      damageNumbers: [],
    };

    // Give player starting weapon
    this.addWeaponToPlayer(WEAPON_TYPES.MAGIC_BOLT);

    // Generate background tiles
    this.generateBackground();

    // Create player sprite
    this.createPlayerSprite(playerEid);

    this.lastTime = performance.now();
  }

  private generateBackground(): void {
    const tileCount = Math.ceil(WORLD_SIZE / MAP_TILE_SIZE);
    const bg = new PIXI.Graphics();

    for (let y = 0; y < tileCount; y++) {
      for (let x = 0; x < tileCount; x++) {
        const shade = ((x + y) % 2 === 0) ? 0x12121a : 0x0e0e16;
        bg.rect(x * MAP_TILE_SIZE, y * MAP_TILE_SIZE, MAP_TILE_SIZE, MAP_TILE_SIZE).fill({ color: shade });
      }
    }

    // Add some decorative elements
    for (let i = 0; i < 200; i++) {
      const x = Math.random() * WORLD_SIZE;
      const y = Math.random() * WORLD_SIZE;
      const size = 2 + Math.random() * 4;
      bg.circle(x, y, size).fill({ color: 0x1a1a2e, alpha: 0.5 });
    }

    this.bgContainer.addChild(bg);
  }

  private createPlayerSprite(eid: number): void {
    const container = new PIXI.Container();
    const gfx = new PIXI.Graphics();

    // Body
    gfx.circle(0, 0, 14).fill({ color: 0xc4a0ff });
    // Eyes
    gfx.circle(-4, -3, 3).fill({ color: 0x1a1a2e });
    gfx.circle(4, -3, 3).fill({ color: 0x1a1a2e });
    // Inner glow
    gfx.circle(0, 0, 10).fill({ color: 0xd8b4fe, alpha: 0.3 });

    container.addChild(gfx);
    container.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(container);
    this.state.entitySprites.set(eid, container);
  }

  private createEnemySprite(eid: number): void {
    const enemyType = Enemy.type[eid];
    const def = getEnemyDef(enemyType);
    const container = new PIXI.Container();
    const gfx = new PIXI.Graphics();

    if (enemyType === ENEMY_TYPES.BAT) {
      // Bat shape
      gfx.moveTo(-def.size, 0).lineTo(-def.size / 2, -def.size / 2).lineTo(0, -2).lineTo(def.size / 2, -def.size / 2).lineTo(def.size, 0).lineTo(0, def.size / 2).closePath().fill({ color: def.color });
    } else if (enemyType === ENEMY_TYPES.GHOST) {
      // Ghost shape
      gfx.circle(0, -def.size / 4, def.size / 2).fill({ color: def.color, alpha: 0.7 });
      gfx.rect(-def.size / 2, -def.size / 4, def.size, def.size / 2).fill({ color: def.color, alpha: 0.7 });
      // Wavy bottom
      for (let i = 0; i < 3; i++) {
        const wx = -def.size / 2 + i * (def.size / 3);
        gfx.circle(wx + def.size / 6, def.size / 4, def.size / 6).fill({ color: def.color, alpha: 0.7 });
      }
    } else if (enemyType === ENEMY_TYPES.BOSS) {
      // Boss - big diamond
      gfx.moveTo(0, -def.size).lineTo(def.size, 0).lineTo(0, def.size).lineTo(-def.size, 0).closePath().fill({ color: def.color });
      gfx.circle(0, 0, def.size * 0.4).fill({ color: 0xff0000 });
      // Crown
      gfx.moveTo(-def.size * 0.5, -def.size * 0.8).lineTo(-def.size * 0.3, -def.size * 1.1).lineTo(0, -def.size * 0.9).lineTo(def.size * 0.3, -def.size * 1.1).lineTo(def.size * 0.5, -def.size * 0.8).fill({ color: 0xffd700 });
    } else {
      // Default - circle with eyes
      gfx.circle(0, 0, def.size).fill({ color: def.color });
      gfx.circle(-def.size * 0.3, -def.size * 0.2, def.size * 0.2).fill({ color: 0x1a1a2e });
      gfx.circle(def.size * 0.3, -def.size * 0.2, def.size * 0.2).fill({ color: 0x1a1a2e });
    }

    container.addChild(gfx);
    container.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(container);
    this.state.entitySprites.set(eid, container);
  }

  private createProjectileSprite(eid: number): void {
    const container = new PIXI.Container();
    const gfx = new PIXI.Graphics();
    const weaponType = Projectile.ownerWeaponType[eid];
    const def = getWeaponDef(weaponType);

    if (weaponType === WEAPON_TYPES.WHIP) {
      gfx.rect(-60, -5, 120, 10).fill({ color: def.color, alpha: 0.8 });
    } else if (weaponType === WEAPON_TYPES.HOLY_CROSS) {
      gfx.rect(-3, -12, 6, 24).fill({ color: def.color });
      gfx.rect(-8, -3, 16, 6).fill({ color: def.color });
    } else if (weaponType === WEAPON_TYPES.SCYTHE) {
      gfx.arc(0, 0, 12, -Math.PI * 0.7, Math.PI * 0.3, false);
      gfx.lineTo(0, 0);
      gfx.closePath();
      gfx.fill({ color: def.color });
    } else if (weaponType === WEAPON_TYPES.BLOOD_WAVE) {
      gfx.ellipse(0, 0, 20, 6).fill({ color: def.color, alpha: 0.7 });
    } else {
      // Default projectile (bolt)
      gfx.circle(0, 0, 5).fill({ color: def.color });
      gfx.circle(0, 0, 3).fill({ color: 0xffffff, alpha: 0.5 });
    }

    container.addChild(gfx);
    container.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(container);
    this.state.entitySprites.set(eid, container);
  }

  private createXPGemSprite(eid: number): void {
    const container = new PIXI.Container();
    const gfx = new PIXI.Graphics();
    const value = XPGem.value[eid];
    const color = value >= 10 ? 0xfbbf24 : value >= 5 ? 0x3b82f6 : 0x4ade80;
    const size = value >= 10 ? 6 : value >= 5 ? 5 : 4;

    // Diamond shape
    gfx.moveTo(0, -size).lineTo(size, 0).lineTo(0, size).lineTo(-size, 0).closePath().fill({ color });
    gfx.moveTo(0, -size + 1).lineTo(size - 1, 0).lineTo(0, size - 1).lineTo(-size + 1, 0).closePath().fill({ color: 0xffffff, alpha: 0.3 });

    container.addChild(gfx);
    container.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(container);
    this.state.entitySprites.set(eid, container);
  }

  private addWeaponToPlayer(weaponType: number): void {
    const { world } = this.state;
    const def = getWeaponDef(weaponType);

    const wEid = addEntity(world);
    addComponent(world, Weapon, wEid);
    addComponent(world, WeaponTag, wEid);

    Weapon.type[wEid] = def.type;
    Weapon.level[wEid] = 1;
    Weapon.damage[wEid] = def.baseDamage;
    Weapon.cooldown[wEid] = def.baseCooldown;
    Weapon.timer[wEid] = 0;
    Weapon.range[wEid] = def.baseRange;
    Weapon.count[wEid] = def.baseCount;
    Weapon.pierce[wEid] = def.basePierce;
    Weapon.speed[wEid] = def.baseSpeed;
    Weapon.area[wEid] = def.baseArea;

    this.state.weaponLevels.set(weaponType, 1);
  }

  private upgradeWeapon(weaponType: number): void {
    const { world } = this.state;
    const currentLevel = this.state.weaponLevels.get(weaponType) || 0;
    const newLevel = currentLevel + 1;
    this.state.weaponLevels.set(weaponType, newLevel);

    // Find weapon entity and update stats
    const weaponQuery = defineQuery([Weapon, WeaponTag]);
    const weapons = weaponQuery(world);
    for (const wEid of weapons) {
      if (Weapon.type[wEid] === weaponType) {
        Weapon.level[wEid] = newLevel;
        const def = getWeaponDef(weaponType);
        // Progressive upgrades
        Weapon.damage[wEid] = def.baseDamage * (1 + (newLevel - 1) * 0.25);
        Weapon.cooldown[wEid] = def.baseCooldown * Math.max(0.3, 1 - (newLevel - 1) * 0.08);
        Weapon.count[wEid] = def.baseCount + Math.floor((newLevel - 1) / 2);
        if (def.basePierce > 0) {
          Weapon.pierce[wEid] = def.basePierce + Math.floor((newLevel - 1) / 3);
        }
        Weapon.area[wEid] = def.baseArea * (1 + (newLevel - 1) * 0.15);
        Weapon.speed[wEid] = def.baseSpeed * (1 + (newLevel - 1) * 0.1);
        break;
      }
    }
  }

  // ============================================================
  // GAME UPDATE
  // ============================================================

  private update(): void {
    if (this.titleScreen || !this.state) return;

    const now = performance.now();
    const dt = Math.min((now - this.lastTime) / 1000, 0.05); // Cap at 50ms
    this.lastTime = now;

    if (this.state.paused || this.state.levelUpActive || this.state.gameOver) {
      this.drawHUD();
      return;
    }

    this.state.gameTime += dt;

    this.updateInput(dt);
    this.updateWaveSpawning(dt);
    this.updateEnemyAI(dt);
    this.updateWeapons(dt);
    this.updateMovement(dt);
    this.updateProjectiles(dt);
    this.updateAreaEffects(dt);
    this.updateCollisions(dt);
    this.updateXPCollection(dt);
    this.updateLifetimes(dt);
    this.updateParticles(dt);
    this.updateDamageNumbers(dt);
    this.updateCamera(dt);
    this.updateSprites();
    this.drawHUD();
    this.drawMinimap();

    // Recovery
    if (this.state.stats.recovery > 0) {
      const playerEid = this.state.playerEid;
      Health.current[playerEid] = Math.min(
        Health.max[playerEid],
        Health.current[playerEid] + this.state.stats.recovery * dt
      );
    }

    // Screen shake decay
    if (this.state.screenShake > 0) {
      this.state.screenShake *= 0.9;
      if (this.state.screenShake < 0.5) this.state.screenShake = 0;
    }
  }

  // ============================================================
  // INPUT SYSTEM
  // ============================================================

  private updateInput(dt: number): void {
    const { keys, playerEid, stats } = this.state;
    let mx = 0, my = 0;

    if (keys.has('w') || keys.has('arrowup')) my -= 1;
    if (keys.has('s') || keys.has('arrowdown')) my += 1;
    if (keys.has('a') || keys.has('arrowleft')) mx -= 1;
    if (keys.has('d') || keys.has('arrowright')) mx += 1;

    // Normalize
    const len = Math.sqrt(mx * mx + my * my);
    if (len > 0) {
      mx /= len;
      my /= len;
    }

    const speed = Player.speed[playerEid] * stats.speed;
    Velocity.x[playerEid] = mx * speed;
    Velocity.y[playerEid] = my * speed;
  }

  // ============================================================
  // MOVEMENT SYSTEM
  // ============================================================

  private updateMovement(dt: number): void {
    const { world, playerEid } = this.state;

    // Player movement
    Position.x[playerEid] += Velocity.x[playerEid] * dt;
    Position.y[playerEid] += Velocity.y[playerEid] * dt;

    // Clamp to world bounds
    Position.x[playerEid] = Math.max(20, Math.min(WORLD_SIZE - 20, Position.x[playerEid]));
    Position.y[playerEid] = Math.max(20, Math.min(WORLD_SIZE - 20, Position.y[playerEid]));

    // Enemy movement
    const enemyQuery = defineQuery([Enemy, EnemyTag, Position, Velocity]);
    const enemies = enemyQuery(world);
    for (const eid of enemies) {
      // Apply knockback
      if (Math.abs(Enemy.knockbackX[eid]) > 0.1 || Math.abs(Enemy.knockbackY[eid]) > 0.1) {
        Position.x[eid] += Enemy.knockbackX[eid] * dt;
        Position.y[eid] += Enemy.knockbackY[eid] * dt;
        Enemy.knockbackX[eid] *= 0.85;
        Enemy.knockbackY[eid] *= 0.85;
      }

      Position.x[eid] += Velocity.x[eid] * dt;
      Position.y[eid] += Velocity.y[eid] * dt;
    }

    // Projectile movement
    const projQuery = defineQuery([Projectile, ProjectileTag, Position, Velocity]);
    const projs = projQuery(world);
    for (const eid of projs) {
      Position.x[eid] += Velocity.x[eid] * dt;
      Position.y[eid] += Velocity.y[eid] * dt;
    }

    // Particle movement
    const particleQuery = defineQuery([Particle, ParticleTag, Position, Velocity]);
    const particles = particleQuery(world);
    for (const eid of particles) {
      Position.x[eid] += Velocity.x[eid] * dt;
      Position.y[eid] += Velocity.y[eid] * dt;
      Velocity.y[eid] += 100 * dt; // gravity
    }
  }

  // ============================================================
  // ENEMY AI SYSTEM
  // ============================================================

  private updateEnemyAI(dt: number): void {
    const { world, playerEid } = this.state;
    const px = Position.x[playerEid];
    const py = Position.y[playerEid];

    const enemyQuery = defineQuery([Enemy, EnemyTag, Position, Velocity]);
    const enemies = enemyQuery(world);

    for (const eid of enemies) {
      const dx = px - Position.x[eid];
      const dy = py - Position.y[eid];
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist > 1) {
        const speed = Enemy.speed[eid];
        Velocity.x[eid] = (dx / dist) * speed;
        Velocity.y[eid] = (dy / dist) * speed;
      }
    }
  }

  // ============================================================
  // WAVE SPAWNING SYSTEM
  // ============================================================

  private updateWaveSpawning(dt: number): void {
    const { gameTime, world, playerEid } = this.state;

    // Check for new waves to start
    while (this.state.currentWaveIndex < WAVES.length &&
           WAVES[this.state.currentWaveIndex].time <= gameTime) {
      const wave = WAVES[this.state.currentWaveIndex];
      this.state.waveSpawnTimers.set(this.state.currentWaveIndex, {
        config: wave,
        spawned: 0,
        timer: 0,
      });
      this.state.currentWaveIndex++;
    }

    // Process active waves
    const px = Position.x[playerEid];
    const py = Position.y[playerEid];

    const toRemove: number[] = [];
    this.state.waveSpawnTimers.forEach((waveState, index) => {
      waveState.timer -= dt;
      if (waveState.timer <= 0 && waveState.spawned < waveState.config.count) {
        if (this.state.enemyCount < this.state.maxEnemies) {
          this.spawnEnemy(
            px, py,
            waveState.config.enemyType,
            waveState.config.healthMult,
            waveState.config.speedMult
          );
          waveState.spawned++;
          waveState.timer = waveState.config.interval;
        }
      }
      if (waveState.spawned >= waveState.config.count) {
        toRemove.push(index);
      }
    });
    toRemove.forEach(i => this.state.waveSpawnTimers.delete(i));

    // Continuous spawning after all waves (difficulty scaling)
    if (this.state.currentWaveIndex >= WAVES.length && this.state.enemyCount < 50) {
      const scaleFactor = 1 + (gameTime - 600) / 120;
      const types = [0, 1, 2, 3, 4];
      const type = types[Math.floor(Math.random() * types.length)];
      this.spawnEnemy(px, py, type, scaleFactor * 2, 1 + scaleFactor * 0.3);
    }
  }

  private spawnEnemy(px: number, py: number, type: number, healthMult: number, speedMult: number): void {
    const { world } = this.state;
    const def = getEnemyDef(type);

    // Spawn at edge of screen
    const angle = Math.random() * Math.PI * 2;
    const dist = SPAWN_DISTANCE + Math.random() * 100;
    const x = px + Math.cos(angle) * dist;
    const y = py + Math.sin(angle) * dist;

    // Clamp to world
    const sx = Math.max(10, Math.min(WORLD_SIZE - 10, x));
    const sy = Math.max(10, Math.min(WORLD_SIZE - 10, y));

    const eid = addEntity(world);
    addComponent(world, Position, eid);
    addComponent(world, Velocity, eid);
    addComponent(world, Health, eid);
    addComponent(world, Collision, eid);
    addComponent(world, Enemy, eid);
    addComponent(world, EnemyTag, eid);
    addComponent(world, SpriteComponent, eid);

    Position.x[eid] = sx;
    Position.y[eid] = sy;
    Health.current[eid] = def.health * healthMult;
    Health.max[eid] = def.health * healthMult;
    Collision.radius[eid] = def.size;
    Enemy.type[eid] = type;
    Enemy.speed[eid] = def.speed * speedMult;
    Enemy.damage[eid] = def.damage;
    Enemy.xpDrop[eid] = def.xpDrop;
    Enemy.attackCooldown[eid] = def.attackCooldown;
    Enemy.attackTimer[eid] = 0;
    SpriteComponent.alpha[eid] = 1;

    this.createEnemySprite(eid);
    this.state.enemyCount++;
  }

  // ============================================================
  // WEAPON SYSTEM
  // ============================================================

  private updateWeapons(dt: number): void {
    const { world, playerEid, stats } = this.state;
    const px = Position.x[playerEid];
    const py = Position.y[playerEid];

    const weaponQuery = defineQuery([Weapon, WeaponTag]);
    const weapons = weaponQuery(world);

    for (const wEid of weapons) {
      Weapon.timer[wEid] -= dt;
      if (Weapon.timer[wEid] <= 0) {
        Weapon.timer[wEid] = Weapon.cooldown[wEid] * stats.cooldown;
        this.fireWeapon(wEid, px, py);
      }
    }
  }

  private fireWeapon(wEid: number, px: number, py: number): void {
    const weaponType = Weapon.type[wEid];
    const count = Weapon.count[wEid] + this.state.stats.amount;
    const damage = Weapon.damage[wEid] * this.state.stats.damage;
    const area = Weapon.area[wEid] * this.state.stats.area;
    const speed = Weapon.speed[wEid];
    const pierce = Weapon.pierce[wEid];
    const range = Weapon.range[wEid];

    switch (weaponType) {
      case WEAPON_TYPES.MAGIC_BOLT:
        this.fireProjectiles(px, py, count, damage, speed, pierce, range, weaponType, area);
        break;
      case WEAPON_TYPES.WHIP:
        this.fireWhip(px, py, count, damage, range, area);
        break;
      case WEAPON_TYPES.FIRE_CIRCLE:
        this.fireOrbitingProjectiles(px, py, count, damage, speed, range, area);
        break;
      case WEAPON_TYPES.HOLY_CROSS:
        this.fireBoomerang(px, py, count, damage, speed, pierce, range, area);
        break;
      case WEAPON_TYPES.GARLIC:
        this.createAreaDamage(px, py, damage, range * area, 0.5, 2.0, true);
        break;
      case WEAPON_TYPES.LIGHTNING:
        this.fireLightning(px, py, count, damage, range, pierce);
        break;
      case WEAPON_TYPES.SCYTHE:
        this.fireProjectiles(px, py, count, damage, speed, pierce, range, weaponType, area);
        break;
      case WEAPON_TYPES.BLOOD_WAVE:
        this.fireBloodWave(px, py, count, damage, speed, range, area);
        break;
    }
  }

  private fireProjectiles(px: number, py: number, count: number, damage: number, speed: number, pierce: number, range: number, weaponType: number, area: number): void {
    const { world } = this.state;

    // Find nearest enemies for targeting
    const enemyQuery = defineQuery([Enemy, EnemyTag, Position]);
    const enemies = enemyQuery(world);
    const targets: { eid: number; dist: number; angle: number }[] = [];

    for (const eid of enemies) {
      const dx = Position.x[eid] - px;
      const dy = Position.y[eid] - py;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < range * 2) {
        targets.push({ eid, dist, angle: Math.atan2(dy, dx) });
      }
    }
    targets.sort((a, b) => a.dist - b.dist);

    for (let i = 0; i < count; i++) {
      let angle: number;
      if (targets.length > 0) {
        const targetIdx = i % targets.length;
        angle = targets[targetIdx].angle + (Math.random() - 0.5) * 0.2;
      } else {
        angle = (Math.PI * 2 * i) / count;
      }

      const eid = addEntity(world);
      addComponent(world, Position, eid);
      addComponent(world, Velocity, eid);
      addComponent(world, Collision, eid);
      addComponent(world, Projectile, eid);
      addComponent(world, ProjectileTag, eid);
      addComponent(world, Lifetime, eid);
      addComponent(world, SpriteComponent, eid);

      Position.x[eid] = px;
      Position.y[eid] = py;
      Velocity.x[eid] = Math.cos(angle) * speed;
      Velocity.y[eid] = Math.sin(angle) * speed;
      Collision.radius[eid] = 5 * area;
      Projectile.damage[eid] = damage;
      Projectile.lifetime[eid] = range / speed + 0.5;
      Projectile.pierce[eid] = pierce;
      Projectile.ownerWeaponType[eid] = weaponType;
      Projectile.speed[eid] = speed;
      Lifetime.remaining[eid] = range / speed + 0.5;
      SpriteComponent.alpha[eid] = 1;

      this.createProjectileSprite(eid);
    }
  }

  private fireWhip(px: number, py: number, count: number, damage: number, range: number, area: number): void {
    const { world } = this.state;

    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + (Math.random() - 0.5) * 0.5;
      const eid = addEntity(world);
      addComponent(world, Position, eid);
      addComponent(world, Velocity, eid);
      addComponent(world, Collision, eid);
      addComponent(world, Projectile, eid);
      addComponent(world, ProjectileTag, eid);
      addComponent(world, Lifetime, eid);
      addComponent(world, SpriteComponent, eid);

      Position.x[eid] = px + Math.cos(angle) * 30;
      Position.y[eid] = py + Math.sin(angle) * 30;
      Velocity.x[eid] = Math.cos(angle) * 50;
      Velocity.y[eid] = Math.sin(angle) * 50;
      Collision.radius[eid] = range * area * 0.5;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = -1; // hits all
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.WHIP;
      Lifetime.remaining[eid] = 0.3;
      SpriteComponent.alpha[eid] = 1;
      SpriteComponent.rotation[eid] = angle;

      this.createProjectileSprite(eid);
    }
  }

  private fireOrbitingProjectiles(px: number, py: number, count: number, damage: number, speed: number, range: number, area: number): void {
    // Fire circle creates orbiting projectiles
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count;
      const { world } = this.state;

      const eid = addEntity(world);
      addComponent(world, Position, eid);
      addComponent(world, Velocity, eid);
      addComponent(world, Collision, eid);
      addComponent(world, Projectile, eid);
      addComponent(world, ProjectileTag, eid);
      addComponent(world, Lifetime, eid);
      addComponent(world, SpriteComponent, eid);

      Position.x[eid] = px + Math.cos(angle) * range * area;
      Position.y[eid] = py + Math.sin(angle) * range * area;
      // Orbit velocity (perpendicular)
      Velocity.x[eid] = Math.cos(angle + Math.PI / 2) * speed;
      Velocity.y[eid] = Math.sin(angle + Math.PI / 2) * speed;
      Collision.radius[eid] = 10 * area;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = -1;
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.FIRE_CIRCLE;
      Lifetime.remaining[eid] = 3.0;
      SpriteComponent.alpha[eid] = 1;

      this.createProjectileSprite(eid);
    }
  }

  private fireBoomerang(px: number, py: number, count: number, damage: number, speed: number, pierce: number, range: number, area: number): void {
    const { world } = this.state;

    const enemyQuery = defineQuery([Enemy, EnemyTag, Position]);
    const enemies = enemyQuery(world);
    let targetAngle = Math.random() * Math.PI * 2;

    if (enemies.length > 0) {
      let closest = Infinity;
      for (const eeid of enemies) {
        const dx = Position.x[eeid] - px;
        const dy = Position.y[eeid] - py;
        const dist = dx * dx + dy * dy;
        if (dist < closest) {
          closest = dist;
          targetAngle = Math.atan2(dy, dx);
        }
      }
    }

    for (let i = 0; i < count; i++) {
      const angle = targetAngle + (i - (count - 1) / 2) * 0.4;
      const eid = addEntity(world);
      addComponent(world, Position, eid);
      addComponent(world, Velocity, eid);
      addComponent(world, Collision, eid);
      addComponent(world, Projectile, eid);
      addComponent(world, ProjectileTag, eid);
      addComponent(world, Lifetime, eid);
      addComponent(world, SpriteComponent, eid);

      Position.x[eid] = px;
      Position.y[eid] = py;
      Velocity.x[eid] = Math.cos(angle) * speed;
      Velocity.y[eid] = Math.sin(angle) * speed;
      Collision.radius[eid] = 12 * area;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = pierce;
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.HOLY_CROSS;
      Projectile.speed[eid] = speed;
      Lifetime.remaining[eid] = 2.0;
      SpriteComponent.alpha[eid] = 1;

      this.createProjectileSprite(eid);
    }
  }

  private fireLightning(px: number, py: number, count: number, damage: number, range: number, chains: number): void {
    const { world } = this.state;
    const enemyQuery = defineQuery([Enemy, EnemyTag, Position, Health]);
    const enemies = enemyQuery(world);

    const inRange: number[] = [];
    for (const eid of enemies) {
      const dx = Position.x[eid] - px;
      const dy = Position.y[eid] - py;
      if (dx * dx + dy * dy < range * range) {
        inRange.push(eid);
      }
    }

    // Strike random enemies
    const strikes = Math.min(count, inRange.length);
    for (let i = 0; i < strikes; i++) {
      const targetIdx = Math.floor(Math.random() * inRange.length);
      const targetEid = inRange[targetIdx];

      // Apply damage
      Health.current[targetEid] -= damage * this.state.stats.damage;
      this.addDamageNumber(Position.x[targetEid], Position.y[targetEid], damage * this.state.stats.damage, 0x60a5fa);

      // Visual lightning bolt
      this.spawnLightningEffect(px, py, Position.x[targetEid], Position.y[targetEid]);

      // Chain to nearby enemies
      let chainSource = targetEid;
      for (let c = 0; c < chains; c++) {
        let closestDist = 150 * 150;
        let chainTarget = -1;
        for (const eeid of inRange) {
          if (eeid === chainSource) continue;
          const dx = Position.x[eeid] - Position.x[chainSource];
          const dy = Position.y[eeid] - Position.y[chainSource];
          const dist = dx * dx + dy * dy;
          if (dist < closestDist) {
            closestDist = dist;
            chainTarget = eeid;
          }
        }
        if (chainTarget >= 0) {
          Health.current[chainTarget] -= damage * this.state.stats.damage * 0.7;
          this.spawnLightningEffect(Position.x[chainSource], Position.y[chainSource], Position.x[chainTarget], Position.y[chainTarget]);
          chainSource = chainTarget;
        }
      }

      inRange.splice(targetIdx, 1);
    }
  }

  private spawnLightningEffect(x1: number, y1: number, x2: number, y2: number): void {
    // Create particle line effect
    const steps = 5;
    for (let i = 0; i < steps; i++) {
      const t = i / steps;
      const x = x1 + (x2 - x1) * t + (Math.random() - 0.5) * 20;
      const y = y1 + (y2 - y1) * t + (Math.random() - 0.5) * 20;
      this.spawnParticle(x, y, 0x60a5fa, 0.3);
    }
  }

  private fireBloodWave(px: number, py: number, count: number, damage: number, speed: number, range: number, area: number): void {
    const { world } = this.state;

    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count;
      const eid = addEntity(world);
      addComponent(world, Position, eid);
      addComponent(world, Velocity, eid);
      addComponent(world, Collision, eid);
      addComponent(world, Projectile, eid);
      addComponent(world, ProjectileTag, eid);
      addComponent(world, Lifetime, eid);
      addComponent(world, SpriteComponent, eid);

      Position.x[eid] = px;
      Position.y[eid] = py;
      Velocity.x[eid] = Math.cos(angle) * speed;
      Velocity.y[eid] = Math.sin(angle) * speed;
      Collision.radius[eid] = 15 * area;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = -1;
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.BLOOD_WAVE;
      Lifetime.remaining[eid] = range / speed;
      SpriteComponent.alpha[eid] = 1;
      SpriteComponent.rotation[eid] = angle;

      this.createProjectileSprite(eid);
    }
  }

  private createAreaDamage(x: number, y: number, damage: number, radius: number, tickRate: number, lifetime: number, followPlayer: boolean): void {
    const { world } = this.state;
    const eid = addEntity(world);
    addComponent(world, Position, eid);
    addComponent(world, AreaEffect, eid);
    addComponent(world, AreaEffectTag, eid);
    addComponent(world, Lifetime, eid);

    Position.x[eid] = x;
    Position.y[eid] = y;
    AreaEffect.damage[eid] = damage;
    AreaEffect.radius[eid] = radius;
    AreaEffect.tickRate[eid] = tickRate;
    AreaEffect.tickTimer[eid] = 0;
    AreaEffect.lifetime[eid] = lifetime;
    AreaEffect.followPlayer[eid] = followPlayer ? 1 : 0;
    Lifetime.remaining[eid] = lifetime;
  }

  // ============================================================
  // AREA EFFECTS SYSTEM
  // ============================================================

  private updateAreaEffects(dt: number): void {
    const { world, playerEid, stats } = this.state;
    const areaQuery = defineQuery([AreaEffect, AreaEffectTag, Position]);
    const areas = areaQuery(world);

    for (const eid of areas) {
      // Follow player
      if (AreaEffect.followPlayer[eid]) {
        Position.x[eid] = Position.x[playerEid];
        Position.y[eid] = Position.y[playerEid];
      }

      AreaEffect.tickTimer[eid] -= dt;
      if (AreaEffect.tickTimer[eid] <= 0) {
        AreaEffect.tickTimer[eid] = AreaEffect.tickRate[eid];

        // Damage enemies in radius
        const ax = Position.x[eid];
        const ay = Position.y[eid];
        const radius = AreaEffect.radius[eid] * stats.area;
        const damage = AreaEffect.damage[eid] * stats.damage;

        const enemyQuery = defineQuery([Enemy, EnemyTag, Position, Health]);
        const enemies = enemyQuery(world);
        for (const eeid of enemies) {
          const dx = Position.x[eeid] - ax;
          const dy = Position.y[eeid] - ay;
          if (dx * dx + dy * dy < radius * radius) {
            Health.current[eeid] -= damage;
            // Knockback
            const dist = Math.sqrt(dx * dx + dy * dy) || 1;
            Enemy.knockbackX[eeid] += (dx / dist) * 200;
            Enemy.knockbackY[eeid] += (dy / dist) * 200;
            this.addDamageNumber(Position.x[eeid], Position.y[eeid], damage, 0x4ade80);
          }
        }

        // Visual pulse
        this.spawnParticle(ax, ay, 0x4ade80, 0.5);
      }
    }
  }

  // ============================================================
  // PROJECTILE SYSTEM
  // ============================================================

  private updateProjectiles(dt: number): void {
    const { world, playerEid } = this.state;
    const projQuery = defineQuery([Projectile, ProjectileTag, Position]);
    const projs = projQuery(world);

    for (const eid of projs) {
      // Boomerang return logic
      if (Projectile.ownerWeaponType[eid] === WEAPON_TYPES.HOLY_CROSS) {
        const lifetime = Lifetime.remaining[eid];
        if (lifetime < 1.0) {
          // Return to player
          const dx = Position.x[playerEid] - Position.x[eid];
          const dy = Position.y[playerEid] - Position.y[eid];
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist > 1) {
            const speed = Projectile.speed[eid] * 1.5;
            Velocity.x[eid] = (dx / dist) * speed;
            Velocity.y[eid] = (dy / dist) * speed;
          }
        }
      }

      // Scythe spinning
      if (Projectile.ownerWeaponType[eid] === WEAPON_TYPES.SCYTHE) {
        SpriteComponent.rotation[eid] += dt * 10;
      }
    }
  }

  // ============================================================
  // COLLISION SYSTEM
  // ============================================================

  private updateCollisions(dt: number): void {
    const { world, playerEid, stats } = this.state;

    // Projectile vs Enemy
    const projQuery = defineQuery([Projectile, ProjectileTag, Position, Collision]);
    const enemyQuery = defineQuery([Enemy, EnemyTag, Position, Collision, Health]);
    const projs = projQuery(world);
    const enemies = enemyQuery(world);

    const projsToRemove: number[] = [];

    for (const pEid of projs) {
      const px = Position.x[pEid];
      const py = Position.y[pEid];
      const pr = Collision.radius[pEid];

      for (const eEid of enemies) {
        const ex = Position.x[eEid];
        const ey = Position.y[eEid];
        const er = Collision.radius[eEid];
        const dx = px - ex;
        const dy = py - ey;
        const distSq = dx * dx + dy * dy;
        const minDist = pr + er;

        if (distSq < minDist * minDist) {
          // Hit!
          const damage = Projectile.damage[pEid];
          Health.current[eEid] -= damage;

          // Knockback
          const dist = Math.sqrt(distSq) || 1;
          Enemy.knockbackX[eEid] += (dx / dist) * -150;
          Enemy.knockbackY[eEid] += (dy / dist) * -150;

          this.addDamageNumber(ex, ey, damage, getWeaponDef(Projectile.ownerWeaponType[pEid]).color);

          // Check pierce
          if (Projectile.pierce[pEid] !== -1) {
            Projectile.pierce[pEid]--;
            if (Projectile.pierce[pEid] <= 0) {
              projsToRemove.push(pEid);
              break;
            }
          }
        }
      }
    }

    // Remove spent projectiles
    for (const eid of projsToRemove) {
      this.removeEntity(eid);
    }

    // Check enemy deaths
    for (const eEid of enemies) {
      if (Health.current[eEid] <= 0) {
        this.onEnemyDeath(eEid);
      }
    }

    // Enemy vs Player
    const pHealth = Health.current[playerEid];
    if (Health.invincibleTimer[playerEid] > 0) {
      Health.invincibleTimer[playerEid] -= dt;
    } else {
      for (const eEid of enemies) {
        const dx = Position.x[playerEid] - Position.x[eEid];
        const dy = Position.y[playerEid] - Position.y[eEid];
        const distSq = dx * dx + dy * dy;
        const minDist = Collision.radius[playerEid] + Collision.radius[eEid];

        if (distSq < minDist * minDist) {
          Enemy.attackTimer[eEid] -= dt;
          if (Enemy.attackTimer[eEid] <= 0) {
            const damage = Math.max(1, Enemy.damage[eEid] * (1 - stats.armor));
            Health.current[playerEid] -= damage;
            Health.invincibleTimer[playerEid] = 0.2;
            Enemy.attackTimer[eEid] = Enemy.attackCooldown[eEid];
            this.state.screenShake = 5;
            this.addDamageNumber(Position.x[playerEid], Position.y[playerEid], damage, 0xef4444);

            // Push player away
            const dist = Math.sqrt(distSq) || 1;
            Position.x[playerEid] += (dx / dist) * 20;
            Position.y[playerEid] += (dy / dist) * 20;

            if (Health.current[playerEid] <= 0) {
              this.onGameOver();
              return;
            }
          }
        }
      }
    }
  }

  private onEnemyDeath(eid: number): void {
    const { world } = this.state;

    // Drop XP gem
    this.spawnXPGem(Position.x[eid], Position.y[eid], Enemy.xpDrop[eid]);

    // Death particles
    const color = getEnemyDef(Enemy.type[eid]).color;
    for (let i = 0; i < 6; i++) {
      this.spawnParticle(Position.x[eid], Position.y[eid], color, 0.6);
    }

    this.state.killCount++;
    this.state.enemyCount--;
    this.removeEntity(eid);
  }

  private spawnXPGem(x: number, y: number, value: number): void {
    const { world } = this.state;
    const eid = addEntity(world);
    addComponent(world, Position, eid);
    addComponent(world, Velocity, eid);
    addComponent(world, XPGem, eid);
    addComponent(world, XPGemTag, eid);
    addComponent(world, Collision, eid);
    addComponent(world, SpriteComponent, eid);

    Position.x[eid] = x + (Math.random() - 0.5) * 20;
    Position.y[eid] = y + (Math.random() - 0.5) * 20;
    XPGem.value[eid] = value;
    Collision.radius[eid] = 8;
    SpriteComponent.alpha[eid] = 1;

    this.createXPGemSprite(eid);
  }

  // ============================================================
  // XP COLLECTION SYSTEM
  // ============================================================

  private updateXPCollection(dt: number): void {
    const { world, playerEid, stats } = this.state;
    const px = Position.x[playerEid];
    const py = Position.y[playerEid];
    const magnetRange = MAGNET_BASE_RANGE * stats.magnet;

    const gemQuery = defineQuery([XPGem, XPGemTag, Position]);
    const gems = gemQuery(world);
    const toCollect: number[] = [];

    for (const eid of gems) {
      const dx = px - Position.x[eid];
      const dy = py - Position.y[eid];
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < magnetRange) {
        // Magnetize toward player
        const speed = 300 + (magnetRange - dist) * 3;
        Position.x[eid] += (dx / dist) * speed * dt;
        Position.y[eid] += (dy / dist) * speed * dt;
        XPGem.magnetized[eid] = 1;
      }

      if (dist < 20) {
        toCollect.push(eid);
      }
    }

    for (const eid of toCollect) {
      const xpValue = XPGem.value[eid] * stats.xpBonus;
      Player.xp[playerEid] += xpValue;

      // Check level up
      while (Player.xp[playerEid] >= Player.xpToNext[playerEid]) {
        Player.xp[playerEid] -= Player.xpToNext[playerEid];
        Player.level[playerEid]++;
        const level = Player.level[playerEid];
        Player.xpToNext[playerEid] = XP_TABLE[Math.min(level - 1, XP_TABLE.length - 1)];
        this.onLevelUp();
      }

      this.removeEntity(eid);
    }
  }

  // ============================================================
  // LEVEL UP SYSTEM
  // ============================================================

  private onLevelUp(): void {
    this.state.levelUpActive = true;
    this.state.screenShake = 3;

    // Generate choices
    const choices: LevelUpChoice[] = [];
    const numChoices = 3;

    // Collect possible upgrades
    const possible: LevelUpChoice[] = [];

    // New weapons (not yet acquired)
    for (let i = 0; i < WEAPONS.length; i++) {
      if (!this.state.weaponLevels.has(i) && this.state.weaponLevels.size < 6) {
        possible.push({
          type: 'weapon',
          index: i,
          name: WEAPONS[i].name,
          description: WEAPONS[i].description,
          color: WEAPONS[i].color,
          level: 0,
          maxLevel: WEAPONS[i].maxLevel,
        });
      }
    }

    // Weapon upgrades
    this.state.weaponLevels.forEach((level, type) => {
      if (level < WEAPONS[type].maxLevel) {
        possible.push({
          type: 'weapon',
          index: type,
          name: WEAPONS[type].name,
          description: WEAPONS[type].upgrades[level - 1] || '+25% Stats',
          color: WEAPONS[type].color,
          level,
          maxLevel: WEAPONS[type].maxLevel,
        });
      }
    });

    // Passive upgrades
    for (let i = 0; i < PASSIVE_UPGRADES.length; i++) {
      if (this.state.passiveLevels[i] < PASSIVE_UPGRADES[i].maxLevel) {
        possible.push({
          type: 'passive',
          index: i,
          name: PASSIVE_UPGRADES[i].name,
          description: PASSIVE_UPGRADES[i].description,
          color: PASSIVE_UPGRADES[i].color,
          level: this.state.passiveLevels[i],
          maxLevel: PASSIVE_UPGRADES[i].maxLevel,
        });
      }
    }

    // Shuffle and pick
    for (let i = possible.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [possible[i], possible[j]] = [possible[j], possible[i]];
    }

    for (let i = 0; i < Math.min(numChoices, possible.length); i++) {
      choices.push(possible[i]);
    }

    this.state.levelUpChoices = choices;
    this.showLevelUpUI();
  }

  private showLevelUpUI(): void {
    this.levelUpContainer.removeChildren();
    this.levelUpContainer.visible = true;

    const w = window.innerWidth;
    const h = window.innerHeight;

    // Dim background
    const dim = new PIXI.Graphics();
    dim.rect(0, 0, w, h).fill({ color: 0x000000, alpha: 0.7 });
    dim.interactive = true;
    this.levelUpContainer.addChild(dim);

    // Title
    const title = new PIXI.Text({
      text: `LEVEL UP! (Lv.${Player.level[this.state.playerEid]})`,
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 36,
        fontWeight: 'bold',
        fill: 0xfbbf24,
      },
    });
    title.anchor.set(0.5);
    title.position.set(w / 2, h / 2 - 160);
    this.levelUpContainer.addChild(title);

    // Choice cards
    const cardWidth = 220;
    const cardHeight = 140;
    const totalWidth = this.state.levelUpChoices.length * (cardWidth + 20) - 20;
    const startX = (w - totalWidth) / 2;

    this.state.levelUpChoices.forEach((choice, i) => {
      const card = new PIXI.Container();
      card.position.set(startX + i * (cardWidth + 20), h / 2 - cardHeight / 2);
      card.interactive = true;
      card.cursor = 'pointer';

      const bg = new PIXI.Graphics();
      bg.roundRect(0, 0, cardWidth, cardHeight, 10).fill({ color: 0x1a1a2e });
      bg.roundRect(0, 0, cardWidth, cardHeight, 10).stroke({ color: choice.color, width: 2, alpha: 0.8 });
      card.addChild(bg);

      // Color accent bar
      const accent = new PIXI.Graphics();
      accent.rect(0, 0, cardWidth, 4).fill({ color: choice.color });
      card.addChild(accent);

      const nameText = new PIXI.Text({
        text: choice.name,
        style: {
          fontFamily: 'Segoe UI, sans-serif',
          fontSize: 16,
          fontWeight: 'bold',
          fill: 0xffffff,
        },
      });
      nameText.position.set(15, 20);
      card.addChild(nameText);

      const levelText = new PIXI.Text({
        text: choice.level === 0 ? 'NEW!' : `Lv.${choice.level} → ${choice.level + 1}`,
        style: {
          fontFamily: 'Segoe UI, sans-serif',
          fontSize: 12,
          fill: choice.level === 0 ? 0x4ade80 : 0x8b8b9a,
        },
      });
      levelText.position.set(15, 45);
      card.addChild(levelText);

      const descText = new PIXI.Text({
        text: choice.description,
        style: {
          fontFamily: 'Segoe UI, sans-serif',
          fontSize: 13,
          fill: 0xccccdd,
          wordWrap: true,
          wordWrapWidth: cardWidth - 30,
        },
      });
      descText.position.set(15, 70);
      card.addChild(descText);

      // Key hint
      const keyText = new PIXI.Text({
        text: `[${i + 1}]`,
        style: {
          fontFamily: 'Segoe UI, sans-serif',
          fontSize: 14,
          fill: 0x666677,
        },
      });
      keyText.position.set(cardWidth - 30, cardHeight - 25);
      card.addChild(keyText);

      card.on('pointerdown', () => this.selectUpgrade(i));
      this.levelUpContainer.addChild(card);
    });

    // Key listener for number keys
    const keyHandler = (e: KeyboardEvent) => {
      const num = parseInt(e.key);
      if (num >= 1 && num <= this.state.levelUpChoices.length) {
        window.removeEventListener('keydown', keyHandler);
        this.selectUpgrade(num - 1);
      }
    };
    window.addEventListener('keydown', keyHandler);
  }

  private selectUpgrade(index: number): void {
    const choice = this.state.levelUpChoices[index];
    if (!choice) return;

    if (choice.type === 'weapon') {
      if (choice.level === 0) {
        // New weapon
        this.addWeaponToPlayer(choice.index);
      } else {
        // Upgrade existing
        this.upgradeWeapon(choice.index);
      }
    } else {
      // Passive upgrade
      this.state.passiveLevels[choice.index]++;
      const upgrade = PASSIVE_UPGRADES[choice.index];
      const statKey = upgrade.effect as keyof PlayerStats;
      if (statKey === 'cooldown' || statKey === 'armor') {
        (this.state.stats[statKey] as number) -= upgrade.valuePerLevel;
      } else {
        (this.state.stats[statKey] as number) += upgrade.valuePerLevel;
      }
      // Apply max HP
      if (statKey === 'maxHp') {
        Health.max[this.state.playerEid] = this.state.stats.maxHp;
        Health.current[this.state.playerEid] = Math.min(Health.current[this.state.playerEid] + upgrade.valuePerLevel, Health.max[this.state.playerEid]);
      }
    }

    this.state.levelUpActive = false;
    this.levelUpContainer.visible = false;

    // Level up particles
    for (let i = 0; i < 15; i++) {
      this.spawnParticle(Position.x[this.state.playerEid], Position.y[this.state.playerEid], 0xfbbf24, 0.8);
    }
  }

  // ============================================================
  // LIFETIME SYSTEM
  // ============================================================

  private updateLifetimes(dt: number): void {
    const { world } = this.state;
    const lifetimeQuery = defineQuery([Lifetime]);
    const entities = lifetimeQuery(world);
    const toRemove: number[] = [];

    for (const eid of entities) {
      Lifetime.remaining[eid] -= dt;
      if (Lifetime.remaining[eid] <= 0) {
        toRemove.push(eid);
      }
    }

    for (const eid of toRemove) {
      this.removeEntity(eid);
    }
  }

  // ============================================================
  // PARTICLE SYSTEM
  // ============================================================

  private spawnParticle(x: number, y: number, color: number, lifetime: number): void {
    const { world } = this.state;
    const eid = addEntity(world);
    addComponent(world, Position, eid);
    addComponent(world, Velocity, eid);
    addComponent(world, Particle, eid);
    addComponent(world, ParticleTag, eid);
    addComponent(world, Lifetime, eid);
    addComponent(world, SpriteComponent, eid);

    Position.x[eid] = x;
    Position.y[eid] = y;
    Velocity.x[eid] = (Math.random() - 0.5) * 200;
    Velocity.y[eid] = -Math.random() * 150 - 50;
    Lifetime.remaining[eid] = lifetime;
    SpriteComponent.alpha[eid] = 1;
    SpriteComponent.tint[eid] = color;
    SpriteComponent.scaleX[eid] = 1;

    // Create particle sprite
    const gfx = new PIXI.Graphics();
    gfx.circle(0, 0, 3 + Math.random() * 3).fill({ color });
    gfx.position.set(x, y);
    this.particleContainer.addChild(gfx);
    this.state.entitySprites.set(eid, gfx);
  }

  private updateParticles(dt: number): void {
    const { world } = this.state;
    const particleQuery = defineQuery([Particle, ParticleTag, Position, Lifetime]);
    const particles = particleQuery(world);

    for (const eid of particles) {
      const sprite = this.state.entitySprites.get(eid);
      if (sprite) {
        const remaining = Lifetime.remaining[eid];
        sprite.alpha = Math.max(0, remaining * 2);
        sprite.scale.set(Math.max(0.1, remaining));
      }
    }
  }

  // ============================================================
  // DAMAGE NUMBERS
  // ============================================================

  private addDamageNumber(x: number, y: number, value: number, color: number): void {
    this.state.damageNumbers.push({
      x: x + (Math.random() - 0.5) * 20,
      y: y - 10,
      value: Math.round(value),
      timer: 0.8,
      vy: -60,
      color,
    });
  }

  private updateDamageNumbers(dt: number): void {
    for (let i = this.state.damageNumbers.length - 1; i >= 0; i--) {
      const dn = this.state.damageNumbers[i];
      dn.timer -= dt;
      dn.y += dn.vy * dt;
      dn.vy += 50 * dt;
      if (dn.timer <= 0) {
        this.state.damageNumbers.splice(i, 1);
      }
    }
  }

  // ============================================================
  // CAMERA SYSTEM
  // ============================================================

  private updateCamera(dt: number): void {
    const { playerEid } = this.state;
    const targetX = Position.x[playerEid];
    const targetY = Position.y[playerEid];

    // Smooth follow
    this.state.cameraX += (targetX - this.state.cameraX) * 5 * dt;
    this.state.cameraY += (targetY - this.state.cameraY) * 5 * dt;

    const screenW = window.innerWidth;
    const screenH = window.innerHeight;

    let offsetX = screenW / 2 - this.state.cameraX;
    let offsetY = screenH / 2 - this.state.cameraY;

    // Screen shake
    if (this.state.screenShake > 0) {
      offsetX += (Math.random() - 0.5) * this.state.screenShake * 2;
      offsetY += (Math.random() - 0.5) * this.state.screenShake * 2;
    }

    this.gameContainer.position.set(offsetX, offsetY);
  }

  // ============================================================
  // SPRITE UPDATE
  // ============================================================

  private updateSprites(): void {
    const { world, playerEid } = this.state;

    // Update all entity positions on screen
    this.state.entitySprites.forEach((sprite, eid) => {
      if (hasComponent(world, Position, eid)) {
        sprite.position.set(Position.x[eid], Position.y[eid]);

        // Rotation for projectiles
        if (hasComponent(world, Projectile, eid)) {
          if (Projectile.ownerWeaponType[eid] === WEAPON_TYPES.SCYTHE ||
              Projectile.ownerWeaponType[eid] === WEAPON_TYPES.HOLY_CROSS) {
            sprite.rotation = SpriteComponent.rotation[eid];
          } else if (Velocity.x[eid] !== 0 || Velocity.y[eid] !== 0) {
            sprite.rotation = Math.atan2(Velocity.y[eid], Velocity.x[eid]);
          }
        }

        // Fade out near death for projectiles
        if (hasComponent(world, Lifetime, eid) && hasComponent(world, Projectile, eid)) {
          const remaining = Lifetime.remaining[eid];
          if (remaining < 0.3) {
            sprite.alpha = remaining / 0.3;
          }
        }

        // Player invincibility flash
        if (eid === playerEid && Health.invincibleTimer[playerEid] > 0) {
          sprite.alpha = Math.sin(Health.invincibleTimer[playerEid] * 30) > 0 ? 1 : 0.3;
        } else if (eid === playerEid) {
          sprite.alpha = 1;
        }

        // XP gem bobbing
        if (hasComponent(world, XPGem, eid)) {
          sprite.scale.set(0.8 + Math.sin(this.state.gameTime * 4 + eid) * 0.2);
        }
      }
    });
  }

  // ============================================================
  // HUD DRAWING
  // ============================================================

  private drawHUD(): void {
    const g = this.hudGraphics;
    g.clear();

    const w = window.innerWidth;
    const h = window.innerHeight;
    const { playerEid, gameTime, killCount, stats } = this.state;

    // HP Bar
    const hpWidth = 250;
    const hpHeight = 16;
    const hpX = 20;
    const hpY = 20;
    const hpRatio = Health.current[playerEid] / Health.max[playerEid];

    g.roundRect(hpX, hpY, hpWidth, hpHeight, 4).fill({ color: 0x1a1a2e });
    g.roundRect(hpX, hpY, hpWidth * hpRatio, hpHeight, 4).fill({ color: hpRatio > 0.3 ? 0x4ade80 : 0xef4444 });
    g.roundRect(hpX, hpY, hpWidth, hpHeight, 4).stroke({ color: 0x333344, width: 1 });

    // XP Bar
    const xpWidth = 250;
    const xpHeight = 8;
    const xpX = 20;
    const xpY = 42;
    const xpRatio = Player.xp[playerEid] / Player.xpToNext[playerEid];

    g.roundRect(xpX, xpY, xpWidth, xpHeight, 3).fill({ color: 0x1a1a2e });
    g.roundRect(xpX, xpY, xpWidth * xpRatio, xpHeight, 3).fill({ color: 0xa855f7 });

    // Timer
    const minutes = Math.floor(gameTime / 60);
    const seconds = Math.floor(gameTime % 60);
    const timerText = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    // Remove old text children and redraw
    while (this.uiContainer.children.length > 3) {
      this.uiContainer.removeChildAt(3);
    }

    const timerDisplay = new PIXI.Text({
      text: timerText,
      style: { fontFamily: 'Segoe UI', fontSize: 28, fontWeight: 'bold', fill: 0xffffff },
    });
    timerDisplay.anchor.set(0.5, 0);
    timerDisplay.position.set(w / 2, 10);
    this.uiContainer.addChild(timerDisplay);

    // Kill counter
    const killDisplay = new PIXI.Text({
      text: `Kills: ${killCount}`,
      style: { fontFamily: 'Segoe UI', fontSize: 14, fill: 0x8b8b9a },
    });
    killDisplay.position.set(20, 58);
    this.uiContainer.addChild(killDisplay);

    // Level
    const levelDisplay = new PIXI.Text({
      text: `Lv.${Player.level[playerEid]}`,
      style: { fontFamily: 'Segoe UI', fontSize: 16, fontWeight: 'bold', fill: 0xfbbf24 },
    });
    levelDisplay.position.set(hpX + hpWidth + 10, hpY);
    this.uiContainer.addChild(levelDisplay);

    // Weapon icons
    let weaponY = h - 60;
    this.state.weaponLevels.forEach((level, type) => {
      const def = getWeaponDef(type);
      g.roundRect(20, weaponY, 180, 22, 4).fill({ color: 0x1a1a2e, alpha: 0.8 });
      g.rect(20, weaponY, 4, 22).fill({ color: def.color });

      const wText = new PIXI.Text({
        text: `${def.name} Lv.${level}`,
        style: { fontFamily: 'Segoe UI', fontSize: 12, fill: 0xccccdd },
      });
      wText.position.set(30, weaponY + 4);
      this.uiContainer.addChild(wText);

      weaponY -= 28;
    });

    // Damage numbers (world space)
    for (const dn of this.state.damageNumbers) {
      const screenX = dn.x - this.state.cameraX + w / 2;
      const screenY = dn.y - this.state.cameraY + h / 2;
      if (screenX > -50 && screenX < w + 50 && screenY > -50 && screenY < h + 50) {
        const dmgText = new PIXI.Text({
          text: `${dn.value}`,
          style: {
            fontFamily: 'Segoe UI',
            fontSize: 14 + dn.value / 5,
            fontWeight: 'bold',
            fill: dn.color,
          },
        });
        dmgText.anchor.set(0.5);
        dmgText.position.set(screenX, screenY);
        dmgText.alpha = Math.min(1, dn.timer * 2);
        this.uiContainer.addChild(dmgText);
      }
    }

    // HP text
    const hpText = new PIXI.Text({
      text: `${Math.ceil(Health.current[playerEid])}/${Math.ceil(Health.max[playerEid])}`,
      style: { fontFamily: 'Segoe UI', fontSize: 11, fill: 0xffffff },
    });
    hpText.anchor.set(0.5);
    hpText.position.set(hpX + hpWidth / 2, hpY + hpHeight / 2);
    this.uiContainer.addChild(hpText);
  }

  // ============================================================
  // MINIMAP
  // ============================================================

  private drawMinimap(): void {
    const g = this.minimapGraphics;
    g.clear();

    const w = window.innerWidth;
    const mapSize = 120;
    const mapX = w - mapSize - 15;
    const mapY = 15;
    const scale = mapSize / WORLD_SIZE;

    // Background
    g.roundRect(mapX, mapY, mapSize, mapSize, 4).fill({ color: 0x0a0a0f, alpha: 0.8 });
    g.roundRect(mapX, mapY, mapSize, mapSize, 4).stroke({ color: 0x333344, width: 1 });

    // Enemies (red dots)
    const { world, playerEid } = this.state;
    const enemyQuery = defineQuery([Enemy, EnemyTag, Position]);
    const enemies = enemyQuery(world);
    for (const eid of enemies) {
      const ex = mapX + Position.x[eid] * scale;
      const ey = mapY + Position.y[eid] * scale;
      g.circle(ex, ey, 1).fill({ color: 0xef4444 });
    }

    // XP gems (green dots)
    const gemQuery = defineQuery([XPGem, XPGemTag, Position]);
    const gems = gemQuery(world);
    for (const eid of gems) {
      const gx = mapX + Position.x[eid] * scale;
      const gy = mapY + Position.y[eid] * scale;
      g.circle(gx, gy, 1).fill({ color: 0x4ade80, alpha: 0.5 });
    }

    // Player (white dot)
    const px = mapX + Position.x[playerEid] * scale;
    const py = mapY + Position.y[playerEid] * scale;
    g.circle(px, py, 3).fill({ color: 0xc4a0ff });
  }

  // ============================================================
  // GAME OVER
  // ============================================================

  private onGameOver(): void {
    this.state.gameOver = true;
    this.gameOverContainer.removeChildren();
    this.gameOverContainer.visible = true;

    const w = window.innerWidth;
    const h = window.innerHeight;

    const bg = new PIXI.Graphics();
    bg.rect(0, 0, w, h).fill({ color: 0x000000, alpha: 0.85 });
    this.gameOverContainer.addChild(bg);

    const title = new PIXI.Text({
      text: 'YOU DIED',
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 64,
        fontWeight: 'bold',
        fill: 0xef4444,
        dropShadow: true,
        dropShadowColor: 0x7f0000,
        dropShadowBlur: 20,
        dropShadowDistance: 0,
      },
    });
    title.anchor.set(0.5);
    title.position.set(w / 2, h / 2 - 80);
    this.gameOverContainer.addChild(title);

    const minutes = Math.floor(this.state.gameTime / 60);
    const seconds = Math.floor(this.state.gameTime % 60);

    const statsText = new PIXI.Text({
      text: `Time: ${minutes}:${seconds.toString().padStart(2, '0')}  |  Kills: ${this.state.killCount}  |  Level: ${Player.level[this.state.playerEid]}`,
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 20,
        fill: 0xccccdd,
      },
    });
    statsText.anchor.set(0.5);
    statsText.position.set(w / 2, h / 2);
    this.gameOverContainer.addChild(statsText);

    const restart = new PIXI.Text({
      text: 'Press any key to restart',
      style: {
        fontFamily: 'Segoe UI, sans-serif',
        fontSize: 16,
        fill: 0x8b8b9a,
      },
    });
    restart.anchor.set(0.5);
    restart.position.set(w / 2, h / 2 + 60);
    this.gameOverContainer.addChild(restart);
  }

  // ============================================================
  // ENTITY REMOVAL
  // ============================================================

  private removeEntity(eid: number): void {
    const { world } = this.state;
    const sprite = this.state.entitySprites.get(eid);
    if (sprite) {
      sprite.destroy();
      this.state.entitySprites.delete(eid);
    }
    removeEntity(world, eid);
  }
}

// ============================================================
// BOOTSTRAP
// ============================================================

const game = new Game();
game.init().catch(console.error);
