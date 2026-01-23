/**
 * CollisionSystem.ts - Handles all collision detection.
 * Uses SpatialGrid for O(1) enemy lookups.
 * Processes: projectile-enemy, player-enemy, player-gem collisions.
 */

import { IWorld } from 'bitecs';
import {
  Position, Velocity, Health, Collision, Projectile, Lifetime,
  Enemy, Player, XPGem,
  projectileCollisionQuery, gemQuery,
} from '../entities/World';
import { SpatialGrid } from './SpatialGrid';
import { EnemyFactory } from '../entities/EnemyFactory';
import { ProjectileFactory } from '../entities/ProjectileFactory';
import { KNOCKBACK_FORCE, INVINCIBILITY_TIME, MAGNET_BASE_RANGE } from '../core/Constants';
import { PlayerStats } from '../progression/UpgradeData';

export interface DamageEvent {
  x: number;
  y: number;
  damage: number;
  enemyEid: number;
  killed: boolean;
}

export interface XPPickupEvent {
  x: number;
  y: number;
  value: number;
}

export class CollisionSystem {
  private world: IWorld;
  private grid: SpatialGrid;
  private enemyFactory: EnemyFactory;
  private projectileFactory: ProjectileFactory;

  constructor(world: IWorld, grid: SpatialGrid, enemyFactory: EnemyFactory, projectileFactory: ProjectileFactory) {
    this.world = world;
    this.grid = grid;
    this.enemyFactory = enemyFactory;
    this.projectileFactory = projectileFactory;
  }

  /** Run all collision checks. Returns damage events for effects. */
  update(
    dt: number, playerEid: number, stats: PlayerStats
  ): { damages: DamageEvent[]; pickups: XPPickupEvent[]; playerHit: boolean } {
    const damages: DamageEvent[] = [];
    let playerHit = false;

    // Rebuild spatial grid with active enemies
    this.grid.clear();
    const enemyEids = this.enemyFactory.getActiveEids();
    for (const eid of enemyEids) {
      this.grid.insert(eid, Position.x[eid], Position.y[eid]);
    }

    // Projectile vs Enemy
    const projEids = projectileCollisionQuery(this.world);
    for (let i = 0; i < projEids.length; i++) {
      const peid = projEids[i];

      // Update lifetime
      Lifetime.remaining[peid] -= dt;
      if (Lifetime.remaining[peid] <= 0) {
        this.projectileFactory.remove(peid);
        continue;
      }

      // Move projectile
      Position.x[peid] += Velocity.x[peid] * dt;
      Position.y[peid] += Velocity.y[peid] * dt;

      // Check collisions with nearby enemies
      const px = Position.x[peid];
      const py = Position.y[peid];
      const pRadius = Collision.radius[peid];
      const nearby = this.grid.query(px, py, pRadius + 30);

      for (const eeid of nearby) {
        if (Health.current[eeid] <= 0) continue;
        const ex = Position.x[eeid];
        const ey = Position.y[eeid];
        const eRadius = Collision.radius[eeid];
        const dx = px - ex;
        const dy = py - ey;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < pRadius + eRadius) {
          const dmg = Projectile.damage[peid];
          Health.current[eeid] -= dmg;
          const killed = Health.current[eeid] <= 0;

          // Knockback
          if (dist > 0) {
            Enemy.knockbackX[eeid] += (dx / dist) * KNOCKBACK_FORCE * -1;
            Enemy.knockbackY[eeid] += (dy / dist) * KNOCKBACK_FORCE * -1;
          }

          damages.push({ x: ex, y: ey, damage: dmg, enemyEid: eeid, killed });

          // Handle pierce
          if (Projectile.pierce[peid] !== -1) {
            Projectile.pierce[peid]--;
            if (Projectile.pierce[peid] <= 0) {
              this.projectileFactory.remove(peid);
              break;
            }
          }
        }
      }
    }

    // Player vs Enemy (contact damage)
    const playerX = Position.x[playerEid];
    const playerY = Position.y[playerEid];
    const playerRadius = Collision.radius[playerEid];

    if (Health.invincibleTimer[playerEid] > 0) {
      Health.invincibleTimer[playerEid] -= dt;
    } else {
      const nearPlayer = this.grid.query(playerX, playerY, playerRadius + 30);
      for (const eeid of nearPlayer) {
        if (Health.current[eeid] <= 0) continue;
        if (Enemy.attackTimer[eeid] > 0) {
          Enemy.attackTimer[eeid] -= dt;
          continue;
        }

        const ex = Position.x[eeid];
        const ey = Position.y[eeid];
        const dx = playerX - ex;
        const dy = playerY - ey;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < playerRadius + Collision.radius[eeid]) {
          const rawDmg = Enemy.damage[eeid];
          const dmg = Math.max(1, rawDmg * (1 - stats.armor));
          Health.current[playerEid] -= dmg;
          Health.invincibleTimer[playerEid] = INVINCIBILITY_TIME;
          Enemy.attackTimer[eeid] = Enemy.attackCooldown[eeid];
          playerHit = true;
          break;
        }
      }
    }

    // Player vs XP Gems
    const pickups: XPPickupEvent[] = [];
    const magnetRange = MAGNET_BASE_RANGE * stats.magnet;
    const gemEids = gemQuery(this.world);
    for (let i = 0; i < gemEids.length; i++) {
      const geid = gemEids[i];
      const gx = Position.x[geid];
      const gy = Position.y[geid];
      const dx = playerX - gx;
      const dy = playerY - gy;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < magnetRange) {
        // Move gem towards player
        const pull = Math.min(1, (magnetRange - dist) / magnetRange) * 400 * dt;
        if (dist > 0) {
          Position.x[geid] += (dx / dist) * pull;
          Position.y[geid] += (dy / dist) * pull;
        }

        if (dist < 20) {
          pickups.push({ x: gx, y: gy, value: XPGem.value[geid] * stats.xpBonus });
        }
      }
    }

    return { damages, pickups, playerHit };
  }
}
