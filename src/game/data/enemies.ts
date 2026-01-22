export interface EnemyDef {
  name: string;
  type: number;
  health: number;
  speed: number;
  damage: number;
  xpDrop: number;
  color: number;
  size: number;
  attackCooldown: number;
}

export const ENEMY_TYPES = {
  SKELETON: 0,
  BAT: 1,
  ZOMBIE: 2,
  GHOST: 3,
  DEMON: 4,
  BOSS: 5,
} as const;

export const ENEMIES: EnemyDef[] = [
  {
    name: 'Skeleton',
    type: ENEMY_TYPES.SKELETON,
    health: 20,
    speed: 60,
    damage: 5,
    xpDrop: 1,
    color: 0xd4d4d8,
    size: 14,
    attackCooldown: 1.0,
  },
  {
    name: 'Bat',
    type: ENEMY_TYPES.BAT,
    health: 10,
    speed: 120,
    damage: 3,
    xpDrop: 1,
    color: 0x7c3aed,
    size: 10,
    attackCooldown: 0.8,
  },
  {
    name: 'Zombie',
    type: ENEMY_TYPES.ZOMBIE,
    health: 50,
    speed: 40,
    damage: 8,
    xpDrop: 2,
    color: 0x4ade80,
    size: 16,
    attackCooldown: 1.5,
  },
  {
    name: 'Ghost',
    type: ENEMY_TYPES.GHOST,
    health: 30,
    speed: 90,
    damage: 6,
    xpDrop: 3,
    color: 0x93c5fd,
    size: 14,
    attackCooldown: 1.2,
  },
  {
    name: 'Demon',
    type: ENEMY_TYPES.DEMON,
    health: 100,
    speed: 70,
    damage: 15,
    xpDrop: 5,
    color: 0xef4444,
    size: 20,
    attackCooldown: 2.0,
  },
  {
    name: 'Boss',
    type: ENEMY_TYPES.BOSS,
    health: 1000,
    speed: 50,
    damage: 25,
    xpDrop: 50,
    color: 0xfbbf24,
    size: 40,
    attackCooldown: 2.5,
  },
];

export const getEnemyDef = (type: number): EnemyDef => ENEMIES[type];

export interface WaveConfig {
  time: number;        // seconds into game when wave starts
  enemyType: number;
  count: number;
  interval: number;    // spawn interval in seconds
  healthMult: number;
  speedMult: number;
}

export const WAVES: WaveConfig[] = [
  // Early game - skeletons
  { time: 0, enemyType: 0, count: 5, interval: 2.0, healthMult: 1.0, speedMult: 1.0 },
  { time: 15, enemyType: 0, count: 8, interval: 1.5, healthMult: 1.0, speedMult: 1.0 },
  { time: 30, enemyType: 1, count: 6, interval: 1.0, healthMult: 1.0, speedMult: 1.0 },
  // Ramp up
  { time: 45, enemyType: 0, count: 12, interval: 1.0, healthMult: 1.2, speedMult: 1.0 },
  { time: 60, enemyType: 2, count: 5, interval: 2.0, healthMult: 1.0, speedMult: 1.0 },
  { time: 75, enemyType: 1, count: 15, interval: 0.5, healthMult: 1.0, speedMult: 1.1 },
  // Mid game
  { time: 90, enemyType: 0, count: 20, interval: 0.8, healthMult: 1.5, speedMult: 1.1 },
  { time: 105, enemyType: 3, count: 8, interval: 1.5, healthMult: 1.0, speedMult: 1.0 },
  { time: 120, enemyType: 2, count: 10, interval: 1.2, healthMult: 1.3, speedMult: 1.0 },
  { time: 135, enemyType: 1, count: 25, interval: 0.3, healthMult: 1.2, speedMult: 1.2 },
  // Hard mode
  { time: 150, enemyType: 4, count: 3, interval: 3.0, healthMult: 1.0, speedMult: 1.0 },
  { time: 165, enemyType: 0, count: 30, interval: 0.5, healthMult: 2.0, speedMult: 1.2 },
  { time: 180, enemyType: 3, count: 15, interval: 0.8, healthMult: 1.5, speedMult: 1.1 },
  { time: 195, enemyType: 4, count: 5, interval: 2.0, healthMult: 1.3, speedMult: 1.0 },
  { time: 210, enemyType: 2, count: 20, interval: 0.6, healthMult: 2.0, speedMult: 1.1 },
  // Intense
  { time: 240, enemyType: 4, count: 8, interval: 1.5, healthMult: 1.5, speedMult: 1.1 },
  { time: 270, enemyType: 0, count: 50, interval: 0.2, healthMult: 2.5, speedMult: 1.3 },
  { time: 300, enemyType: 5, count: 1, interval: 0, healthMult: 1.0, speedMult: 1.0 },
  // Post boss - chaos
  { time: 330, enemyType: 4, count: 15, interval: 1.0, healthMult: 2.0, speedMult: 1.2 },
  { time: 360, enemyType: 3, count: 30, interval: 0.3, healthMult: 2.0, speedMult: 1.3 },
  { time: 390, enemyType: 0, count: 80, interval: 0.1, healthMult: 3.0, speedMult: 1.4 },
  { time: 420, enemyType: 5, count: 2, interval: 5.0, healthMult: 1.5, speedMult: 1.0 },
  { time: 480, enemyType: 4, count: 25, interval: 0.5, healthMult: 3.0, speedMult: 1.3 },
  { time: 540, enemyType: 5, count: 3, interval: 3.0, healthMult: 2.0, speedMult: 1.2 },
  { time: 600, enemyType: 0, count: 200, interval: 0.05, healthMult: 5.0, speedMult: 1.5 },
];
