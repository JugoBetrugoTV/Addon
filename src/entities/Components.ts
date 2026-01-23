/**
 * Components.ts - All ECS component definitions.
 * Each component is a typed store. Entities are composed from these.
 */

import * as THREE from 'three';
import { defineComponent, ComponentStore } from '../core/ECS';

// === TRANSFORM ===
export interface TransformData {
  position: THREE.Vector3;
  rotation: THREE.Euler;
  velocity: THREE.Vector3;
  grounded: boolean;
}
export const Transform: ComponentStore<TransformData> = defineComponent('Transform');

// === MESH REFERENCE ===
export interface MeshData {
  object: THREE.Object3D;
  visible: boolean;
}
export const MeshRef: ComponentStore<MeshData> = defineComponent('MeshRef');

// === PLAYER TAG ===
export interface PlayerData {
  speed: number;
  health: number;
  maxHealth: number;
  heat: number;        // Crime heat / wanted level
  inVehicle: boolean;
  vehicleId: number;   // Entity ID of vehicle if driving
}
export const PlayerComp: ComponentStore<PlayerData> = defineComponent('Player');

// === NPC ===
export type NPCRole = 'civilian' | 'criminal' | 'cop' | 'worker';
export type NPCState = 'idle' | 'walking' | 'running' | 'fleeing' | 'attacking' | 'driving';

export interface NPCData {
  role: NPCRole;
  state: NPCState;
  targetX: number;
  targetZ: number;
  stateTimer: number;   // Time remaining in current state
  speed: number;
  awareness: number;    // 0-1, how alert to player crimes
  health: number;
}
export const NPCComp: ComponentStore<NPCData> = defineComponent('NPC');

// === VEHICLE ===
export type VehicleType = 'sedan' | 'truck' | 'sports' | 'police';

export interface VehicleData {
  type: VehicleType;
  speed: number;
  maxSpeed: number;
  acceleration: number;
  steering: number;     // Current wheel angle
  throttle: number;     // -1 to 1
  occupied: boolean;
  driverEid: number;    // Entity driving this
}
export const VehicleComp: ComponentStore<VehicleData> = defineComponent('Vehicle');

// === COLLISION ===
export interface CollisionData {
  radius: number;
  height: number;
  isStatic: boolean;
}
export const CollisionComp: ComponentStore<CollisionData> = defineComponent('Collision');

// === AI TARGET (where NPC/vehicle is heading) ===
export interface AITargetData {
  waypoints: THREE.Vector3[];
  currentWaypoint: number;
  finalGoal: THREE.Vector3 | null;
}
export const AITarget: ComponentStore<AITargetData> = defineComponent('AITarget');
