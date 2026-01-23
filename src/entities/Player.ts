/**
 * Player.ts - Player entity creation and mesh.
 * Creates a capsule-shaped character with basic coloring.
 */

import * as THREE from 'three';
import { World, EntityId } from '../core/ECS';
import { Transform, MeshRef, PlayerComp, CollisionComp, TransformData } from './Components';
import { PLAYER_HEIGHT, PLAYER_RADIUS, PLAYER_WALK_SPEED, PLAYER_BASE_HP, WORLD_SIZE } from '../core/Constants';

export function createPlayer(world: World, scene: THREE.Scene): EntityId {
  const eid = world.createEntity();

  // Transform
  const startX = WORLD_SIZE / 2;
  const startZ = WORLD_SIZE / 2;
  world.add(Transform, eid, {
    position: new THREE.Vector3(startX, 0, startZ),
    rotation: new THREE.Euler(0, 0, 0),
    velocity: new THREE.Vector3(0, 0, 0),
    grounded: true,
  });

  // Player data
  world.add(PlayerComp, eid, {
    speed: PLAYER_WALK_SPEED,
    health: PLAYER_BASE_HP,
    maxHealth: PLAYER_BASE_HP,
    heat: 0,
    inVehicle: false,
    vehicleId: 0,
  });

  // Collision
  world.add(CollisionComp, eid, {
    radius: PLAYER_RADIUS,
    height: PLAYER_HEIGHT,
    isStatic: false,
  });

  // Create mesh (capsule body + head)
  const group = new THREE.Group();

  // Body (cylinder)
  const bodyGeo = new THREE.CylinderGeometry(0.25, 0.3, 1.2, 8);
  const bodyMat = new THREE.MeshStandardMaterial({ color: 0x2d3748, roughness: 0.8 });
  const body = new THREE.Mesh(bodyGeo, bodyMat);
  body.position.y = 0.7;
  body.castShadow = true;
  group.add(body);

  // Head (sphere)
  const headGeo = new THREE.SphereGeometry(0.2, 8, 6);
  const headMat = new THREE.MeshStandardMaterial({ color: 0xd4a574, roughness: 0.6 });
  const head = new THREE.Mesh(headGeo, headMat);
  head.position.y = 1.5;
  head.castShadow = true;
  group.add(head);

  // Legs (two thin cylinders)
  const legGeo = new THREE.CylinderGeometry(0.08, 0.1, 0.8, 6);
  const legMat = new THREE.MeshStandardMaterial({ color: 0x1a202c, roughness: 0.9 });
  const legL = new THREE.Mesh(legGeo, legMat);
  legL.position.set(-0.12, 0.15, 0);
  legL.castShadow = true;
  group.add(legL);
  const legR = new THREE.Mesh(legGeo, legMat);
  legR.position.set(0.12, 0.15, 0);
  legR.castShadow = true;
  group.add(legR);

  group.position.set(startX, 0, startZ);
  scene.add(group);

  world.add(MeshRef, eid, { object: group, visible: true });

  return eid;
}
