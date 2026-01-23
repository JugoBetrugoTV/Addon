/**
 * Input.ts - Centralized input handling.
 * Tracks currently pressed keys and provides movement vector.
 */

export class Input {
  private keys: Set<string> = new Set();
  private _enabled: boolean = true;

  constructor() {
    window.addEventListener('keydown', (e) => {
      if (this._enabled) {
        this.keys.add(e.key.toLowerCase());
      }
    });
    window.addEventListener('keyup', (e) => {
      this.keys.delete(e.key.toLowerCase());
    });
    // Prevent keys sticking when window loses focus
    window.addEventListener('blur', () => this.keys.clear());
  }

  /** Returns normalized movement direction vector [x, y] */
  getMovement(): [number, number] {
    let mx = 0, my = 0;
    if (this.keys.has('w') || this.keys.has('arrowup')) my -= 1;
    if (this.keys.has('s') || this.keys.has('arrowdown')) my += 1;
    if (this.keys.has('a') || this.keys.has('arrowleft')) mx -= 1;
    if (this.keys.has('d') || this.keys.has('arrowright')) mx += 1;

    const len = Math.sqrt(mx * mx + my * my);
    if (len > 0) {
      mx /= len;
      my /= len;
    }
    return [mx, my];
  }

  /** Check if a specific key is pressed */
  isDown(key: string): boolean {
    return this.keys.has(key.toLowerCase());
  }

  /** Check if any key is pressed (for title screen, etc.) */
  anyKeyPressed(): boolean {
    return this.keys.size > 0;
  }

  /** Enable/disable input processing */
  set enabled(val: boolean) {
    this._enabled = val;
    if (!val) this.keys.clear();
  }

  get enabled(): boolean {
    return this._enabled;
  }

  /** Clear all pressed keys */
  clear(): void {
    this.keys.clear();
  }
}
