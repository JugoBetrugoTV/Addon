/**
 * CityLayout.ts - Procedural city grid generation.
 * Defines districts, blocks, roads, and building placement.
 * Pure data - no rendering. Used by CityMeshBuilder.
 */

import {
  WORLD_SIZE, BLOCK_SIZE, ROAD_WIDTH, CHUNK_SIZE,
  DISTRICT_SIZE, DISTRICTS_PER_SIDE, CHUNKS_PER_SIDE,
} from '../core/Constants';

export type DistrictType = 'downtown' | 'residential' | 'industrial' | 'slums' | 'commercial';

export interface District {
  type: DistrictType;
  gridX: number;
  gridZ: number;
  minBuildingHeight: number;
  maxBuildingHeight: number;
  density: number;  // 0-1, how filled with buildings
  color: number;    // Base building color
}

export interface Building {
  x: number;
  z: number;
  width: number;
  depth: number;
  height: number;
  color: number;
}

export interface ChunkData {
  cx: number;
  cz: number;
  buildings: Building[];
  roads: { x: number; z: number; w: number; d: number }[];
  sidewalks: { x: number; z: number; w: number; d: number }[];
}

const DISTRICT_CONFIGS: Record<DistrictType, { minH: number; maxH: number; density: number; color: number }> = {
  downtown:    { minH: 20, maxH: 80, density: 0.9, color: 0x4a5568 },
  commercial:  { minH: 8,  maxH: 30, density: 0.8, color: 0x718096 },
  residential: { minH: 5,  maxH: 15, density: 0.7, color: 0xa0aec0 },
  industrial:  { minH: 6,  maxH: 20, density: 0.6, color: 0x5a4a3a },
  slums:       { minH: 3,  maxH: 8,  density: 0.5, color: 0x6b5b4a },
};

export class CityLayout {
  districts: District[][] = [];
  private rng: () => number;

  constructor(seed: number = 42) {
    this.rng = this.createRng(seed);
    this.generateDistricts();
  }

  private generateDistricts(): void {
    // Place downtown in center, other types radiate outward
    const center = Math.floor(DISTRICTS_PER_SIDE / 2);

    for (let gz = 0; gz < DISTRICTS_PER_SIDE; gz++) {
      this.districts[gz] = [];
      for (let gx = 0; gx < DISTRICTS_PER_SIDE; gx++) {
        const distFromCenter = Math.abs(gx - center) + Math.abs(gz - center);
        let type: DistrictType;

        if (distFromCenter === 0) {
          type = 'downtown';
        } else if (distFromCenter === 1) {
          type = this.rng() > 0.5 ? 'commercial' : 'downtown';
        } else if (distFromCenter === 2) {
          type = 'commercial';
        } else {
          const r = this.rng();
          if (r < 0.4) type = 'residential';
          else if (r < 0.7) type = 'industrial';
          else type = 'slums';
        }

        const cfg = DISTRICT_CONFIGS[type];
        this.districts[gz][gx] = {
          type, gridX: gx, gridZ: gz,
          minBuildingHeight: cfg.minH,
          maxBuildingHeight: cfg.maxH,
          density: cfg.density,
          color: cfg.color,
        };
      }
    }
  }

  /** Generate chunk data at chunk coordinates (cx, cz) */
  generateChunk(cx: number, cz: number): ChunkData {
    const worldX = cx * CHUNK_SIZE;
    const worldZ = cz * CHUNK_SIZE;
    const buildings: Building[] = [];
    const roads: { x: number; z: number; w: number; d: number }[] = [];
    const sidewalks: { x: number; z: number; w: number; d: number }[] = [];

    // Determine district for this chunk
    const dIdx = Math.floor(cx * CHUNK_SIZE / DISTRICT_SIZE);
    const dIdz = Math.floor(cz * CHUNK_SIZE / DISTRICT_SIZE);
    const district = this.districts[Math.min(dIdz, DISTRICTS_PER_SIDE - 1)]
                                   ?.[Math.min(dIdx, DISTRICTS_PER_SIDE - 1)];
    if (!district) return { cx, cz, buildings, roads, sidewalks };

    const blocksInChunk = Math.floor(CHUNK_SIZE / BLOCK_SIZE);
    const rng = this.createRng(cx * 1000 + cz);

    for (let bz = 0; bz < blocksInChunk; bz++) {
      for (let bx = 0; bx < blocksInChunk; bx++) {
        const blockWorldX = worldX + bx * BLOCK_SIZE;
        const blockWorldZ = worldZ + bz * BLOCK_SIZE;

        // Roads along block edges
        // Horizontal road (along X)
        roads.push({
          x: blockWorldX + BLOCK_SIZE / 2,
          z: blockWorldZ,
          w: BLOCK_SIZE,
          d: ROAD_WIDTH,
        });
        // Vertical road (along Z)
        roads.push({
          x: blockWorldX,
          z: blockWorldZ + BLOCK_SIZE / 2,
          w: ROAD_WIDTH,
          d: BLOCK_SIZE,
        });

        // Sidewalks (next to roads)
        sidewalks.push({
          x: blockWorldX + BLOCK_SIZE / 2,
          z: blockWorldZ + ROAD_WIDTH / 2 + 1.5,
          w: BLOCK_SIZE - ROAD_WIDTH,
          d: 3,
        });
        sidewalks.push({
          x: blockWorldX + ROAD_WIDTH / 2 + 1.5,
          z: blockWorldZ + BLOCK_SIZE / 2,
          w: 3,
          d: BLOCK_SIZE - ROAD_WIDTH,
        });

        // Buildings inside block (skip if low density roll)
        if (rng() > district.density) continue;

        const buildableX = blockWorldX + ROAD_WIDTH + 2;
        const buildableZ = blockWorldZ + ROAD_WIDTH + 2;
        const buildableSize = BLOCK_SIZE - ROAD_WIDTH * 2 - 4;

        // Place 1-4 buildings per block
        const buildingCount = Math.ceil(rng() * 3);
        for (let b = 0; b < buildingCount; b++) {
          const w = 10 + rng() * (buildableSize / buildingCount - 12);
          const d = 10 + rng() * (buildableSize - 12);
          const h = district.minBuildingHeight + rng() * (district.maxBuildingHeight - district.minBuildingHeight);

          const bxPos = buildableX + (b / buildingCount) * buildableSize + rng() * 4;
          const bzPos = buildableZ + rng() * (buildableSize - d);

          // Color variation
          const baseR = (district.color >> 16) & 0xFF;
          const baseG = (district.color >> 8) & 0xFF;
          const baseB = district.color & 0xFF;
          const variation = 0.8 + rng() * 0.4;
          const color = (Math.floor(baseR * variation) << 16) |
                       (Math.floor(baseG * variation) << 8) |
                       Math.floor(baseB * variation);

          buildings.push({ x: bxPos, z: bzPos, width: w, depth: d, height: h, color });
        }
      }
    }

    return { cx, cz, buildings, roads, sidewalks };
  }

  /** Get district type at world position */
  getDistrictAt(x: number, z: number): DistrictType {
    const gx = Math.floor(x / DISTRICT_SIZE);
    const gz = Math.floor(z / DISTRICT_SIZE);
    return this.districts[Math.min(gz, DISTRICTS_PER_SIDE - 1)]
                         ?.[Math.min(gx, DISTRICTS_PER_SIDE - 1)]?.type || 'residential';
  }

  private createRng(seed: number): () => number {
    let s = seed;
    return () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
  }
}
