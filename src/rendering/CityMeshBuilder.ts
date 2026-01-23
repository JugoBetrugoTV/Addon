/**
 * CityMeshBuilder.ts - Builds Three.js meshes from CityLayout chunk data.
 * Creates instanced geometry for buildings, planes for roads.
 * Returns a Group per chunk for easy add/remove from scene.
 */

import * as THREE from 'three';
import { ChunkData, Building } from '../world/CityLayout';
import { GROUND_Y } from '../core/Constants';

// Shared materials (created once)
const roadMaterial = new THREE.MeshStandardMaterial({
  color: 0x2d2d2d, roughness: 0.9, metalness: 0.0,
});
const sidewalkMaterial = new THREE.MeshStandardMaterial({
  color: 0x6b6b6b, roughness: 0.85, metalness: 0.0,
});
const groundMaterial = new THREE.MeshStandardMaterial({
  color: 0x3a5a3a, roughness: 1.0, metalness: 0.0,
});

// Reusable geometries
const boxGeo = new THREE.BoxGeometry(1, 1, 1);
const planeGeo = new THREE.PlaneGeometry(1, 1);

export class CityMeshBuilder {
  /** Build all meshes for a chunk. Returns a Group to add to scene. */
  buildChunk(data: ChunkData): THREE.Group {
    const group = new THREE.Group();
    group.name = `chunk_${data.cx}_${data.cz}`;

    // Ground plane for chunk
    this.addGround(group, data);

    // Roads
    for (const road of data.roads) {
      this.addRoad(group, road);
    }

    // Sidewalks
    for (const sw of data.sidewalks) {
      this.addSidewalk(group, sw);
    }

    // Buildings
    for (const building of data.buildings) {
      this.addBuilding(group, building);
    }

    return group;
  }

  private addGround(group: THREE.Group, data: ChunkData): void {
    const chunkSize = 320; // CHUNK_SIZE
    const ground = new THREE.Mesh(planeGeo.clone(), groundMaterial);
    ground.scale.set(chunkSize, chunkSize, 1);
    ground.rotation.x = -Math.PI / 2;
    ground.position.set(
      data.cx * chunkSize + chunkSize / 2,
      GROUND_Y - 0.05,
      data.cz * chunkSize + chunkSize / 2
    );
    ground.receiveShadow = true;
    group.add(ground);
  }

  private addRoad(group: THREE.Group, road: { x: number; z: number; w: number; d: number }): void {
    const mesh = new THREE.Mesh(planeGeo.clone(), roadMaterial);
    mesh.scale.set(road.w, road.d, 1);
    mesh.rotation.x = -Math.PI / 2;
    mesh.position.set(road.x, GROUND_Y + 0.01, road.z);
    mesh.receiveShadow = true;
    group.add(mesh);
  }

  private addSidewalk(group: THREE.Group, sw: { x: number; z: number; w: number; d: number }): void {
    const mesh = new THREE.Mesh(boxGeo.clone(), sidewalkMaterial);
    mesh.scale.set(sw.w, 0.15, sw.d);
    mesh.position.set(sw.x, GROUND_Y + 0.075, sw.z);
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    group.add(mesh);
  }

  private addBuilding(group: THREE.Group, b: Building): void {
    const material = new THREE.MeshStandardMaterial({
      color: b.color,
      roughness: 0.7,
      metalness: 0.1,
    });

    const mesh = new THREE.Mesh(boxGeo.clone(), material);
    mesh.scale.set(b.width, b.height, b.depth);
    mesh.position.set(b.x + b.width / 2, GROUND_Y + b.height / 2, b.z + b.depth / 2);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    group.add(mesh);

    // Window-like horizontal strips (simple dark bands)
    if (b.height > 8) {
      const windowMat = new THREE.MeshStandardMaterial({
        color: 0x1a1a2e, roughness: 0.3, metalness: 0.5, emissive: 0x111122, emissiveIntensity: 0.2,
      });
      const floors = Math.floor(b.height / 3.5);
      for (let f = 1; f < Math.min(floors, 8); f++) {
        const strip = new THREE.Mesh(boxGeo.clone(), windowMat);
        strip.scale.set(b.width + 0.1, 1.2, b.depth + 0.1);
        strip.position.set(b.x + b.width / 2, GROUND_Y + f * 3.5, b.z + b.depth / 2);
        group.add(strip);
      }
    }
  }
}
