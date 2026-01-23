/**
 * GemFactory.ts - XP gem entity creation and sprite pool.
 * Manages gem lifecycle: spawn on enemy death, attract to player, collect.
 */

import * as PIXI from 'pixi.js';
import { addEntity, addComponent, removeEntity, IWorld } from 'bitecs';
import { Position, XPGem, XPGemTag } from './World';
import { MAX_XP_GEMS } from '../core/Constants';

interface GemEntry {
  eid: number;
  sprite: PIXI.Sprite;
  active: boolean;
}

export class GemFactory {
  private world: IWorld;
  private container: PIXI.Container;
  private textures: PIXI.Texture[];
  private pool: GemEntry[] = [];
  private activeCount: number = 0;

  constructor(world: IWorld, container: PIXI.Container, textures: PIXI.Texture[]) {
    this.world = world;
    this.container = container;
    this.textures = textures;
  }

  /** Spawn an XP gem at position */
  spawn(x: number, y: number, value: number): void {
    if (this.activeCount >= MAX_XP_GEMS) return;

    let entry = this.findInactive();
    if (!entry) {
      entry = this.createEntry();
    }

    const eid = addEntity(this.world);
    addComponent(this.world, Position, eid);
    addComponent(this.world, XPGem, eid);
    addComponent(this.world, XPGemTag, eid);

    Position.x[eid] = x + (Math.random() - 0.5) * 20;
    Position.y[eid] = y + (Math.random() - 0.5) * 20;
    XPGem.value[eid] = value;

    // Pick texture based on value
    const texIdx = value >= 10 ? 2 : value >= 3 ? 1 : 0;
    entry.eid = eid;
    entry.active = true;
    entry.sprite.texture = this.textures[texIdx] || this.textures[0];
    entry.sprite.position.set(Position.x[eid], Position.y[eid]);
    entry.sprite.visible = true;
    this.activeCount++;
  }

  /** Remove a collected gem */
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

  /** Update sprite positions (for magnet pull animation) */
  updateSprites(): void {
    for (const entry of this.pool) {
      if (!entry.active) continue;
      entry.sprite.position.set(Position.x[entry.eid], Position.y[entry.eid]);
    }
  }

  get count(): number { return this.activeCount; }

  private findInactive(): GemEntry | null {
    for (const entry of this.pool) {
      if (!entry.active) return entry;
    }
    return null;
  }

  private createEntry(): GemEntry {
    const sprite = new PIXI.Sprite(this.textures[0]);
    sprite.anchor.set(0.5);
    sprite.visible = false;
    this.container.addChild(sprite);
    const entry: GemEntry = { eid: 0, sprite, active: false };
    this.pool.push(entry);
    return entry;
  }
}
