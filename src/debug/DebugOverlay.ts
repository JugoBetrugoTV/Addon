/**
 * DebugOverlay.ts - Performance metrics and debug info.
 * Shows FPS, entity counts, memory usage.
 * Toggle with F3 key.
 */

import * as PIXI from 'pixi.js';

export class DebugOverlay {
  private container: PIXI.Container;
  private text: PIXI.Text;
  private fpsHistory: number[] = [];
  private visible: boolean = false;

  constructor(parent: PIXI.Container) {
    this.container = new PIXI.Container();
    this.container.zIndex = 999;
    this.container.visible = false;
    parent.addChild(this.container);

    const bg = new PIXI.Graphics();
    bg.beginFill(0x000000, 0.7);
    bg.drawRoundedRect(0, 0, 220, 130, 6);
    bg.endFill();
    bg.position.set(8, 50);
    this.container.addChild(bg);

    this.text = new PIXI.Text('', {
      fontFamily: 'Courier New', fontSize: 11, fill: '#4ade80',
      lineHeight: 15,
    });
    this.text.position.set(14, 56);
    this.container.addChild(this.text);
  }

  /** Toggle visibility */
  toggle(): void {
    this.visible = !this.visible;
    this.container.visible = this.visible;
  }

  /** Update debug display */
  update(dt: number, stats: {
    enemies: number;
    projectiles: number;
    particles: number;
    fps: number;
  }): void {
    if (!this.visible) return;

    this.fpsHistory.push(stats.fps);
    if (this.fpsHistory.length > 60) this.fpsHistory.shift();
    const avgFps = this.fpsHistory.reduce((a, b) => a + b, 0) / this.fpsHistory.length;

    const memMB = (performance as unknown as { memory?: { usedJSHeapSize: number } }).memory
      ? ((performance as unknown as { memory: { usedJSHeapSize: number } }).memory.usedJSHeapSize / 1048576).toFixed(1)
      : 'N/A';

    this.text.text = [
      `FPS: ${Math.round(avgFps)} (${Math.round(stats.fps)})`,
      `Enemies:     ${stats.enemies}`,
      `Projectiles: ${stats.projectiles}`,
      `Particles:   ${stats.particles}`,
      `Memory: ${memMB} MB`,
      `dt: ${(dt * 1000).toFixed(1)}ms`,
      ``,
      `[F3] Toggle debug`,
    ].join('\n');
  }
}
