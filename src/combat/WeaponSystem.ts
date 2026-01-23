/**
 * WeaponSystem.ts - Weapon firing logic for all 8 weapon types.
 * Each weapon has a unique pattern (projectiles, auras, chains, etc.).
 * Timers managed via ECS Weapon component.
 */

import { IWorld } from 'bitecs';
import { Weapon, weaponQuery } from '../entities/World';
import { getWeaponDef, WEAPON_TYPES } from './WeaponTypes';
import { ProjectileFactory } from '../entities/ProjectileFactory';
import { PlayerStats } from '../progression/UpgradeData';

export class WeaponSystem {
  private world: IWorld;
  private projectiles: ProjectileFactory;

  constructor(world: IWorld, projectiles: ProjectileFactory) {
    this.world = world;
    this.projectiles = projectiles;
  }

  /** Update weapon timers and fire when ready */
  update(
    dt: number,
    playerX: number, playerY: number,
    enemies: { x: number; y: number; eid: number }[],
    stats: PlayerStats
  ): { fired: boolean; weaponType: number; x: number; y: number }[] {
    const events: { fired: boolean; weaponType: number; x: number; y: number }[] = [];
    const weaponEids = weaponQuery(this.world);

    for (let i = 0; i < weaponEids.length; i++) {
      const weid = weaponEids[i];
      Weapon.timer[weid] -= dt;

      if (Weapon.timer[weid] <= 0) {
        const type = Weapon.type[weid];
        const level = Weapon.level[weid];
        const cooldown = Weapon.cooldown[weid] * (1 - stats.cooldown * 0.08);
        Weapon.timer[weid] = Math.max(0.1, cooldown);

        const damage = Weapon.damage[weid] * stats.damage;
        const count = Weapon.count[weid] + stats.amount;
        const pierce = Weapon.pierce[weid];
        const speed = Weapon.speed[weid];
        const range = Weapon.range[weid];
        const area = Weapon.area[weid] * stats.area;

        const result = this.fireWeapon(type, playerX, playerY, damage, count, pierce, speed, range, area, enemies);
        if (result) {
          events.push({ fired: true, weaponType: type, x: playerX, y: playerY });
        }
      }
    }
    return events;
  }

  private fireWeapon(
    type: number, px: number, py: number,
    damage: number, count: number, pierce: number,
    speed: number, range: number, area: number,
    enemies: { x: number; y: number; eid: number }[]
  ): boolean {
    switch (type) {
      case WEAPON_TYPES.WHIP:
        return this.fireWhip(px, py, damage, count, range, area);
      case WEAPON_TYPES.MAGIC_BOLT:
        return this.fireBolt(px, py, damage, count, pierce, speed, enemies);
      case WEAPON_TYPES.FIRE_CIRCLE:
        return this.fireCircle(px, py, damage, count, speed, area);
      case WEAPON_TYPES.HOLY_CROSS:
        return this.fireCross(px, py, damage, count, pierce, speed);
      case WEAPON_TYPES.GARLIC:
        return true; // Handled by AreaEffect in CollisionSystem
      case WEAPON_TYPES.LIGHTNING:
        return this.fireLightning(px, py, damage, count, enemies);
      case WEAPON_TYPES.SCYTHE:
        return this.fireScythe(px, py, damage, count, pierce, speed);
      case WEAPON_TYPES.BLOOD_WAVE:
        return this.fireBloodWave(px, py, damage, count, speed, area);
      default:
        return false;
    }
  }

  private fireWhip(px: number, py: number, damage: number, count: number, range: number, area: number): boolean {
    for (let i = 0; i < count; i++) {
      const angle = (Math.random() - 0.5) * Math.PI * 0.8;
      const vx = Math.cos(angle) * 50;
      const vy = Math.sin(angle) * 50;
      this.projectiles.spawn(px + vx * 0.5, py + vy * 0.5, vx, vy, damage, -1, WEAPON_TYPES.WHIP, 50, 0.3);
    }
    return true;
  }

  private fireBolt(px: number, py: number, damage: number, count: number, pierce: number, speed: number, enemies: { x: number; y: number }[]): boolean {
    for (let i = 0; i < count; i++) {
      let angle: number;
      if (enemies.length > 0) {
        const target = enemies[Math.floor(Math.random() * Math.min(enemies.length, 5))];
        angle = Math.atan2(target.y - py, target.x - px);
      } else {
        angle = Math.random() * Math.PI * 2;
      }
      angle += (Math.random() - 0.5) * 0.3;
      this.projectiles.spawn(px, py, Math.cos(angle) * speed, Math.sin(angle) * speed, damage, pierce, WEAPON_TYPES.MAGIC_BOLT, speed);
    }
    return true;
  }

  private fireCircle(px: number, py: number, damage: number, count: number, speed: number, area: number): boolean {
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + Math.random() * 0.2;
      const vx = Math.cos(angle) * speed;
      const vy = Math.sin(angle) * speed;
      this.projectiles.spawn(px, py, vx, vy, damage, -1, WEAPON_TYPES.FIRE_CIRCLE, speed, 1.5);
    }
    return true;
  }

  private fireCross(px: number, py: number, damage: number, count: number, pierce: number, speed: number): boolean {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      this.projectiles.spawn(px, py, Math.cos(angle) * speed, Math.sin(angle) * speed, damage, pierce, WEAPON_TYPES.HOLY_CROSS, speed, 2.0);
    }
    return true;
  }

  private fireLightning(px: number, py: number, damage: number, count: number, enemies: { x: number; y: number; eid: number }[]): boolean {
    if (enemies.length === 0) return false;
    for (let i = 0; i < count; i++) {
      const target = enemies[Math.floor(Math.random() * enemies.length)];
      const dx = target.x - px;
      const dy = target.y - py;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 400) {
        this.projectiles.spawn(target.x, target.y, 0, 0, damage, 2, WEAPON_TYPES.LIGHTNING, 0, 0.15);
      }
    }
    return true;
  }

  private fireScythe(px: number, py: number, damage: number, count: number, pierce: number, speed: number): boolean {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      this.projectiles.spawn(px, py, Math.cos(angle) * speed, Math.sin(angle) * speed, damage, pierce, WEAPON_TYPES.SCYTHE, speed, 3.0);
    }
    return true;
  }

  private fireBloodWave(px: number, py: number, damage: number, count: number, speed: number, area: number): boolean {
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count;
      this.projectiles.spawn(px, py, Math.cos(angle) * speed, Math.sin(angle) * speed, damage, -1, WEAPON_TYPES.BLOOD_WAVE, speed, 2.0);
    }
    return true;
  }
}
