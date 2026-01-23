/**
 * EnemyFactory.ts - Enemy entity creation and sprite pool management.
 * Creates enemies from EnemyDef data and manages their sprites.
 */

import * as PIXI from 'pixi.js';
import { addEntity, addComponent, removeEntity, IWorld } from 'bitecs';
import { Position, Velocity, Health, Collision, Enemy, EnemyTag } from './World';
import { getEnemyDef, EnemyDef } from '../progression/EnemyData';
import { MAX_ENEMIES, SPAWN_DISTANCE } from '../core/Constants';

interface EnemySprite {
  eid: number;
  sprite: PIXI.Sprite;
  active: boolean;
}

export class EnemyFactory {
  private world: IWorld;
  private container: PIXI.Container;
  private textures: PIXI.Texture[];
  private pool: EnemySprite[] = [];
  private activeCount: number = 0;

  constructor(world: IWorld, container: PIXI.Container, textures: PIXI.Texture[]) {
    this.world = world;
    this.container = container;
    this.textures = textures;
  }

  /** Spawn an enemy of given type near the player */
  spawn(type: number, playerX: number, playerY: number, healthMult: number, speedMult: number): number | null {
    if (this.activeCount >= MAX_ENEMIES) return null;

    const def = getEnemyDef(type);
    const angle = Math.random() * Math.PI * 2;
    const dist = SPAWN_DISTANCE + Math.random() * 100;
    const x = playerX + Math.cos(angle) * dist;
    const y = playerY + Math.sin(angle) * dist;

    // Find or create a pool entry
    let entry = this.findInactive();
    if (!entry) {
      entry = this.createEntry(def);
    }

    const eid = addEntity(this.world);
    addComponent(this.world, Position, eid);
    addComponent(this.world, Velocity, eid);
    addComponent(this.world, Health, eid);
    addComponent(this.world, Collision, eid);
    addComponent(this.world, Enemy, eid);
    addComponent(this.world, EnemyTag, eid);

    Position.x[eid] = x;
    Position.y[eid] = y;
    Velocity.x[eid] = 0;
    Velocity.y[eid] = 0;
    Health.current[eid] = def.health * healthMult;
    Health.max[eid] = def.health * healthMult;
    Health.invincibleTimer[eid] = 0;
    Collision.radius[eid] = def.size;
    Enemy.type[eid] = type;
    Enemy.speed[eid] = def.speed * speedMult;
    Enemy.damage[eid] = def.damage;
    Enemy.xpDrop[eid] = def.xpDrop;
    Enemy.attackCooldown[eid] = def.attackCooldown;
    Enemy.attackTimer[eid] = 0;
    Enemy.knockbackX[eid] = 0;
    Enemy.knockbackY[eid] = 0;

    entry.eid = eid;
    entry.active = true;
    entry.sprite.texture = this.textures[type] || this.textures[0];
    entry.sprite.position.set(x, y);
    entry.sprite.visible = true;
    entry.sprite.alpha = 1;
    this.activeCount++;

    return eid;
  }

  /** Remove an enemy (death) */
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

  /** Update all enemy sprites from ECS positions */
  updateSprites(): void {
    for (const entry of this.pool) {
      if (!entry.active) continue;
      entry.sprite.position.set(
        Position.x[entry.eid],
        Position.y[entry.eid]
      );
    }
  }

  /** Get sprite for a given entity ID */
  getSprite(eid: number): PIXI.Sprite | null {
    for (const entry of this.pool) {
      if (entry.active && entry.eid === eid) return entry.sprite;
    }
    return null;
  }

  /** Get all active enemy entity IDs */
  getActiveEids(): number[] {
    const result: number[] = [];
    for (const entry of this.pool) {
      if (entry.active) result.push(entry.eid);
    }
    return result;
  }

  get count(): number { return this.activeCount; }

  private findInactive(): EnemySprite | null {
    for (const entry of this.pool) {
      if (!entry.active) return entry;
    }
    return null;
  }

  private createEntry(def: EnemyDef): EnemySprite {
    const sprite = new PIXI.Sprite(this.textures[0]);
    sprite.anchor.set(0.5);
    sprite.visible = false;
    this.container.addChild(sprite);
    const entry: EnemySprite = { eid: 0, sprite, active: false };
    this.pool.push(entry);
    return entry;
  }
}
