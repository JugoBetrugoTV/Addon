/**
 * Renderer.ts - Main rendering orchestrator.
 * Creates PIXI application, manages layer containers, applies post-processing.
 * Single source of truth for the display pipeline.
 */

import * as PIXI from 'pixi.js';
import { BLOOM_INTENSITY, VIGNETTE_INTENSITY, CHROMATIC_INTENSITY } from '../core/Constants';
import { Camera } from './Camera';
import { MapRenderer } from './MapRenderer';
import { ParticleSystem } from './ParticleSystem';
import { LightingSystem } from './LightingSystem';
import { BloomFilter } from './shaders/BloomShader';
import { VignetteFilter } from './shaders/VignetteShader';
import { ChromaticFilter } from './shaders/ChromaticShader';
import {
  generatePlayerTexture, generateEnemyTextures, generateProjectileTextures,
  generateGemTextures, generateParticleTexture,
} from './TextureGenerator';

export interface TextureAtlas {
  player: PIXI.Texture;
  enemies: PIXI.Texture[];
  projectiles: Map<number, PIXI.Texture>;
  gems: PIXI.Texture[];
  particle: PIXI.Texture;
}

export class Renderer {
  app: PIXI.Application;
  camera: Camera;
  mapRenderer: MapRenderer;
  particles: ParticleSystem;
  lighting: LightingSystem;
  textures: TextureAtlas;

  // Layer containers (bottom to top)
  worldContainer: PIXI.Container;
  entityContainer: PIXI.Container;
  projectileContainer: PIXI.Container;
  effectContainer: PIXI.Container;
  uiContainer: PIXI.Container;

  // Post-processing filters
  private bloomFilter: BloomFilter;
  private vignetteFilter: VignetteFilter;
  private chromaticFilter: ChromaticFilter;

  screenW: number = 0;
  screenH: number = 0;

  constructor(container: HTMLElement) {
    this.app = new PIXI.Application({
      width: window.innerWidth,
      height: window.innerHeight,
      backgroundColor: 0x0a0a0f,
      antialias: false,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
    });
    container.appendChild(this.app.view as HTMLCanvasElement);
    this.screenW = this.app.screen.width;
    this.screenH = this.app.screen.height;

    // Create layer hierarchy
    this.worldContainer = new PIXI.Container();
    this.entityContainer = new PIXI.Container();
    this.projectileContainer = new PIXI.Container();
    this.effectContainer = new PIXI.Container();
    this.uiContainer = new PIXI.Container();

    this.app.stage.addChild(this.worldContainer);
    this.app.stage.addChild(this.entityContainer);
    this.app.stage.addChild(this.projectileContainer);
    this.app.stage.addChild(this.effectContainer);
    this.app.stage.addChild(this.uiContainer);

    // Camera
    this.camera = new Camera();

    // Generate all textures at startup
    this.textures = {
      player: generatePlayerTexture(),
      enemies: generateEnemyTextures(),
      projectiles: generateProjectileTextures(),
      gems: generateGemTextures(),
      particle: generateParticleTexture(),
    };

    // Map
    this.mapRenderer = new MapRenderer(this.worldContainer);

    // Particle system
    this.particles = new ParticleSystem(this.effectContainer, this.textures.particle);

    // Lighting
    this.lighting = new LightingSystem(this.effectContainer);

    // Post-processing
    this.bloomFilter = new BloomFilter(BLOOM_INTENSITY);
    this.vignetteFilter = new VignetteFilter(VIGNETTE_INTENSITY);
    this.chromaticFilter = new ChromaticFilter(CHROMATIC_INTENSITY);

    this.app.stage.filters = [this.bloomFilter, this.chromaticFilter, this.vignetteFilter];

    // Handle resize
    window.addEventListener('resize', () => this.onResize());
  }

  /** Update camera, filters, and particles each frame */
  update(dt: number, time: number, playerX: number, playerY: number): void {
    // Camera follow and shake
    this.camera.follow(playerX, playerY, dt);
    this.camera.update(dt);

    const offset = this.camera.getOffset(this.screenW, this.screenH);

    // Apply camera transform to world layers
    this.worldContainer.position.set(offset.x, offset.y);
    this.worldContainer.scale.set(offset.zoom);
    this.entityContainer.position.set(offset.x, offset.y);
    this.entityContainer.scale.set(offset.zoom);
    this.projectileContainer.position.set(offset.x, offset.y);
    this.projectileContainer.scale.set(offset.zoom);
    this.effectContainer.position.set(offset.x, offset.y);
    this.effectContainer.scale.set(offset.zoom);

    // Update particles
    this.particles.update(dt);

    // Update lighting
    this.lighting.setPlayerPosition(playerX, playerY);
    this.lighting.render(this.camera.x, this.camera.y, this.screenW, this.screenH, time);

    // Map frustum culling
    this.mapRenderer.updateVisibility(this.camera.x, this.camera.y, this.screenW, this.screenH);

    // Update post-processing
    this.vignetteFilter.update(time);
    this.chromaticFilter.boost(this.camera.shakeAmount * 0.01);
  }

  /** Trigger damage flash on vignette */
  damageFlash(intensity: number = 0.6): void {
    this.vignetteFilter.flash(intensity);
  }

  /** Trigger camera shake and chromatic boost */
  impact(intensity: number = 5): void {
    this.camera.shake(intensity);
  }

  private onResize(): void {
    this.app.renderer.resize(window.innerWidth, window.innerHeight);
    this.screenW = this.app.screen.width;
    this.screenH = this.app.screen.height;
  }

  /** Clean up PIXI resources */
  destroy(): void {
    this.app.destroy(true, { children: true, texture: true, baseTexture: true });
  }
}
