/**
 * ParticleSystem.ts - High-performance pooled particle system.
 * Pre-allocates sprites; reuses them via circular buffer.
 * All particles share one texture, tinted per-particle.
 */

import * as PIXI from 'pixi.js';
import { MAX_PARTICLES, PARTICLE_GRAVITY, PARTICLE_FADE_SPEED } from '../core/Constants';

interface ParticleState {
  active: boolean;
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  scale: number;
  scaleDecay: number;
  gravity: number;
}

export class ParticleSystem {
  private container: PIXI.Container;
  private sprites: PIXI.Sprite[] = [];
  private states: ParticleState[] = [];
  private nextSlot: number = 0;

  constructor(parent: PIXI.Container, texture: PIXI.Texture) {
    this.container = new PIXI.Container();
    parent.addChild(this.container);

    // Pre-allocate all particle sprites
    for (let i = 0; i < MAX_PARTICLES; i++) {
      const sprite = new PIXI.Sprite(texture);
      sprite.anchor.set(0.5);
      sprite.visible = false;
      sprite.blendMode = PIXI.BLEND_MODES.ADD; // Additive blending for glow
      this.container.addChild(sprite);
      this.sprites.push(sprite);
      this.states.push({
        active: false, x: 0, y: 0, vx: 0, vy: 0,
        life: 0, maxLife: 0, scale: 1, scaleDecay: 1, gravity: PARTICLE_GRAVITY,
      });
    }
  }

  /**
   * Emit a single particle.
   * @param x World X position
   * @param y World Y position
   * @param color Tint color (e.g. 0xff0000)
   * @param life Lifetime in seconds
   * @param options Override velocity, scale, gravity
   */
  emit(x: number, y: number, color: number, life: number, options?: {
    vx?: number; vy?: number; scale?: number; gravity?: number; scaleDecay?: number;
  }): void {
    const idx = this.nextSlot;
    this.nextSlot = (this.nextSlot + 1) % MAX_PARTICLES;

    const state = this.states[idx];
    state.active = true;
    state.x = x;
    state.y = y;
    state.vx = options?.vx ?? (Math.random() - 0.5) * 200;
    state.vy = options?.vy ?? (-Math.random() * 160 - 60);
    state.life = life;
    state.maxLife = life;
    state.scale = options?.scale ?? (0.6 + Math.random() * 0.8);
    state.scaleDecay = options?.scaleDecay ?? 1.0;
    state.gravity = options?.gravity ?? PARTICLE_GRAVITY;

    const sprite = this.sprites[idx];
    sprite.tint = color;
    sprite.visible = true;
    sprite.alpha = 1;
    sprite.scale.set(state.scale);
    sprite.position.set(x, y);
  }

  /**
   * Emit a burst of particles (for explosions, death effects).
   * @param count Number of particles to emit
   */
  burst(x: number, y: number, color: number, count: number, options?: {
    life?: number; speed?: number; scale?: number; gravity?: number;
  }): void {
    const life = options?.life ?? 0.5;
    const speed = options?.speed ?? 180;
    const scale = options?.scale ?? 0.7;
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + (Math.random() - 0.5) * 0.5;
      const spd = speed * (0.5 + Math.random() * 0.5);
      this.emit(x, y, color, life, {
        vx: Math.cos(angle) * spd,
        vy: Math.sin(angle) * spd,
        scale,
        gravity: options?.gravity ?? 60,
      });
    }
  }

  /** Update all active particles. Call once per frame. */
  update(dt: number): void {
    for (let i = 0; i < MAX_PARTICLES; i++) {
      const state = this.states[i];
      if (!state.active) continue;

      state.life -= dt;
      if (state.life <= 0) {
        state.active = false;
        this.sprites[i].visible = false;
        continue;
      }

      // Physics
      state.x += state.vx * dt;
      state.y += state.vy * dt;
      state.vy += state.gravity * dt;

      // Visual decay
      const lifeRatio = state.life / state.maxLife;
      const sprite = this.sprites[i];
      sprite.position.set(state.x, state.y);
      sprite.alpha = Math.min(1, lifeRatio * PARTICLE_FADE_SPEED);
      sprite.scale.set(state.scale * lifeRatio * state.scaleDecay);
    }
  }

  /** Get active particle count (for debug) */
  get activeCount(): number {
    let count = 0;
    for (let i = 0; i < MAX_PARTICLES; i++) {
      if (this.states[i].active) count++;
    }
    return count;
  }
}
