/**
 * Streamer.ts - World streaming system.
 * Loads/unloads city chunks based on player position.
 * Prevents loading too many chunks at once.
 */

import * as THREE from 'three';
import { CHUNK_SIZE, STREAM_RADIUS, UNLOAD_RADIUS, CHUNKS_PER_SIDE } from '../core/Constants';
import { CityLayout, ChunkData } from './CityLayout';
import { CityMeshBuilder } from '../rendering/CityMeshBuilder';

interface LoadedChunk {
  cx: number;
  cz: number;
  group: THREE.Group;
  data: ChunkData;
}

export class Streamer {
  private layout: CityLayout;
  private builder: CityMeshBuilder;
  private scene: THREE.Scene;
  private loaded: Map<string, LoadedChunk> = new Map();
  private lastChunkX: number = -999;
  private lastChunkZ: number = -999;

  constructor(layout: CityLayout, builder: CityMeshBuilder, scene: THREE.Scene) {
    this.layout = layout;
    this.builder = builder;
    this.scene = scene;
  }

  /** Update streaming based on player world position */
  update(playerX: number, playerZ: number): void {
    const cx = Math.floor(playerX / CHUNK_SIZE);
    const cz = Math.floor(playerZ / CHUNK_SIZE);

    // Only recalculate if player moved to a new chunk
    if (cx === this.lastChunkX && cz === this.lastChunkZ) return;
    this.lastChunkX = cx;
    this.lastChunkZ = cz;

    // Load chunks within radius
    for (let dz = -STREAM_RADIUS; dz <= STREAM_RADIUS; dz++) {
      for (let dx = -STREAM_RADIUS; dx <= STREAM_RADIUS; dx++) {
        const tcx = cx + dx;
        const tcz = cz + dz;
        if (tcx < 0 || tcx >= CHUNKS_PER_SIDE || tcz < 0 || tcz >= CHUNKS_PER_SIDE) continue;

        const key = `${tcx},${tcz}`;
        if (!this.loaded.has(key)) {
          this.loadChunk(tcx, tcz);
        }
      }
    }

    // Unload chunks beyond unload radius
    for (const [key, chunk] of this.loaded) {
      const dx = Math.abs(chunk.cx - cx);
      const dz = Math.abs(chunk.cz - cz);
      if (dx > UNLOAD_RADIUS || dz > UNLOAD_RADIUS) {
        this.unloadChunk(key, chunk);
      }
    }
  }

  private loadChunk(cx: number, cz: number): void {
    const data = this.layout.generateChunk(cx, cz);
    const group = this.builder.buildChunk(data);
    this.scene.add(group);
    this.loaded.set(`${cx},${cz}`, { cx, cz, group, data });
  }

  private unloadChunk(key: string, chunk: LoadedChunk): void {
    this.scene.remove(chunk.group);
    // Dispose geometries and materials
    chunk.group.traverse((child) => {
      if (child instanceof THREE.Mesh) {
        child.geometry.dispose();
        if (Array.isArray(child.material)) {
          child.material.forEach(m => m.dispose());
        } else {
          child.material.dispose();
        }
      }
    });
    this.loaded.delete(key);
  }

  /** Get chunk data at position (for NPC spawning, pathfinding) */
  getChunkAt(x: number, z: number): ChunkData | null {
    const cx = Math.floor(x / CHUNK_SIZE);
    const cz = Math.floor(z / CHUNK_SIZE);
    return this.loaded.get(`${cx},${cz}`)?.data || null;
  }

  get loadedCount(): number { return this.loaded.size; }
}
