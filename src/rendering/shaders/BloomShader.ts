/**
 * BloomShader.ts - Multi-pass bloom post-processing filter.
 * Extracts bright pixels, blurs them, then composites on top.
 * Creates the "glowing weapons/projectiles" effect.
 */

import * as PIXI from 'pixi.js';

const BLOOM_FRAGMENT = `
  precision mediump float;
  varying vec2 vTextureCoord;
  uniform sampler2D uSampler;
  uniform float uIntensity;
  uniform float uThreshold;
  uniform vec2 uResolution;

  // 9-tap gaussian blur
  vec4 blur(sampler2D tex, vec2 uv, vec2 dir) {
    vec4 color = vec4(0.0);
    vec2 off1 = vec2(1.3846153846) * dir;
    vec2 off2 = vec2(3.2307692308) * dir;
    color += texture2D(tex, uv) * 0.2270270270;
    color += texture2D(tex, uv + off1) * 0.3162162162;
    color += texture2D(tex, uv - off1) * 0.3162162162;
    color += texture2D(tex, uv + off2) * 0.0702702703;
    color += texture2D(tex, uv - off2) * 0.0702702703;
    return color;
  }

  void main() {
    vec2 pixelSize = 1.0 / uResolution;
    vec4 color = texture2D(uSampler, vTextureCoord);

    // Extract bright areas
    float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec4 bright = color * smoothstep(uThreshold, uThreshold + 0.2, brightness);

    // Two-pass blur approximation (combined for single-pass)
    vec4 blurH = blur(uSampler, vTextureCoord, vec2(pixelSize.x * 2.0, 0.0));
    vec4 blurV = blur(uSampler, vTextureCoord, vec2(0.0, pixelSize.y * 2.0));
    vec4 blurred = (blurH + blurV) * 0.5;

    // Extract bloom from blurred
    float blurBright = dot(blurred.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec4 bloom = blurred * smoothstep(uThreshold * 0.7, uThreshold + 0.1, blurBright);

    // Composite: original + bloom glow
    gl_FragColor = color + bloom * uIntensity;
  }
`;

export class BloomFilter extends PIXI.Filter {
  constructor(intensity: number = 0.35, threshold: number = 0.5) {
    super(undefined, BLOOM_FRAGMENT, {
      uIntensity: intensity,
      uThreshold: threshold,
      uResolution: [window.innerWidth, window.innerHeight],
    });
    this.padding = 0;
  }

  /** Update resolution when window resizes */
  updateResolution(width: number, height: number): void {
    this.uniforms.uResolution = [width, height];
  }

  set intensity(val: number) {
    this.uniforms.uIntensity = val;
  }

  set threshold(val: number) {
    this.uniforms.uThreshold = val;
  }
}
