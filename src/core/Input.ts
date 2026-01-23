/**
 * Input.ts - Keyboard + mouse input for 3D game.
 * Tracks keys, mouse movement (pointer lock), and mouse buttons.
 */

export class Input {
  private keys: Set<string> = new Set();
  private mouseX: number = 0;
  private mouseY: number = 0;
  private mouseDX: number = 0;
  private mouseDY: number = 0;
  private mouseButtons: Set<number> = new Set();
  private _locked: boolean = false;

  constructor(canvas: HTMLCanvasElement) {
    window.addEventListener('keydown', (e) => {
      this.keys.add(e.code);
      e.preventDefault();
    });
    window.addEventListener('keyup', (e) => {
      this.keys.delete(e.code);
    });
    window.addEventListener('blur', () => {
      this.keys.clear();
      this.mouseButtons.clear();
    });

    canvas.addEventListener('mousedown', (e) => {
      this.mouseButtons.add(e.button);
      if (!this._locked) {
        canvas.requestPointerLock();
      }
    });
    canvas.addEventListener('mouseup', (e) => {
      this.mouseButtons.delete(e.button);
    });

    document.addEventListener('mousemove', (e) => {
      if (this._locked) {
        this.mouseDX += e.movementX;
        this.mouseDY += e.movementY;
      }
      this.mouseX = e.clientX;
      this.mouseY = e.clientY;
    });

    document.addEventListener('pointerlockchange', () => {
      this._locked = document.pointerLockElement === canvas;
    });
  }

  /** Get and reset mouse delta (for camera rotation) */
  consumeMouseDelta(): { dx: number; dy: number } {
    const dx = this.mouseDX;
    const dy = this.mouseDY;
    this.mouseDX = 0;
    this.mouseDY = 0;
    return { dx, dy };
  }

  /** Get WASD movement vector (normalized) */
  getMovement(): { x: number; z: number } {
    let x = 0, z = 0;
    if (this.keys.has('KeyW')) z -= 1;
    if (this.keys.has('KeyS')) z += 1;
    if (this.keys.has('KeyA')) x -= 1;
    if (this.keys.has('KeyD')) x += 1;
    const len = Math.sqrt(x * x + z * z);
    if (len > 0) { x /= len; z /= len; }
    return { x, z };
  }

  isDown(code: string): boolean { return this.keys.has(code); }
  get isRunning(): boolean { return this.keys.has('ShiftLeft') || this.keys.has('ShiftRight'); }
  get isMouseDown(): boolean { return this.mouseButtons.has(0); }
  get isRightMouseDown(): boolean { return this.mouseButtons.has(2); }
  get isLocked(): boolean { return this._locked; }
}
