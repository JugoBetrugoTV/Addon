import { defineComponent, Types } from 'bitecs';

// Core components
export const Position = defineComponent({
  x: Types.f32,
  y: Types.f32,
});

export const Velocity = defineComponent({
  x: Types.f32,
  y: Types.f32,
});

export const Rotation = defineComponent({
  angle: Types.f32,
});

// Health & combat
export const Health = defineComponent({
  current: Types.f32,
  max: Types.f32,
  invincibleTimer: Types.f32,
});

export const Damage = defineComponent({
  amount: Types.f32,
  knockback: Types.f32,
});

export const Collision = defineComponent({
  radius: Types.f32,
});

// Player
export const Player = defineComponent({
  speed: Types.f32,
  xp: Types.f32,
  level: Types.ui16,
  xpToNext: Types.f32,
  kills: Types.ui32,
  moveX: Types.f32,
  moveY: Types.f32,
});

// Enemy
export const Enemy = defineComponent({
  type: Types.ui8,         // 0=skeleton, 1=bat, 2=zombie, 3=ghost, 4=demon, 5=boss
  speed: Types.f32,
  damage: Types.f32,
  xpDrop: Types.f32,
  attackCooldown: Types.f32,
  attackTimer: Types.f32,
  knockbackX: Types.f32,
  knockbackY: Types.f32,
});

// Weapons
export const Weapon = defineComponent({
  type: Types.ui8,         // 0=whip, 1=magic_bolt, 2=fire_circle, 3=holy_cross, 4=garlic, 5=lightning, 6=scythe, 7=blood_wave
  level: Types.ui8,
  damage: Types.f32,
  cooldown: Types.f32,
  timer: Types.f32,
  range: Types.f32,
  count: Types.ui8,        // projectile count
  pierce: Types.ui8,       // how many enemies it can hit
  speed: Types.f32,        // projectile speed
  area: Types.f32,         // area multiplier
});

// Projectile
export const Projectile = defineComponent({
  damage: Types.f32,
  lifetime: Types.f32,
  pierce: Types.i8,        // -1 = infinite, otherwise decrements
  ownerWeaponType: Types.ui8,
  speed: Types.f32,
});

// Area effect (garlic, fire circle, etc)
export const AreaEffect = defineComponent({
  damage: Types.f32,
  radius: Types.f32,
  tickRate: Types.f32,
  tickTimer: Types.f32,
  lifetime: Types.f32,
  followPlayer: Types.ui8, // 1 = follows player
});

// XP Gem
export const XPGem = defineComponent({
  value: Types.f32,
  magnetized: Types.ui8,   // 1 = being attracted to player
});

// Visual/Rendering
export const SpriteComponent = defineComponent({
  type: Types.ui8,         // sprite type index
  frame: Types.ui8,
  animSpeed: Types.f32,
  animTimer: Types.f32,
  scaleX: Types.f32,
  scaleY: Types.f32,
  alpha: Types.f32,
  tint: Types.ui32,
  rotation: Types.f32,
});

// Lifetime (auto-destroy)
export const Lifetime = defineComponent({
  remaining: Types.f32,
});

// Particle
export const Particle = defineComponent({
  type: Types.ui8,   // 0=damage, 1=xp, 2=levelup, 3=death
  scaleDecay: Types.f32,
  alphaDecay: Types.f32,
});

// Flash effect
export const FlashEffect = defineComponent({
  timer: Types.f32,
  duration: Types.f32,
  color: Types.ui32,
});

// Tags
export const PlayerTag = defineComponent();
export const EnemyTag = defineComponent();
export const ProjectileTag = defineComponent();
export const XPGemTag = defineComponent();
export const PickupTag = defineComponent();
export const ParticleTag = defineComponent();
export const WeaponTag = defineComponent();
export const AreaEffectTag = defineComponent();
