export interface PassiveUpgrade {
  name: string;
  description: string;
  maxLevel: number;
  color: number;
  effect: string;
  valuePerLevel: number;
}

export const PASSIVE_UPGRADES: PassiveUpgrade[] = [
  { name: 'Might', description: '+10% Damage', maxLevel: 5, color: 0xef4444, effect: 'damage', valuePerLevel: 0.1 },
  { name: 'Armor', description: '-5% Damage taken', maxLevel: 5, color: 0x6b7280, effect: 'armor', valuePerLevel: 0.05 },
  { name: 'Speed', description: '+10% Move speed', maxLevel: 5, color: 0x3b82f6, effect: 'speed', valuePerLevel: 0.1 },
  { name: 'Recovery', description: '+0.3 HP/s', maxLevel: 5, color: 0x4ade80, effect: 'recovery', valuePerLevel: 0.3 },
  { name: 'Magnet', description: '+30% Pickup range', maxLevel: 5, color: 0xa855f7, effect: 'magnet', valuePerLevel: 0.3 },
  { name: 'Luck', description: '+10% XP gain', maxLevel: 5, color: 0xfbbf24, effect: 'xpBonus', valuePerLevel: 0.1 },
  { name: 'Cooldown', description: '-5% Cooldowns', maxLevel: 5, color: 0x06b6d4, effect: 'cooldown', valuePerLevel: 0.05 },
  { name: 'Area', description: '+10% Effect area', maxLevel: 5, color: 0xf97316, effect: 'area', valuePerLevel: 0.1 },
  { name: 'Amount', description: '+1 Projectile', maxLevel: 3, color: 0xec4899, effect: 'amount', valuePerLevel: 1 },
  { name: 'Max HP', description: '+20 Max Health', maxLevel: 5, color: 0x10b981, effect: 'maxHp', valuePerLevel: 20 },
];

export interface PlayerStats {
  damage: number;
  armor: number;
  speed: number;
  recovery: number;
  magnet: number;
  xpBonus: number;
  cooldown: number;
  area: number;
  amount: number;
  maxHp: number;
}

export const BASE_STATS: PlayerStats = {
  damage: 1.0,
  armor: 0,
  speed: 1.0,
  recovery: 0,
  magnet: 1.0,
  xpBonus: 1.0,
  cooldown: 1.0,
  area: 1.0,
  amount: 0,
  maxHp: 100,
};

export const XP_TABLE: number[] = [];
for (let i = 0; i < 100; i++) {
  XP_TABLE.push(Math.floor(5 + i * 3 + Math.pow(i, 1.5)));
}
