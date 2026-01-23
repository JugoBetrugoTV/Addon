/**
 * NPCFactory.ts - NPC entity creation with role-based appearance.
 * Creates capsule characters with different colors per role.
 */

import * as THREE from 'three';
import { World, EntityId } from '../core/ECS';
import { Transform, MeshRef, NPCComp, CollisionComp, NPCRole } from './Components';
import { NPC_WALK_SPEED } from '../core/Constants';

const ROLE_COLORS: Record<NPCRole, { body: number; head: number }> = {
  civilian: { body: 0x4a5568, head: 0xd4a574 },
  worker:   { body: 0xc05621, head: 0xd4a574 },
  criminal: { body: 0x1a1a2e, head: 0xc4a574 },
  cop:      { body: 0x1a365d, head: 0xd4a574 },
};

export class NPCFactory {
  private world: World;
  private scene: THREE.Scene;
  private activeNPCs: Map<EntityId, THREE.Group> = new Map();

  constructor(world: World, scene: THREE.Scene) {
    this.world = world;
    this.scene = scene;
  }

  /** Spawn an NPC at position with given role */
  spawn(x: number, z: number, role: NPCRole): EntityId {
    const eid = this.world.createEntity();

    this.world.add(Transform, eid, {
      position: new THREE.Vector3(x, 0, z),
      rotation: new THREE.Euler(0, Math.random() * Math.PI * 2, 0),
      velocity: new THREE.Vector3(0, 0, 0),
      grounded: true,
    });

    // Pick random target nearby
    const targetX = x + (Math.random() - 0.5) * 100;
    const targetZ = z + (Math.random() - 0.5) * 100;

    this.world.add(NPCComp, eid, {
      role,
      state: 'idle',
      targetX, targetZ,
      stateTimer: 2 + Math.random() * 5,
      speed: NPC_WALK_SPEED * (0.8 + Math.random() * 0.4),
      awareness: role === 'cop' ? 0.9 : 0.3,
      health: 100,
    });

    this.world.add(CollisionComp, eid, {
      radius: 0.3, height: 1.8, isStatic: false,
    });

    // Create mesh
    const group = this.createMesh(role);
    group.position.set(x, 0, z);
    this.scene.add(group);

    this.world.add(MeshRef, eid, { object: group, visible: true });
    this.activeNPCs.set(eid, group);

    return eid;
  }

  /** Remove an NPC entity and its mesh */
  remove(eid: EntityId): void {
    const group = this.activeNPCs.get(eid);
    if (group) {
      this.scene.remove(group);
      group.traverse((child) => {
        if (child instanceof THREE.Mesh) {
          child.geometry.dispose();
          (child.material as THREE.Material).dispose();
        }
      });
      this.activeNPCs.delete(eid);
    }
    this.world.removeEntity(eid, Transform, MeshRef, NPCComp, CollisionComp);
  }

  get count(): number { return this.activeNPCs.size; }

  getActiveIds(): EntityId[] {
    return Array.from(this.activeNPCs.keys());
  }

  private createMesh(role: NPCRole): THREE.Group {
    const colors = ROLE_COLORS[role];
    const group = new THREE.Group();

    // Body
    const bodyGeo = new THREE.CylinderGeometry(0.22, 0.26, 1.0, 6);
    const bodyMat = new THREE.MeshStandardMaterial({ color: colors.body, roughness: 0.8 });
    const body = new THREE.Mesh(bodyGeo, bodyMat);
    body.position.y = 0.6;
    body.castShadow = true;
    group.add(body);

    // Head
    const headGeo = new THREE.SphereGeometry(0.17, 6, 5);
    const headMat = new THREE.MeshStandardMaterial({ color: colors.head, roughness: 0.6 });
    const head = new THREE.Mesh(headGeo, headMat);
    head.position.y = 1.3;
    head.castShadow = true;
    group.add(head);

    // Cop hat
    if (role === 'cop') {
      const hatGeo = new THREE.CylinderGeometry(0.15, 0.2, 0.12, 6);
      const hatMat = new THREE.MeshStandardMaterial({ color: 0x1a365d, roughness: 0.5 });
      const hat = new THREE.Mesh(hatGeo, hatMat);
      hat.position.y = 1.5;
      group.add(hat);
    }

    return group;
  }
}
