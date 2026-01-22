import * as PIXI from 'pixi.js';
import {
  createWorld, addEntity, removeEntity, addComponent,
  hasComponent, defineQuery,
  IWorld,
} from 'bitecs';
import {
  Position, Velocity, Health, Collision, Player, Enemy,
  Weapon, Projectile, XPGem, SpriteComponent, Lifetime,
  Particle, AreaEffect, PlayerTag, EnemyTag, ProjectileTag,
  XPGemTag, ParticleTag, WeaponTag, AreaEffectTag,
} from './ecs/components';
import { WEAPONS, WEAPON_TYPES, getWeaponDef } from './data/weapons';
import { ENEMY_TYPES, getEnemyDef, WAVES, WaveConfig } from './data/enemies';
import { PASSIVE_UPGRADES, PlayerStats, BASE_STATS, XP_TABLE } from './data/upgrades';
import { TextureAtlas, generateTextureAtlas } from './textures';

// ============================================================
// QUERIES - Defined ONCE, not per frame
// ============================================================
const enemyQuery = defineQuery([Enemy, EnemyTag, Position, Velocity]);
const enemyPosQuery = defineQuery([Enemy, EnemyTag, Position]);
const enemyHealthQuery = defineQuery([Enemy, EnemyTag, Position, Health]);
const enemyCollisionQuery = defineQuery([Enemy, EnemyTag, Position, Collision, Health]);
const projQuery = defineQuery([Projectile, ProjectileTag, Position, Velocity]);
const projCollisionQuery = defineQuery([Projectile, ProjectileTag, Position, Collision]);
const particleQuery = defineQuery([Particle, ParticleTag, Position, Velocity]);
const particleLifeQuery = defineQuery([Particle, ParticleTag, Position, Lifetime]);
const gemQuery = defineQuery([XPGem, XPGemTag, Position]);
const weaponQuery = defineQuery([Weapon, WeaponTag]);
const areaQuery = defineQuery([AreaEffect, AreaEffectTag, Position]);
const lifetimeQuery = defineQuery([Lifetime]);

// ============================================================
// CONSTANTS
// ============================================================
const WORLD_SIZE = 4000;
const MAGNET_BASE_RANGE = 80;
const MAX_ENEMIES = 200;
const MAX_PARTICLES = 60;
const MAX_XP_GEMS = 80;
const MAX_DAMAGE_NUMBERS = 25;
const SPAWN_DISTANCE = 550;
const TILE_SIZE = 64;
const GRID_CELL_SIZE = 128;
const GRID_SIZE = Math.ceil(WORLD_SIZE / GRID_CELL_SIZE);

// ============================================================
// SPATIAL GRID
// ============================================================
class SpatialGrid {
  private cells: Map<number, number[]> = new Map();

  clear(): void {
    this.cells.clear();
  }

  private key(cx: number, cy: number): number {
    return cy * GRID_SIZE + cx;
  }

  insert(eid: number, x: number, y: number): void {
    const cx = Math.floor(x / GRID_CELL_SIZE);
    const cy = Math.floor(y / GRID_CELL_SIZE);
    const k = this.key(cx, cy);
    const cell = this.cells.get(k);
    if (cell) {
      cell.push(eid);
    } else {
      this.cells.set(k, [eid]);
    }
  }

  query(x: number, y: number, radius: number): number[] {
    const result: number[] = [];
    const minCx = Math.max(0, Math.floor((x - radius) / GRID_CELL_SIZE));
    const maxCx = Math.min(GRID_SIZE - 1, Math.floor((x + radius) / GRID_CELL_SIZE));
    const minCy = Math.max(0, Math.floor((y - radius) / GRID_CELL_SIZE));
    const maxCy = Math.min(GRID_SIZE - 1, Math.floor((y + radius) / GRID_CELL_SIZE));

    for (let cy = minCy; cy <= maxCy; cy++) {
      for (let cx = minCx; cx <= maxCx; cx++) {
        const cell = this.cells.get(this.key(cx, cy));
        if (cell) {
          for (let i = 0; i < cell.length; i++) {
            result.push(cell[i]);
          }
        }
      }
    }
    return result;
  }
}

// ============================================================
// OBJECT POOLS
// ============================================================
interface DamageNumber {
  x: number;
  y: number;
  value: number;
  timer: number;
  vy: number;
  color: number;
  active: boolean;
}

interface ParticlePool {
  sprites: PIXI.Sprite[];
  eids: number[];
  count: number;
}

// ============================================================
// GAME STATE
// ============================================================
interface GameState {
  world: IWorld;
  playerEid: number;
  stats: PlayerStats;
  passiveLevels: number[];
  weaponLevels: Map<number, number>;
  gameTime: number;
  paused: boolean;
  levelUpActive: boolean;
  levelUpChoices: LevelUpChoice[];
  gameOver: boolean;
  cameraX: number;
  cameraY: number;
  keys: Set<string>;
  entitySprites: Map<number, PIXI.Sprite>;
  currentWaveIndex: number;
  waveSpawnTimers: Map<number, { config: WaveConfig; spawned: number; timer: number }>;
  enemyCount: number;
  maxEnemies: number;
  screenShake: number;
  killCount: number;
  damageNumbers: DamageNumber[];
  particleCount: number;
  xpGemCount: number;
  enemyGrid: SpatialGrid;
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

// ============================================================
// MAIN GAME CLASS
// ============================================================
class Game {
  private app: PIXI.Application;
  private gameContainer!: PIXI.Container;
  private uiContainer!: PIXI.Container;
  private bgContainer!: PIXI.Container;
  private entityContainer!: PIXI.Container;
  private particleContainer!: PIXI.Container;
  private levelUpContainer!: PIXI.Container;
  private dmgNumberContainer!: PIXI.Container;
  private state!: GameState;
  private lastTime: number = 0;
  private titleScreen: boolean = true;
  private titleContainer!: PIXI.Container;
  private gameOverContainer!: PIXI.Container;
  private atlas!: TextureAtlas;

  // Persistent HUD elements (never recreated)
  private hudGraphics!: PIXI.Graphics;
  private hudTimerText!: PIXI.Text;
  private hudKillText!: PIXI.Text;
  private hudLevelText!: PIXI.Text;
  private hudHpText!: PIXI.Text;
  private hudWeaponTexts: PIXI.Text[] = [];
  private minimapGraphics!: PIXI.Graphics;

  // Pooled damage number texts
  private dmgTextPool: PIXI.Text[] = [];

  // Key handler ref for cleanup
  private levelUpKeyHandler: ((e: KeyboardEvent) => void) | null = null;

  constructor() {
    this.app = new PIXI.Application({
      width: window.innerWidth,
      height: window.innerHeight,
      backgroundColor: 0x0a0a0f,
      antialias: false,
      resolution: 1,
    });
  }

  init(): void {
    const loadingEl = document.getElementById('loading');
    if (loadingEl) loadingEl.remove();

    document.body.appendChild(this.app.view as HTMLCanvasElement);

    // Generate all textures once
    this.atlas = generateTextureAtlas();

    window.addEventListener('resize', () => {
      this.app.renderer.resize(window.innerWidth, window.innerHeight);
    });

    this.setupContainers();
    this.setupHUD();
    this.setupDamageNumberPool();
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
    this.dmgNumberContainer = new PIXI.Container();
    this.uiContainer = new PIXI.Container();

    this.gameContainer.addChild(this.bgContainer);
    this.gameContainer.addChild(this.entityContainer);
    this.gameContainer.addChild(this.particleContainer);
    this.gameContainer.addChild(this.dmgNumberContainer);

    this.app.stage.addChild(this.gameContainer);
    this.app.stage.addChild(this.uiContainer);

    this.levelUpContainer = new PIXI.Container();
    this.levelUpContainer.visible = false;
    this.uiContainer.addChild(this.levelUpContainer);

    this.titleContainer = new PIXI.Container();
    this.app.stage.addChild(this.titleContainer);

    this.gameOverContainer = new PIXI.Container();
    this.gameOverContainer.visible = false;
    this.app.stage.addChild(this.gameOverContainer);
  }

  private setupHUD(): void {
    this.hudGraphics = new PIXI.Graphics();
    this.uiContainer.addChild(this.hudGraphics);

    this.minimapGraphics = new PIXI.Graphics();
    this.uiContainer.addChild(this.minimapGraphics);

    const textStyle = { fontFamily: 'Segoe UI', fontSize: 14, fill: 0x8b8b9a };

    this.hudTimerText = new PIXI.Text('00:00', {
      fontFamily: 'Segoe UI', fontSize: 28, fontWeight: 'bold', fill: 0xffffff,
    });
    this.hudTimerText.anchor.set(0.5, 0);
    this.uiContainer.addChild(this.hudTimerText);

    this.hudKillText = new PIXI.Text('Kills: 0', textStyle);
    this.hudKillText.position.set(20, 58);
    this.uiContainer.addChild(this.hudKillText);

    this.hudLevelText = new PIXI.Text('Lv.1', {
      fontFamily: 'Segoe UI', fontSize: 16, fontWeight: 'bold', fill: 0xfbbf24,
    });
    this.uiContainer.addChild(this.hudLevelText);

    this.hudHpText = new PIXI.Text('100/100', {
      fontFamily: 'Segoe UI', fontSize: 11, fill: 0xffffff,
    });
    this.hudHpText.anchor.set(0.5);
    this.uiContainer.addChild(this.hudHpText);

    // Pre-create weapon display texts (max 6 weapons)
    for (let i = 0; i < 6; i++) {
      const wt = new PIXI.Text('', { fontFamily: 'Segoe UI', fontSize: 12, fill: 0xccccdd });
      wt.visible = false;
      this.uiContainer.addChild(wt);
      this.hudWeaponTexts.push(wt);
    }
  }

  private setupDamageNumberPool(): void {
    for (let i = 0; i < MAX_DAMAGE_NUMBERS; i++) {
      const text = new PIXI.Text('', {
        fontFamily: 'Segoe UI', fontSize: 14, fontWeight: 'bold', fill: 0xffffff,
      });
      text.anchor.set(0.5);
      text.visible = false;
      this.dmgNumberContainer.addChild(text);
      this.dmgTextPool.push(text);
    }
  }

  private showTitle(): void {
    this.titleContainer.removeChildren();
    const w = window.innerWidth;
    const h = window.innerHeight;

    const bg = new PIXI.Graphics();
    bg.beginFill(0x0a0a0f);
    bg.drawRect(0, 0, w, h);
    bg.endFill();
    this.titleContainer.addChild(bg);

    const title = new PIXI.Text('CODEX MORTIS', {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 72, fontWeight: 'bold',
      fill: 0xc4a0ff, dropShadow: true, dropShadowColor: 0x8b5cf6,
      dropShadowBlur: 20, dropShadowDistance: 0,
    });
    title.anchor.set(0.5);
    title.position.set(w / 2, h / 2 - 80);
    this.titleContainer.addChild(title);

    const subtitle = new PIXI.Text('Survive the endless hordes of darkness', {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 20, fill: 0x8b8b9a,
    });
    subtitle.anchor.set(0.5);
    subtitle.position.set(w / 2, h / 2);
    this.titleContainer.addChild(subtitle);

    const start = new PIXI.Text('Press any key to start', {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 18, fill: 0xc4a0ff,
    });
    start.anchor.set(0.5);
    start.position.set(w / 2, h / 2 + 80);
    this.titleContainer.addChild(start);

    const controls = new PIXI.Text('WASD - Move  |  Weapons auto-attack  |  Survive!', {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 14, fill: 0x555566,
    });
    controls.anchor.set(0.5);
    controls.position.set(w / 2, h - 60);
    this.titleContainer.addChild(controls);
  }

  private startGame(): void {
    // Cleanup old sprites
    this.entityContainer.removeChildren();
    this.particleContainer.removeChildren();
    this.bgContainer.removeChildren();
    this.levelUpContainer.visible = false;
    this.gameOverContainer.visible = false;

    // Reset damage number pool
    for (const t of this.dmgTextPool) {
      t.visible = false;
    }

    // Remove old level up key handler
    if (this.levelUpKeyHandler) {
      window.removeEventListener('keydown', this.levelUpKeyHandler);
      this.levelUpKeyHandler = null;
    }

    const world = createWorld();

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
      particleCount: 0,
      xpGemCount: 0,
      enemyGrid: new SpatialGrid(),
    };

    this.addWeaponToPlayer(WEAPON_TYPES.MAGIC_BOLT);
    this.generateBackground();
    this.createPlayerSprite(playerEid);
    this.lastTime = performance.now();
  }

  // ============================================================
  // BACKGROUND - Tiled map with decorations
  // ============================================================
  private generateBackground(): void {
    const tileCount = Math.ceil(WORLD_SIZE / TILE_SIZE);
    const rng = this.seedRandom(12345);

    // Generate tile map data
    const tileMap: number[][] = [];
    for (let y = 0; y < tileCount; y++) {
      tileMap[y] = [];
      for (let x = 0; x < tileCount; x++) {
        const n = rng();
        if (n < 0.7) {
          tileMap[y][x] = 0; // grass
        } else if (n < 0.9) {
          tileMap[y][x] = 1; // dirt
        } else {
          tileMap[y][x] = 2; // stone
        }
      }
    }

    // Create dirt paths (wandering lines)
    for (let p = 0; p < 8; p++) {
      let px = Math.floor(rng() * tileCount);
      let py = Math.floor(rng() * tileCount);
      const steps = 20 + Math.floor(rng() * 30);
      for (let s = 0; s < steps; s++) {
        if (px >= 0 && px < tileCount && py >= 0 && py < tileCount) {
          tileMap[py][px] = 1;
        }
        const dir = Math.floor(rng() * 4);
        if (dir === 0) px++;
        else if (dir === 1) px--;
        else if (dir === 2) py++;
        else py--;
      }
    }

    // Render tiles - Only visible tiles would be ideal but with WORLD_SIZE=4000
    // and TILE_SIZE=64 that's 62x62 = 3844 sprites which is too many.
    // Instead use a chunked approach: render tiles to larger chunk textures
    const CHUNK_SIZE = 512; // pixels
    const chunksPerSide = Math.ceil(WORLD_SIZE / CHUNK_SIZE);
    const tilesPerChunk = CHUNK_SIZE / TILE_SIZE;

    for (let cy = 0; cy < chunksPerSide; cy++) {
      for (let cx = 0; cx < chunksPerSide; cx++) {
        const canvas = document.createElement('canvas');
        canvas.width = CHUNK_SIZE;
        canvas.height = CHUNK_SIZE;
        const ctx = canvas.getContext('2d')!;
        ctx.imageSmoothingEnabled = false;

        for (let ty = 0; ty < tilesPerChunk; ty++) {
          for (let tx = 0; tx < tilesPerChunk; tx++) {
            const mapX = cx * tilesPerChunk + tx;
            const mapY = cy * tilesPerChunk + ty;
            if (mapX >= tileCount || mapY >= tileCount) continue;

            const tileType = tileMap[mapY][mapX];
            let tex: PIXI.Texture;
            if (tileType === 0) {
              tex = this.atlas.grassTiles[Math.floor(rng() * this.atlas.grassTiles.length)];
            } else if (tileType === 1) {
              tex = this.atlas.dirtTiles[Math.floor(rng() * this.atlas.dirtTiles.length)];
            } else {
              tex = this.atlas.stoneTile;
            }
            // Extract canvas from texture and draw
            const source = tex.baseTexture.resource as any;
            if (source && source.source) {
              ctx.drawImage(source.source, tx * TILE_SIZE, ty * TILE_SIZE, TILE_SIZE, TILE_SIZE);
            }
          }
        }

        const chunkTexture = PIXI.Texture.from(canvas);
        const chunkSprite = new PIXI.Sprite(chunkTexture);
        chunkSprite.position.set(cx * CHUNK_SIZE, cy * CHUNK_SIZE);
        this.bgContainer.addChild(chunkSprite);
      }
    }

    // Add decorations
    const decorations = [
      { tex: this.atlas.decorations.tombstone, count: 40, scale: 1.2 },
      { tex: this.atlas.decorations.deadTree, count: 25, scale: 1.5 },
      { tex: this.atlas.decorations.bone, count: 60, scale: 1.0 },
      { tex: this.atlas.decorations.skull, count: 30, scale: 0.9 },
      { tex: this.atlas.decorations.bloodPool, count: 25, scale: 1.0 },
      { tex: this.atlas.decorations.mushroom, count: 35, scale: 1.0 },
    ];

    for (const dec of decorations) {
      for (let i = 0; i < dec.count; i++) {
        const sprite = new PIXI.Sprite(dec.tex);
        sprite.anchor.set(0.5, 1.0);
        sprite.position.set(
          50 + rng() * (WORLD_SIZE - 100),
          50 + rng() * (WORLD_SIZE - 100)
        );
        sprite.scale.set(dec.scale);
        sprite.alpha = 0.6 + rng() * 0.3;
        if (rng() > 0.5) sprite.scale.x *= -1; // flip some
        this.bgContainer.addChild(sprite);
      }
    }
  }

  private seedRandom(seed: number): () => number {
    let s = seed;
    return () => {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    };
  }

  // ============================================================
  // SPRITE CREATION
  // ============================================================
  private createPlayerSprite(eid: number): void {
    const sprite = new PIXI.Sprite(this.atlas.player);
    sprite.anchor.set(0.5);
    sprite.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(sprite);
    this.state.entitySprites.set(eid, sprite);
  }

  private createEnemySprite(eid: number): void {
    const enemyType = Enemy.type[eid];
    const tex = this.atlas.enemies[enemyType] || this.atlas.enemies[0];
    const sprite = new PIXI.Sprite(tex);
    sprite.anchor.set(0.5);
    sprite.position.set(Position.x[eid], Position.y[eid]);
    if (enemyType === ENEMY_TYPES.BOSS) {
      sprite.scale.set(2.0);
    } else if (enemyType === ENEMY_TYPES.DEMON) {
      sprite.scale.set(1.3);
    }
    this.entityContainer.addChild(sprite);
    this.state.entitySprites.set(eid, sprite);
  }

  private createProjectileSprite(eid: number): void {
    const weaponType = Projectile.ownerWeaponType[eid];
    let tex: PIXI.Texture;

    switch (weaponType) {
      case WEAPON_TYPES.WHIP: tex = this.atlas.projectiles.whip; break;
      case WEAPON_TYPES.FIRE_CIRCLE: tex = this.atlas.projectiles.fireball; break;
      case WEAPON_TYPES.HOLY_CROSS: tex = this.atlas.projectiles.cross; break;
      case WEAPON_TYPES.SCYTHE: tex = this.atlas.projectiles.scythe; break;
      case WEAPON_TYPES.BLOOD_WAVE: tex = this.atlas.projectiles.bloodWave; break;
      case WEAPON_TYPES.LIGHTNING: tex = this.atlas.projectiles.lightning; break;
      default: tex = this.atlas.projectiles.magicBolt; break;
    }

    const sprite = new PIXI.Sprite(tex);
    sprite.anchor.set(0.5);
    sprite.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(sprite);
    this.state.entitySprites.set(eid, sprite);
  }

  private createXPGemSprite(eid: number): void {
    const value = XPGem.value[eid];
    const tier = value >= 10 ? 2 : value >= 5 ? 1 : 0;
    const tex = this.atlas.xpGems[tier];
    const sprite = new PIXI.Sprite(tex);
    sprite.anchor.set(0.5);
    sprite.position.set(Position.x[eid], Position.y[eid]);
    this.entityContainer.addChild(sprite);
    this.state.entitySprites.set(eid, sprite);
  }

  private createParticleSprite(eid: number, color: number): void {
    const sprite = new PIXI.Sprite(this.atlas.particle);
    sprite.anchor.set(0.5);
    sprite.tint = color;
    sprite.position.set(Position.x[eid], Position.y[eid]);
    sprite.scale.set(0.5 + Math.random() * 0.8);
    this.particleContainer.addChild(sprite);
    this.state.entitySprites.set(eid, sprite);
  }

  // ============================================================
  // WEAPON MANAGEMENT
  // ============================================================
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

    const weapons = weaponQuery(world);
    for (const wEid of weapons) {
      if (Weapon.type[wEid] === weaponType) {
        Weapon.level[wEid] = newLevel;
        const def = getWeaponDef(weaponType);
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
    const dt = Math.min((now - this.lastTime) / 1000, 0.05);
    this.lastTime = now;

    if (this.state.paused || this.state.levelUpActive || this.state.gameOver) {
      this.drawHUD();
      return;
    }

    this.state.gameTime += dt;

    // Rebuild spatial grid each frame
    this.state.enemyGrid.clear();
    const enemies = enemyPosQuery(this.state.world);
    for (let i = 0; i < enemies.length; i++) {
      const eid = enemies[i];
      this.state.enemyGrid.insert(eid, Position.x[eid], Position.y[eid]);
    }

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

    if (this.state.stats.recovery > 0) {
      const playerEid = this.state.playerEid;
      Health.current[playerEid] = Math.min(
        Health.max[playerEid],
        Health.current[playerEid] + this.state.stats.recovery * dt
      );
    }

    if (this.state.screenShake > 0) {
      this.state.screenShake *= 0.9;
      if (this.state.screenShake < 0.5) this.state.screenShake = 0;
    }
  }

  // ============================================================
  // INPUT
  // ============================================================
  private updateInput(_dt: number): void {
    const { keys, playerEid, stats } = this.state;
    let mx = 0, my = 0;

    if (keys.has('w') || keys.has('arrowup')) my -= 1;
    if (keys.has('s') || keys.has('arrowdown')) my += 1;
    if (keys.has('a') || keys.has('arrowleft')) mx -= 1;
    if (keys.has('d') || keys.has('arrowright')) mx += 1;

    const len = Math.sqrt(mx * mx + my * my);
    if (len > 0) { mx /= len; my /= len; }

    const speed = Player.speed[playerEid] * stats.speed;
    Velocity.x[playerEid] = mx * speed;
    Velocity.y[playerEid] = my * speed;
  }

  // ============================================================
  // MOVEMENT
  // ============================================================
  private updateMovement(dt: number): void {
    const { world, playerEid } = this.state;

    Position.x[playerEid] += Velocity.x[playerEid] * dt;
    Position.y[playerEid] += Velocity.y[playerEid] * dt;
    Position.x[playerEid] = Math.max(20, Math.min(WORLD_SIZE - 20, Position.x[playerEid]));
    Position.y[playerEid] = Math.max(20, Math.min(WORLD_SIZE - 20, Position.y[playerEid]));

    const enemies2 = enemyQuery(world);
    for (let i = 0; i < enemies2.length; i++) {
      const eid = enemies2[i];
      if (Math.abs(Enemy.knockbackX[eid]) > 0.1 || Math.abs(Enemy.knockbackY[eid]) > 0.1) {
        Position.x[eid] += Enemy.knockbackX[eid] * dt;
        Position.y[eid] += Enemy.knockbackY[eid] * dt;
        Enemy.knockbackX[eid] *= 0.85;
        Enemy.knockbackY[eid] *= 0.85;
      }
      Position.x[eid] += Velocity.x[eid] * dt;
      Position.y[eid] += Velocity.y[eid] * dt;
    }

    const projs = projQuery(world);
    for (let i = 0; i < projs.length; i++) {
      const eid = projs[i];
      Position.x[eid] += Velocity.x[eid] * dt;
      Position.y[eid] += Velocity.y[eid] * dt;
    }

    const particles = particleQuery(world);
    for (let i = 0; i < particles.length; i++) {
      const eid = particles[i];
      Position.x[eid] += Velocity.x[eid] * dt;
      Position.y[eid] += Velocity.y[eid] * dt;
      Velocity.y[eid] += 100 * dt;
    }
  }

  // ============================================================
  // ENEMY AI
  // ============================================================
  private updateEnemyAI(_dt: number): void {
    const { world, playerEid } = this.state;
    const px = Position.x[playerEid];
    const py = Position.y[playerEid];

    const enemies2 = enemyQuery(world);
    for (let i = 0; i < enemies2.length; i++) {
      const eid = enemies2[i];
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
  // WAVE SPAWNING
  // ============================================================
  private updateWaveSpawning(dt: number): void {
    const { gameTime, playerEid } = this.state;

    while (this.state.currentWaveIndex < WAVES.length &&
           WAVES[this.state.currentWaveIndex].time <= gameTime) {
      const wave = WAVES[this.state.currentWaveIndex];
      this.state.waveSpawnTimers.set(this.state.currentWaveIndex, {
        config: wave, spawned: 0, timer: 0,
      });
      this.state.currentWaveIndex++;
    }

    const px = Position.x[playerEid];
    const py = Position.y[playerEid];

    const toRemove: number[] = [];
    this.state.waveSpawnTimers.forEach((waveState, index) => {
      waveState.timer -= dt;
      if (waveState.timer <= 0 && waveState.spawned < waveState.config.count) {
        if (this.state.enemyCount < this.state.maxEnemies) {
          this.spawnEnemy(px, py, waveState.config.enemyType, waveState.config.healthMult, waveState.config.speedMult);
          waveState.spawned++;
          waveState.timer = waveState.config.interval;
        }
      }
      if (waveState.spawned >= waveState.config.count) {
        toRemove.push(index);
      }
    });
    for (let i = 0; i < toRemove.length; i++) {
      this.state.waveSpawnTimers.delete(toRemove[i]);
    }

    if (this.state.currentWaveIndex >= WAVES.length && this.state.enemyCount < 50) {
      const scaleFactor = 1 + (gameTime - 600) / 120;
      const types = [0, 1, 2, 3, 4];
      const type = types[Math.floor(Math.random() * types.length)];
      this.spawnEnemy(px, py, type, scaleFactor * 2, 1 + scaleFactor * 0.3);
    }
  }

  private spawnEnemy(px: number, py: number, type: number, healthMult: number, speedMult: number): void {
    const { world } = this.state;
    if (this.state.enemyCount >= this.state.maxEnemies) return;

    const def = getEnemyDef(type);
    const angle = Math.random() * Math.PI * 2;
    const dist = SPAWN_DISTANCE + Math.random() * 100;
    const sx = Math.max(10, Math.min(WORLD_SIZE - 10, px + Math.cos(angle) * dist));
    const sy = Math.max(10, Math.min(WORLD_SIZE - 10, py + Math.sin(angle) * dist));

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

    const weapons = weaponQuery(world);
    for (let i = 0; i < weapons.length; i++) {
      const wEid = weapons[i];
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

    // Use spatial grid for nearest enemy
    const nearby = this.state.enemyGrid.query(px, py, range * 2);
    const targets: { angle: number }[] = [];
    for (let i = 0; i < Math.min(nearby.length, 10); i++) {
      const eid = nearby[i];
      const dx = Position.x[eid] - px;
      const dy = Position.y[eid] - py;
      targets.push({ angle: Math.atan2(dy, dx) });
    }

    for (let i = 0; i < count; i++) {
      let angle: number;
      if (targets.length > 0) {
        angle = targets[i % targets.length].angle + (Math.random() - 0.5) * 0.2;
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

      Position.x[eid] = px;
      Position.y[eid] = py;
      Velocity.x[eid] = Math.cos(angle) * speed;
      Velocity.y[eid] = Math.sin(angle) * speed;
      Collision.radius[eid] = 5 * area;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = pierce;
      Projectile.ownerWeaponType[eid] = weaponType;
      Projectile.speed[eid] = speed;
      Lifetime.remaining[eid] = range / speed + 0.5;

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

      Position.x[eid] = px + Math.cos(angle) * 30;
      Position.y[eid] = py + Math.sin(angle) * 30;
      Velocity.x[eid] = Math.cos(angle) * 50;
      Velocity.y[eid] = Math.sin(angle) * 50;
      Collision.radius[eid] = range * area * 0.5;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = -1;
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.WHIP;
      Lifetime.remaining[eid] = 0.3;

      this.createProjectileSprite(eid);
    }
  }

  private fireOrbitingProjectiles(px: number, py: number, count: number, damage: number, speed: number, range: number, area: number): void {
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

      Position.x[eid] = px + Math.cos(angle) * range * area;
      Position.y[eid] = py + Math.sin(angle) * range * area;
      Velocity.x[eid] = Math.cos(angle + Math.PI / 2) * speed;
      Velocity.y[eid] = Math.sin(angle + Math.PI / 2) * speed;
      Collision.radius[eid] = 10 * area;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = -1;
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.FIRE_CIRCLE;
      Lifetime.remaining[eid] = 3.0;

      this.createProjectileSprite(eid);
    }
  }

  private fireBoomerang(px: number, py: number, count: number, damage: number, speed: number, pierce: number, range: number, area: number): void {
    const { world } = this.state;

    const nearby = this.state.enemyGrid.query(px, py, range * 2);
    let targetAngle = Math.random() * Math.PI * 2;
    let closest = Infinity;
    for (let i = 0; i < nearby.length; i++) {
      const eeid = nearby[i];
      const dx = Position.x[eeid] - px;
      const dy = Position.y[eeid] - py;
      const dist = dx * dx + dy * dy;
      if (dist < closest) {
        closest = dist;
        targetAngle = Math.atan2(dy, dx);
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

      this.createProjectileSprite(eid);
    }
  }

  private fireLightning(px: number, py: number, count: number, damage: number, range: number, chains: number): void {
    const { world } = this.state;
    const nearby = this.state.enemyGrid.query(px, py, range);
    const inRange: number[] = [];
    for (let i = 0; i < nearby.length; i++) {
      const eid = nearby[i];
      if (hasComponent(world, Health, eid)) {
        inRange.push(eid);
      }
    }

    const strikes = Math.min(count, inRange.length);
    for (let i = 0; i < strikes; i++) {
      const targetIdx = Math.floor(Math.random() * inRange.length);
      const targetEid = inRange[targetIdx];

      Health.current[targetEid] -= damage * this.state.stats.damage;
      this.addDamageNumber(Position.x[targetEid], Position.y[targetEid], damage * this.state.stats.damage, 0x60a5fa);
      this.spawnLightningEffect(px, py, Position.x[targetEid], Position.y[targetEid]);

      let chainSource = targetEid;
      for (let c = 0; c < chains; c++) {
        let closestDist = 150 * 150;
        let chainTarget = -1;
        for (let j = 0; j < inRange.length; j++) {
          const eeid = inRange[j];
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
    const steps = 3; // reduced from 5
    for (let i = 0; i < steps; i++) {
      const t = i / steps;
      const x = x1 + (x2 - x1) * t + (Math.random() - 0.5) * 20;
      const y = y1 + (y2 - y1) * t + (Math.random() - 0.5) * 20;
      this.spawnParticle(x, y, 0x60a5fa, 0.2);
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

      Position.x[eid] = px;
      Position.y[eid] = py;
      Velocity.x[eid] = Math.cos(angle) * speed;
      Velocity.y[eid] = Math.sin(angle) * speed;
      Collision.radius[eid] = 15 * area;
      Projectile.damage[eid] = damage;
      Projectile.pierce[eid] = -1;
      Projectile.ownerWeaponType[eid] = WEAPON_TYPES.BLOOD_WAVE;
      Lifetime.remaining[eid] = range / speed;

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
    AreaEffect.followPlayer[eid] = followPlayer ? 1 : 0;
    Lifetime.remaining[eid] = lifetime;
  }

  // ============================================================
  // AREA EFFECTS
  // ============================================================
  private updateAreaEffects(dt: number): void {
    const { world, playerEid, stats } = this.state;
    const areas = areaQuery(world);

    for (let i = 0; i < areas.length; i++) {
      const eid = areas[i];
      if (AreaEffect.followPlayer[eid]) {
        Position.x[eid] = Position.x[playerEid];
        Position.y[eid] = Position.y[playerEid];
      }

      AreaEffect.tickTimer[eid] -= dt;
      if (AreaEffect.tickTimer[eid] <= 0) {
        AreaEffect.tickTimer[eid] = AreaEffect.tickRate[eid];

        const ax = Position.x[eid];
        const ay = Position.y[eid];
        const radius = AreaEffect.radius[eid] * stats.area;
        const damage = AreaEffect.damage[eid] * stats.damage;

        // Use spatial grid
        const nearby = this.state.enemyGrid.query(ax, ay, radius);
        for (let j = 0; j < nearby.length; j++) {
          const eeid = nearby[j];
          if (!hasComponent(world, Health, eeid)) continue;
          const dx = Position.x[eeid] - ax;
          const dy = Position.y[eeid] - ay;
          if (dx * dx + dy * dy < radius * radius) {
            Health.current[eeid] -= damage;
            const dist = Math.sqrt(dx * dx + dy * dy) || 1;
            Enemy.knockbackX[eeid] += (dx / dist) * 200;
            Enemy.knockbackY[eeid] += (dy / dist) * 200;
            this.addDamageNumber(Position.x[eeid], Position.y[eeid], damage, 0x4ade80);
          }
        }
      }
    }
  }

  // ============================================================
  // PROJECTILES
  // ============================================================
  private updateProjectiles(_dt: number): void {
    const { world, playerEid } = this.state;
    const projs = projQuery(world);

    for (let i = 0; i < projs.length; i++) {
      const eid = projs[i];
      if (Projectile.ownerWeaponType[eid] === WEAPON_TYPES.HOLY_CROSS) {
        if (hasComponent(world, Lifetime, eid)) {
          const lifetime = Lifetime.remaining[eid];
          if (lifetime < 1.0) {
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
      }
    }
  }

  // ============================================================
  // COLLISIONS - Uses spatial grid
  // ============================================================
  private updateCollisions(dt: number): void {
    const { world, playerEid, stats } = this.state;

    const projs = projCollisionQuery(world);
    const projsToRemove: number[] = [];

    for (let pi = 0; pi < projs.length; pi++) {
      const pEid = projs[pi];
      const px = Position.x[pEid];
      const py = Position.y[pEid];
      const pr = Collision.radius[pEid];

      // Use spatial grid to find nearby enemies
      const nearby = this.state.enemyGrid.query(px, py, pr + 50);

      for (let ni = 0; ni < nearby.length; ni++) {
        const eEid = nearby[ni];
        if (!hasComponent(world, Health, eEid)) continue;

        const ex = Position.x[eEid];
        const ey = Position.y[eEid];
        const er = Collision.radius[eEid];
        const dx = px - ex;
        const dy = py - ey;
        const distSq = dx * dx + dy * dy;
        const minDist = pr + er;

        if (distSq < minDist * minDist) {
          const damage = Projectile.damage[pEid];
          Health.current[eEid] -= damage;

          const dist = Math.sqrt(distSq) || 1;
          Enemy.knockbackX[eEid] += (dx / dist) * -150;
          Enemy.knockbackY[eEid] += (dy / dist) * -150;

          this.addDamageNumber(ex, ey, damage, getWeaponDef(Projectile.ownerWeaponType[pEid]).color);

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

    for (let i = 0; i < projsToRemove.length; i++) {
      this.removeEntity(projsToRemove[i]);
    }

    // Check enemy deaths
    const enemies2 = enemyCollisionQuery(world);
    for (let i = 0; i < enemies2.length; i++) {
      const eEid = enemies2[i];
      if (Health.current[eEid] <= 0) {
        this.onEnemyDeath(eEid);
      }
    }

    // Player-enemy collision
    if (Health.invincibleTimer[playerEid] > 0) {
      Health.invincibleTimer[playerEid] -= dt;
    } else {
      const nearPlayer = this.state.enemyGrid.query(
        Position.x[playerEid], Position.y[playerEid],
        Collision.radius[playerEid] + 50
      );

      for (let i = 0; i < nearPlayer.length; i++) {
        const eEid = nearPlayer[i];
        if (!hasComponent(world, Health, eEid) || Health.current[eEid] <= 0) continue;

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
    if (this.state.xpGemCount < MAX_XP_GEMS) {
      this.spawnXPGem(Position.x[eid], Position.y[eid], Enemy.xpDrop[eid]);
    }

    const color = getEnemyDef(Enemy.type[eid]).color;
    // Only spawn 3 death particles (reduced from 6)
    for (let i = 0; i < 3; i++) {
      this.spawnParticle(Position.x[eid], Position.y[eid], color, 0.4);
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

    Position.x[eid] = x + (Math.random() - 0.5) * 20;
    Position.y[eid] = y + (Math.random() - 0.5) * 20;
    XPGem.value[eid] = value;
    Collision.radius[eid] = 8;

    this.createXPGemSprite(eid);
    this.state.xpGemCount++;
  }

  // ============================================================
  // XP COLLECTION
  // ============================================================
  private updateXPCollection(dt: number): void {
    const { world, playerEid, stats } = this.state;
    const px = Position.x[playerEid];
    const py = Position.y[playerEid];
    const magnetRange = MAGNET_BASE_RANGE * stats.magnet;

    const gems = gemQuery(world);
    const toCollect: number[] = [];

    for (let i = 0; i < gems.length; i++) {
      const eid = gems[i];
      const dx = px - Position.x[eid];
      const dy = py - Position.y[eid];
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < magnetRange) {
        const speed = 300 + (magnetRange - dist) * 3;
        Position.x[eid] += (dx / dist) * speed * dt;
        Position.y[eid] += (dy / dist) * speed * dt;
      }

      if (dist < 20) {
        toCollect.push(eid);
      }
    }

    for (let i = 0; i < toCollect.length; i++) {
      const eid = toCollect[i];
      const xpValue = XPGem.value[eid] * stats.xpBonus;
      Player.xp[playerEid] += xpValue;

      while (Player.xp[playerEid] >= Player.xpToNext[playerEid]) {
        Player.xp[playerEid] -= Player.xpToNext[playerEid];
        Player.level[playerEid]++;
        const level = Player.level[playerEid];
        Player.xpToNext[playerEid] = XP_TABLE[Math.min(level - 1, XP_TABLE.length - 1)];
        this.onLevelUp();
      }

      this.removeEntity(eid);
      this.state.xpGemCount--;
    }
  }

  // ============================================================
  // LEVEL UP
  // ============================================================
  private onLevelUp(): void {
    this.state.levelUpActive = true;
    this.state.screenShake = 3;

    const possible: LevelUpChoice[] = [];

    for (let i = 0; i < WEAPONS.length; i++) {
      if (!this.state.weaponLevels.has(i) && this.state.weaponLevels.size < 6) {
        possible.push({
          type: 'weapon', index: i, name: WEAPONS[i].name,
          description: WEAPONS[i].description, color: WEAPONS[i].color,
          level: 0, maxLevel: WEAPONS[i].maxLevel,
        });
      }
    }

    this.state.weaponLevels.forEach((level, type) => {
      if (level < WEAPONS[type].maxLevel) {
        possible.push({
          type: 'weapon', index: type, name: WEAPONS[type].name,
          description: WEAPONS[type].upgrades[level - 1] || '+25% Stats',
          color: WEAPONS[type].color, level, maxLevel: WEAPONS[type].maxLevel,
        });
      }
    });

    for (let i = 0; i < PASSIVE_UPGRADES.length; i++) {
      if (this.state.passiveLevels[i] < PASSIVE_UPGRADES[i].maxLevel) {
        possible.push({
          type: 'passive', index: i, name: PASSIVE_UPGRADES[i].name,
          description: PASSIVE_UPGRADES[i].description, color: PASSIVE_UPGRADES[i].color,
          level: this.state.passiveLevels[i], maxLevel: PASSIVE_UPGRADES[i].maxLevel,
        });
      }
    }

    // Shuffle
    for (let i = possible.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [possible[i], possible[j]] = [possible[j], possible[i]];
    }

    this.state.levelUpChoices = possible.slice(0, 3);
    this.showLevelUpUI();
  }

  private showLevelUpUI(): void {
    this.levelUpContainer.removeChildren();
    this.levelUpContainer.visible = true;

    const w = window.innerWidth;
    const h = window.innerHeight;

    const dim = new PIXI.Graphics();
    dim.beginFill(0x000000, 0.7);
    dim.drawRect(0, 0, w, h);
    dim.endFill();
    dim.interactive = true;
    this.levelUpContainer.addChild(dim);

    const title = new PIXI.Text(`LEVEL UP! (Lv.${Player.level[this.state.playerEid]})`, {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 36, fontWeight: 'bold', fill: 0xfbbf24,
    });
    title.anchor.set(0.5);
    title.position.set(w / 2, h / 2 - 160);
    this.levelUpContainer.addChild(title);

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
      bg.beginFill(0x1a1a2e);
      bg.drawRoundedRect(0, 0, cardWidth, cardHeight, 10);
      bg.endFill();
      bg.lineStyle(2, choice.color, 0.8);
      bg.drawRoundedRect(0, 0, cardWidth, cardHeight, 10);
      card.addChild(bg);

      const accent = new PIXI.Graphics();
      accent.beginFill(choice.color);
      accent.drawRect(0, 0, cardWidth, 4);
      accent.endFill();
      card.addChild(accent);

      const nameText = new PIXI.Text(choice.name, {
        fontFamily: 'Segoe UI', fontSize: 16, fontWeight: 'bold', fill: 0xffffff,
      });
      nameText.position.set(15, 20);
      card.addChild(nameText);

      const levelText = new PIXI.Text(choice.level === 0 ? 'NEW!' : `Lv.${choice.level} -> ${choice.level + 1}`, {
        fontFamily: 'Segoe UI', fontSize: 12, fill: choice.level === 0 ? 0x4ade80 : 0x8b8b9a,
      });
      levelText.position.set(15, 45);
      card.addChild(levelText);

      const descText = new PIXI.Text(choice.description, {
        fontFamily: 'Segoe UI', fontSize: 13, fill: 0xccccdd, wordWrap: true, wordWrapWidth: cardWidth - 30,
      });
      descText.position.set(15, 70);
      card.addChild(descText);

      const keyText = new PIXI.Text(`[${i + 1}]`, {
        fontFamily: 'Segoe UI', fontSize: 14, fill: 0x666677,
      });
      keyText.position.set(cardWidth - 30, cardHeight - 25);
      card.addChild(keyText);

      card.on('pointerdown', () => this.selectUpgrade(i));
      this.levelUpContainer.addChild(card);
    });

    // Remove old handler
    if (this.levelUpKeyHandler) {
      window.removeEventListener('keydown', this.levelUpKeyHandler);
    }
    this.levelUpKeyHandler = (e: KeyboardEvent) => {
      const num = parseInt(e.key);
      if (num >= 1 && num <= this.state.levelUpChoices.length) {
        window.removeEventListener('keydown', this.levelUpKeyHandler!);
        this.levelUpKeyHandler = null;
        this.selectUpgrade(num - 1);
      }
    };
    window.addEventListener('keydown', this.levelUpKeyHandler);
  }

  private selectUpgrade(index: number): void {
    const choice = this.state.levelUpChoices[index];
    if (!choice) return;

    if (choice.type === 'weapon') {
      if (choice.level === 0) {
        this.addWeaponToPlayer(choice.index);
      } else {
        this.upgradeWeapon(choice.index);
      }
    } else {
      this.state.passiveLevels[choice.index]++;
      const upgrade = PASSIVE_UPGRADES[choice.index];
      const statKey = upgrade.effect as keyof PlayerStats;
      if (statKey === 'cooldown' || statKey === 'armor') {
        (this.state.stats[statKey] as number) -= upgrade.valuePerLevel;
      } else {
        (this.state.stats[statKey] as number) += upgrade.valuePerLevel;
      }
      if (statKey === 'maxHp') {
        Health.max[this.state.playerEid] = this.state.stats.maxHp;
        Health.current[this.state.playerEid] = Math.min(
          Health.current[this.state.playerEid] + upgrade.valuePerLevel,
          Health.max[this.state.playerEid]
        );
      }
    }

    this.state.levelUpActive = false;
    this.levelUpContainer.visible = false;

    // Reduced level up particles (5 instead of 15)
    for (let i = 0; i < 5; i++) {
      this.spawnParticle(Position.x[this.state.playerEid], Position.y[this.state.playerEid], 0xfbbf24, 0.6);
    }
  }

  // ============================================================
  // LIFETIME
  // ============================================================
  private updateLifetimes(dt: number): void {
    const { world } = this.state;
    const entities = lifetimeQuery(world);
    const toRemove: number[] = [];

    for (let i = 0; i < entities.length; i++) {
      const eid = entities[i];
      Lifetime.remaining[eid] -= dt; // Use actual dt, not fixed step
      if (Lifetime.remaining[eid] <= 0) {
        toRemove.push(eid);
      }
    }

    for (let i = 0; i < toRemove.length; i++) {
      const eid = toRemove[i];
      if (hasComponent(world, Particle, eid)) {
        this.state.particleCount--;
      }
      this.removeEntity(eid);
    }
  }

  // ============================================================
  // PARTICLES - with limits
  // ============================================================
  private spawnParticle(x: number, y: number, color: number, lifetime: number): void {
    if (this.state.particleCount >= MAX_PARTICLES) return;

    const { world } = this.state;
    const eid = addEntity(world);
    addComponent(world, Position, eid);
    addComponent(world, Velocity, eid);
    addComponent(world, Particle, eid);
    addComponent(world, ParticleTag, eid);
    addComponent(world, Lifetime, eid);

    Position.x[eid] = x;
    Position.y[eid] = y;
    Velocity.x[eid] = (Math.random() - 0.5) * 200;
    Velocity.y[eid] = -Math.random() * 150 - 50;
    Lifetime.remaining[eid] = lifetime;

    this.createParticleSprite(eid, color);
    this.state.particleCount++;
  }

  private updateParticles(_dt: number): void {
    const { world } = this.state;
    const particles = particleLifeQuery(world);

    for (let i = 0; i < particles.length; i++) {
      const eid = particles[i];
      const sprite = this.state.entitySprites.get(eid);
      if (sprite) {
        const remaining = Lifetime.remaining[eid];
        sprite.alpha = Math.max(0, remaining * 2.5);
        const s = Math.max(0.1, remaining * 1.5);
        sprite.scale.set(s);
      }
    }
  }

  // ============================================================
  // DAMAGE NUMBERS - Pooled, no per-frame allocation
  // ============================================================
  private addDamageNumber(x: number, y: number, value: number, color: number): void {
    const dns = this.state.damageNumbers;

    // Find inactive slot or overwrite oldest
    let slot = -1;
    for (let i = 0; i < dns.length; i++) {
      if (!dns[i].active) { slot = i; break; }
    }
    if (slot === -1) {
      if (dns.length < MAX_DAMAGE_NUMBERS) {
        slot = dns.length;
        dns.push({ x: 0, y: 0, value: 0, timer: 0, vy: 0, color: 0, active: false });
      } else {
        // Overwrite oldest
        let oldest = 0;
        for (let i = 1; i < dns.length; i++) {
          if (dns[i].timer < dns[oldest].timer) oldest = i;
        }
        slot = oldest;
      }
    }

    const dn = dns[slot];
    dn.x = x + (Math.random() - 0.5) * 20;
    dn.y = y - 10;
    dn.value = Math.round(value);
    dn.timer = 0.6;
    dn.vy = -60;
    dn.color = color;
    dn.active = true;
  }

  private updateDamageNumbers(dt: number): void {
    const dns = this.state.damageNumbers;
    for (let i = 0; i < dns.length; i++) {
      const dn = dns[i];
      if (!dn.active) continue;
      dn.timer -= dt;
      dn.y += dn.vy * dt;
      dn.vy += 50 * dt;
      if (dn.timer <= 0) {
        dn.active = false;
      }
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================
  private updateCamera(dt: number): void {
    const { playerEid } = this.state;
    const targetX = Position.x[playerEid];
    const targetY = Position.y[playerEid];

    this.state.cameraX += (targetX - this.state.cameraX) * 5 * dt;
    this.state.cameraY += (targetY - this.state.cameraY) * 5 * dt;

    const screenW = window.innerWidth;
    const screenH = window.innerHeight;

    let offsetX = screenW / 2 - this.state.cameraX;
    let offsetY = screenH / 2 - this.state.cameraY;

    if (this.state.screenShake > 0) {
      offsetX += (Math.random() - 0.5) * this.state.screenShake * 2;
      offsetY += (Math.random() - 0.5) * this.state.screenShake * 2;
    }

    this.gameContainer.position.set(offsetX, offsetY);
  }

  // ============================================================
  // SPRITE UPDATE - with culling
  // ============================================================
  private updateSprites(): void {
    const { world, playerEid } = this.state;
    const cx = this.state.cameraX;
    const cy = this.state.cameraY;
    const hw = window.innerWidth / 2 + 100;
    const hh = window.innerHeight / 2 + 100;

    this.state.entitySprites.forEach((sprite, eid) => {
      if (!hasComponent(world, Position, eid)) return;

      const ex = Position.x[eid];
      const ey = Position.y[eid];

      // Frustum culling
      if (Math.abs(ex - cx) > hw || Math.abs(ey - cy) > hh) {
        sprite.visible = false;
        return;
      }
      sprite.visible = true;
      sprite.position.set(ex, ey);

      if (hasComponent(world, Projectile, eid)) {
        const wType = Projectile.ownerWeaponType[eid];
        if (wType === WEAPON_TYPES.SCYTHE || wType === WEAPON_TYPES.HOLY_CROSS) {
          SpriteComponent.rotation[eid] += 0.15;
          sprite.rotation = SpriteComponent.rotation[eid];
        } else if (Velocity.x[eid] !== 0 || Velocity.y[eid] !== 0) {
          sprite.rotation = Math.atan2(Velocity.y[eid], Velocity.x[eid]);
        }

        if (hasComponent(world, Lifetime, eid)) {
          const remaining = Lifetime.remaining[eid];
          if (remaining < 0.3) {
            sprite.alpha = remaining / 0.3;
          } else {
            sprite.alpha = 1;
          }
        }
      }

      if (eid === playerEid) {
        if (Health.invincibleTimer[playerEid] > 0) {
          sprite.alpha = Math.sin(Health.invincibleTimer[playerEid] * 30) > 0 ? 1 : 0.3;
        } else {
          sprite.alpha = 1;
        }
      }

      if (hasComponent(world, XPGem, eid)) {
        const s = 0.8 + Math.sin(this.state.gameTime * 4 + eid) * 0.2;
        sprite.scale.set(s);
      }

      if (hasComponent(world, Enemy, eid)) {
        // Flip sprite to face player
        const dx = Position.x[playerEid] - ex;
        if (dx < 0) {
          sprite.scale.x = -Math.abs(sprite.scale.x);
        } else {
          sprite.scale.x = Math.abs(sprite.scale.x);
        }
      }
    });
  }

  // ============================================================
  // HUD - Uses persistent text objects (never recreated)
  // ============================================================
  private drawHUD(): void {
    const g = this.hudGraphics;
    g.clear();

    const w = window.innerWidth;
    const { playerEid, gameTime, killCount } = this.state;

    // HP Bar
    const hpWidth = 250;
    const hpHeight = 16;
    const hpX = 20;
    const hpY = 20;
    const hpRatio = Math.max(0, Health.current[playerEid] / Health.max[playerEid]);

    g.beginFill(0x1a1a2e);
    g.drawRoundedRect(hpX, hpY, hpWidth, hpHeight, 4);
    g.endFill();
    g.beginFill(hpRatio > 0.3 ? 0x4ade80 : 0xef4444);
    g.drawRoundedRect(hpX, hpY, hpWidth * hpRatio, hpHeight, 4);
    g.endFill();
    g.lineStyle(1, 0x333344);
    g.drawRoundedRect(hpX, hpY, hpWidth, hpHeight, 4);
    g.lineStyle(0);

    // XP Bar
    const xpWidth = 250;
    const xpHeight = 8;
    const xpX = 20;
    const xpY = 42;
    const xpRatio = Math.max(0, Math.min(1, Player.xp[playerEid] / Player.xpToNext[playerEid]));

    g.beginFill(0x1a1a2e);
    g.drawRoundedRect(xpX, xpY, xpWidth, xpHeight, 3);
    g.endFill();
    g.beginFill(0xa855f7);
    g.drawRoundedRect(xpX, xpY, xpWidth * xpRatio, xpHeight, 3);
    g.endFill();

    // Update persistent text objects
    const minutes = Math.floor(gameTime / 60);
    const seconds = Math.floor(gameTime % 60);
    this.hudTimerText.text = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    this.hudTimerText.position.set(w / 2, 10);

    this.hudKillText.text = `Kills: ${killCount}`;
    this.hudLevelText.text = `Lv.${Player.level[playerEid]}`;
    this.hudLevelText.position.set(hpX + hpWidth + 10, hpY);

    this.hudHpText.text = `${Math.ceil(Math.max(0, Health.current[playerEid]))}/${Math.ceil(Health.max[playerEid])}`;
    this.hudHpText.position.set(hpX + hpWidth / 2, hpY + hpHeight / 2);

    // Weapon list
    const h = window.innerHeight;
    let weaponIdx = 0;
    this.state.weaponLevels.forEach((level, type) => {
      if (weaponIdx >= this.hudWeaponTexts.length) return;
      const def = getWeaponDef(type);
      const weaponY = h - 60 - weaponIdx * 28;

      g.beginFill(0x1a1a2e, 0.8);
      g.drawRoundedRect(20, weaponY, 180, 22, 4);
      g.endFill();
      g.beginFill(def.color);
      g.drawRect(20, weaponY, 4, 22);
      g.endFill();

      const wText = this.hudWeaponTexts[weaponIdx];
      wText.text = `${def.name} Lv.${level}`;
      wText.position.set(30, weaponY + 4);
      wText.visible = true;
      weaponIdx++;
    });
    // Hide unused weapon texts
    for (let i = weaponIdx; i < this.hudWeaponTexts.length; i++) {
      this.hudWeaponTexts[i].visible = false;
    }

    // Render damage numbers using pool
    const dns = this.state.damageNumbers;
    let poolIdx = 0;
    for (let i = 0; i < dns.length && poolIdx < this.dmgTextPool.length; i++) {
      const dn = dns[i];
      if (!dn.active) continue;

      const screenX = dn.x - this.state.cameraX + w / 2;
      const screenY = dn.y - this.state.cameraY + h / 2;

      if (screenX > -50 && screenX < w + 50 && screenY > -50 && screenY < h + 50) {
        const text = this.dmgTextPool[poolIdx];
        text.text = `${dn.value}`;
        text.style.fill = dn.color;
        text.style.fontSize = Math.min(24, 14 + dn.value / 10);
        text.position.set(screenX, screenY);
        text.alpha = Math.min(1, dn.timer * 2.5);
        text.visible = true;
        poolIdx++;
      }
    }
    // Hide unused pool texts
    for (let i = poolIdx; i < this.dmgTextPool.length; i++) {
      this.dmgTextPool[i].visible = false;
    }
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

    g.beginFill(0x0a0a0f, 0.8);
    g.drawRoundedRect(mapX, mapY, mapSize, mapSize, 4);
    g.endFill();
    g.lineStyle(1, 0x333344);
    g.drawRoundedRect(mapX, mapY, mapSize, mapSize, 4);
    g.lineStyle(0);

    const { world, playerEid } = this.state;

    // Only draw nearby enemies on minimap (limit to 100)
    const enemies2 = enemyPosQuery(world);
    const maxDraw = Math.min(enemies2.length, 100);
    for (let i = 0; i < maxDraw; i++) {
      const eid = enemies2[i];
      const ex = mapX + Position.x[eid] * scale;
      const ey = mapY + Position.y[eid] * scale;
      g.beginFill(0xef4444);
      g.drawRect(ex, ey, 2, 2); // Rects are faster than circles
      g.endFill();
    }

    // Player
    const px = mapX + Position.x[playerEid] * scale;
    const py = mapY + Position.y[playerEid] * scale;
    g.beginFill(0xc4a0ff);
    g.drawCircle(px, py, 3);
    g.endFill();
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
    bg.beginFill(0x000000, 0.85);
    bg.drawRect(0, 0, w, h);
    bg.endFill();
    this.gameOverContainer.addChild(bg);

    const title = new PIXI.Text('YOU DIED', {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 64, fontWeight: 'bold',
      fill: 0xef4444, dropShadow: true, dropShadowColor: 0x7f0000,
      dropShadowBlur: 20, dropShadowDistance: 0,
    });
    title.anchor.set(0.5);
    title.position.set(w / 2, h / 2 - 80);
    this.gameOverContainer.addChild(title);

    const minutes = Math.floor(this.state.gameTime / 60);
    const seconds = Math.floor(this.state.gameTime % 60);

    const statsText = new PIXI.Text(
      `Time: ${minutes}:${seconds.toString().padStart(2, '0')}  |  Kills: ${this.state.killCount}  |  Level: ${Player.level[this.state.playerEid]}`,
      { fontFamily: 'Segoe UI, sans-serif', fontSize: 20, fill: 0xccccdd }
    );
    statsText.anchor.set(0.5);
    statsText.position.set(w / 2, h / 2);
    this.gameOverContainer.addChild(statsText);

    const restart = new PIXI.Text('Press any key to restart', {
      fontFamily: 'Segoe UI, sans-serif', fontSize: 16, fill: 0x8b8b9a,
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
game.init();
