/**
 * Game.ts - Main entry point.
 * Creates all systems, runs the game loop, orchestrates updates.
 */

import { World } from './ECS';
import { Input } from './Input';
import { SceneManager } from '../rendering/SceneManager';
import { ThirdPersonCamera } from '../rendering/ThirdPersonCamera';
import { CityMeshBuilder } from '../rendering/CityMeshBuilder';
import { CityLayout } from '../world/CityLayout';
import { Streamer } from '../world/Streamer';
import { createPlayer } from '../entities/Player';
import { NPCFactory } from '../entities/NPCFactory';
import { PlayerController } from '../systems/PlayerController';
import { NPCBehaviorSystem } from '../systems/NPCBehavior';
import { Transform, MeshRef } from '../entities/Components';
import { HUD } from '../ui/HUD';
import { EntityId } from './ECS';

class Game {
  private world: World;
  private sceneManager: SceneManager;
  private cameraController: ThirdPersonCamera;
  private input: Input;
  private streamer: Streamer;
  private playerController: PlayerController;
  private npcFactory: NPCFactory;
  private npcBehavior: NPCBehaviorSystem;
  private hud: HUD;
  private cityLayout: CityLayout;

  private playerEid: EntityId;
  private lastTime: number = 0;
  private running: boolean = true;

  constructor() {
    const container = document.getElementById('game')!;

    // Remove loading screen
    const loading = document.getElementById('loading');
    if (loading) loading.remove();

    // Core
    this.world = new World();
    this.sceneManager = new SceneManager(container);
    this.cameraController = new ThirdPersonCamera();
    this.input = new Input(this.sceneManager.canvas);

    // City
    this.cityLayout = new CityLayout(12345);
    const meshBuilder = new CityMeshBuilder();
    this.streamer = new Streamer(this.cityLayout, meshBuilder, this.sceneManager.scene);

    // Player
    this.playerEid = createPlayer(this.world, this.sceneManager.scene);
    this.playerController = new PlayerController(
      this.world, this.input, this.cameraController, this.playerEid
    );

    // NPCs
    this.npcFactory = new NPCFactory(this.world, this.sceneManager.scene);
    this.npcBehavior = new NPCBehaviorSystem(this.world, this.npcFactory);

    // UI
    this.hud = new HUD();
    this.hud.showMessage('Click to lock mouse. WASD to move.', 5);

    // Start loop
    this.lastTime = performance.now();
    this.loop();
  }

  private loop = (): void => {
    if (!this.running) return;
    requestAnimationFrame(this.loop);

    const now = performance.now();
    const rawDt = (now - this.lastTime) / 1000;
    const dt = Math.min(rawDt, 0.05);
    this.lastTime = now;

    // Update player
    this.playerController.update(dt);
    const pos = this.playerController.position;

    // Update player mesh
    const transform = this.world.get(Transform, this.playerEid);
    const meshData = this.world.get(MeshRef, this.playerEid);
    if (transform && meshData) {
      meshData.object.position.copy(transform.position);
      meshData.object.rotation.copy(transform.rotation);
    }

    // Stream city chunks
    this.streamer.update(pos.x, pos.z);

    // NPC behavior
    this.npcBehavior.update(dt, pos.x, pos.z);

    // Sun follows player
    this.sceneManager.updateSun(pos.x, pos.z);

    // Render
    this.sceneManager.render(this.cameraController.camera);

    // HUD
    this.hud.update({
      fps: 1 / Math.max(0.001, rawDt),
      playerX: pos.x,
      playerZ: pos.z,
      district: this.cityLayout.getDistrictAt(pos.x, pos.z),
      npcs: this.npcFactory.count,
      chunks: this.streamer.loadedCount,
    }, dt);
  };
}

// === BOOTSTRAP ===
window.addEventListener('DOMContentLoaded', () => {
  new Game();
});
