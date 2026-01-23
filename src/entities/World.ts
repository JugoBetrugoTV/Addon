/**
 * World.ts - ECS world setup and component definitions.
 * Uses bitECS for high-performance entity management.
 * All components are defined here as the single source of truth.
 */

import { defineComponent, Types, defineQuery, createWorld, IWorld } from 'bitecs';

// === CORE COMPONENTS ===

export const Position = defineComponent({ x: Types.f32, y: Types.f32 });
export const Velocity = defineComponent({ x: Types.f32, y: Types.f32 });
export const Health = defineComponent({
  current: Types.f32,
  max: Types.f32,
  invincibleTimer: Types.f32,
});
export const Collision = defineComponent({ radius: Types.f32 });

// === PLAYER ===
export const Player = defineComponent({
  speed: Types.f32,
  xp: Types.f32,
  level: Types.ui16,
  xpToNext: Types.f32,
});

// === ENEMY ===
export const Enemy = defineComponent({
  type: Types.ui8,
  speed: Types.f32,
  damage: Types.f32,
  xpDrop: Types.f32,
  attackCooldown: Types.f32,
  attackTimer: Types.f32,
  knockbackX: Types.f32,
  knockbackY: Types.f32,
});

// === WEAPON (entity-based, one per weapon slot) ===
export const Weapon = defineComponent({
  type: Types.ui8,
  level: Types.ui8,
  damage: Types.f32,
  cooldown: Types.f32,
  timer: Types.f32,
  range: Types.f32,
  count: Types.ui8,
  pierce: Types.i8,
  speed: Types.f32,
  area: Types.f32,
});

// === PROJECTILE ===
export const Projectile = defineComponent({
  damage: Types.f32,
  pierce: Types.i8,
  ownerWeaponType: Types.ui8,
  speed: Types.f32,
});

// === AREA EFFECT (garlic, etc.) ===
export const AreaEffect = defineComponent({
  damage: Types.f32,
  radius: Types.f32,
  tickRate: Types.f32,
  tickTimer: Types.f32,
  followPlayer: Types.ui8,
});

// === XP GEM ===
export const XPGem = defineComponent({
  value: Types.f32,
});

// === LIFETIME (auto-destroy after timer expires) ===
export const Lifetime = defineComponent({
  remaining: Types.f32,
});

// === VISUAL STATE (for rendering) ===
export const SpriteState = defineComponent({
  rotation: Types.f32,
});

// === PARTICLE (visual-only entity) ===
export const Particle = defineComponent({
  color: Types.ui32,
});

// === TAG COMPONENTS (zero-storage markers) ===
export const PlayerTag = defineComponent();
export const EnemyTag = defineComponent();
export const ProjectileTag = defineComponent();
export const XPGemTag = defineComponent();
export const ParticleTag = defineComponent();
export const WeaponTag = defineComponent();
export const AreaEffectTag = defineComponent();

// === QUERIES (defined ONCE, reused every frame) ===
export const enemyMovementQuery = defineQuery([Enemy, EnemyTag, Position, Velocity]);
export const enemyPositionQuery = defineQuery([Enemy, EnemyTag, Position]);
export const enemyCollisionQuery = defineQuery([Enemy, EnemyTag, Position, Collision, Health]);
export const projectileMovementQuery = defineQuery([Projectile, ProjectileTag, Position, Velocity]);
export const projectileCollisionQuery = defineQuery([Projectile, ProjectileTag, Position, Collision]);
export const particleMovementQuery = defineQuery([Particle, ParticleTag, Position, Velocity]);
export const particleLifetimeQuery = defineQuery([Particle, ParticleTag, Position, Lifetime]);
export const gemQuery = defineQuery([XPGem, XPGemTag, Position]);
export const weaponQuery = defineQuery([Weapon, WeaponTag]);
export const areaEffectQuery = defineQuery([AreaEffect, AreaEffectTag, Position]);
export const lifetimeQuery = defineQuery([Lifetime]);

// === WORLD FACTORY ===
export function createGameWorld(): IWorld {
  return createWorld();
}
