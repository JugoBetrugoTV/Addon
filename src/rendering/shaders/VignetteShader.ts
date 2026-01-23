/**
 * VignetteShader.ts - Screen-edge darkening effect.
 * Intensifies when player takes damage for visceral feedback.
 * Also adds subtle noise grain for film-like quality.
 */

import * as PIXI from 'pixi.js';

const VIGNETTE_FRAGMENT = `
  precision mediump float;
  varying vec2 vTextureCoord;
  uniform sampler2D uSampler;
  uniform float uIntensity;
  uniform float uDamageFlash;
  uniform float uTime;

  // Pseudo-random noise for film grain
  float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
  }

  void main() {
    vec4 color = texture2D(uSampler, vTextureCoord);

    // Vignette: darken edges
    vec2 center = vTextureCoord - 0.5;
    float dist = length(center);
    float vignette = 1.0 - smoothstep(0.3, 0.85, dist) * uIntensity;
    color.rgb *= vignette;

    // Damage flash: red tint on edges when hit
    if (uDamageFlash > 0.0) {
      float edgeFade = smoothstep(0.2, 0.7, dist);
      color.rgb = mix(color.rgb, vec3(0.8, 0.1, 0.1), edgeFade * uDamageFlash * 0.6);
    }

    // Subtle film grain (barely visible, adds texture)
    float grain = rand(vTextureCoord + vec2(uTime * 0.1, 0.0)) * 0.03;
    color.rgb += grain - 0.015;

    gl_FragColor = color;
  }
`;

export class VignetteFilter extends PIXI.Filter {
  constructor(intensity: number = 0.4) {
    super(undefined, VIGNETTE_FRAGMENT, {
      uIntensity: intensity,
      uDamageFlash: 0.0,
      uTime: 0.0,
    });
    this.padding = 0;
  }

  /** Call each frame with elapsed time */
  update(time: number): void {
    this.uniforms.uTime = time;
    // Decay damage flash
    if (this.uniforms.uDamageFlash > 0) {
      this.uniforms.uDamageFlash *= 0.92;
      if (this.uniforms.uDamageFlash < 0.01) {
        this.uniforms.uDamageFlash = 0;
      }
    }
  }

  /** Trigger damage flash (0-1 intensity) */
  flash(intensity: number = 0.8): void {
    this.uniforms.uDamageFlash = Math.min(1, intensity);
  }

  set intensity(val: number) {
    this.uniforms.uIntensity = val;
  }
}
