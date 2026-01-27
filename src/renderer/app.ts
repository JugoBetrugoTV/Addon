/**
 * Renderer App - Main UI for WoW PvP Analyzer
 */

import { CLASS_COLORS, WowClass, REGIONS } from '../types/wow';

declare global {
  interface Window {
    api: {
      setConfig: (config: { clientId?: string; clientSecret?: string; region?: string }) => Promise<{ success: boolean }>;
      getConfig: () => Promise<{ clientId: string; hasSecret: boolean; region: string }>;
      searchCharacter: (name: string, realm: string) => Promise<any>;
      getPvPStats: (name: string, realm: string) => Promise<any>;
      getLeaderboard: (bracket: '2v2' | '3v3' | 'rbg') => Promise<any>;
    };
  }
}

class App {
  private currentView: 'search' | 'leaderboard' | 'settings' = 'search';
  private currentCharacter: any = null;
  private currentStats: any = null;

  constructor() {
    this.init();
  }

  private async init(): Promise<void> {
    this.setupNavigation();
    this.setupSearch();
    this.setupLeaderboard();
    this.setupSettings();
    await this.loadConfig();
  }

  private setupNavigation(): void {
    document.querySelectorAll('[data-nav]').forEach(btn => {
      btn.addEventListener('click', () => {
        const view = (btn as HTMLElement).dataset.nav as any;
        this.switchView(view);
      });
    });
  }

  private switchView(view: 'search' | 'leaderboard' | 'settings'): void {
    this.currentView = view;
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('[data-nav]').forEach(b => b.classList.remove('active'));
    document.getElementById(`view-${view}`)?.classList.add('active');
    document.querySelector(`[data-nav="${view}"]`)?.classList.add('active');
  }

  private setupSearch(): void {
    const form = document.getElementById('search-form') as HTMLFormElement;
    const input = document.getElementById('search-input') as HTMLInputElement;
    const realmInput = document.getElementById('realm-input') as HTMLInputElement;

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = input.value.trim();
      const realm = realmInput.value.trim();
      if (!name || !realm) return;

      this.showLoading(true);
      await this.searchCharacter(name, realm);
      this.showLoading(false);
    });
  }

  private async searchCharacter(name: string, realm: string): Promise<void> {
    const result = document.getElementById('search-result')!;

    const [charData, statsData] = await Promise.all([
      window.api.searchCharacter(name, realm),
      window.api.getPvPStats(name, realm),
    ]);

    if (charData.error) {
      result.innerHTML = `<div class="error">${charData.error}</div>`;
      return;
    }

    this.currentCharacter = charData;
    this.currentStats = statsData;
    this.renderCharacterProfile();
  }

  private renderCharacterProfile(): void {
    const result = document.getElementById('search-result')!;
    const char = this.currentCharacter;
    const stats = this.currentStats;
    const color = CLASS_COLORS[char.class as WowClass] || '#ffffff';

    let ratingsHtml = '';
    if (stats && stats.ratings) {
      ratingsHtml = stats.ratings.map((r: any) => `
        <div class="rating-card">
          <div class="bracket">${r.bracket.toUpperCase()}</div>
          <div class="rating" style="color: ${this.getRatingColor(r.rating)}">${r.rating}</div>
          <div class="record">${r.seasonWins}W - ${r.seasonLosses}L</div>
          <div class="winrate">${this.calcWinRate(r.seasonWins, r.seasonLosses)}% WR</div>
        </div>
      `).join('');
    }

    result.innerHTML = `
      <div class="character-profile">
        <div class="char-header">
          ${char.avatarUrl ? `<img src="${char.avatarUrl}" class="avatar" alt="">` : ''}
          <div class="char-info">
            <h2 style="color: ${color}">${char.name}</h2>
            <div class="char-details">
              <span class="spec">${char.spec}</span>
              <span class="class" style="color: ${color}">${this.formatClass(char.class)}</span>
              <span class="realm">${char.realm}-${char.region.toUpperCase()}</span>
            </div>
            <div class="char-meta">
              <span>Level ${char.level}</span>
              <span>iLvl ${char.itemLevel}</span>
              <span class="faction ${char.faction}">${char.faction}</span>
            </div>
          </div>
        </div>

        ${stats ? `
          <div class="pvp-stats">
            <div class="honor-info">
              <span>Honor Level: ${stats.honorLevel}</span>
              <span>HKs: ${stats.honorableKills.toLocaleString()}</span>
            </div>
            <div class="ratings-grid">${ratingsHtml || '<p class="no-data">No rated PvP data</p>'}</div>
          </div>
        ` : ''}
      </div>
    `;
  }

  private setupLeaderboard(): void {
    document.querySelectorAll('[data-bracket]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const bracket = (btn as HTMLElement).dataset.bracket as '2v2' | '3v3' | 'rbg';
        document.querySelectorAll('[data-bracket]').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        await this.loadLeaderboard(bracket);
      });
    });
  }

  private async loadLeaderboard(bracket: '2v2' | '3v3' | 'rbg'): Promise<void> {
    const container = document.getElementById('leaderboard-list')!;
    container.innerHTML = '<div class="loading">Loading leaderboard...</div>';

    const data = await window.api.getLeaderboard(bracket);

    if (data.error) {
      container.innerHTML = `<div class="error">${data.error}</div>`;
      return;
    }

    if (!data.length) {
      container.innerHTML = '<div class="no-data">No leaderboard data available</div>';
      return;
    }

    container.innerHTML = `
      <table class="leaderboard-table">
        <thead>
          <tr>
            <th>Rank</th>
            <th>Player</th>
            <th>Rating</th>
            <th>Record</th>
            <th>Win Rate</th>
          </tr>
        </thead>
        <tbody>
          ${data.map((entry: any) => `
            <tr>
              <td class="rank">#${entry.rank}</td>
              <td class="player">
                <span class="name">${entry.character.name}</span>
                <span class="realm">${entry.character.realm}</span>
              </td>
              <td class="rating" style="color: ${this.getRatingColor(entry.rating)}">${entry.rating}</td>
              <td class="record">${entry.wins}W - ${entry.losses}L</td>
              <td class="winrate">${entry.winRate}%</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  private setupSettings(): void {
    const form = document.getElementById('settings-form') as HTMLFormElement;

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const clientId = (document.getElementById('client-id') as HTMLInputElement).value;
      const clientSecret = (document.getElementById('client-secret') as HTMLInputElement).value;
      const region = (document.getElementById('region-select') as HTMLSelectElement).value;

      await window.api.setConfig({ clientId, clientSecret, region });
      this.showMessage('Settings saved!');
    });
  }

  private async loadConfig(): Promise<void> {
    const config = await window.api.getConfig();
    (document.getElementById('region-select') as HTMLSelectElement).value = config.region;

    const status = document.getElementById('api-status')!;
    if (config.hasSecret) {
      status.innerHTML = '<span class="status-ok">✓ API configured</span>';
    } else {
      status.innerHTML = '<span class="status-warn">⚠ API credentials not set</span>';
    }
  }

  private showLoading(show: boolean): void {
    const loader = document.getElementById('loader');
    if (loader) loader.style.display = show ? 'flex' : 'none';
  }

  private showMessage(msg: string): void {
    const el = document.getElementById('message');
    if (el) {
      el.textContent = msg;
      el.style.display = 'block';
      setTimeout(() => el.style.display = 'none', 3000);
    }
  }

  private getRatingColor(rating: number): string {
    if (rating >= 2400) return '#ff8000'; // Orange (Gladiator)
    if (rating >= 2100) return '#a335ee'; // Purple (Duelist)
    if (rating >= 1800) return '#0070dd'; // Blue (Rival)
    if (rating >= 1600) return '#1eff00'; // Green (Challenger)
    return '#ffffff';
  }

  private calcWinRate(wins: number, losses: number): number {
    const total = wins + losses;
    return total > 0 ? Math.round((wins / total) * 100) : 0;
  }

  private formatClass(cls: string): string {
    return cls.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
  }
}

// Initialize
window.addEventListener('DOMContentLoaded', () => new App());
