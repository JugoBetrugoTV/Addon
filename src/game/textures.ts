import * as PIXI from 'pixi.js';

// ============================================================
// PIXEL ART TEXTURE GENERATOR
// Generates all game textures at startup using offscreen canvas
// ============================================================

const SPRITE_SIZE = 32;
const TILE_SIZE = 64;

type PixelData = number[][];

function createTexture(width: number, height: number, drawFn: (ctx: CanvasRenderingContext2D) => void): PIXI.Texture {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d')!;
  ctx.imageSmoothingEnabled = false;
  drawFn(ctx);
  return PIXI.Texture.from(canvas);
}

function drawPixels(ctx: CanvasRenderingContext2D, pixels: PixelData, palette: string[], scale: number = 2, ox: number = 0, oy: number = 0): void {
  for (let y = 0; y < pixels.length; y++) {
    for (let x = 0; x < pixels[y].length; x++) {
      const colorIdx = pixels[y][x];
      if (colorIdx > 0 && palette[colorIdx]) {
        ctx.fillStyle = palette[colorIdx];
        ctx.fillRect(ox + x * scale, oy + y * scale, scale, scale);
      }
    }
  }
}

// ============================================================
// PLAYER SPRITE
// ============================================================
function generatePlayerTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,0,1,1,1,1,0,0,0],
    [0,0,1,2,2,2,2,1,0,0],
    [0,1,2,2,2,2,2,2,1,0],
    [0,1,2,3,2,2,3,2,1,0],
    [0,1,2,3,2,2,3,2,1,0],
    [0,1,2,2,2,2,2,2,1,0],
    [0,0,1,2,4,4,2,1,0,0],
    [0,0,0,1,1,1,1,0,0,0],
    [0,0,1,5,5,5,5,1,0,0],
    [0,1,5,5,5,5,5,5,1,0],
    [1,5,5,5,5,5,5,5,5,1],
    [1,5,5,5,5,5,5,5,5,1],
    [0,1,5,5,5,5,5,5,1,0],
    [0,0,1,5,0,0,5,1,0,0],
    [0,0,1,1,0,0,1,1,0,0],
    [0,0,6,6,0,0,6,6,0,0],
  ];
  const palette = ['', '#1a1a2e', '#c4a0ff', '#4a2080', '#ff6699', '#6b3fa0', '#3d2060'];
  return createTexture(SPRITE_SIZE, SPRITE_SIZE, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 6, 0);
  });
}

// ============================================================
// ENEMY SPRITES
// ============================================================

function generateSkeletonTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,0,1,1,1,0,0,0],
    [0,0,1,2,2,2,1,0,0],
    [0,1,2,2,2,2,2,1,0],
    [0,1,3,2,2,3,2,1,0],
    [0,1,2,2,2,2,2,1,0],
    [0,0,1,2,4,2,1,0,0],
    [0,0,0,1,1,1,0,0,0],
    [0,0,1,2,2,2,1,0,0],
    [0,1,1,2,2,2,1,1,0],
    [1,0,1,2,2,2,1,0,1],
    [0,0,0,1,2,1,0,0,0],
    [0,0,0,1,2,1,0,0,0],
    [0,0,1,0,0,0,1,0,0],
    [0,0,1,0,0,0,1,0,0],
  ];
  const palette = ['', '#333333', '#e8e8e8', '#222222', '#444444'];
  return createTexture(SPRITE_SIZE, SPRITE_SIZE, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 5, 2);
  });
}

function generateBatTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0],
    [1,1,0,0,0,0,0,0,0,0,0,1,1],
    [2,1,1,0,0,0,0,0,0,0,1,1,2],
    [2,2,1,1,0,0,0,0,0,1,1,2,2],
    [0,2,2,1,1,1,1,1,1,1,2,2,0],
    [0,0,2,1,3,1,1,3,1,2,2,0,0],
    [0,0,0,1,1,1,1,1,1,0,0,0,0],
    [0,0,0,0,1,1,1,1,0,0,0,0,0],
    [0,0,0,0,0,1,1,0,0,0,0,0,0],
  ];
  const palette = ['', '#5b21b6', '#7c3aed', '#ff0000'];
  return createTexture(SPRITE_SIZE, SPRITE_SIZE, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 3, 7);
  });
}

function generateZombieTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,0,1,1,1,0,0,0],
    [0,0,1,2,2,2,1,0,0],
    [0,1,2,2,2,2,2,1,0],
    [0,1,3,2,2,3,2,1,0],
    [0,1,2,2,2,2,2,1,0],
    [0,0,1,4,4,4,1,0,0],
    [0,0,1,1,1,1,1,0,0],
    [0,1,2,2,2,2,2,1,0],
    [1,2,2,2,2,2,2,2,1],
    [1,2,2,2,2,2,2,2,1],
    [0,1,2,2,2,2,2,1,0],
    [0,0,1,2,2,2,1,0,0],
    [0,0,1,1,0,1,1,0,0],
    [0,0,2,1,0,1,2,0,0],
    [0,0,2,2,0,2,2,0,0],
  ];
  const palette = ['', '#1a3a1a', '#2d6b2d', '#111111', '#4a1a1a'];
  return createTexture(SPRITE_SIZE, SPRITE_SIZE + 4, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 5, 2);
  });
}

function generateGhostTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,0,1,1,1,1,0,0,0],
    [0,0,1,2,2,2,2,1,0,0],
    [0,1,2,2,2,2,2,2,1,0],
    [1,2,2,3,2,2,3,2,2,1],
    [1,2,2,3,2,2,3,2,2,1],
    [1,2,2,2,2,2,2,2,2,1],
    [1,2,2,2,4,4,2,2,2,1],
    [1,2,2,2,2,2,2,2,2,1],
    [1,2,2,2,2,2,2,2,2,1],
    [1,2,2,2,2,2,2,2,2,1],
    [1,2,1,2,2,2,2,1,2,1],
    [1,0,0,1,2,2,1,0,0,1],
    [0,0,0,0,1,1,0,0,0,0],
  ];
  const palette = ['', '#4a6fa5', '#93c5fd', '#1a1a4a', '#3b5998'];
  return createTexture(SPRITE_SIZE, SPRITE_SIZE, (ctx) => {
    ctx.globalAlpha = 0.85;
    drawPixels(ctx, pixels, palette, 2, 6, 3);
    ctx.globalAlpha = 1.0;
  });
}

function generateDemonTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,1,0,0,0,0,0,1,0,0],
    [0,1,2,1,0,0,0,1,2,1,0],
    [0,0,1,2,1,1,1,2,1,0,0],
    [0,0,1,2,2,2,2,2,1,0,0],
    [0,1,2,3,2,2,3,2,2,1,0],
    [0,1,2,3,2,2,3,2,2,1,0],
    [0,1,2,2,2,2,2,2,2,1,0],
    [0,1,2,2,4,4,4,2,2,1,0],
    [0,1,2,2,2,2,2,2,2,1,0],
    [1,2,2,2,2,2,2,2,2,2,1],
    [1,2,2,2,2,2,2,2,2,2,1],
    [0,1,2,2,2,2,2,2,2,1,0],
    [0,0,1,2,0,0,0,2,1,0,0],
    [0,0,1,1,0,0,0,1,1,0,0],
  ];
  const palette = ['', '#4a0000', '#cc2222', '#ffff00', '#ff6600'];
  return createTexture(SPRITE_SIZE + 8, SPRITE_SIZE, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 9, 2);
  });
}

function generateBossTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,0,1,0,0,0,0,0,1,0,0,0],
    [0,0,1,2,1,0,0,0,1,2,1,0,0],
    [0,1,2,2,2,1,1,1,2,2,2,1,0],
    [0,1,2,2,2,2,2,2,2,2,2,1,0],
    [1,2,2,3,3,2,2,2,3,3,2,2,1],
    [1,2,2,3,4,2,2,2,4,3,2,2,1],
    [1,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,2,5,5,5,5,5,5,5,2,2,1],
    [1,2,2,2,5,2,2,2,5,2,2,2,1],
    [1,2,2,2,2,2,2,2,2,2,2,2,1],
    [0,1,2,2,2,2,2,2,2,2,2,1,0],
    [0,1,6,6,6,6,6,6,6,6,6,1,0],
    [1,6,6,6,6,6,6,6,6,6,6,6,1],
    [1,6,6,6,6,6,6,6,6,6,6,6,1],
    [0,1,6,6,6,6,6,6,6,6,6,1,0],
    [0,0,1,6,0,0,6,0,0,6,1,0,0],
    [0,0,1,1,0,0,1,0,0,1,1,0,0],
  ];
  const palette = ['', '#4a3000', '#fbbf24', '#ff0000', '#ffffff', '#ff4444', '#8b4513'];
  return createTexture(48, 48, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 9, 7);
  });
}

// ============================================================
// MAP TILES
// ============================================================

function generateGrassTile(variant: number): PIXI.Texture {
  return createTexture(TILE_SIZE, TILE_SIZE, (ctx) => {
    // Base grass color
    const baseColors = ['#1a2e1a', '#162a16', '#1e321e', '#142812'];
    ctx.fillStyle = baseColors[variant % baseColors.length];
    ctx.fillRect(0, 0, TILE_SIZE, TILE_SIZE);

    // Grass tufts
    const rng = seedRandom(variant * 7 + 13);
    const detailColors = ['#2a4a2a', '#1e3e1e', '#223c22', '#2e4e2e'];
    for (let i = 0; i < 12; i++) {
      ctx.fillStyle = detailColors[Math.floor(rng() * detailColors.length)];
      const x = Math.floor(rng() * (TILE_SIZE - 4));
      const y = Math.floor(rng() * (TILE_SIZE - 4));
      ctx.fillRect(x, y, 2 + Math.floor(rng() * 3), 2);
    }

    // Subtle dark spots
    for (let i = 0; i < 4; i++) {
      ctx.fillStyle = 'rgba(0,0,0,0.15)';
      const x = Math.floor(rng() * (TILE_SIZE - 6));
      const y = Math.floor(rng() * (TILE_SIZE - 6));
      ctx.fillRect(x, y, 3 + Math.floor(rng() * 4), 3 + Math.floor(rng() * 4));
    }
  });
}

function generateDirtTile(variant: number): PIXI.Texture {
  return createTexture(TILE_SIZE, TILE_SIZE, (ctx) => {
    const baseColors = ['#2a1f15', '#261b11', '#2e2318', '#221910'];
    ctx.fillStyle = baseColors[variant % baseColors.length];
    ctx.fillRect(0, 0, TILE_SIZE, TILE_SIZE);

    const rng = seedRandom(variant * 11 + 37);
    for (let i = 0; i < 15; i++) {
      ctx.fillStyle = `rgba(60,40,20,${0.2 + rng() * 0.3})`;
      const x = Math.floor(rng() * (TILE_SIZE - 3));
      const y = Math.floor(rng() * (TILE_SIZE - 3));
      ctx.fillRect(x, y, 2 + Math.floor(rng() * 4), 2 + Math.floor(rng() * 3));
    }
    // Small pebbles
    for (let i = 0; i < 3; i++) {
      ctx.fillStyle = '#4a3a2a';
      const x = Math.floor(rng() * (TILE_SIZE - 4));
      const y = Math.floor(rng() * (TILE_SIZE - 4));
      ctx.beginPath();
      ctx.arc(x + 2, y + 2, 1 + rng() * 2, 0, Math.PI * 2);
      ctx.fill();
    }
  });
}

function generateStoneTile(): PIXI.Texture {
  return createTexture(TILE_SIZE, TILE_SIZE, (ctx) => {
    ctx.fillStyle = '#2a2a3a';
    ctx.fillRect(0, 0, TILE_SIZE, TILE_SIZE);

    // Stone cracks
    ctx.strokeStyle = '#1a1a28';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, TILE_SIZE / 2);
    ctx.lineTo(TILE_SIZE / 3, TILE_SIZE / 2 + 4);
    ctx.lineTo(TILE_SIZE * 2 / 3, TILE_SIZE / 2 - 3);
    ctx.lineTo(TILE_SIZE, TILE_SIZE / 2 + 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(TILE_SIZE / 2, 0);
    ctx.lineTo(TILE_SIZE / 2 + 3, TILE_SIZE / 3);
    ctx.lineTo(TILE_SIZE / 2 - 2, TILE_SIZE * 2 / 3);
    ctx.lineTo(TILE_SIZE / 2 + 1, TILE_SIZE);
    ctx.stroke();

    // Moss spots
    const rng = seedRandom(42);
    for (let i = 0; i < 5; i++) {
      ctx.fillStyle = 'rgba(30,60,30,0.3)';
      const x = Math.floor(rng() * TILE_SIZE);
      const y = Math.floor(rng() * TILE_SIZE);
      ctx.fillRect(x, y, 3, 2);
    }
  });
}

// ============================================================
// MAP DECORATIONS
// ============================================================

function generateTombstoneTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,1,1,1,1,0,0],
    [0,1,2,2,2,2,1,0],
    [1,2,2,2,2,2,2,1],
    [1,2,2,3,3,2,2,1],
    [1,2,2,2,2,2,2,1],
    [1,2,2,3,2,2,2,1],
    [1,2,2,3,2,2,2,1],
    [1,2,2,3,3,2,2,1],
    [1,2,2,2,2,2,2,1],
    [1,2,2,2,2,2,2,1],
    [1,1,1,1,1,1,1,1],
    [0,4,4,4,4,4,4,0],
  ];
  const palette = ['', '#333340', '#555570', '#3a3a50', '#2a1f15'];
  return createTexture(24, 28, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 4, 2);
  });
}

function generateDeadTreeTexture(): PIXI.Texture {
  return createTexture(40, 56, (ctx) => {
    ctx.fillStyle = '#3a2820';
    // Trunk
    ctx.fillRect(17, 20, 6, 36);
    // Branches
    ctx.fillRect(10, 18, 20, 4);
    ctx.fillRect(8, 10, 4, 12);
    ctx.fillRect(26, 8, 4, 14);
    ctx.fillRect(5, 6, 4, 6);
    ctx.fillRect(28, 4, 4, 8);
    // Knots
    ctx.fillStyle = '#2a1a10';
    ctx.fillRect(18, 30, 4, 3);
    ctx.fillRect(19, 40, 3, 2);
  });
}

function generateBoneTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,1,0,0,0,0,1,0],
    [1,2,1,0,0,1,2,1],
    [0,1,2,2,2,2,1,0],
    [1,2,1,0,0,1,2,1],
    [0,1,0,0,0,0,1,0],
  ];
  const palette = ['', '#888888', '#cccccc'];
  return createTexture(20, 14, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 2, 2);
  });
}

function generateSkullDecorTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,1,1,1,1,0,0],
    [0,1,2,2,2,2,1,0],
    [1,2,2,2,2,2,2,1],
    [1,2,3,2,2,3,2,1],
    [1,2,3,2,2,3,2,1],
    [1,2,2,2,2,2,2,1],
    [0,1,2,3,3,2,1,0],
    [0,0,1,1,1,1,0,0],
  ];
  const palette = ['', '#555555', '#cccccc', '#222222'];
  return createTexture(20, 20, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 2, 2);
  });
}

function generateBloodPoolTexture(): PIXI.Texture {
  return createTexture(24, 16, (ctx) => {
    ctx.fillStyle = 'rgba(100,0,0,0.4)';
    ctx.beginPath();
    ctx.ellipse(12, 8, 10, 6, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = 'rgba(60,0,0,0.3)';
    ctx.beginPath();
    ctx.ellipse(14, 9, 6, 4, 0.3, 0, Math.PI * 2);
    ctx.fill();
  });
}

function generateMushroomTexture(): PIXI.Texture {
  const pixels: PixelData = [
    [0,0,1,1,1,0,0],
    [0,1,2,2,2,1,0],
    [1,2,3,2,3,2,1],
    [1,2,2,2,2,2,1],
    [0,0,4,4,4,0,0],
    [0,0,0,4,0,0,0],
    [0,0,0,4,0,0,0],
  ];
  const palette = ['', '#4a1a4a', '#8b3a8b', '#ff99ff', '#6b4a2a'];
  return createTexture(18, 18, (ctx) => {
    drawPixels(ctx, pixels, palette, 2, 2, 2);
  });
}

// ============================================================
// PROJECTILE TEXTURES
// ============================================================

function generateMagicBoltTexture(): PIXI.Texture {
  return createTexture(14, 14, (ctx) => {
    ctx.fillStyle = '#a855f7';
    ctx.beginPath();
    ctx.arc(7, 7, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#d8b4fe';
    ctx.beginPath();
    ctx.arc(7, 7, 3, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(6, 6, 1.5, 0, Math.PI * 2);
    ctx.fill();
  });
}

function generateFireballTexture(): PIXI.Texture {
  return createTexture(18, 18, (ctx) => {
    ctx.fillStyle = '#ff4400';
    ctx.beginPath();
    ctx.arc(9, 9, 7, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#ff8800';
    ctx.beginPath();
    ctx.arc(9, 9, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#ffcc00';
    ctx.beginPath();
    ctx.arc(9, 8, 3, 0, Math.PI * 2);
    ctx.fill();
  });
}

function generateWhipTexture(): PIXI.Texture {
  return createTexture(64, 10, (ctx) => {
    const grad = ctx.createLinearGradient(0, 5, 64, 5);
    grad.addColorStop(0, 'rgba(168,85,247,0.2)');
    grad.addColorStop(0.5, '#a855f7');
    grad.addColorStop(1, 'rgba(168,85,247,0.2)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 2, 64, 6);
    ctx.fillStyle = '#d8b4fe';
    ctx.fillRect(28, 3, 8, 4);
  });
}

function generateCrossTexture(): PIXI.Texture {
  return createTexture(16, 20, (ctx) => {
    ctx.fillStyle = '#fbbf24';
    ctx.fillRect(5, 0, 6, 20);
    ctx.fillRect(1, 5, 14, 6);
    ctx.fillStyle = '#fde68a';
    ctx.fillRect(7, 2, 2, 16);
    ctx.fillRect(3, 7, 10, 2);
  });
}

function generateScytheTexture(): PIXI.Texture {
  return createTexture(24, 24, (ctx) => {
    ctx.fillStyle = '#6b7280';
    ctx.fillRect(10, 8, 3, 14);
    ctx.fillStyle = '#9ca3af';
    ctx.beginPath();
    ctx.arc(12, 8, 8, Math.PI, Math.PI * 1.8);
    ctx.lineTo(12, 8);
    ctx.fill();
    ctx.fillStyle = '#d1d5db';
    ctx.beginPath();
    ctx.arc(12, 8, 6, Math.PI * 1.1, Math.PI * 1.7);
    ctx.lineTo(12, 8);
    ctx.fill();
  });
}

function generateBloodWaveTexture(): PIXI.Texture {
  return createTexture(28, 12, (ctx) => {
    ctx.fillStyle = 'rgba(200,0,0,0.7)';
    ctx.beginPath();
    ctx.ellipse(14, 6, 12, 5, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = 'rgba(255,50,50,0.5)';
    ctx.beginPath();
    ctx.ellipse(14, 5, 8, 3, 0, 0, Math.PI * 2);
    ctx.fill();
  });
}

function generateXPGemTexture(tier: number): PIXI.Texture {
  const colors = ['#4ade80', '#3b82f6', '#fbbf24'];
  const sizes = [8, 10, 12];
  const color = colors[tier] || colors[0];
  const size = sizes[tier] || sizes[0];
  return createTexture(size * 2, size * 2, (ctx) => {
    const cx = size, cy = size;
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.moveTo(cx, cy - size + 2);
    ctx.lineTo(cx + size - 2, cy);
    ctx.lineTo(cx, cy + size - 2);
    ctx.lineTo(cx - size + 2, cy);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = 'rgba(255,255,255,0.4)';
    ctx.beginPath();
    ctx.moveTo(cx, cy - size + 4);
    ctx.lineTo(cx + size - 4, cy);
    ctx.lineTo(cx, cy + size - 4);
    ctx.lineTo(cx - size + 4, cy);
    ctx.closePath();
    ctx.fill();
  });
}

function generateParticleTexture(): PIXI.Texture {
  return createTexture(8, 8, (ctx) => {
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(4, 4, 3, 0, Math.PI * 2);
    ctx.fill();
  });
}

function generateLightningTexture(): PIXI.Texture {
  return createTexture(12, 12, (ctx) => {
    ctx.fillStyle = '#60a5fa';
    ctx.beginPath();
    ctx.arc(6, 6, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(6, 6, 2, 0, Math.PI * 2);
    ctx.fill();
  });
}

// ============================================================
// SEEDED RANDOM
// ============================================================

function seedRandom(seed: number): () => number {
  let s = seed;
  return () => {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return (s / 0x7fffffff);
  };
}

// ============================================================
// TEXTURE ATLAS EXPORT
// ============================================================

export interface TextureAtlas {
  player: PIXI.Texture;
  enemies: PIXI.Texture[];  // indexed by ENEMY_TYPES
  grassTiles: PIXI.Texture[];
  dirtTiles: PIXI.Texture[];
  stoneTile: PIXI.Texture;
  decorations: {
    tombstone: PIXI.Texture;
    deadTree: PIXI.Texture;
    bone: PIXI.Texture;
    skull: PIXI.Texture;
    bloodPool: PIXI.Texture;
    mushroom: PIXI.Texture;
  };
  projectiles: {
    magicBolt: PIXI.Texture;
    fireball: PIXI.Texture;
    whip: PIXI.Texture;
    cross: PIXI.Texture;
    scythe: PIXI.Texture;
    bloodWave: PIXI.Texture;
    lightning: PIXI.Texture;
  };
  xpGems: PIXI.Texture[];  // 3 tiers
  particle: PIXI.Texture;
}

export function generateTextureAtlas(): TextureAtlas {
  return {
    player: generatePlayerTexture(),
    enemies: [
      generateSkeletonTexture(),
      generateBatTexture(),
      generateZombieTexture(),
      generateGhostTexture(),
      generateDemonTexture(),
      generateBossTexture(),
    ],
    grassTiles: [
      generateGrassTile(0),
      generateGrassTile(1),
      generateGrassTile(2),
      generateGrassTile(3),
    ],
    dirtTiles: [
      generateDirtTile(0),
      generateDirtTile(1),
      generateDirtTile(2),
    ],
    stoneTile: generateStoneTile(),
    decorations: {
      tombstone: generateTombstoneTexture(),
      deadTree: generateDeadTreeTexture(),
      bone: generateBoneTexture(),
      skull: generateSkullDecorTexture(),
      bloodPool: generateBloodPoolTexture(),
      mushroom: generateMushroomTexture(),
    },
    projectiles: {
      magicBolt: generateMagicBoltTexture(),
      fireball: generateFireballTexture(),
      whip: generateWhipTexture(),
      cross: generateCrossTexture(),
      scythe: generateScytheTexture(),
      bloodWave: generateBloodWaveTexture(),
      lightning: generateLightningTexture(),
    },
    xpGems: [
      generateXPGemTexture(0),
      generateXPGemTexture(1),
      generateXPGemTexture(2),
    ],
    particle: generateParticleTexture(),
  };
}
