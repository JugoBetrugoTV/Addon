/**
 * SpatialGrid.ts - Spatial hash grid for O(1) collision lookups.
 * Divides the world into cells; entities are inserted each frame.
 * Queries return only entities in nearby cells, avoiding O(n²) checks.
 */

import { GRID_CELL_SIZE, GRID_SIZE } from '../core/Constants';

export class SpatialGrid {
  private cells: Map<number, number[]> = new Map();

  /** Clear all cells. Called once per frame before re-inserting entities. */
  clear(): void {
    this.cells.clear();
  }

  /** Compute cell key from cell coordinates */
  private key(cx: number, cy: number): number {
    return cy * GRID_SIZE + cx;
  }

  /** Insert an entity at world position (x, y) */
  insert(eid: number, x: number, y: number): void {
    const cx = Math.floor(x / GRID_CELL_SIZE);
    const cy = Math.floor(y / GRID_CELL_SIZE);
    const k = this.key(cx, cy);
    const cell = this.cells.get(k);
    if (cell) {
      cell.push(eid);
    } else {
      this.cells.set(k, [eid]);
    }
  }

  /** Query all entities within radius of point (x, y) */
  query(x: number, y: number, radius: number): number[] {
    const result: number[] = [];
    const minCx = Math.max(0, Math.floor((x - radius) / GRID_CELL_SIZE));
    const maxCx = Math.min(GRID_SIZE - 1, Math.floor((x + radius) / GRID_CELL_SIZE));
    const minCy = Math.max(0, Math.floor((y - radius) / GRID_CELL_SIZE));
    const maxCy = Math.min(GRID_SIZE - 1, Math.floor((y + radius) / GRID_CELL_SIZE));

    for (let cy = minCy; cy <= maxCy; cy++) {
      for (let cx = minCx; cx <= maxCx; cx++) {
        const cell = this.cells.get(this.key(cx, cy));
        if (cell) {
          for (let i = 0; i < cell.length; i++) {
            result.push(cell[i]);
          }
        }
      }
    }
    return result;
  }
}
