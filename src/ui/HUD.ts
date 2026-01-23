/**
 * HUD.ts - Persistent heads-up display elements.
 * Shows HP bar, XP bar, timer, level, kills, and weapon icons.
 * All text/graphics objects are created once and updated each frame.
 */

import * as PIXI from 'pixi.js';

export class HUD {
  private container: PIXI.Container;
  private hpBar: PIXI.Graphics;
  private hpText: PIXI.Text;
  private xpBar: PIXI.Graphics;
  private levelText: PIXI.Text;
  private timerText: PIXI.Text;
  private killsText: PIXI.Text;

  private screenW: number;
  private screenH: number;

  constructor(parent: PIXI.Container, screenW: number, screenH: number) {
    this.container = new PIXI.Container();
    this.container.zIndex = 100;
    parent.addChild(this.container);
    this.screenW = screenW;
    this.screenH = screenH;

    // HP Bar
    this.hpBar = new PIXI.Graphics();
    this.container.addChild(this.hpBar);

    this.hpText = new PIXI.Text('100/100', {
      fontFamily: 'Arial', fontSize: 13, fill: '#ffffff',
      stroke: '#000000', strokeThickness: 2,
    });
    this.hpText.anchor.set(0.5, 0.5);
    this.container.addChild(this.hpText);

    // XP Bar
    this.xpBar = new PIXI.Graphics();
    this.container.addChild(this.xpBar);

    // Level
    this.levelText = new PIXI.Text('Lv.1', {
      fontFamily: 'Arial', fontSize: 14, fontWeight: 'bold', fill: '#fbbf24',
      stroke: '#000000', strokeThickness: 2,
    });
    this.levelText.anchor.set(0, 0.5);
    this.container.addChild(this.levelText);

    // Timer
    this.timerText = new PIXI.Text('0:00', {
      fontFamily: 'Arial', fontSize: 18, fontWeight: 'bold', fill: '#e2e8f0',
      stroke: '#000000', strokeThickness: 3,
    });
    this.timerText.anchor.set(0.5, 0);
    this.container.addChild(this.timerText);

    // Kills
    this.killsText = new PIXI.Text('Kills: 0', {
      fontFamily: 'Arial', fontSize: 13, fill: '#a1a1aa',
      stroke: '#000000', strokeThickness: 2,
    });
    this.killsText.anchor.set(1, 0);
    this.container.addChild(this.killsText);
  }

  /** Update all HUD elements with current game state */
  update(hp: number, maxHp: number, xp: number, xpNeeded: number, level: number, time: string, kills: number): void {
    const barW = 200;
    const barH = 16;
    const barX = 10;
    const barY = 10;

    // HP Bar
    this.hpBar.clear();
    this.hpBar.beginFill(0x1f1f1f);
    this.hpBar.drawRoundedRect(barX, barY, barW, barH, 4);
    this.hpBar.endFill();
    const hpRatio = Math.max(0, hp / maxHp);
    const hpColor = hpRatio > 0.5 ? 0x22c55e : hpRatio > 0.25 ? 0xfbbf24 : 0xef4444;
    this.hpBar.beginFill(hpColor);
    this.hpBar.drawRoundedRect(barX, barY, barW * hpRatio, barH, 4);
    this.hpBar.endFill();

    this.hpText.text = `${Math.ceil(hp)}/${Math.ceil(maxHp)}`;
    this.hpText.position.set(barX + barW / 2, barY + barH / 2);

    // XP Bar
    const xpY = barY + barH + 4;
    const xpH = 8;
    this.xpBar.clear();
    this.xpBar.beginFill(0x1f1f1f);
    this.xpBar.drawRoundedRect(barX, xpY, barW, xpH, 3);
    this.xpBar.endFill();
    const xpRatio = Math.min(1, xp / Math.max(1, xpNeeded));
    this.xpBar.beginFill(0x8b5cf6);
    this.xpBar.drawRoundedRect(barX, xpY, barW * xpRatio, xpH, 3);
    this.xpBar.endFill();

    // Level
    this.levelText.text = `Lv.${level}`;
    this.levelText.position.set(barX + barW + 8, barY + barH / 2);

    // Timer
    this.timerText.text = time;
    this.timerText.position.set(this.screenW / 2, 10);

    // Kills
    this.killsText.text = `Kills: ${kills}`;
    this.killsText.position.set(this.screenW - 10, 10);
  }

  /** Handle screen resize */
  resize(screenW: number, screenH: number): void {
    this.screenW = screenW;
    this.screenH = screenH;
  }
}
