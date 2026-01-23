/**
 * MenuScreens.ts - Title screen and game over screen.
 * Handles transitions between game states.
 */

import * as PIXI from 'pixi.js';

export class MenuScreens {
  private container: PIXI.Container;
  private titleContainer: PIXI.Container;
  private gameOverContainer: PIXI.Container;

  private titleText: PIXI.Text;
  private subtitleText: PIXI.Text;
  private startText: PIXI.Text;

  private goTitleText: PIXI.Text;
  private goStatsText: PIXI.Text;
  private goRestartText: PIXI.Text;

  private screenW: number;
  private screenH: number;

  currentScreen: 'title' | 'game' | 'gameover' = 'title';

  constructor(parent: PIXI.Container, screenW: number, screenH: number) {
    this.container = new PIXI.Container();
    this.container.zIndex = 300;
    parent.addChild(this.container);
    this.screenW = screenW;
    this.screenH = screenH;

    // === TITLE SCREEN ===
    this.titleContainer = new PIXI.Container();
    this.container.addChild(this.titleContainer);

    const titleBg = new PIXI.Graphics();
    titleBg.beginFill(0x0a0a0f);
    titleBg.drawRect(0, 0, screenW, screenH);
    titleBg.endFill();
    this.titleContainer.addChild(titleBg);

    this.titleText = new PIXI.Text('CODEX MORTIS', {
      fontFamily: 'Arial', fontSize: 52, fontWeight: 'bold',
      fill: ['#c4b5fd', '#7c3aed'],
      stroke: '#1e1b4b', strokeThickness: 5,
    });
    this.titleText.anchor.set(0.5);
    this.titleContainer.addChild(this.titleText);

    this.subtitleText = new PIXI.Text('Survive the endless dark', {
      fontFamily: 'Arial', fontSize: 18, fill: '#a1a1aa',
    });
    this.subtitleText.anchor.set(0.5);
    this.titleContainer.addChild(this.subtitleText);

    this.startText = new PIXI.Text('Press any key to start', {
      fontFamily: 'Arial', fontSize: 16, fill: '#fbbf24',
    });
    this.startText.anchor.set(0.5);
    this.titleContainer.addChild(this.startText);

    // === GAME OVER SCREEN ===
    this.gameOverContainer = new PIXI.Container();
    this.gameOverContainer.visible = false;
    this.container.addChild(this.gameOverContainer);

    const goBg = new PIXI.Graphics();
    goBg.beginFill(0x000000, 0.85);
    goBg.drawRect(0, 0, screenW, screenH);
    goBg.endFill();
    this.gameOverContainer.addChild(goBg);

    this.goTitleText = new PIXI.Text('YOU DIED', {
      fontFamily: 'Arial', fontSize: 48, fontWeight: 'bold',
      fill: '#ef4444', stroke: '#450a0a', strokeThickness: 4,
    });
    this.goTitleText.anchor.set(0.5);
    this.gameOverContainer.addChild(this.goTitleText);

    this.goStatsText = new PIXI.Text('', {
      fontFamily: 'Arial', fontSize: 16, fill: '#e2e8f0',
      align: 'center',
    });
    this.goStatsText.anchor.set(0.5);
    this.gameOverContainer.addChild(this.goStatsText);

    this.goRestartText = new PIXI.Text('Press any key to restart', {
      fontFamily: 'Arial', fontSize: 16, fill: '#fbbf24',
    });
    this.goRestartText.anchor.set(0.5);
    this.gameOverContainer.addChild(this.goRestartText);

    this.layoutTitle();
  }

  private layoutTitle(): void {
    this.titleText.position.set(this.screenW / 2, this.screenH * 0.35);
    this.subtitleText.position.set(this.screenW / 2, this.screenH * 0.45);
    this.startText.position.set(this.screenW / 2, this.screenH * 0.6);
  }

  /** Show title screen */
  showTitle(): void {
    this.currentScreen = 'title';
    this.titleContainer.visible = true;
    this.gameOverContainer.visible = false;
  }

  /** Hide menus, start game */
  showGame(): void {
    this.currentScreen = 'game';
    this.titleContainer.visible = false;
    this.gameOverContainer.visible = false;
  }

  /** Show game over with stats */
  showGameOver(time: string, kills: number, level: number): void {
    this.currentScreen = 'gameover';
    this.titleContainer.visible = false;
    this.gameOverContainer.visible = true;

    this.goTitleText.position.set(this.screenW / 2, this.screenH * 0.3);
    this.goStatsText.text = `Time: ${time}\nKills: ${kills}\nLevel: ${level}`;
    this.goStatsText.position.set(this.screenW / 2, this.screenH * 0.48);
    this.goRestartText.position.set(this.screenW / 2, this.screenH * 0.65);
  }

  /** Animate the start text blinking */
  updateTitle(time: number): void {
    if (this.currentScreen === 'title') {
      this.startText.alpha = 0.5 + Math.sin(time * 3) * 0.5;
    }
    if (this.currentScreen === 'gameover') {
      this.goRestartText.alpha = 0.5 + Math.sin(time * 3) * 0.5;
    }
  }

  /** Handle screen resize */
  resize(screenW: number, screenH: number): void {
    this.screenW = screenW;
    this.screenH = screenH;
    this.layoutTitle();
  }
}
