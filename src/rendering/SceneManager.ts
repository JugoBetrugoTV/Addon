/**
 * SceneManager.ts - Three.js scene setup.
 * Creates renderer, scene, lights, fog.
 * Does NOT handle camera (that's ThirdPersonCamera).
 */

import * as THREE from 'three';
import {
  AMBIENT_LIGHT, SUN_INTENSITY, FOG_NEAR, FOG_FAR,
  MAX_DRAW_DISTANCE, SHADOW_MAP_SIZE,
} from '../core/Constants';

export class SceneManager {
  renderer: THREE.WebGLRenderer;
  scene: THREE.Scene;
  sunLight: THREE.DirectionalLight;
  ambientLight: THREE.AmbientLight;

  constructor(container: HTMLElement) {
    // Renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.1;
    container.appendChild(this.renderer.domElement);

    // Scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x87ceeb); // Sky blue
    this.scene.fog = new THREE.Fog(0x9db8c8, FOG_NEAR, FOG_FAR);

    // Ambient light
    this.ambientLight = new THREE.AmbientLight(0xffffff, AMBIENT_LIGHT);
    this.scene.add(this.ambientLight);

    // Sun (directional)
    this.sunLight = new THREE.DirectionalLight(0xfff4e0, SUN_INTENSITY);
    this.sunLight.position.set(100, 200, 80);
    this.sunLight.castShadow = true;
    this.sunLight.shadow.mapSize.set(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
    this.sunLight.shadow.camera.left = -100;
    this.sunLight.shadow.camera.right = 100;
    this.sunLight.shadow.camera.top = 100;
    this.sunLight.shadow.camera.bottom = -100;
    this.sunLight.shadow.camera.near = 1;
    this.sunLight.shadow.camera.far = 400;
    this.sunLight.shadow.bias = -0.001;
    this.scene.add(this.sunLight);
    this.scene.add(this.sunLight.target);

    // Hemisphere light for ambient fill
    const hemiLight = new THREE.HemisphereLight(0x87ceeb, 0x3a5a3a, 0.3);
    this.scene.add(hemiLight);

    // Handle resize
    window.addEventListener('resize', () => this.onResize());
  }

  /** Update sun position to follow player (for shadow coverage) */
  updateSun(playerX: number, playerZ: number): void {
    this.sunLight.position.set(playerX + 100, 200, playerZ + 80);
    this.sunLight.target.position.set(playerX, 0, playerZ);
    this.sunLight.target.updateMatrixWorld();
  }

  /** Render a frame */
  render(camera: THREE.Camera): void {
    this.renderer.render(this.scene, camera);
  }

  get canvas(): HTMLCanvasElement {
    return this.renderer.domElement;
  }

  private onResize(): void {
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  destroy(): void {
    this.renderer.dispose();
  }
}
