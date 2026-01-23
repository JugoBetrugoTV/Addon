/**
 * UpgradeData.ts - Passive upgrade definitions and XP progression table.
 * Controls the meta-progression and stat scaling.
 */

export interface PlayerStats {
  damage: number;
  armor: number;
  speed: number;
  recovery: number;
  magnet: number;
  luck: number;
  cooldown: number;
  area: number;
  amount: number;
  maxHp: number;
  xpBonus: number;
}

export const BASE_STATS: PlayerStats = {
  damage: 1.0,
  armor: 0,
  speed: 1.0,
  recovery: 0,
  magnet: 1.0,
  luck: 1.0,
  cooldown: 1.0,
  area: 1.0,
  amount: 0,
  maxHp: 100,
  xpBonus: 1.0,
};

export interface PassiveUpgrade {
  name: string;
  description: string;
  effect: keyof PlayerStats;
  valuePerLevel: number;
  maxLevel: number;
  color: number;
}

export const PASSIVE_UPGRADES: PassiveUpgrade[] = [
  { name: 'Might', description: '+10% Damage', effect: 'damage', valuePerLevel: 0.1, maxLevel: 5, color: 0xef4444 },
  { name: 'Armor', description: '+5% Damage Reduction', effect: 'armor', valuePerLevel: 0.05, maxLevel: 5, color: 0x6b7280 },
  { name: 'Swift', description: '+10% Move Speed', effect: 'speed', valuePerLevel: 0.1, maxLevel: 5, color: 0x38bdf8 },
  { name: 'Recovery', description: '+0.3 HP/sec', effect: 'recovery', valuePerLevel: 0.3, maxLevel: 5, color: 0x4ade80 },
  { name: 'Magnet', description: '+20% Pickup Range', effect: 'magnet', valuePerLevel: 0.2, maxLevel: 5, color: 0xa855f7 },
  { name: 'Luck', description: '+10% Rare Chance', effect: 'luck', valuePerLevel: 0.1, maxLevel: 3, color: 0xfbbf24 },
  { name: 'Haste', description: '-8% Cooldowns', effect: 'cooldown', valuePerLevel: 0.08, maxLevel: 5, color: 0x14b8a6 },
  { name: 'Amplify', description: '+10% Effect Area', effect: 'area', valuePerLevel: 0.1, maxLevel: 5, color: 0xf97316 },
  { name: 'Multi', description: '+1 Projectile', effect: 'amount', valuePerLevel: 1, maxLevel: 3, color: 0xe879f9 },
  { name: 'Vitality', description: '+20 Max HP', effect: 'maxHp', valuePerLevel: 20, maxLevel: 5, color: 0xf87171 },
];

/** XP required for each level (100 levels) */
export const XP_TABLE: number[] = (() => {
  const table: number[] = [];
  for (let i = 0; i < 100; i++) {
    // Exponential curve: starts at 5, grows moderately
    table.push(Math.floor(5 + i * 3 + Math.pow(i, 1.6) * 0.8));
  }
  return table;
})();
