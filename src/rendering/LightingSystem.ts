/**
 * LightingSystem.ts - Dynamic 2D point light system.
 * Renders colored light circles onto a dark overlay.
 * Uses multiply blend to darken unlit areas and brighten lit areas.
 * Performance: Max 30 lights, culled by camera frustum.
 */

import * as PIXI from 'pixi.js';

interface Light {
  x: number;
  y: number;
  radius: number;
  color: number;
  intensity: number;
  flicker: number;  // 0 = steady, 1 = maximum flicker
}

const MAX_LIGHTS = 30;

export class LightingSystem {
  private container: PIXI.Container;
  private lightGraphics: PIXI.Graphics;
  private ambientLevel: number = 0.15;  // Ambient brightness (0=pitch black, 1=fully lit)
  private lights: Light[] = [];
  private playerLight: Light;

  constructor(parent: PIXI.Container) {
    this.container = new PIXI.Container();
    parent.addChild(this.container);

    this.lightGraphics = new PIXI.Graphics();
    // Multiply blend: dark areas darken the scene, bright areas keep it
    this.lightGraphics.blendMode = PIXI.BLEND_MODES.MULTIPLY;
    this.container.addChild(this.lightGraphics);

    // Player always has a light
    this.playerLight = {
      x: 0, y: 0, radius: 250, color: 0xc4a0ff, intensity: 0.6, flicker: 0.05,
    };
  }

  /** Update player light position */
  setPlayerPosition(x: number, y: number): void {
    this.playerLight.x = x;
    this.playerLight.y = y;
  }

  /** Add a temporary light (e.g. weapon fire, explosion) */
  addLight(x: number, y: number, radius: number, color: number, intensity: number = 0.8, flicker: number = 0): void {
    if (this.lights.length >= MAX_LIGHTS) {
      // Replace oldest
      this.lights.shift();
    }
    this.lights.push({ x, y, radius, color, intensity, flicker });
  }

  /** Clear all temporary lights (called each frame before re-adding) */
  clearLights(): void {
    this.lights.length = 0;
  }

  /** Render the lighting overlay. Call after entity updates. */
  render(cameraX: number, cameraY: number, screenW: number, screenH: number, time: number): void {
    const g = this.lightGraphics;
    g.clear();

    // Fill with ambient darkness
    const ambient = Math.floor(this.ambientLevel * 255);
    const ambientColor = (ambient << 16) | (ambient << 8) | ambient;
    g.beginFill(ambientColor);
    g.drawRect(cameraX - screenW, cameraY - screenH, screenW * 3, screenH * 3);
    g.endFill();

    // Draw player light
    this.drawLight(g, this.playerLight, time);

    // Draw temporary lights (with frustum culling)
    const margin = 300;
    for (let i = 0; i < this.lights.length; i++) {
      const light = this.lights[i];
      if (Math.abs(light.x - cameraX) < screenW / 2 + margin &&
          Math.abs(light.y - cameraY) < screenH / 2 + margin) {
        this.drawLight(g, light, time);
      }
    }
  }

  private drawLight(g: PIXI.Graphics, light: Light, time: number): void {
    const flickerAmount = light.flicker > 0
      ? 1 + Math.sin(time * 12 + light.x * 0.01) * light.flicker * 0.3
      : 1;
    const radius = light.radius * flickerAmount;
    const intensity = light.intensity * flickerAmount;

    // Draw multiple concentric circles for soft falloff
    const steps = 4;
    for (let s = steps; s >= 1; s--) {
      const r = radius * (s / steps);
      const alpha = intensity * (1 - (s - 1) / steps) * 0.5;
      const colorR = ((light.color >> 16) & 0xFF) / 255;
      const colorG = ((light.color >> 8) & 0xFF) / 255;
      const colorB = (light.color & 0xFF) / 255;

      // Blend towards white for lighting effect
      const mixedR = Math.min(255, Math.floor((this.ambientLevel + colorR * alpha) * 255));
      const mixedG = Math.min(255, Math.floor((this.ambientLevel + colorG * alpha) * 255));
      const mixedB = Math.min(255, Math.floor((this.ambientLevel + colorB * alpha) * 255));
      const mixedColor = (mixedR << 16) | (mixedG << 8) | mixedB;

      g.beginFill(mixedColor);
      g.drawCircle(light.x, light.y, r);
      g.endFill();
    }
  }

  /** Set ambient light level (0 = dark, 1 = bright) */
  setAmbient(level: number): void {
    this.ambientLevel = Math.max(0.05, Math.min(1, level));
  }
}
