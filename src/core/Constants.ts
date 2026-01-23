/**
 * Constants.ts - All game constants.
 * World dimensions, performance caps, physics, rendering.
 */

// === WORLD ===
export const WORLD_SIZE = 2000;           // World is 2000x2000 meters
export const BLOCK_SIZE = 80;             // City block = 80m
export const ROAD_WIDTH = 12;             // Road width in meters
export const SIDEWALK_WIDTH = 3;          // Sidewalk width
export const CHUNK_SIZE = 320;            // Streaming chunk = 4 blocks = 320m
export const CHUNKS_PER_SIDE = Math.ceil(WORLD_SIZE / CHUNK_SIZE);

// === DISTRICTS ===
export const DISTRICT_SIZE = 640;         // Each district = 8 blocks wide
export const DISTRICTS_PER_SIDE = Math.ceil(WORLD_SIZE / DISTRICT_SIZE);

// === STREAMING ===
export const STREAM_RADIUS = 2;           // Load chunks within 2-chunk radius
export const UNLOAD_RADIUS = 3;           // Unload beyond 3-chunk radius

// === PERFORMANCE ===
export const MAX_NPCS = 80;               // Visible NPCs at once
export const MAX_VEHICLES = 30;           // Visible vehicles at once
export const MAX_DRAW_DISTANCE = 500;     // Fog/cull distance in meters
export const LOD_DISTANCE = 150;          // Switch to low-detail beyond this

// === PLAYER ===
export const PLAYER_WALK_SPEED = 4.5;     // m/s walking
export const PLAYER_RUN_SPEED = 8.0;      // m/s running (shift)
export const PLAYER_HEIGHT = 1.8;         // Player capsule height
export const PLAYER_RADIUS = 0.3;         // Collision radius
export const PLAYER_BASE_HP = 100;        // Starting health

// === NPC ===
export const NPC_WALK_SPEED = 3.0;        // m/s NPC walking
export const NPC_RUN_SPEED = 6.5;         // m/s NPC running
export const NPC_SPAWN_RADIUS = 120;      // Spawn NPCs within this distance
export const NPC_DESPAWN_RADIUS = 160;    // Remove NPCs beyond this

// === VEHICLES ===
export const VEHICLE_MAX_SPEED = 20;      // m/s (~72 km/h)
export const VEHICLE_ACCELERATION = 8;    // m/s²
export const VEHICLE_BRAKE_FORCE = 15;    // m/s² braking
export const VEHICLE_TURN_SPEED = 2.5;    // rad/s

// === CAMERA ===
export const CAMERA_DISTANCE = 8;         // Distance behind player
export const CAMERA_HEIGHT = 4;           // Height above player
export const CAMERA_LERP = 5;             // Follow smoothing
export const CAMERA_MOUSE_SENSITIVITY = 0.003;

// === PHYSICS ===
export const GRAVITY = -20;               // m/s²
export const GROUND_Y = 0;               // Ground plane Y

// === CRIME ===
export const HEAT_DECAY_RATE = 0.5;       // Heat per second decay
export const HEAT_PER_ASSAULT = 20;
export const HEAT_PER_VEHICLE_THEFT = 15;
export const HEAT_PER_MURDER = 50;
export const HEAT_THRESHOLD_PATROL = 10;
export const HEAT_THRESHOLD_CHASE = 30;
export const HEAT_THRESHOLD_SWAT = 70;

// === RENDERING ===
export const AMBIENT_LIGHT = 0.4;
export const SUN_INTENSITY = 1.2;
export const FOG_NEAR = 200;
export const FOG_FAR = 500;
export const SHADOW_MAP_SIZE = 2048;
