/**
 * PlayerController.ts - Processes input to move the player.
 * Uses camera heading to orient movement direction.
 * Handles walking, running, and basic collision with world bounds.
 */

import { World, EntityId } from '../core/ECS';
import { Transform, PlayerComp } from '../entities/Components';
import { Input } from '../core/Input';
import { ThirdPersonCamera } from '../rendering/ThirdPersonCamera';
import { PLAYER_WALK_SPEED, PLAYER_RUN_SPEED, WORLD_SIZE, GRAVITY, GROUND_Y } from '../core/Constants';

export class PlayerController {
  private world: World;
  private input: Input;
  private camera: ThirdPersonCamera;
  private playerEid: EntityId;

  constructor(world: World, input: Input, camera: ThirdPersonCamera, playerEid: EntityId) {
    this.world = world;
    this.input = input;
    this.camera = camera;
    this.playerEid = playerEid;
  }

  update(dt: number): void {
    const transform = this.world.get(Transform, this.playerEid);
    const player = this.world.get(PlayerComp, this.playerEid);
    if (!transform || !player) return;

    // Camera rotation from mouse
    if (this.input.isLocked) {
      const { dx, dy } = this.input.consumeMouseDelta();
      this.camera.rotate(dx, dy);
    }

    // Movement relative to camera facing
    const move = this.input.getMovement();
    const speed = this.input.isRunning ? PLAYER_RUN_SPEED : PLAYER_WALK_SPEED;

    if (move.x !== 0 || move.z !== 0) {
      const forward = this.camera.getForward();
      const right = this.camera.getRight();

      const moveX = (forward.x * move.z + right.x * move.x) * speed;
      const moveZ = (forward.z * move.z + right.z * move.x) * speed;

      transform.velocity.x = moveX;
      transform.velocity.z = moveZ;

      // Face movement direction
      transform.rotation.y = Math.atan2(-moveX, -moveZ);
    } else {
      // Decelerate
      transform.velocity.x *= 0.85;
      transform.velocity.z *= 0.85;
    }

    // Gravity
    if (!transform.grounded) {
      transform.velocity.y += GRAVITY * dt;
    }

    // Apply velocity
    transform.position.x += transform.velocity.x * dt;
    transform.position.z += transform.velocity.z * dt;
    transform.position.y += transform.velocity.y * dt;

    // Ground collision
    if (transform.position.y <= GROUND_Y) {
      transform.position.y = GROUND_Y;
      transform.velocity.y = 0;
      transform.grounded = true;
    }

    // World bounds
    transform.position.x = Math.max(1, Math.min(WORLD_SIZE - 1, transform.position.x));
    transform.position.z = Math.max(1, Math.min(WORLD_SIZE - 1, transform.position.z));

    // Update camera
    this.camera.update(
      transform.position.x, transform.position.y,
      transform.position.z, dt
    );
  }

  get position(): { x: number; y: number; z: number } {
    const t = this.world.get(Transform, this.playerEid);
    return t ? { x: t.position.x, y: t.position.y, z: t.position.z } : { x: 0, y: 0, z: 0 };
  }
}
