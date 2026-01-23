/**
 * HUD.ts - HTML-based heads-up display.
 * Shows: minimap placeholder, position, FPS, NPC count, district.
 * Uses DOM elements for zero-impact on Three.js rendering.
 */

export class HUD {
  private container: HTMLElement;
  private infoEl: HTMLElement;
  private crosshair: HTMLElement;
  private messageEl: HTMLElement;
  private messageTimer: number = 0;

  constructor() {
    this.container = document.getElementById('hud')!;

    // Info panel (top-left)
    this.infoEl = document.createElement('div');
    this.infoEl.style.cssText = `
      position: absolute; top: 10px; left: 10px;
      color: #e2e8f0; font-size: 12px; font-family: 'Courier New', monospace;
      background: rgba(0,0,0,0.5); padding: 8px 12px; border-radius: 4px;
      line-height: 1.6; pointer-events: none;
    `;
    this.container.appendChild(this.infoEl);

    // Crosshair (center)
    this.crosshair = document.createElement('div');
    this.crosshair.style.cssText = `
      position: absolute; top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      width: 6px; height: 6px;
      border: 1px solid rgba(255,255,255,0.4);
      border-radius: 50%;
      pointer-events: none;
    `;
    this.container.appendChild(this.crosshair);

    // Message area (bottom-center)
    this.messageEl = document.createElement('div');
    this.messageEl.style.cssText = `
      position: absolute; bottom: 40px; left: 50%;
      transform: translateX(-50%);
      color: #fbbf24; font-size: 14px; font-family: 'Segoe UI', sans-serif;
      background: rgba(0,0,0,0.6); padding: 6px 16px; border-radius: 4px;
      pointer-events: none; opacity: 0; transition: opacity 0.3s;
    `;
    this.container.appendChild(this.messageEl);
  }

  /** Update HUD with current game state */
  update(data: {
    fps: number;
    playerX: number;
    playerZ: number;
    district: string;
    npcs: number;
    chunks: number;
  }, dt: number): void {
    this.infoEl.innerHTML = [
      `FPS: ${Math.round(data.fps)}`,
      `Pos: ${Math.round(data.playerX)}, ${Math.round(data.playerZ)}`,
      `District: ${data.district}`,
      `NPCs: ${data.npcs}`,
      `Chunks: ${data.chunks}`,
      ``,
      `<span style="color:#a0aec0">WASD move | Mouse look</span>`,
      `<span style="color:#a0aec0">Shift run | Click to lock</span>`,
    ].join('<br>');

    // Message fade
    if (this.messageTimer > 0) {
      this.messageTimer -= dt;
      if (this.messageTimer <= 0) {
        this.messageEl.style.opacity = '0';
      }
    }
  }

  /** Show a temporary message */
  showMessage(text: string, duration: number = 3): void {
    this.messageEl.textContent = text;
    this.messageEl.style.opacity = '1';
    this.messageTimer = duration;
  }
}
