/**
 * DamageSystem.ts - Visual damage feedback.
 * Manages floating damage numbers, hit effects, and death explosions.
 * Uses pooled PIXI.Text objects for zero-allocation rendering.
 */

import * as PIXI from 'pixi.js';
import { MAX_DAMAGE_NUMBERS, DAMAGE_NUMBER_LIFETIME, DAMAGE_NUMBER_VELOCITY } from '../core/Constants';

interface DamageNumber {
  text: PIXI.Text;
  x: number;
  y: number;
  vy: number;
  life: number;
  active: boolean;
}

export class DamageSystem {
  private container: PIXI.Container;
  private pool: DamageNumber[] = [];
  private nextSlot: number = 0;

  constructor(parent: PIXI.Container) {
    this.container = new PIXI.Container();
    parent.addChild(this.container);

    // Pre-allocate damage number text objects
    const style = new PIXI.TextStyle({
      fontFamily: 'Arial',
      fontSize: 16,
      fontWeight: 'bold',
      fill: '#ffffff',
      stroke: '#000000',
      strokeThickness: 3,
    });

    for (let i = 0; i < MAX_DAMAGE_NUMBERS; i++) {
      const text = new PIXI.Text('', style);
      text.anchor.set(0.5);
      text.visible = false;
      this.container.addChild(text);
      this.pool.push({ text, x: 0, y: 0, vy: DAMAGE_NUMBER_VELOCITY, life: 0, active: false });
    }
  }

  /** Show a damage number at position */
  show(x: number, y: number, damage: number, critical: boolean = false): void {
    const entry = this.pool[this.nextSlot];
    this.nextSlot = (this.nextSlot + 1) % MAX_DAMAGE_NUMBERS;

    entry.active = true;
    entry.x = x + (Math.random() - 0.5) * 20;
    entry.y = y - 10;
    entry.vy = DAMAGE_NUMBER_VELOCITY + (Math.random() - 0.5) * 20;
    entry.life = DAMAGE_NUMBER_LIFETIME;

    entry.text.text = Math.floor(damage).toString();
    entry.text.visible = true;
    entry.text.position.set(entry.x, entry.y);
    entry.text.alpha = 1;

    if (critical) {
      entry.text.style.fill = '#fbbf24';
      entry.text.style.fontSize = 22;
    } else {
      entry.text.style.fill = '#ffffff';
      entry.text.style.fontSize = 16;
    }
  }

  /** Update floating numbers (move up, fade out) */
  update(dt: number): void {
    for (const entry of this.pool) {
      if (!entry.active) continue;

      entry.life -= dt;
      if (entry.life <= 0) {
        entry.active = false;
        entry.text.visible = false;
        continue;
      }

      entry.y += entry.vy * dt;
      entry.text.position.set(entry.x, entry.y);
      entry.text.alpha = Math.min(1, entry.life / (DAMAGE_NUMBER_LIFETIME * 0.5));
      entry.text.scale.set(1 + (1 - entry.life / DAMAGE_NUMBER_LIFETIME) * 0.3);
    }
  }
}
