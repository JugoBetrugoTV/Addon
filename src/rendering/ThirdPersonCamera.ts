/**
 * ThirdPersonCamera.ts - Third-person camera controller.
 * Orbits behind the player, rotated by mouse.
 * Smooth follow with collision avoidance (TODO: raycasting).
 */

import * as THREE from 'three';
import { CAMERA_DISTANCE, CAMERA_HEIGHT, CAMERA_LERP, CAMERA_MOUSE_SENSITIVITY } from '../core/Constants';

export class ThirdPersonCamera {
  camera: THREE.PerspectiveCamera;
  private yaw: number = 0;         // Horizontal rotation (radians)
  private pitch: number = -0.3;    // Vertical rotation (radians)
  private distance: number = CAMERA_DISTANCE;
  private targetPos: THREE.Vector3 = new THREE.Vector3();
  private currentPos: THREE.Vector3 = new THREE.Vector3();

  constructor() {
    this.camera = new THREE.PerspectiveCamera(65, window.innerWidth / window.innerHeight, 0.5, 600);
    this.camera.position.set(0, CAMERA_HEIGHT, CAMERA_DISTANCE);

    window.addEventListener('resize', () => {
      this.camera.aspect = window.innerWidth / window.innerHeight;
      this.camera.updateProjectionMatrix();
    });
  }

  /** Apply mouse movement to rotate camera */
  rotate(dx: number, dy: number): void {
    this.yaw -= dx * CAMERA_MOUSE_SENSITIVITY;
    this.pitch -= dy * CAMERA_MOUSE_SENSITIVITY;
    // Clamp pitch
    this.pitch = Math.max(-1.2, Math.min(0.5, this.pitch));
  }

  /** Update camera position to follow target */
  update(targetX: number, targetY: number, targetZ: number, dt: number): void {
    // Calculate ideal camera position behind player
    const offsetX = Math.sin(this.yaw) * Math.cos(this.pitch) * this.distance;
    const offsetZ = Math.cos(this.yaw) * Math.cos(this.pitch) * this.distance;
    const offsetY = Math.sin(-this.pitch) * this.distance + CAMERA_HEIGHT;

    this.targetPos.set(
      targetX + offsetX,
      targetY + Math.max(1.5, offsetY),
      targetZ + offsetZ
    );

    // Smooth follow
    const lerp = 1 - Math.exp(-CAMERA_LERP * dt);
    this.currentPos.lerp(this.targetPos, lerp);

    this.camera.position.copy(this.currentPos);
    this.camera.lookAt(targetX, targetY + 1.2, targetZ);
  }

  /** Get the forward direction the camera is facing (for player movement) */
  getForward(): { x: number; z: number } {
    return {
      x: -Math.sin(this.yaw),
      z: -Math.cos(this.yaw),
    };
  }

  /** Get the right direction */
  getRight(): { x: number; z: number } {
    return {
      x: Math.cos(this.yaw),
      z: -Math.sin(this.yaw),
    };
  }

  get heading(): number { return this.yaw; }
}
