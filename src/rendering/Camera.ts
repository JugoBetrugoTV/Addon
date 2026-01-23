/**
 * Camera.ts - Camera system with smooth follow, shake, and zoom.
 * Provides transform offset for the game container.
 * Shake intensity feeds into chromatic aberration for synced impact.
 */

import { CAMERA_LERP_SPEED, CAMERA_SHAKE_DECAY } from '../core/Constants';

export class Camera {
  x: number = 0;
  y: number = 0;
  private shakeIntensity: number = 0;
  private shakeOffsetX: number = 0;
  private shakeOffsetY: number = 0;
  private targetZoom: number = 1;
  private currentZoom: number = 1;

  /** Smoothly follow a target position */
  follow(targetX: number, targetY: number, dt: number): void {
    this.x += (targetX - this.x) * CAMERA_LERP_SPEED * dt;
    this.y += (targetY - this.y) * CAMERA_LERP_SPEED * dt;
  }

  /** Update shake decay and calculate offset */
  update(dt: number): void {
    if (this.shakeIntensity > 0.1) {
      this.shakeOffsetX = (Math.random() - 0.5) * this.shakeIntensity * 2;
      this.shakeOffsetY = (Math.random() - 0.5) * this.shakeIntensity * 2;
      this.shakeIntensity *= CAMERA_SHAKE_DECAY;
    } else {
      this.shakeIntensity = 0;
      this.shakeOffsetX = 0;
      this.shakeOffsetY = 0;
    }

    // Smooth zoom
    this.currentZoom += (this.targetZoom - this.currentZoom) * 3 * dt;
  }

  /** Trigger screen shake with given intensity */
  shake(intensity: number): void {
    this.shakeIntensity = Math.max(this.shakeIntensity, intensity);
  }

  /** Set target zoom level (1.0 = normal) */
  setZoom(zoom: number): void {
    this.targetZoom = Math.max(0.5, Math.min(2.0, zoom));
  }

  /** Get the final screen offset including shake */
  getOffset(screenW: number, screenH: number): { x: number; y: number; zoom: number } {
    return {
      x: screenW / 2 - this.x + this.shakeOffsetX,
      y: screenH / 2 - this.y + this.shakeOffsetY,
      zoom: this.currentZoom,
    };
  }

  /** Current shake intensity (0-1 normalized, for shader feedback) */
  get shakeAmount(): number {
    return Math.min(1, this.shakeIntensity / 10);
  }
}
