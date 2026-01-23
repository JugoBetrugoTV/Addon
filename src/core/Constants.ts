/**
 * Constants.ts - All game constants in one place.
 * Changing values here affects the entire game balance and performance.
 */

// === WORLD ===
export const WORLD_SIZE = 5000;
export const TILE_SIZE = 64;

// === PERFORMANCE CAPS ===
export const MAX_ENEMIES = 250;
export const MAX_PARTICLES = 120;
export const MAX_XP_GEMS = 100;
export const MAX_DAMAGE_NUMBERS = 30;
export const MAX_PROJECTILES = 200;

// === SPATIAL GRID ===
export const GRID_CELL_SIZE = 128;
export const GRID_SIZE = Math.ceil(WORLD_SIZE / GRID_CELL_SIZE);

// === GAMEPLAY ===
export const SPAWN_DISTANCE = 600;
export const MAGNET_BASE_RANGE = 90;
export const PLAYER_BASE_SPEED = 160;
export const PLAYER_BASE_HP = 100;
export const INVINCIBILITY_TIME = 0.25;

// === CAMERA ===
export const CAMERA_LERP_SPEED = 6;
export const CAMERA_SHAKE_DECAY = 0.88;

// === RENDERING ===
export const CHUNK_SIZE = 512;
export const LIGHT_RADIUS_BASE = 200;
export const BLOOM_INTENSITY = 0.35;
export const VIGNETTE_INTENSITY = 0.4;
export const CHROMATIC_INTENSITY = 0.002;

// === PARTICLES ===
export const PARTICLE_GRAVITY = 120;
export const PARTICLE_FADE_SPEED = 2.5;

// === COMBAT ===
export const KNOCKBACK_FORCE = 180;
export const KNOCKBACK_DECAY = 0.82;
export const DAMAGE_NUMBER_LIFETIME = 0.7;
export const DAMAGE_NUMBER_VELOCITY = -70;
