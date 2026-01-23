/**
 * Player.ts - Player entity creation and sprite management.
 * Creates the ECS entity and attaches a PIXI sprite to it.
 */

import * as PIXI from 'pixi.js';
import { addEntity, addComponent, IWorld } from 'bitecs';
import { Position, Velocity, Health, Collision, Player, PlayerTag } from './World';
import { PLAYER_BASE_SPEED, PLAYER_BASE_HP, WORLD_SIZE } from '../core/Constants';

export class PlayerEntity {
  eid: number;
  sprite: PIXI.Sprite;

  constructor(world: IWorld, container: PIXI.Container, texture: PIXI.Texture) {
    this.eid = addEntity(world);

    addComponent(world, Position, this.eid);
    addComponent(world, Velocity, this.eid);
    addComponent(world, Health, this.eid);
    addComponent(world, Collision, this.eid);
    addComponent(world, Player, this.eid);
    addComponent(world, PlayerTag, this.eid);

    Position.x[this.eid] = WORLD_SIZE / 2;
    Position.y[this.eid] = WORLD_SIZE / 2;
    Velocity.x[this.eid] = 0;
    Velocity.y[this.eid] = 0;
    Health.current[this.eid] = PLAYER_BASE_HP;
    Health.max[this.eid] = PLAYER_BASE_HP;
    Health.invincibleTimer[this.eid] = 0;
    Collision.radius[this.eid] = 14;
    Player.speed[this.eid] = PLAYER_BASE_SPEED;
    Player.xp[this.eid] = 0;
    Player.level[this.eid] = 1;
    Player.xpToNext[this.eid] = 5;

    this.sprite = new PIXI.Sprite(texture);
    this.sprite.anchor.set(0.5);
    this.sprite.position.set(WORLD_SIZE / 2, WORLD_SIZE / 2);
    container.addChild(this.sprite);
  }

  /** Update sprite to match ECS position */
  updateSprite(): void {
    this.sprite.position.set(Position.x[this.eid], Position.y[this.eid]);
  }

  /** Apply movement from input, respecting world bounds */
  move(mx: number, my: number, speed: number, dt: number): void {
    const px = Position.x[this.eid] + mx * speed * dt;
    const py = Position.y[this.eid] + my * speed * dt;
    Position.x[this.eid] = Math.max(20, Math.min(WORLD_SIZE - 20, px));
    Position.y[this.eid] = Math.max(20, Math.min(WORLD_SIZE - 20, py));
  }

  get x(): number { return Position.x[this.eid]; }
  get y(): number { return Position.y[this.eid]; }
  get hp(): number { return Health.current[this.eid]; }
  get maxHp(): number { return Health.max[this.eid]; }
}
