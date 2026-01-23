/**
 * LevelUpUI.ts - Level-up upgrade selection cards.
 * Shows 3 choices as styled cards. Player picks one.
 * Pauses game while active.
 */

import * as PIXI from 'pixi.js';
import { UpgradeChoice } from '../progression/LevelUpSystem';

export class LevelUpUI {
  private container: PIXI.Container;
  private overlay: PIXI.Graphics;
  private cards: PIXI.Container[] = [];
  private titleText: PIXI.Text;
  visible: boolean = false;
  selectedIndex: number = -1;

  private screenW: number;
  private screenH: number;

  constructor(parent: PIXI.Container, screenW: number, screenH: number) {
    this.container = new PIXI.Container();
    this.container.visible = false;
    this.container.zIndex = 200;
    parent.addChild(this.container);
    this.screenW = screenW;
    this.screenH = screenH;

    // Dark overlay
    this.overlay = new PIXI.Graphics();
    this.container.addChild(this.overlay);

    // Title
    this.titleText = new PIXI.Text('LEVEL UP!', {
      fontFamily: 'Arial', fontSize: 32, fontWeight: 'bold', fill: '#fbbf24',
      stroke: '#000000', strokeThickness: 4,
    });
    this.titleText.anchor.set(0.5);
    this.container.addChild(this.titleText);

    // Create 3 card containers
    for (let i = 0; i < 3; i++) {
      const card = new PIXI.Container();
      this.container.addChild(card);
      this.cards.push(card);
    }
  }

  /** Show the level up UI with choices */
  show(choices: UpgradeChoice[]): void {
    this.visible = true;
    this.selectedIndex = -1;
    this.container.visible = true;

    // Draw overlay
    this.overlay.clear();
    this.overlay.beginFill(0x000000, 0.7);
    this.overlay.drawRect(0, 0, this.screenW, this.screenH);
    this.overlay.endFill();

    this.titleText.position.set(this.screenW / 2, this.screenH * 0.2);

    const cardW = 180;
    const cardH = 220;
    const gap = 20;
    const totalW = choices.length * cardW + (choices.length - 1) * gap;
    const startX = (this.screenW - totalW) / 2;
    const cardY = this.screenH * 0.35;

    for (let i = 0; i < 3; i++) {
      const card = this.cards[i];
      card.removeChildren();

      if (i >= choices.length) {
        card.visible = false;
        continue;
      }
      card.visible = true;

      const choice = choices[i];
      const cx = startX + i * (cardW + gap);

      // Card background
      const bg = new PIXI.Graphics();
      bg.beginFill(0x1a1a2e);
      bg.lineStyle(2, choice.color);
      bg.drawRoundedRect(0, 0, cardW, cardH, 10);
      bg.endFill();
      card.addChild(bg);

      // Name
      const nameText = new PIXI.Text(choice.name, {
        fontFamily: 'Arial', fontSize: 15, fontWeight: 'bold',
        fill: '#' + choice.color.toString(16).padStart(6, '0'),
        wordWrap: true, wordWrapWidth: cardW - 20,
      });
      nameText.anchor.set(0.5, 0);
      nameText.position.set(cardW / 2, 15);
      card.addChild(nameText);

      // Level indicator
      const lvlStr = choice.currentLevel > 0
        ? `Lv.${choice.currentLevel} → ${choice.currentLevel + 1}`
        : 'NEW';
      const lvlText = new PIXI.Text(lvlStr, {
        fontFamily: 'Arial', fontSize: 12, fill: '#a1a1aa',
      });
      lvlText.anchor.set(0.5, 0);
      lvlText.position.set(cardW / 2, 40);
      card.addChild(lvlText);

      // Description
      const descText = new PIXI.Text(choice.description, {
        fontFamily: 'Arial', fontSize: 13, fill: '#e2e8f0',
        wordWrap: true, wordWrapWidth: cardW - 24,
      });
      descText.anchor.set(0.5, 0);
      descText.position.set(cardW / 2, 70);
      card.addChild(descText);

      // Key hint
      const keyText = new PIXI.Text(`[${i + 1}]`, {
        fontFamily: 'Arial', fontSize: 20, fontWeight: 'bold', fill: '#fbbf24',
      });
      keyText.anchor.set(0.5, 1);
      keyText.position.set(cardW / 2, cardH - 15);
      card.addChild(keyText);

      card.position.set(cx, cardY);
    }
  }

  /** Hide the UI */
  hide(): void {
    this.visible = false;
    this.container.visible = false;
  }

  /** Check for keyboard selection (1, 2, 3 keys) */
  checkInput(isDown: (key: string) => boolean): number {
    if (!this.visible) return -1;
    if (isDown('1')) return 0;
    if (isDown('2')) return 1;
    if (isDown('3')) return 2;
    return -1;
  }

  /** Handle screen resize */
  resize(screenW: number, screenH: number): void {
    this.screenW = screenW;
    this.screenH = screenH;
  }
}
