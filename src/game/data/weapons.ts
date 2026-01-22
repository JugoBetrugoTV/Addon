export interface WeaponDef {
  name: string;
  description: string;
  type: number;
  baseDamage: number;
  baseCooldown: number;
  baseRange: number;
  baseCount: number;
  basePierce: number;
  baseSpeed: number;
  baseArea: number;
  maxLevel: number;
  color: number;
  upgrades: string[];
}

export const WEAPON_TYPES = {
  WHIP: 0,
  MAGIC_BOLT: 1,
  FIRE_CIRCLE: 2,
  HOLY_CROSS: 3,
  GARLIC: 4,
  LIGHTNING: 5,
  SCYTHE: 6,
  BLOOD_WAVE: 7,
} as const;

export const WEAPONS: WeaponDef[] = [
  {
    name: 'Shadow Whip',
    description: 'Lashes enemies in front of you',
    type: WEAPON_TYPES.WHIP,
    baseDamage: 15,
    baseCooldown: 1.2,
    baseRange: 120,
    baseCount: 1,
    basePierce: -1,
    baseSpeed: 0,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0x9333ea,
    upgrades: ['+20% Damage', '+1 Attack', '+30% Area', '+25% Damage', '+1 Attack', '+40% Area', '+50% Damage', 'Evolve: Void Lash'],
  },
  {
    name: 'Arcane Bolt',
    description: 'Fires homing magic missiles',
    type: WEAPON_TYPES.MAGIC_BOLT,
    baseDamage: 10,
    baseCooldown: 0.8,
    baseRange: 300,
    baseCount: 1,
    basePierce: 1,
    baseSpeed: 350,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0x3b82f6,
    upgrades: ['+1 Projectile', '+30% Damage', '+1 Pierce', '+1 Projectile', '+40% Speed', '+1 Pierce', '+2 Projectiles', 'Evolve: Soul Seeker'],
  },
  {
    name: 'Fire Circle',
    description: 'Orbiting flames damage nearby enemies',
    type: WEAPON_TYPES.FIRE_CIRCLE,
    baseDamage: 8,
    baseCooldown: 3.0,
    baseRange: 80,
    baseCount: 2,
    basePierce: -1,
    baseSpeed: 200,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0xf97316,
    upgrades: ['+1 Orb', '+25% Damage', '+30% Area', '+1 Orb', '+40% Speed', '+1 Orb', '+50% Damage', 'Evolve: Inferno Ring'],
  },
  {
    name: 'Holy Cross',
    description: 'Throws a boomerang cross that returns',
    type: WEAPON_TYPES.HOLY_CROSS,
    baseDamage: 20,
    baseCooldown: 1.5,
    baseRange: 250,
    baseCount: 1,
    basePierce: 3,
    baseSpeed: 300,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0xfbbf24,
    upgrades: ['+30% Damage', '+1 Projectile', '+2 Pierce', '+25% Speed', '+1 Projectile', '+50% Area', '+40% Damage', 'Evolve: Divine Judgment'],
  },
  {
    name: 'Garlic Aura',
    description: 'Damages enemies near you and pushes them back',
    type: WEAPON_TYPES.GARLIC,
    baseDamage: 5,
    baseCooldown: 0.5,
    baseRange: 60,
    baseCount: 1,
    basePierce: -1,
    baseSpeed: 0,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0x4ade80,
    upgrades: ['+30% Area', '+40% Damage', '+30% Area', '+50% Damage', '+20% Knockback', '+40% Area', '+60% Damage', 'Evolve: Soul Eater'],
  },
  {
    name: 'Chain Lightning',
    description: 'Lightning strikes random enemies and chains',
    type: WEAPON_TYPES.LIGHTNING,
    baseDamage: 25,
    baseCooldown: 2.0,
    baseRange: 400,
    baseCount: 1,
    basePierce: 2,
    baseSpeed: 0,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0x60a5fa,
    upgrades: ['+1 Chain', '+30% Damage', '+1 Strike', '+2 Chains', '+40% Damage', '+1 Strike', '+50% Damage', 'Evolve: Thundergod'],
  },
  {
    name: 'Death Scythe',
    description: 'Scythes orbit outward and return',
    type: WEAPON_TYPES.SCYTHE,
    baseDamage: 18,
    baseCooldown: 2.5,
    baseRange: 200,
    baseCount: 1,
    basePierce: 5,
    baseSpeed: 250,
    baseArea: 1.0,
    maxLevel: 8,
    color: 0xa855f7,
    upgrades: ['+1 Scythe', '+30% Damage', '+40% Area', '+1 Scythe', '+2 Pierce', '+50% Speed', '+60% Damage', 'Evolve: Reaper\'s Harvest'],
  },
  {
    name: 'Blood Wave',
    description: 'Unleashes a wave of blood in all directions',
    type: WEAPON_TYPES.BLOOD_WAVE,
    baseDamage: 12,
    baseCooldown: 3.5,
    baseRange: 200,
    baseCount: 4,
    basePierce: -1,
    baseSpeed: 200,
    baseArea: 1.2,
    maxLevel: 8,
    color: 0xef4444,
    upgrades: ['+2 Waves', '+30% Damage', '+40% Area', '+2 Waves', '+50% Damage', '+30% Speed', '+4 Waves', 'Evolve: Crimson Tide'],
  },
];

export const getWeaponDef = (type: number): WeaponDef => WEAPONS[type];
