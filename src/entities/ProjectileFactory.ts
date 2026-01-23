/**
 * ProjectileFactory.ts - Projectile entity creation and sprite pool.
 * Manages projectile lifecycle (spawn, move, expire, recycle).
 */

import * as PIXI from 'pixi.js';
import { addEntity, addComponent, removeEntity, IWorld } from 'bitecs';
import { Position, Velocity, Collision, Projectile, ProjectileTag, Lifetime } from './World';
import { MAX_PROJECTILES } from '../core/Constants';

interface ProjEntry {
  eid: number;
  sprite: PIXI.Sprite;
  active: boolean;
}

export class ProjectileFactory {
  private world: IWorld;
  private container: PIXI.Container;
  private textures: Map<number, PIXI.Texture>;
  private pool: ProjEntry[] = [];
  private activeCount: number = 0;

  constructor(world: IWorld, container: PIXI.Container, textures: Map<number, PIXI.Texture>) {
    this.world = world;
    this.container = container;
    this.textures = textures;
  }

  /** Spawn a projectile at position, moving in given direction */
  spawn(
    x: number, y: number,
    vx: number, vy: number,
    damage: number, pierce: number,
    weaponType: number, speed: number,
    lifetime: number = 3.0
  ): number | null {
    if (this.activeCount >= MAX_PROJECTILES) return null;

    let entry = this.findInactive();
    if (!entry) {
      entry = this.createEntry();
    }

    const eid = addEntity(this.world);
    addComponent(this.world, Position, eid);
    addComponent(this.world, Velocity, eid);
    addComponent(this.world, Collision, eid);
    addComponent(this.world, Projectile, eid);
    addComponent(this.world, ProjectileTag, eid);
    addComponent(this.world, Lifetime, eid);

    Position.x[eid] = x;
    Position.y[eid] = y;
    Velocity.x[eid] = vx;
    Velocity.y[eid] = vy;
    Collision.radius[eid] = 8;
    Projectile.damage[eid] = damage;
    Projectile.pierce[eid] = pierce;
    Projectile.ownerWeaponType[eid] = weaponType;
    Projectile.speed[eid] = speed;
    Lifetime.remaining[eid] = lifetime;

    const tex = this.textures.get(weaponType) || this.textures.get(1)!;
    entry.eid = eid;
    entry.active = true;
    entry.sprite.texture = tex;
    entry.sprite.position.set(x, y);
    entry.sprite.visible = true;
    entry.sprite.alpha = 1;
    entry.sprite.rotation = Math.atan2(vy, vx);
    this.activeCount++;

    return eid;
  }

  /** Remove a projectile (hit or expired) */
  remove(eid: number): void {
    for (const entry of this.pool) {
      if (entry.active && entry.eid === eid) {
        entry.active = false;
        entry.sprite.visible = false;
        this.activeCount--;
        removeEntity(this.world, eid);
        break;
      }
    }
  }

  /** Update sprite positions from ECS */
  updateSprites(): void {
    for (const entry of this.pool) {
      if (!entry.active) continue;
      const x = Position.x[entry.eid];
      const y = Position.y[entry.eid];
      entry.sprite.position.set(x, y);
      entry.sprite.rotation = Math.atan2(Velocity.y[entry.eid], Velocity.x[entry.eid]);
    }
  }

  /** Get all active projectile entries */
  getActiveEntries(): { eid: number; sprite: PIXI.Sprite }[] {
    const result: { eid: number; sprite: PIXI.Sprite }[] = [];
    for (const entry of this.pool) {
      if (entry.active) result.push({ eid: entry.eid, sprite: entry.sprite });
    }
    return result;
  }

  get count(): number { return this.activeCount; }

  private findInactive(): ProjEntry | null {
    for (const entry of this.pool) {
      if (!entry.active) return entry;
    }
    return null;
  }

  private createEntry(): ProjEntry {
    const sprite = new PIXI.Sprite(PIXI.Texture.WHITE);
    sprite.anchor.set(0.5);
    sprite.visible = false;
    sprite.blendMode = PIXI.BLEND_MODES.ADD;
    this.container.addChild(sprite);
    const entry: ProjEntry = { eid: 0, sprite, active: false };
    this.pool.push(entry);
    return entry;
  }
}
