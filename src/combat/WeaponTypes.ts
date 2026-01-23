/**
 * WeaponTypes.ts - All weapon definitions and balance data.
 * Each weapon has a unique firing pattern, visuals, and upgrade path.
 */

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

export interface WeaponDef {
  type: number;
  name: string;
  description: string;
  baseDamage: number;
  baseCooldown: number;
  baseRange: number;
  baseCount: number;
  basePierce: number;
  baseSpeed: number;
  baseArea: number;
  color: number;
  maxLevel: number;
  upgrades: string[];
  /** Glow color for lighting effects */
  glowColor: number;
}

export const WEAPONS: WeaponDef[] = [
  {
    type: 0, name: 'Shadow Whip', description: 'Lashes nearby enemies',
    baseDamage: 15, baseCooldown: 1.2, baseRange: 80, baseCount: 1,
    basePierce: -1, baseSpeed: 50, baseArea: 1.0, color: 0xa855f7,
    maxLevel: 8, glowColor: 0x7c3aed,
    upgrades: ['+25% Damage', '+1 Whip', '+30% Area', '+25% Damage', '+1 Whip', '+50% Area', '+50% Damage'],
  },
  {
    type: 1, name: 'Arcane Bolt', description: 'Fires homing projectiles',
    baseDamage: 12, baseCooldown: 0.9, baseRange: 350, baseCount: 1,
    basePierce: 1, baseSpeed: 350, baseArea: 1.0, color: 0xc4a0ff,
    maxLevel: 8, glowColor: 0x8b5cf6,
    upgrades: ['+1 Bolt', '+25% Speed', '+1 Pierce', '+1 Bolt', '+25% Damage', '+1 Pierce', '+2 Bolts'],
  },
  {
    type: 2, name: 'Inferno Ring', description: 'Orbiting flames around you',
    baseDamage: 10, baseCooldown: 3.0, baseRange: 80, baseCount: 3,
    basePierce: -1, baseSpeed: 200, baseArea: 1.0, color: 0xf97316,
    maxLevel: 8, glowColor: 0xea580c,
    upgrades: ['+1 Flame', '+20% Speed', '+30% Area', '+1 Flame', '+25% Damage', '+1 Flame', '+50% Damage'],
  },
  {
    type: 3, name: 'Holy Cross', description: 'Boomerang that returns to you',
    baseDamage: 18, baseCooldown: 1.8, baseRange: 300, baseCount: 1,
    basePierce: 5, baseSpeed: 280, baseArea: 1.0, color: 0xfbbf24,
    maxLevel: 8, glowColor: 0xd97706,
    upgrades: ['+3 Pierce', '+25% Speed', '+1 Cross', '+25% Damage', '+5 Pierce', '+1 Cross', '+100% Damage'],
  },
  {
    type: 4, name: 'Decay Aura', description: 'Damages all nearby enemies',
    baseDamage: 5, baseCooldown: 0.5, baseRange: 60, baseCount: 1,
    basePierce: -1, baseSpeed: 0, baseArea: 1.0, color: 0x4ade80,
    maxLevel: 8, glowColor: 0x16a34a,
    upgrades: ['+30% Area', '+25% Damage', '+30% Area', '+25% Damage', '+50% Area', '+50% Damage', '+100% Area'],
  },
  {
    type: 5, name: 'Chain Lightning', description: 'Strikes and chains between enemies',
    baseDamage: 20, baseCooldown: 2.0, baseRange: 300, baseCount: 1,
    basePierce: 2, baseSpeed: 0, baseArea: 1.0, color: 0x60a5fa,
    maxLevel: 8, glowColor: 0x2563eb,
    upgrades: ['+1 Chain', '+1 Strike', '+25% Damage', '+1 Chain', '+1 Strike', '+50% Damage', '+2 Chains'],
  },
  {
    type: 6, name: 'Death Scythe', description: 'Spinning blade passes through',
    baseDamage: 22, baseCooldown: 2.2, baseRange: 400, baseCount: 1,
    basePierce: 10, baseSpeed: 250, baseArea: 1.2, color: 0x9ca3af,
    maxLevel: 8, glowColor: 0x6b7280,
    upgrades: ['+5 Pierce', '+25% Speed', '+1 Scythe', '+25% Damage', '+10 Pierce', '+1 Scythe', '+100% Damage'],
  },
  {
    type: 7, name: 'Blood Nova', description: 'Expanding ring of blood magic',
    baseDamage: 14, baseCooldown: 3.5, baseRange: 250, baseCount: 8,
    basePierce: -1, baseSpeed: 180, baseArea: 1.0, color: 0xef4444,
    maxLevel: 8, glowColor: 0xdc2626,
    upgrades: ['+4 Waves', '+25% Speed', '+25% Damage', '+4 Waves', '+50% Area', '+25% Damage', '+8 Waves'],
  },
];

export function getWeaponDef(type: number): WeaponDef {
  return WEAPONS[type] || WEAPONS[1];
}
