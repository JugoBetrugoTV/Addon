/**
 * TextureGenerator.ts - Generates all game textures at startup.
 * Uses Canvas2D to create smooth, detailed sprites with gradients.
 * Style: dark fantasy with glowing elements, NOT retro pixel art.
 */

import * as PIXI from 'pixi.js';

function createTexture(w: number, h: number, draw: (ctx: CanvasRenderingContext2D) => void): PIXI.Texture {
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d')!;
  draw(ctx);
  return PIXI.Texture.from(canvas);
}

function radialGradient(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, inner: string, outer: string): CanvasGradient {
  const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
  grad.addColorStop(0, inner);
  grad.addColorStop(1, outer);
  return grad;
}

// === PLAYER ===
export function generatePlayerTexture(): PIXI.Texture {
  return createTexture(48, 48, (ctx) => {
    // Body - glowing orb with cloak
    ctx.fillStyle = radialGradient(ctx, 24, 28, 16, '#d8b4fe', '#6b21a8');
    ctx.beginPath();
    ctx.ellipse(24, 28, 12, 14, 0, 0, Math.PI * 2);
    ctx.fill();
    // Head
    ctx.fillStyle = radialGradient(ctx, 24, 16, 10, '#e9d5ff', '#7c3aed');
    ctx.beginPath();
    ctx.arc(24, 16, 8, 0, Math.PI * 2);
    ctx.fill();
    // Eyes (glowing)
    ctx.fillStyle = '#ffffff';
    ctx.shadowColor = '#c4b5fd';
    ctx.shadowBlur = 6;
    ctx.beginPath();
    ctx.arc(21, 15, 2.5, 0, Math.PI * 2);
    ctx.arc(27, 15, 2.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
    // Pupils
    ctx.fillStyle = '#1e1b4b';
    ctx.beginPath();
    ctx.arc(21, 15, 1.2, 0, Math.PI * 2);
    ctx.arc(27, 15, 1.2, 0, Math.PI * 2);
    ctx.fill();
  });
}

// === ENEMIES ===
export function generateEnemyTextures(): PIXI.Texture[] {
  return [
    generateSkeleton(),
    generateBat(),
    generateZombie(),
    generateGhost(),
    generateDemon(),
    generateBoss(),
  ];
}

function generateSkeleton(): PIXI.Texture {
  return createTexture(36, 42, (ctx) => {
    // Skull
    ctx.fillStyle = radialGradient(ctx, 18, 14, 10, '#f5f5f5', '#a1a1aa');
    ctx.beginPath();
    ctx.arc(18, 14, 9, 0, Math.PI * 2);
    ctx.fill();
    // Eyes (dark sockets)
    ctx.fillStyle = '#18181b';
    ctx.beginPath();
    ctx.ellipse(15, 13, 2.5, 3, 0, 0, Math.PI * 2);
    ctx.ellipse(21, 13, 2.5, 3, 0, 0, Math.PI * 2);
    ctx.fill();
    // Red eye glow
    ctx.fillStyle = '#ef4444';
    ctx.shadowColor = '#ef4444';
    ctx.shadowBlur = 4;
    ctx.beginPath();
    ctx.arc(15, 13, 1, 0, Math.PI * 2);
    ctx.arc(21, 13, 1, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
    // Jaw
    ctx.fillStyle = '#d4d4d8';
    ctx.fillRect(14, 20, 8, 3);
    // Ribcage body
    ctx.strokeStyle = '#a1a1aa';
    ctx.lineWidth = 2;
    for (let i = 0; i < 4; i++) {
      ctx.beginPath();
      ctx.moveTo(14, 26 + i * 3);
      ctx.lineTo(22, 26 + i * 3);
      ctx.stroke();
    }
    // Spine
    ctx.strokeStyle = '#d4d4d8';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.moveTo(18, 22);
    ctx.lineTo(18, 40);
    ctx.stroke();
  });
}

function generateBat(): PIXI.Texture {
  return createTexture(40, 28, (ctx) => {
    // Wings
    ctx.fillStyle = radialGradient(ctx, 20, 14, 18, '#7c3aed', '#3b0764');
    ctx.beginPath();
    ctx.moveTo(20, 14);
    ctx.bezierCurveTo(5, 6, 0, 14, 2, 22);
    ctx.bezierCurveTo(6, 18, 10, 20, 20, 14);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(20, 14);
    ctx.bezierCurveTo(35, 6, 40, 14, 38, 22);
    ctx.bezierCurveTo(34, 18, 30, 20, 20, 14);
    ctx.fill();
    // Body
    ctx.fillStyle = '#4c1d95';
    ctx.beginPath();
    ctx.ellipse(20, 16, 5, 6, 0, 0, Math.PI * 2);
    ctx.fill();
    // Eyes
    ctx.fillStyle = '#ff0000';
    ctx.shadowColor = '#ff0000';
    ctx.shadowBlur = 5;
    ctx.beginPath();
    ctx.arc(18, 14, 1.5, 0, Math.PI * 2);
    ctx.arc(22, 14, 1.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
  });
}

function generateZombie(): PIXI.Texture {
  return createTexture(36, 44, (ctx) => {
    // Body (hunched)
    ctx.fillStyle = radialGradient(ctx, 18, 28, 14, '#4d7c0f', '#1a2e05');
    ctx.beginPath();
    ctx.ellipse(18, 30, 10, 13, 0, 0, Math.PI * 2);
    ctx.fill();
    // Head
    ctx.fillStyle = radialGradient(ctx, 18, 14, 9, '#65a30d', '#365314');
    ctx.beginPath();
    ctx.arc(18, 14, 8, 0, Math.PI * 2);
    ctx.fill();
    // Wounds
    ctx.fillStyle = '#7f1d1d';
    ctx.beginPath();
    ctx.ellipse(15, 20, 2, 1.5, 0.3, 0, Math.PI * 2);
    ctx.ellipse(22, 26, 1.5, 2, -0.2, 0, Math.PI * 2);
    ctx.fill();
    // Eyes (one missing)
    ctx.fillStyle = '#fde047';
    ctx.shadowColor = '#fde047';
    ctx.shadowBlur = 3;
    ctx.beginPath();
    ctx.arc(15, 13, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#1a1a1a';
    ctx.beginPath();
    ctx.arc(21, 13, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
  });
}

function generateGhost(): PIXI.Texture {
  return createTexture(36, 44, (ctx) => {
    ctx.globalAlpha = 0.75;
    // Ethereal body
    ctx.fillStyle = radialGradient(ctx, 18, 20, 16, 'rgba(147,197,253,0.8)', 'rgba(59,130,246,0.2)');
    ctx.beginPath();
    ctx.moveTo(6, 22);
    ctx.quadraticCurveTo(18, 2, 30, 22);
    ctx.quadraticCurveTo(30, 40, 26, 42);
    ctx.lineTo(22, 38);
    ctx.lineTo(18, 42);
    ctx.lineTo(14, 38);
    ctx.lineTo(10, 42);
    ctx.quadraticCurveTo(6, 40, 6, 22);
    ctx.fill();
    ctx.globalAlpha = 1;
    // Eyes (hollow)
    ctx.fillStyle = '#1e3a5f';
    ctx.beginPath();
    ctx.ellipse(14, 20, 3, 4, 0, 0, Math.PI * 2);
    ctx.ellipse(22, 20, 3, 4, 0, 0, Math.PI * 2);
    ctx.fill();
    // Eye glow
    ctx.fillStyle = '#bfdbfe';
    ctx.shadowColor = '#93c5fd';
    ctx.shadowBlur = 6;
    ctx.beginPath();
    ctx.arc(14, 20, 1.5, 0, Math.PI * 2);
    ctx.arc(22, 20, 1.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
  });
}

function generateDemon(): PIXI.Texture {
  return createTexture(44, 48, (ctx) => {
    // Horns
    ctx.fillStyle = '#4a0000';
    ctx.beginPath();
    ctx.moveTo(12, 16);
    ctx.lineTo(8, 4);
    ctx.lineTo(14, 12);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(32, 16);
    ctx.lineTo(36, 4);
    ctx.lineTo(30, 12);
    ctx.fill();
    // Body
    ctx.fillStyle = radialGradient(ctx, 22, 30, 16, '#dc2626', '#450a0a');
    ctx.beginPath();
    ctx.ellipse(22, 30, 13, 16, 0, 0, Math.PI * 2);
    ctx.fill();
    // Head
    ctx.fillStyle = radialGradient(ctx, 22, 16, 10, '#ef4444', '#7f1d1d');
    ctx.beginPath();
    ctx.arc(22, 16, 9, 0, Math.PI * 2);
    ctx.fill();
    // Eyes (yellow fire)
    ctx.fillStyle = '#fbbf24';
    ctx.shadowColor = '#fbbf24';
    ctx.shadowBlur = 8;
    ctx.beginPath();
    ctx.arc(19, 15, 2.5, 0, Math.PI * 2);
    ctx.arc(25, 15, 2.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
    // Mouth
    ctx.fillStyle = '#7f1d1d';
    ctx.beginPath();
    ctx.arc(22, 21, 4, 0, Math.PI);
    ctx.fill();
  });
}

function generateBoss(): PIXI.Texture {
  return createTexture(72, 72, (ctx) => {
    // Crown/horns
    ctx.fillStyle = '#fbbf24';
    for (let i = 0; i < 5; i++) {
      const angle = -Math.PI * 0.7 + (i / 4) * Math.PI * 0.4;
      const x = 36 + Math.cos(angle) * 22;
      const y = 20 + Math.sin(angle) * 22;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x - 3, y + 8);
      ctx.lineTo(x + 3, y + 8);
      ctx.fill();
    }
    // Massive body
    ctx.fillStyle = radialGradient(ctx, 36, 42, 24, '#fbbf24', '#78350f');
    ctx.beginPath();
    ctx.ellipse(36, 42, 22, 26, 0, 0, Math.PI * 2);
    ctx.fill();
    // Face
    ctx.fillStyle = radialGradient(ctx, 36, 30, 14, '#fde68a', '#b45309');
    ctx.beginPath();
    ctx.arc(36, 30, 13, 0, Math.PI * 2);
    ctx.fill();
    // Eyes (menacing)
    ctx.fillStyle = '#ff0000';
    ctx.shadowColor = '#ff0000';
    ctx.shadowBlur = 10;
    ctx.beginPath();
    ctx.ellipse(30, 28, 3, 4, -0.2, 0, Math.PI * 2);
    ctx.ellipse(42, 28, 3, 4, 0.2, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
    // Mouth
    ctx.fillStyle = '#450a0a';
    ctx.beginPath();
    ctx.arc(36, 36, 6, 0.1, Math.PI - 0.1);
    ctx.fill();
    // Teeth
    ctx.fillStyle = '#fde68a';
    for (let i = 0; i < 4; i++) {
      ctx.fillRect(30 + i * 4, 34, 2, 4);
    }
  });
}

// === PROJECTILE TEXTURES ===
export function generateProjectileTextures(): Map<number, PIXI.Texture> {
  const map = new Map<number, PIXI.Texture>();
  // 0: Whip
  map.set(0, createTexture(48, 8, (ctx) => {
    const grad = ctx.createLinearGradient(0, 4, 48, 4);
    grad.addColorStop(0, 'rgba(168,85,247,0.1)');
    grad.addColorStop(0.5, '#a855f7');
    grad.addColorStop(1, 'rgba(168,85,247,0.1)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 1, 48, 6);
    ctx.fillStyle = '#d8b4fe';
    ctx.fillRect(20, 2, 8, 4);
  }));
  // 1: Magic Bolt
  map.set(1, createTexture(16, 16, (ctx) => {
    ctx.fillStyle = radialGradient(ctx, 8, 8, 7, '#ffffff', '#8b5cf6');
    ctx.shadowColor = '#c4b5fd';
    ctx.shadowBlur = 6;
    ctx.beginPath();
    ctx.arc(8, 8, 6, 0, Math.PI * 2);
    ctx.fill();
  }));
  // 2: Fireball
  map.set(2, createTexture(20, 20, (ctx) => {
    ctx.fillStyle = radialGradient(ctx, 10, 10, 9, '#fde047', '#ea580c');
    ctx.shadowColor = '#f97316';
    ctx.shadowBlur = 8;
    ctx.beginPath();
    ctx.arc(10, 10, 8, 0, Math.PI * 2);
    ctx.fill();
  }));
  // 3: Cross
  map.set(3, createTexture(18, 22, (ctx) => {
    ctx.fillStyle = '#fbbf24';
    ctx.shadowColor = '#fbbf24';
    ctx.shadowBlur = 4;
    ctx.fillRect(6, 0, 6, 22);
    ctx.fillRect(1, 6, 16, 6);
    ctx.fillStyle = '#fde68a';
    ctx.fillRect(8, 2, 2, 18);
    ctx.fillRect(3, 8, 12, 2);
  }));
  // 5: Lightning
  map.set(5, createTexture(14, 14, (ctx) => {
    ctx.fillStyle = radialGradient(ctx, 7, 7, 6, '#ffffff', '#3b82f6');
    ctx.shadowColor = '#60a5fa';
    ctx.shadowBlur = 8;
    ctx.beginPath();
    ctx.arc(7, 7, 5, 0, Math.PI * 2);
    ctx.fill();
  }));
  // 6: Scythe
  map.set(6, createTexture(28, 28, (ctx) => {
    ctx.fillStyle = '#9ca3af';
    ctx.fillRect(12, 8, 4, 18);
    ctx.fillStyle = radialGradient(ctx, 14, 10, 10, '#e5e7eb', '#4b5563');
    ctx.beginPath();
    ctx.arc(14, 10, 10, Math.PI, Math.PI * 1.8);
    ctx.lineTo(14, 10);
    ctx.fill();
  }));
  // 7: Blood Wave
  map.set(7, createTexture(28, 14, (ctx) => {
    ctx.fillStyle = radialGradient(ctx, 14, 7, 12, 'rgba(239,68,68,0.8)', 'rgba(127,29,29,0.3)');
    ctx.beginPath();
    ctx.ellipse(14, 7, 13, 6, 0, 0, Math.PI * 2);
    ctx.fill();
  }));
  return map;
}

// === XP GEM TEXTURES ===
export function generateGemTextures(): PIXI.Texture[] {
  const colors = [
    { inner: '#86efac', outer: '#15803d' },
    { inner: '#93c5fd', outer: '#1d4ed8' },
    { inner: '#fde047', outer: '#a16207' },
  ];
  const sizes = [12, 14, 16];
  return colors.map((c, i) => createTexture(sizes[i], sizes[i], (ctx) => {
    const s = sizes[i] / 2;
    ctx.fillStyle = radialGradient(ctx, s, s, s - 1, c.inner, c.outer);
    ctx.shadowColor = c.inner;
    ctx.shadowBlur = 4;
    ctx.beginPath();
    ctx.moveTo(s, 1);
    ctx.lineTo(sizes[i] - 1, s);
    ctx.lineTo(s, sizes[i] - 1);
    ctx.lineTo(1, s);
    ctx.closePath();
    ctx.fill();
  }));
}

// === PARTICLE TEXTURE (shared, tinted per-particle) ===
export function generateParticleTexture(): PIXI.Texture {
  return createTexture(12, 12, (ctx) => {
    ctx.fillStyle = radialGradient(ctx, 6, 6, 5, 'rgba(255,255,255,1)', 'rgba(255,255,255,0)');
    ctx.beginPath();
    ctx.arc(6, 6, 5, 0, Math.PI * 2);
    ctx.fill();
  });
}

// === MAP TILE TEXTURES ===
export function generateTileTextures(seed: number): { grass: PIXI.Texture[]; dirt: PIXI.Texture[]; stone: PIXI.Texture } {
  const rng = seededRandom(seed);
  const TILE = 64;

  const grass = Array.from({ length: 4 }, (_, i) => createTexture(TILE, TILE, (ctx) => {
    ctx.fillStyle = ['#1a2e1a', '#162a16', '#1e321e', '#142812'][i];
    ctx.fillRect(0, 0, TILE, TILE);
    for (let j = 0; j < 15; j++) {
      ctx.fillStyle = `rgba(${30 + rng() * 20},${60 + rng() * 30},${20 + rng() * 20},0.4)`;
      ctx.fillRect(rng() * TILE, rng() * TILE, 2 + rng() * 4, 1 + rng() * 2);
    }
  }));

  const dirt = Array.from({ length: 3 }, (_, i) => createTexture(TILE, TILE, (ctx) => {
    ctx.fillStyle = ['#2a1f15', '#261b11', '#2e2318'][i];
    ctx.fillRect(0, 0, TILE, TILE);
    for (let j = 0; j < 12; j++) {
      ctx.fillStyle = `rgba(60,40,20,${0.15 + rng() * 0.25})`;
      ctx.fillRect(rng() * TILE, rng() * TILE, 2 + rng() * 5, 2 + rng() * 4);
    }
  }));

  const stone = createTexture(TILE, TILE, (ctx) => {
    ctx.fillStyle = '#2a2a3a';
    ctx.fillRect(0, 0, TILE, TILE);
    ctx.strokeStyle = '#1a1a28';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, 32);
    ctx.lineTo(22, 35);
    ctx.lineTo(44, 30);
    ctx.lineTo(64, 33);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(32, 0);
    ctx.lineTo(35, 22);
    ctx.lineTo(30, 44);
    ctx.lineTo(33, 64);
    ctx.stroke();
  });

  return { grass, dirt, stone };
}

// === DECORATION TEXTURES ===
export function generateDecorationTextures(): { name: string; tex: PIXI.Texture; count: number; scale: number }[] {
  return [
    { name: 'tombstone', tex: createTexture(20, 28, (ctx) => {
      ctx.fillStyle = '#4a4a5a';
      ctx.beginPath();
      ctx.moveTo(3, 28);
      ctx.lineTo(3, 8);
      ctx.quadraticCurveTo(10, 0, 17, 8);
      ctx.lineTo(17, 28);
      ctx.fill();
      ctx.fillStyle = '#3a3a48';
      ctx.fillRect(7, 8, 2, 8);
      ctx.fillRect(5, 11, 6, 2);
    }), count: 50, scale: 1.3 },
    { name: 'deadTree', tex: createTexture(36, 52, (ctx) => {
      ctx.fillStyle = '#3a2820';
      ctx.fillRect(15, 18, 6, 34);
      ctx.fillRect(8, 16, 20, 4);
      ctx.fillRect(6, 8, 4, 12);
      ctx.fillRect(26, 6, 4, 14);
      ctx.fillStyle = '#2a1a10';
      ctx.fillRect(16, 30, 4, 3);
    }), count: 30, scale: 1.4 },
    { name: 'skull', tex: createTexture(14, 14, (ctx) => {
      ctx.fillStyle = '#b0b0b0';
      ctx.beginPath();
      ctx.arc(7, 7, 5, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = '#1a1a1a';
      ctx.beginPath();
      ctx.arc(5, 6, 1.5, 0, Math.PI * 2);
      ctx.arc(9, 6, 1.5, 0, Math.PI * 2);
      ctx.fill();
    }), count: 40, scale: 1.0 },
    { name: 'mushroom', tex: createTexture(14, 16, (ctx) => {
      ctx.fillStyle = '#7c3aed';
      ctx.beginPath();
      ctx.arc(7, 6, 6, Math.PI, 0);
      ctx.fill();
      ctx.fillStyle = '#5b21b6';
      ctx.fillRect(5, 8, 4, 8);
      ctx.fillStyle = '#e9d5ff';
      ctx.beginPath();
      ctx.arc(5, 4, 1.5, 0, Math.PI * 2);
      ctx.arc(9, 3, 1, 0, Math.PI * 2);
      ctx.fill();
    }), count: 35, scale: 1.1 },
    { name: 'bloodPool', tex: createTexture(22, 14, (ctx) => {
      ctx.fillStyle = 'rgba(127,29,29,0.5)';
      ctx.beginPath();
      ctx.ellipse(11, 7, 10, 6, 0, 0, Math.PI * 2);
      ctx.fill();
    }), count: 30, scale: 1.0 },
  ];
}

function seededRandom(seed: number): () => number {
  let s = seed;
  return () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
}
