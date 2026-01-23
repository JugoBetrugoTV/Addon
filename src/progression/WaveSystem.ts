/**
 * WaveSystem.ts - Controls enemy wave spawning over time.
 * Activates waves from WAVES config as game time progresses.
 * Manages spawn intervals and counts for each active wave.
 */

import { WAVES, WaveConfig } from './EnemyData';
import { EnemyFactory } from '../entities/EnemyFactory';

interface ActiveWave {
  config: WaveConfig;
  spawned: number;
  spawnTimer: number;
}

export class WaveSystem {
  private enemyFactory: EnemyFactory;
  private activeWaves: ActiveWave[] = [];
  private nextWaveIndex: number = 0;
  private gameTime: number = 0;
  kills: number = 0;

  constructor(enemyFactory: EnemyFactory) {
    this.enemyFactory = enemyFactory;
  }

  /** Update wave spawning. Call each frame. */
  update(dt: number, playerX: number, playerY: number): void {
    this.gameTime += dt;

    // Activate new waves
    while (this.nextWaveIndex < WAVES.length && WAVES[this.nextWaveIndex].time <= this.gameTime) {
      this.activeWaves.push({
        config: WAVES[this.nextWaveIndex],
        spawned: 0,
        spawnTimer: 0,
      });
      this.nextWaveIndex++;
    }

    // Process active waves
    for (let i = this.activeWaves.length - 1; i >= 0; i--) {
      const wave = this.activeWaves[i];
      wave.spawnTimer -= dt;

      if (wave.spawnTimer <= 0 && wave.spawned < wave.config.count) {
        this.enemyFactory.spawn(
          wave.config.enemyType,
          playerX, playerY,
          wave.config.healthMult,
          wave.config.speedMult
        );
        wave.spawned++;
        wave.spawnTimer = wave.config.interval;
      }

      // Remove completed waves
      if (wave.spawned >= wave.config.count) {
        this.activeWaves.splice(i, 1);
      }
    }
  }

  /** Get elapsed game time in seconds */
  get elapsed(): number {
    return this.gameTime;
  }

  /** Format time as MM:SS */
  get timeString(): string {
    const mins = Math.floor(this.gameTime / 60);
    const secs = Math.floor(this.gameTime % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  /** Reset for new game */
  reset(): void {
    this.activeWaves = [];
    this.nextWaveIndex = 0;
    this.gameTime = 0;
    this.kills = 0;
  }
}
