/**
 * EnemyData.ts - Enemy type definitions and wave configuration.
 * Controls spawning patterns, health scaling, and enemy behavior.
 */

export const ENEMY_TYPES = {
  SKELETON: 0,
  BAT: 1,
  ZOMBIE: 2,
  GHOST: 3,
  DEMON: 4,
  BOSS: 5,
} as const;

export interface EnemyDef {
  name: string;
  health: number;
  speed: number;
  damage: number;
  xpDrop: number;
  size: number;  // collision radius
  color: number;
  attackCooldown: number;
  /** Glow color for dynamic lighting on hit */
  glowColor: number;
}

export const ENEMIES: EnemyDef[] = [
  { name: 'Skeleton', health: 20, speed: 55, damage: 8, xpDrop: 1, size: 12, color: 0xd4d4d8, attackCooldown: 1.0, glowColor: 0xa1a1aa },
  { name: 'Bat', health: 8, speed: 110, damage: 5, xpDrop: 1, size: 8, color: 0x7c3aed, attackCooldown: 0.6, glowColor: 0x6d28d9 },
  { name: 'Zombie', health: 45, speed: 35, damage: 12, xpDrop: 2, size: 14, color: 0x22c55e, attackCooldown: 1.5, glowColor: 0x16a34a },
  { name: 'Ghost', health: 15, speed: 70, damage: 7, xpDrop: 2, size: 11, color: 0x93c5fd, attackCooldown: 0.8, glowColor: 0x60a5fa },
  { name: 'Demon', health: 80, speed: 50, damage: 18, xpDrop: 5, size: 16, color: 0xef4444, attackCooldown: 1.2, glowColor: 0xdc2626 },
  { name: 'Boss', health: 500, speed: 30, damage: 30, xpDrop: 50, size: 28, color: 0xfbbf24, attackCooldown: 2.0, glowColor: 0xd97706 },
];

export function getEnemyDef(type: number): EnemyDef {
  return ENEMIES[type] || ENEMIES[0];
}

// === WAVE SYSTEM ===

export interface WaveConfig {
  time: number;       // seconds when this wave activates
  enemyType: number;
  count: number;      // total enemies to spawn
  interval: number;   // seconds between spawns
  healthMult: number; // multiplier on base health
  speedMult: number;  // multiplier on base speed
}

/** 24 escalating waves over 10 minutes */
export const WAVES: WaveConfig[] = [
  // 0:00 - Light start
  { time: 0, enemyType: 0, count: 10, interval: 1.5, healthMult: 1, speedMult: 1 },
  { time: 15, enemyType: 1, count: 8, interval: 0.8, healthMult: 1, speedMult: 1 },
  // 0:30 - Pressure
  { time: 30, enemyType: 0, count: 15, interval: 1.0, healthMult: 1.2, speedMult: 1.1 },
  { time: 45, enemyType: 2, count: 8, interval: 2.0, healthMult: 1, speedMult: 1 },
  // 1:00 - Mixed
  { time: 60, enemyType: 1, count: 20, interval: 0.5, healthMult: 1.3, speedMult: 1.2 },
  { time: 75, enemyType: 0, count: 20, interval: 0.8, healthMult: 1.5, speedMult: 1.1 },
  { time: 90, enemyType: 3, count: 10, interval: 1.5, healthMult: 1, speedMult: 1 },
  // 2:00 - Escalation
  { time: 120, enemyType: 2, count: 15, interval: 1.0, healthMult: 1.5, speedMult: 1.2 },
  { time: 140, enemyType: 4, count: 5, interval: 3.0, healthMult: 1, speedMult: 1 },
  { time: 160, enemyType: 1, count: 30, interval: 0.3, healthMult: 1.5, speedMult: 1.3 },
  // 3:00 - Intense
  { time: 180, enemyType: 0, count: 30, interval: 0.5, healthMult: 2, speedMult: 1.3 },
  { time: 200, enemyType: 3, count: 15, interval: 1.0, healthMult: 1.5, speedMult: 1.2 },
  { time: 220, enemyType: 4, count: 8, interval: 2.0, healthMult: 1.5, speedMult: 1.1 },
  // 4:00 - First boss
  { time: 240, enemyType: 5, count: 1, interval: 1, healthMult: 1, speedMult: 1 },
  { time: 250, enemyType: 2, count: 20, interval: 0.8, healthMult: 2, speedMult: 1.3 },
  // 5:00 - Chaos
  { time: 300, enemyType: 1, count: 40, interval: 0.2, healthMult: 2, speedMult: 1.5 },
  { time: 320, enemyType: 4, count: 12, interval: 1.5, healthMult: 2, speedMult: 1.2 },
  { time: 350, enemyType: 3, count: 25, interval: 0.6, healthMult: 2, speedMult: 1.4 },
  // 7:00 - Hell
  { time: 420, enemyType: 0, count: 50, interval: 0.3, healthMult: 3, speedMult: 1.5 },
  { time: 450, enemyType: 4, count: 15, interval: 1.0, healthMult: 2.5, speedMult: 1.3 },
  { time: 480, enemyType: 5, count: 2, interval: 5, healthMult: 1.5, speedMult: 1.2 },
  // 9:00 - Endgame
  { time: 540, enemyType: 4, count: 25, interval: 0.5, healthMult: 3, speedMult: 1.5 },
  { time: 570, enemyType: 2, count: 40, interval: 0.3, healthMult: 3, speedMult: 1.5 },
  { time: 590, enemyType: 5, count: 3, interval: 3, healthMult: 2, speedMult: 1.3 },
];
