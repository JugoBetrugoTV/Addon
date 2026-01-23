/**
 * LevelUpSystem.ts - Handles XP, leveling, and upgrade selection.
 * Manages player stats, weapon upgrades, and passive upgrade choices.
 */

import { IWorld, addEntity, addComponent } from 'bitecs';
import { Weapon, WeaponTag, Player } from '../entities/World';
import { PlayerStats, BASE_STATS, PASSIVE_UPGRADES, PassiveUpgrade, XP_TABLE } from './UpgradeData';
import { WEAPONS, WeaponDef, getWeaponDef } from '../combat/WeaponTypes';

export interface UpgradeChoice {
  type: 'weapon' | 'passive';
  index: number;  // weapon type or passive upgrade index
  name: string;
  description: string;
  color: number;
  currentLevel: number;
  maxLevel: number;
}

export class LevelUpSystem {
  private world: IWorld;
  stats: PlayerStats;
  private passiveLevels: number[] = [];
  private ownedWeapons: number[] = [];  // weapon types owned
  private weaponEntities: Map<number, number> = new Map();  // type -> eid
  pendingLevelUp: boolean = false;
  choices: UpgradeChoice[] = [];

  constructor(world: IWorld) {
    this.world = world;
    this.stats = { ...BASE_STATS };
    this.passiveLevels = new Array(PASSIVE_UPGRADES.length).fill(0);
  }

  /** Add a starting weapon */
  addWeapon(type: number): void {
    if (this.ownedWeapons.includes(type)) return;
    this.ownedWeapons.push(type);

    const def = getWeaponDef(type);
    const weid = addEntity(this.world);
    addComponent(this.world, Weapon, weid);
    addComponent(this.world, WeaponTag, weid);

    Weapon.type[weid] = type;
    Weapon.level[weid] = 1;
    Weapon.damage[weid] = def.baseDamage;
    Weapon.cooldown[weid] = def.baseCooldown;
    Weapon.timer[weid] = 0;
    Weapon.range[weid] = def.baseRange;
    Weapon.count[weid] = def.baseCount;
    Weapon.pierce[weid] = def.basePierce;
    Weapon.speed[weid] = def.baseSpeed;
    Weapon.area[weid] = def.baseArea;

    this.weaponEntities.set(type, weid);
  }

  /** Add XP and check for level up. Returns true if leveled. */
  addXP(amount: number, playerEid: number): boolean {
    Player.xp[playerEid] += amount;
    const level = Player.level[playerEid];
    const needed = XP_TABLE[Math.min(level - 1, XP_TABLE.length - 1)];

    if (Player.xp[playerEid] >= needed) {
      Player.xp[playerEid] -= needed;
      Player.level[playerEid]++;
      Player.xpToNext[playerEid] = XP_TABLE[Math.min(Player.level[playerEid] - 1, XP_TABLE.length - 1)];
      this.generateChoices();
      this.pendingLevelUp = true;
      return true;
    }
    return false;
  }

  /** Apply the chosen upgrade */
  applyChoice(choiceIndex: number): void {
    const choice = this.choices[choiceIndex];
    if (!choice) return;

    if (choice.type === 'weapon') {
      if (this.ownedWeapons.includes(choice.index)) {
        this.upgradeWeapon(choice.index);
      } else {
        this.addWeapon(choice.index);
      }
    } else {
      this.upgradePassive(choice.index);
    }

    this.pendingLevelUp = false;
    this.choices = [];
  }

  /** Generate 3 random upgrade choices */
  private generateChoices(): void {
    const pool: UpgradeChoice[] = [];

    // Weapon upgrades for owned weapons
    for (const wtype of this.ownedWeapons) {
      const weid = this.weaponEntities.get(wtype);
      if (!weid) continue;
      const level = Weapon.level[weid];
      const def = getWeaponDef(wtype);
      if (level < def.maxLevel) {
        pool.push({
          type: 'weapon', index: wtype,
          name: def.name, description: def.upgrades[level - 1] || '+Upgrade',
          color: def.color, currentLevel: level, maxLevel: def.maxLevel,
        });
      }
    }

    // New weapons (if fewer than 6 owned)
    if (this.ownedWeapons.length < 6) {
      for (let i = 0; i < WEAPONS.length; i++) {
        if (!this.ownedWeapons.includes(i)) {
          const def = WEAPONS[i];
          pool.push({
            type: 'weapon', index: i,
            name: def.name, description: def.description,
            color: def.color, currentLevel: 0, maxLevel: def.maxLevel,
          });
        }
      }
    }

    // Passive upgrades
    for (let i = 0; i < PASSIVE_UPGRADES.length; i++) {
      const upgrade = PASSIVE_UPGRADES[i];
      if (this.passiveLevels[i] < upgrade.maxLevel) {
        pool.push({
          type: 'passive', index: i,
          name: upgrade.name, description: upgrade.description,
          color: upgrade.color, currentLevel: this.passiveLevels[i], maxLevel: upgrade.maxLevel,
        });
      }
    }

    // Shuffle and pick 3
    this.shuffleArray(pool);
    this.choices = pool.slice(0, 3);
  }

  private upgradeWeapon(type: number): void {
    const weid = this.weaponEntities.get(type);
    if (!weid) return;
    const level = Weapon.level[weid];
    const def = getWeaponDef(type);
    const upgradeDesc = def.upgrades[level - 1] || '';

    Weapon.level[weid]++;

    // Parse upgrade effect
    if (upgradeDesc.includes('Damage')) {
      const match = upgradeDesc.match(/(\d+)%/);
      if (match) Weapon.damage[weid] *= 1 + parseInt(match[1]) / 100;
    }
    if (upgradeDesc.includes('Area')) {
      const match = upgradeDesc.match(/(\d+)%/);
      if (match) Weapon.area[weid] *= 1 + parseInt(match[1]) / 100;
    }
    if (upgradeDesc.includes('Speed')) {
      const match = upgradeDesc.match(/(\d+)%/);
      if (match) Weapon.speed[weid] *= 1 + parseInt(match[1]) / 100;
    }
    if (upgradeDesc.includes('+') && (upgradeDesc.includes('Whip') || upgradeDesc.includes('Bolt') || upgradeDesc.includes('Flame') || upgradeDesc.includes('Cross') || upgradeDesc.includes('Strike') || upgradeDesc.includes('Scythe') || upgradeDesc.includes('Waves'))) {
      const match = upgradeDesc.match(/\+(\d+)/);
      if (match) Weapon.count[weid] += parseInt(match[1]);
    }
    if (upgradeDesc.includes('Pierce')) {
      const match = upgradeDesc.match(/(\d+)/);
      if (match) Weapon.pierce[weid] += parseInt(match[1]);
    }
    if (upgradeDesc.includes('Chain')) {
      const match = upgradeDesc.match(/(\d+)/);
      if (match) Weapon.pierce[weid] += parseInt(match[1]);
    }
  }

  private upgradePassive(index: number): void {
    const upgrade = PASSIVE_UPGRADES[index];
    this.passiveLevels[index]++;
    const key = upgrade.effect;

    if (key === 'cooldown') {
      this.stats[key] += upgrade.valuePerLevel;
    } else {
      (this.stats[key] as number) += upgrade.valuePerLevel;
    }
  }

  private shuffleArray<T>(arr: T[]): void {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
  }

  /** Reset for new game */
  reset(): void {
    this.stats = { ...BASE_STATS };
    this.passiveLevels.fill(0);
    this.ownedWeapons = [];
    this.weaponEntities.clear();
    this.pendingLevelUp = false;
    this.choices = [];
  }
}
