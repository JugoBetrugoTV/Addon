/**
 * MapRenderer.ts - Chunk-based tiled map renderer.
 * Generates map chunks as pre-rendered textures to minimize draw calls.
 * Places decorations (tombstones, trees, etc.) with deterministic seeding.
 */

import * as PIXI from 'pixi.js';
import { WORLD_SIZE, TILE_SIZE, CHUNK_SIZE } from '../core/Constants';
import { generateTileTextures, generateDecorationTextures } from './TextureGenerator';

interface Chunk {
  x: number;
  y: number;
  sprite: PIXI.Sprite;
}

interface Decoration {
  sprite: PIXI.Sprite;
  x: number;
  y: number;
}

export class MapRenderer {
  private container: PIXI.Container;
  private chunks: Chunk[] = [];
  private decorations: Decoration[] = [];
  private tilesPerChunk: number;

  constructor(parent: PIXI.Container) {
    this.container = new PIXI.Container();
    this.container.zIndex = -1;
    parent.addChild(this.container);
    this.tilesPerChunk = Math.ceil(CHUNK_SIZE / TILE_SIZE);
  }

  /** Generate all map chunks and decorations. Call once at game start. */
  generate(seed: number): void {
    const tiles = generateTileTextures(seed);
    const decoData = generateDecorationTextures();
    const rng = this.createRng(seed + 42);

    const chunksPerSide = Math.ceil(WORLD_SIZE / CHUNK_SIZE);

    // Generate chunk textures
    for (let cy = 0; cy < chunksPerSide; cy++) {
      for (let cx = 0; cx < chunksPerSide; cx++) {
        const chunk = this.createChunk(cx, cy, tiles, rng);
        this.chunks.push(chunk);
      }
    }

    // Place decorations
    for (const deco of decoData) {
      for (let i = 0; i < deco.count; i++) {
        const x = rng() * WORLD_SIZE;
        const y = rng() * WORLD_SIZE;
        const sprite = new PIXI.Sprite(deco.tex);
        sprite.anchor.set(0.5, 1.0);
        sprite.position.set(x, y);
        sprite.scale.set(deco.scale);
        sprite.alpha = 0.7 + rng() * 0.3;
        this.container.addChild(sprite);
        this.decorations.push({ sprite, x, y });
      }
    }
  }

  /** Cull chunks and decorations outside camera view */
  updateVisibility(camX: number, camY: number, screenW: number, screenH: number): void {
    const marginChunk = CHUNK_SIZE;
    const halfW = screenW / 2 + marginChunk;
    const halfH = screenH / 2 + marginChunk;

    for (const chunk of this.chunks) {
      const dx = Math.abs(chunk.x + CHUNK_SIZE / 2 - camX);
      const dy = Math.abs(chunk.y + CHUNK_SIZE / 2 - camY);
      chunk.sprite.visible = dx < halfW && dy < halfH;
    }

    const decoMargin = 200;
    const dHalfW = screenW / 2 + decoMargin;
    const dHalfH = screenH / 2 + decoMargin;
    for (const deco of this.decorations) {
      const dx = Math.abs(deco.x - camX);
      const dy = Math.abs(deco.y - camY);
      deco.sprite.visible = dx < dHalfW && dy < dHalfH;
    }
  }

  private createChunk(
    cx: number, cy: number,
    tiles: { grass: PIXI.Texture[]; dirt: PIXI.Texture[]; stone: PIXI.Texture },
    rng: () => number
  ): Chunk {
    const worldX = cx * CHUNK_SIZE;
    const worldY = cy * CHUNK_SIZE;

    // Render chunk to a single texture via RenderTexture alternative:
    // We use a container of tile sprites, rendered once
    const chunkContainer = new PIXI.Container();

    for (let ty = 0; ty < this.tilesPerChunk; ty++) {
      for (let tx = 0; tx < this.tilesPerChunk; tx++) {
        const r = rng();
        let tex: PIXI.Texture;
        if (r < 0.65) {
          tex = tiles.grass[Math.floor(rng() * tiles.grass.length)];
        } else if (r < 0.9) {
          tex = tiles.dirt[Math.floor(rng() * tiles.dirt.length)];
        } else {
          tex = tiles.stone;
        }
        const tile = new PIXI.Sprite(tex);
        tile.position.set(tx * TILE_SIZE, ty * TILE_SIZE);
        chunkContainer.addChild(tile);
      }
    }

    // Position the chunk container in the world
    chunkContainer.position.set(worldX, worldY);
    this.container.addChild(chunkContainer);

    // Use the container directly as the "sprite" for visibility culling
    return {
      x: worldX,
      y: worldY,
      sprite: chunkContainer as unknown as PIXI.Sprite,
    };
  }

  private createRng(seed: number): () => number {
    let s = seed;
    return () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
  }
}
