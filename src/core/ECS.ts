/**
 * ECS.ts - Lightweight Entity-Component-System.
 * Entities are numeric IDs. Components are stored in typed Maps.
 * Systems query entities by required components.
 */

export type EntityId = number;

export interface ComponentStore<T> {
  name: string;
  data: Map<EntityId, T>;
}

export function defineComponent<T>(name: string): ComponentStore<T> {
  return { name, data: new Map() };
}

export class World {
  private nextId: number = 1;
  private alive: Set<EntityId> = new Set();

  createEntity(): EntityId {
    const id = this.nextId++;
    this.alive.add(id);
    return id;
  }

  removeEntity(id: EntityId, ...stores: ComponentStore<unknown>[]): void {
    this.alive.delete(id);
    for (const store of stores) {
      store.data.delete(id);
    }
  }

  isAlive(id: EntityId): boolean {
    return this.alive.has(id);
  }

  get entityCount(): number {
    return this.alive.size;
  }

  /** Add a component to an entity */
  add<T>(store: ComponentStore<T>, id: EntityId, data: T): void {
    store.data.set(id, data);
  }

  /** Get a component (or undefined) */
  get<T>(store: ComponentStore<T>, id: EntityId): T | undefined {
    return store.data.get(id);
  }

  /** Check if entity has a component */
  has<T>(store: ComponentStore<T>, id: EntityId): boolean {
    return store.data.has(id);
  }

  /** Query all entities that have ALL specified components */
  query(...stores: ComponentStore<unknown>[]): EntityId[] {
    if (stores.length === 0) return [];
    // Start with smallest store for efficiency
    const sorted = [...stores].sort((a, b) => a.data.size - b.data.size);
    const result: EntityId[] = [];
    for (const id of sorted[0].data.keys()) {
      if (!this.alive.has(id)) continue;
      let hasAll = true;
      for (let i = 1; i < sorted.length; i++) {
        if (!sorted[i].data.has(id)) { hasAll = false; break; }
      }
      if (hasAll) result.push(id);
    }
    return result;
  }
}
