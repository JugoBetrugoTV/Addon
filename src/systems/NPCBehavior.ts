/**
 * NPCBehavior.ts - NPC AI state machine.
 * NPCs cycle between: idle → walking → idle.
 * Cops patrol. Criminals loiter. Civilians walk to random goals.
 * Future: fleeing, attacking, driving.
 */

import * as THREE from 'three';
import { World, EntityId } from '../core/ECS';
import { Transform, NPCComp, MeshRef, NPCState } from '../entities/Components';
import { NPC_WALK_SPEED, NPC_SPAWN_RADIUS, NPC_DESPAWN_RADIUS, MAX_NPCS, WORLD_SIZE } from '../core/Constants';
import { NPCFactory } from '../entities/NPCFactory';

export class NPCBehaviorSystem {
  private world: World;
  private factory: NPCFactory;
  private spawnTimer: number = 0;

  constructor(world: World, factory: NPCFactory) {
    this.world = world;
    this.factory = factory;
  }

  update(dt: number, playerX: number, playerZ: number): void {
    // Spawn/despawn management
    this.managePopulation(dt, playerX, playerZ);

    // Update each NPC's behavior
    const ids = this.factory.getActiveIds();
    for (const eid of ids) {
      this.updateNPC(eid, dt);
    }
  }

  private updateNPC(eid: EntityId, dt: number): void {
    const transform = this.world.get(Transform, eid);
    const npc = this.world.get(NPCComp, eid);
    const meshData = this.world.get(MeshRef, eid);
    if (!transform || !npc || !meshData) return;

    npc.stateTimer -= dt;

    switch (npc.state) {
      case 'idle':
        transform.velocity.x *= 0.9;
        transform.velocity.z *= 0.9;
        if (npc.stateTimer <= 0) {
          this.pickNewTarget(npc, transform.position.x, transform.position.z);
          npc.state = 'walking';
          npc.stateTimer = 5 + Math.random() * 10;
        }
        break;

      case 'walking':
        this.moveToTarget(transform, npc, dt);
        if (npc.stateTimer <= 0 || this.reachedTarget(transform, npc)) {
          npc.state = 'idle';
          npc.stateTimer = 2 + Math.random() * 4;
        }
        break;

      case 'fleeing':
        this.moveToTarget(transform, npc, dt);
        if (npc.stateTimer <= 0) {
          npc.state = 'walking';
          npc.stateTimer = 5;
        }
        break;

      default:
        npc.state = 'idle';
        npc.stateTimer = 2;
        break;
    }

    // Apply velocity
    transform.position.x += transform.velocity.x * dt;
    transform.position.z += transform.velocity.z * dt;

    // Clamp to world
    transform.position.x = Math.max(1, Math.min(WORLD_SIZE - 1, transform.position.x));
    transform.position.z = Math.max(1, Math.min(WORLD_SIZE - 1, transform.position.z));

    // Update mesh
    meshData.object.position.set(transform.position.x, 0, transform.position.z);
    meshData.object.rotation.copy(transform.rotation);
  }

  private moveToTarget(transform: { position: THREE.Vector3; rotation: THREE.Euler; velocity: THREE.Vector3 }, npc: { targetX: number; targetZ: number; speed: number; state: NPCState }, dt: number): void {
    const dx = npc.targetX - transform.position.x;
    const dz = npc.targetZ - transform.position.z;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist > 1) {
      const speed = npc.state === 'fleeing' ? npc.speed * 2 : npc.speed;
      transform.velocity.x = (dx / dist) * speed;
      transform.velocity.z = (dz / dist) * speed;
      transform.rotation.y = Math.atan2(-dx, -dz);
    } else {
      transform.velocity.x = 0;
      transform.velocity.z = 0;
    }
  }

  private reachedTarget(transform: { position: THREE.Vector3 }, npc: { targetX: number; targetZ: number }): boolean {
    const dx = npc.targetX - transform.position.x;
    const dz = npc.targetZ - transform.position.z;
    return dx * dx + dz * dz < 4;
  }

  private pickNewTarget(npc: { targetX: number; targetZ: number }, x: number, z: number): void {
    npc.targetX = x + (Math.random() - 0.5) * 120;
    npc.targetZ = z + (Math.random() - 0.5) * 120;
    npc.targetX = Math.max(10, Math.min(WORLD_SIZE - 10, npc.targetX));
    npc.targetZ = Math.max(10, Math.min(WORLD_SIZE - 10, npc.targetZ));
  }

  private managePopulation(dt: number, px: number, pz: number): void {
    this.spawnTimer -= dt;

    // Spawn new NPCs near player
    if (this.spawnTimer <= 0 && this.factory.count < MAX_NPCS) {
      this.spawnTimer = 0.5; // Check every 0.5s
      const needed = Math.min(3, MAX_NPCS - this.factory.count);
      for (let i = 0; i < needed; i++) {
        const angle = Math.random() * Math.PI * 2;
        const dist = NPC_SPAWN_RADIUS * 0.5 + Math.random() * NPC_SPAWN_RADIUS * 0.5;
        const x = px + Math.cos(angle) * dist;
        const z = pz + Math.sin(angle) * dist;
        if (x < 1 || x > WORLD_SIZE - 1 || z < 1 || z > WORLD_SIZE - 1) continue;

        const r = Math.random();
        const role = r < 0.6 ? 'civilian' : r < 0.75 ? 'worker' : r < 0.88 ? 'criminal' : 'cop';
        this.factory.spawn(x, z, role as any);
      }
    }

    // Despawn far NPCs
    const ids = this.factory.getActiveIds();
    for (const eid of ids) {
      const transform = this.world.get(Transform, eid);
      if (!transform) continue;
      const dx = transform.position.x - px;
      const dz = transform.position.z - pz;
      if (dx * dx + dz * dz > NPC_DESPAWN_RADIUS * NPC_DESPAWN_RADIUS) {
        this.factory.remove(eid);
      }
    }
  }
}
