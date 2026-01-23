/**
 * ChromaticShader.ts - RGB channel separation effect.
 * Intensity increases during screen shake for impact feel.
 * Creates that "power surge" visual on big hits.
 */

import * as PIXI from 'pixi.js';

const CHROMATIC_FRAGMENT = `
  precision mediump float;
  varying vec2 vTextureCoord;
  uniform sampler2D uSampler;
  uniform float uIntensity;
  uniform vec2 uDirection;

  void main() {
    vec2 offset = uDirection * uIntensity;

    float r = texture2D(uSampler, vTextureCoord + offset).r;
    float g = texture2D(uSampler, vTextureCoord).g;
    float b = texture2D(uSampler, vTextureCoord - offset).b;
    float a = texture2D(uSampler, vTextureCoord).a;

    gl_FragColor = vec4(r, g, b, a);
  }
`;

export class ChromaticFilter extends PIXI.Filter {
  private baseIntensity: number;
  private currentBoost: number = 0;

  constructor(intensity: number = 0.002) {
    super(undefined, CHROMATIC_FRAGMENT, {
      uIntensity: intensity,
      uDirection: [1.0, 0.5],  // Direction of RGB split
    });
    this.baseIntensity = intensity;
    this.padding = 0;
  }

  /** Update each frame - decays boost back to base */
  update(_dt: number): void {
    if (this.currentBoost > 0) {
      this.currentBoost *= 0.9;
      if (this.currentBoost < 0.0001) this.currentBoost = 0;
    }
    this.uniforms.uIntensity = this.baseIntensity + this.currentBoost;
  }

  /** Boost chromatic effect (for screen shake moments) */
  boost(amount: number): void {
    this.currentBoost = Math.min(0.015, amount);
  }

  set intensity(val: number) {
    this.baseIntensity = val;
  }
}
