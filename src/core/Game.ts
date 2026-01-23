/**
 * Game.ts - Main entry point and game loop orchestrator.
 * Connects all systems: rendering, entities, combat, progression, UI.
 * Manages game state transitions (title, playing, levelup, gameover).
 */

import { createGameWorld, Position, Health, Player, Enemy, Velocity } from '../entities/World';
import { Input } from './Input';
import { Renderer } from '../rendering/Renderer';
import { PlayerEntity } from '../entities/Player';
import { EnemyFactory } from '../entities/EnemyFactory';
import { ProjectileFactory } from '../entities/ProjectileFactory';
import { GemFactory } from '../entities/GemFactory';
import { SpatialGrid } from '../combat/SpatialGrid';
import { WeaponSystem } from '../combat/WeaponSystem';
import { CollisionSystem } from '../combat/CollisionSystem';
import { DamageSystem } from '../combat/DamageSystem';
import { WaveSystem } from '../progression/WaveSystem';
import { LevelUpSystem } from '../progression/LevelUpSystem';
import { HUD } from '../ui/HUD';
import { LevelUpUI } from '../ui/LevelUpUI';
import { MenuScreens } from '../ui/MenuScreens';
import { DebugOverlay } from '../debug/DebugOverlay';
import { KNOCKBACK_DECAY, WORLD_SIZE } from './Constants';
import { WEAPON_TYPES, getWeaponDef } from '../combat/WeaponTypes';
import { getEnemyDef } from '../progression/EnemyData';
import { IWorld } from 'bitecs';

type GameState = 'title' | 'playing' | 'levelup' | 'gameover';

class Game {
  private renderer: Renderer;
  private input: Input;
  private world: IWorld;
  private state: GameState = 'title';
  private time: number = 0;
  private lastTime: number = 0;

  // Entities
  private player!: PlayerEntity;
  private enemyFactory!: EnemyFactory;
  private projectileFactory!: ProjectileFactory;
  private gemFactory!: GemFactory;

  // Combat
  private spatialGrid!: SpatialGrid;
  private weaponSystem!: WeaponSystem;
  private collisionSystem!: CollisionSystem;
  private damageSystem!: DamageSystem;

  // Progression
  private waveSystem!: WaveSystem;
  private levelUpSystem!: LevelUpSystem;

  // UI
  private hud!: HUD;
  private levelUpUI!: LevelUpUI;
  private menuScreens!: MenuScreens;
  private debugOverlay!: DebugOverlay;

  // Input cooldown for menu transitions
  private inputCooldown: number = 0;

  constructor() {
    const container = document.getElementById('game') || document.body;
    this.renderer = new Renderer(container);
    this.input = new Input();
    this.world = createGameWorld();

    this.initSystems();
    this.initUI();

    // Generate map
    this.renderer.mapRenderer.generate(Date.now());

    // Show title screen
    this.menuScreens.showTitle();

    // F3 for debug
    window.addEventListener('keydown', (e) => {
      if (e.key === 'F3') {
        e.preventDefault();
        this.debugOverlay.toggle();
      }
    });

    // Start game loop
    this.lastTime = performance.now();
    this.renderer.app.ticker.add(() => this.loop());
  }

  private initSystems(): void {
    // Entity factories
    this.player = new PlayerEntity(
      this.world, this.renderer.entityContainer, this.renderer.textures.player
    );
    this.enemyFactory = new EnemyFactory(
      this.world, this.renderer.entityContainer, this.renderer.textures.enemies
    );
    this.projectileFactory = new ProjectileFactory(
      this.world, this.renderer.projectileContainer, this.renderer.textures.projectiles
    );
    this.gemFactory = new GemFactory(
      this.world, this.renderer.entityContainer, this.renderer.textures.gems
    );

    // Combat
    this.spatialGrid = new SpatialGrid();
    this.weaponSystem = new WeaponSystem(this.world, this.projectileFactory);
    this.collisionSystem = new CollisionSystem(
      this.world, this.spatialGrid, this.enemyFactory, this.projectileFactory
    );
    this.damageSystem = new DamageSystem(this.renderer.entityContainer);

    // Progression
    this.waveSystem = new WaveSystem(this.enemyFactory);
    this.levelUpSystem = new LevelUpSystem(this.world);
    this.levelUpSystem.addWeapon(WEAPON_TYPES.MAGIC_BOLT);
  }

  private initUI(): void {
    const sw = this.renderer.screenW;
    const sh = this.renderer.screenH;
    this.hud = new HUD(this.renderer.uiContainer, sw, sh);
    this.levelUpUI = new LevelUpUI(this.renderer.uiContainer, sw, sh);
    this.menuScreens = new MenuScreens(this.renderer.uiContainer, sw, sh);
    this.debugOverlay = new DebugOverlay(this.renderer.uiContainer);
  }

  private loop(): void {
    const now = performance.now();
    const rawDt = (now - this.lastTime) / 1000;
    const dt = Math.min(rawDt, 0.05); // Cap at 50ms to prevent spiral
    this.lastTime = now;
    this.time += dt;

    if (this.inputCooldown > 0) this.inputCooldown -= dt;

    switch (this.state) {
      case 'title': this.updateTitle(dt); break;
      case 'playing': this.updatePlaying(dt); break;
      case 'levelup': this.updateLevelUp(dt); break;
      case 'gameover': this.updateGameOver(dt); break;
    }

    // Always update renderer
    this.renderer.update(dt, this.time, this.player.x, this.player.y);

    // Debug
    this.debugOverlay.update(dt, {
      enemies: this.enemyFactory.count,
      projectiles: this.projectileFactory.count,
      particles: this.renderer.particles.activeCount,
      fps: 1 / Math.max(0.001, rawDt),
    });
  }

  private updateTitle(dt: number): void {
    this.menuScreens.updateTitle(this.time);
    if (this.input.anyKeyPressed() && this.inputCooldown <= 0) {
      this.startGame();
    }
  }

  private updatePlaying(dt: number): void {
    // Player movement
    const [mx, my] = this.input.getMovement();
    const speed = Player.speed[this.player.eid] * this.levelUpSystem.stats.speed;
    this.player.move(mx, my, speed, dt);
    this.player.updateSprite();

    // Recovery
    if (this.levelUpSystem.stats.recovery > 0) {
      Health.current[this.player.eid] = Math.min(
        Health.max[this.player.eid],
        Health.current[this.player.eid] + this.levelUpSystem.stats.recovery * dt
      );
    }

    // Wave spawning
    this.waveSystem.update(dt, this.player.x, this.player.y);

    // Enemy movement (chase player)
    this.updateEnemyMovement(dt);

    // Weapon firing
    const nearbyEnemies = this.getNearbyEnemies(400);
    const weaponEvents = this.weaponSystem.update(
      dt, this.player.x, this.player.y, nearbyEnemies, this.levelUpSystem.stats
    );

    // Weapon effects (particles, lights)
    for (const evt of weaponEvents) {
      if (evt.fired) {
        const def = getWeaponDef(evt.weaponType);
        this.renderer.lighting.addLight(evt.x, evt.y, 80, def.glowColor, 0.5, 0);
      }
    }

    // Collisions
    const collResult = this.collisionSystem.update(
      dt, this.player.eid, this.levelUpSystem.stats
    );

    // Handle damage events
    for (const dmg of collResult.damages) {
      this.damageSystem.show(dmg.x, dmg.y - 10, dmg.damage);
      this.renderer.particles.burst(dmg.x, dmg.y, 0xff4444, 3, { life: 0.3, speed: 80 });

      if (dmg.killed) {
        this.handleEnemyDeath(dmg.enemyEid, dmg.x, dmg.y);
      }
    }

    // Handle XP pickups
    for (const pickup of collResult.pickups) {
      const leveled = this.levelUpSystem.addXP(pickup.value, this.player.eid);
      this.renderer.particles.burst(pickup.x, pickup.y, 0x8b5cf6, 4, { life: 0.25, speed: 60 });
      // Remove the gem entity
      this.removeGemAt(pickup.x, pickup.y);
      if (leveled) {
        this.enterLevelUp();
        return;
      }
    }

    // Player hit effects
    if (collResult.playerHit) {
      this.renderer.damageFlash(0.5);
      this.renderer.impact(4);
      this.renderer.particles.burst(this.player.x, this.player.y, 0xef4444, 6, { life: 0.4, speed: 100 });
    }

    // Check death
    if (Health.current[this.player.eid] <= 0) {
      this.enterGameOver();
      return;
    }

    // Update sprites
    this.enemyFactory.updateSprites();
    this.projectileFactory.updateSprites();
    this.gemFactory.updateSprites();
    this.damageSystem.update(dt);

    // Update HUD
    this.hud.update(
      this.player.hp, this.player.maxHp,
      Player.xp[this.player.eid], Player.xpToNext[this.player.eid],
      Player.level[this.player.eid],
      this.waveSystem.timeString, this.waveSystem.kills
    );
  }

  private updateLevelUp(dt: number): void {
    const choice = this.levelUpUI.checkInput((k) => this.input.isDown(k));
    if (choice >= 0 && this.inputCooldown <= 0) {
      this.levelUpSystem.applyChoice(choice);
      this.levelUpUI.hide();
      this.state = 'playing';
      this.input.clear();
      this.inputCooldown = 0.3;
    }
  }

  private updateGameOver(dt: number): void {
    this.menuScreens.updateTitle(this.time);
    if (this.input.anyKeyPressed() && this.inputCooldown <= 0) {
      this.restartGame();
    }
  }

  private updateEnemyMovement(dt: number): void {
    const eids = this.enemyFactory.getActiveEids();
    const px = this.player.x;
    const py = this.player.y;

    for (const eid of eids) {
      // Apply and decay knockback
      if (Math.abs(Enemy.knockbackX[eid]) > 0.1 || Math.abs(Enemy.knockbackY[eid]) > 0.1) {
        Position.x[eid] += Enemy.knockbackX[eid] * dt;
        Position.y[eid] += Enemy.knockbackY[eid] * dt;
        Enemy.knockbackX[eid] *= KNOCKBACK_DECAY;
        Enemy.knockbackY[eid] *= KNOCKBACK_DECAY;
      }

      // Chase player
      const ex = Position.x[eid];
      const ey = Position.y[eid];
      const dx = px - ex;
      const dy = py - ey;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist > 5) {
        const speed = Enemy.speed[eid];
        Position.x[eid] += (dx / dist) * speed * dt;
        Position.y[eid] += (dy / dist) * speed * dt;
      }

      // Clamp to world
      Position.x[eid] = Math.max(0, Math.min(WORLD_SIZE, Position.x[eid]));
      Position.y[eid] = Math.max(0, Math.min(WORLD_SIZE, Position.y[eid]));
    }
  }

  private getNearbyEnemies(range: number): { x: number; y: number; eid: number }[] {
    const result: { x: number; y: number; eid: number }[] = [];
    const eids = this.enemyFactory.getActiveEids();
    const px = this.player.x;
    const py = this.player.y;

    for (const eid of eids) {
      const dx = Position.x[eid] - px;
      const dy = Position.y[eid] - py;
      if (dx * dx + dy * dy < range * range) {
        result.push({ x: Position.x[eid], y: Position.y[eid], eid });
      }
    }
    return result;
  }

  private handleEnemyDeath(eid: number, x: number, y: number): void {
    const enemyType = Enemy.type[eid];
    const def = getEnemyDef(enemyType);

    // Death particles
    this.renderer.particles.burst(x, y, def.color, 8, { life: 0.5, speed: 120 });
    this.renderer.lighting.addLight(x, y, 60, def.glowColor, 0.7, 0);

    // Spawn XP gem
    this.gemFactory.spawn(x, y, def.xpDrop);

    // Remove enemy
    this.enemyFactory.remove(eid);
    this.waveSystem.kills++;

    // Small impact
    this.renderer.impact(1.5);
  }

  private removeGemAt(x: number, y: number): void {
    // Find closest gem entity near this position and remove it
    const gemEids = this.gemFactory as unknown as { pool: { eid: number; active: boolean }[] };
    if (gemEids.pool) {
      for (const entry of gemEids.pool) {
        if (!entry.active) continue;
        const gx = Position.x[entry.eid];
        const gy = Position.y[entry.eid];
        if (Math.abs(gx - x) < 25 && Math.abs(gy - y) < 25) {
          this.gemFactory.remove(entry.eid);
          break;
        }
      }
    }
  }

  private enterLevelUp(): void {
    this.state = 'levelup';
    this.levelUpUI.show(this.levelUpSystem.choices);
    this.input.clear();
    this.inputCooldown = 0.3;
  }

  private enterGameOver(): void {
    this.state = 'gameover';
    this.menuScreens.showGameOver(
      this.waveSystem.timeString,
      this.waveSystem.kills,
      Player.level[this.player.eid]
    );
    this.input.clear();
    this.inputCooldown = 1.0;
  }

  private startGame(): void {
    this.state = 'playing';
    this.menuScreens.showGame();
    this.input.clear();
    this.inputCooldown = 0.3;
  }

  private restartGame(): void {
    // Reset all systems
    this.renderer.destroy();

    const container = document.getElementById('game') || document.body;
    this.renderer = new Renderer(container);
    this.world = createGameWorld();

    this.initSystems();
    this.initUI();
    this.renderer.mapRenderer.generate(Date.now());

    this.state = 'playing';
    this.menuScreens.showGame();
    this.input.clear();
    this.inputCooldown = 0.5;
    this.time = 0;

    this.lastTime = performance.now();
    this.renderer.app.ticker.add(() => this.loop());
  }
}

// === BOOTSTRAP ===
window.addEventListener('DOMContentLoaded', () => {
  const loading = document.getElementById('loading');
  if (loading) loading.remove();
  new Game();
});
