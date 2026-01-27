/**
 * WoW PvP Analyzer - Complete UI
 * Features: Player search, builds, meta rankings, leaderboards
 */

import {
  CLASSES, GAME_MODES, REGIONS, getRatingColor, getRatingTitle, getClassInfo,
  PlayerProfile, SpecBuild, MetaSnapshot, LeaderboardEntry, GameMode, WowClass,
} from '../types/wow';

declare global {
  interface Window {
    api: {
      setConfig: (c: any) => Promise<any>;
      getConfig: () => Promise<any>;
      getPlayerProfile: (name: string, realm: string) => Promise<any>;
      getLeaderboard: (bracket: string) => Promise<any>;
      getSpecBuild: (specId: number, gameMode: string) => Promise<SpecBuild>;
      getMetaRankings: (gameMode: string, role: string) => Promise<MetaSnapshot>;
    };
  }
}

class App {
  private currentView = 'search';
  private selectedClass: WowClass | null = null;
  private selectedSpec: number | null = null;
  private selectedGameMode: GameMode = 'solo';

  constructor() {
    this.init();
  }

  private async init() {
    this.setupNav();
    this.setupSearch();
    this.setupBuilds();
    this.setupMeta();
    this.setupLeaderboard();
    this.setupSettings();
    await this.loadConfig();
  }

  private setupNav() {
    document.querySelectorAll('[data-nav]').forEach(btn => {
      btn.addEventListener('click', () => {
        const view = (btn as HTMLElement).dataset.nav!;
        this.switchView(view);
      });
    });
  }

  private switchView(view: string) {
    this.currentView = view;
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('[data-nav]').forEach(b => b.classList.remove('active'));
    document.getElementById(`view-${view}`)?.classList.add('active');
    document.querySelector(`[data-nav="${view}"]`)?.classList.add('active');
  }

  // === PLAYER SEARCH ===
  private setupSearch() {
    const form = document.getElementById('search-form') as HTMLFormElement;
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = (document.getElementById('search-name') as HTMLInputElement).value.trim();
      const realm = (document.getElementById('search-realm') as HTMLInputElement).value.trim();
      if (!name || !realm) return;
      this.showLoader(true);
      const profile = await window.api.getPlayerProfile(name, realm);
      this.showLoader(false);
      this.renderProfile(profile);
    });
  }

  private renderProfile(data: PlayerProfile | { error: string }) {
    const container = document.getElementById('search-result')!;
    if ('error' in data) {
      container.innerHTML = `<div class="error-box">${data.error}</div>`;
      return;
    }

    const c = data.character;
    const classInfo = getClassInfo(c.class);

    container.innerHTML = `
      <div class="profile-card">
        <div class="profile-header">
          ${c.avatarUrl ? `<img src="${c.avatarUrl}" class="avatar" alt="">` : '<div class="avatar-placeholder"></div>'}
          <div class="profile-info">
            <h2 style="color: ${classInfo?.color || '#fff'}">${c.name}</h2>
            <div class="profile-meta">
              <span class="spec">${c.spec}</span>
              <span class="class-name" style="color: ${classInfo?.color}">${classInfo?.name || c.class}</span>
              <span class="realm">${c.realm}-${c.region.toUpperCase()}</span>
            </div>
            <div class="profile-extra">
              <span>Level ${c.level}</span>
              <span>iLvl ${c.itemLevel}</span>
              <span class="faction-${c.faction}">${c.faction}</span>
            </div>
          </div>
          <div class="honor-stats">
            <div class="honor-level">Honor ${data.honorLevel}</div>
            <div class="hks">${data.honorableKills.toLocaleString()} HKs</div>
          </div>
        </div>

        <div class="ratings-section">
          <h3>Ratings</h3>
          <div class="ratings-grid">
            ${data.ratings.map(r => `
              <div class="rating-card">
                <div class="bracket-name">${r.bracket.toUpperCase()}</div>
                <div class="current-rating" style="color: ${getRatingColor(r.current)}">${r.current}</div>
                <div class="rating-title">${getRatingTitle(r.current)}</div>
                <div class="season-high">Season: ${r.seasonHigh}</div>
                <div class="record">${r.wins}W - ${r.losses}L</div>
                <div class="winrate">${this.winRate(r.wins, r.losses)}% WR</div>
              </div>
            `).join('') || '<p class="no-data">No rated PvP data</p>'}
          </div>
        </div>

        ${data.ratingHistory.length > 0 ? `
          <div class="history-section">
            <h3>Rating History (30 days)</h3>
            <div class="history-tabs">
              ${data.ratingHistory.map((h, i) => `
                <button class="history-tab ${i === 0 ? 'active' : ''}" data-bracket="${h.bracket}">${h.bracket.toUpperCase()}</button>
              `).join('')}
            </div>
            <div class="history-chart" id="rating-chart"></div>
          </div>
        ` : ''}

        ${data.achievements.length > 0 ? `
          <div class="achievements-section">
            <h3>PvP Achievements</h3>
            <div class="achievements-list">
              ${data.achievements.map(a => `
                <div class="achievement achievement-${a.category}">
                  <span class="ach-name">${a.name}</span>
                  <span class="ach-date">${a.earnedDate}</span>
                </div>
              `).join('')}
            </div>
          </div>
        ` : ''}

        ${data.alts.length > 0 ? `
          <div class="alts-section">
            <h3>Alt Characters</h3>
            <div class="alts-list">
              ${data.alts.map(alt => {
                const altClass = getClassInfo(alt.class);
                return `
                  <div class="alt-card">
                    <span class="alt-name" style="color: ${altClass?.color}">${alt.name}</span>
                    <span class="alt-spec">${alt.spec}</span>
                    ${alt.ratings.map(r => `
                      <span class="alt-rating">${r.bracket}: <b style="color: ${getRatingColor(r.current)}">${r.current}</b> (${r.high})</span>
                    `).join('')}
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        ` : ''}
      </div>
    `;

    // Setup rating history chart
    if (data.ratingHistory.length > 0) {
      this.renderRatingChart(data.ratingHistory[0].data);
      document.querySelectorAll('.history-tab').forEach(tab => {
        tab.addEventListener('click', () => {
          document.querySelectorAll('.history-tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          const bracket = (tab as HTMLElement).dataset.bracket;
          const history = data.ratingHistory.find(h => h.bracket === bracket);
          if (history) this.renderRatingChart(history.data);
        });
      });
    }
  }

  private renderRatingChart(data: { date: string; rating: number }[]) {
    const chart = document.getElementById('rating-chart');
    if (!chart || data.length === 0) return;

    const maxR = Math.max(...data.map(d => d.rating));
    const minR = Math.min(...data.map(d => d.rating));
    const range = maxR - minR || 100;

    const points = data.map((d, i) => {
      const x = (i / (data.length - 1)) * 100;
      const y = 100 - ((d.rating - minR) / range) * 80 - 10;
      return `${x},${y}`;
    }).join(' ');

    chart.innerHTML = `
      <svg viewBox="0 0 100 100" preserveAspectRatio="none" class="chart-svg">
        <polyline points="${points}" fill="none" stroke="${getRatingColor(data[data.length - 1].rating)}" stroke-width="0.5"/>
      </svg>
      <div class="chart-labels">
        <span>${maxR}</span>
        <span>${minR}</span>
      </div>
    `;
  }

  // === BUILDS ===
  private setupBuilds() {
    // Class selector
    const classGrid = document.getElementById('class-grid')!;
    classGrid.innerHTML = CLASSES.map(c => `
      <button class="class-btn" data-class="${c.id}" style="--class-color: ${c.color}">
        <span class="class-icon"></span>
        <span class="class-name">${c.name}</span>
      </button>
    `).join('');

    classGrid.addEventListener('click', (e) => {
      const btn = (e.target as HTMLElement).closest('.class-btn') as HTMLElement;
      if (!btn) return;
      document.querySelectorAll('.class-btn').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      this.selectedClass = btn.dataset.class as WowClass;
      this.renderSpecSelector();
    });

    // Game mode selector
    document.querySelectorAll('.mode-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.mode-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.selectedGameMode = (btn as HTMLElement).dataset.mode as GameMode;
        if (this.selectedSpec) this.loadBuild();
      });
    });
  }

  private renderSpecSelector() {
    const specGrid = document.getElementById('spec-grid')!;
    const classInfo = getClassInfo(this.selectedClass!);
    if (!classInfo) return;

    specGrid.innerHTML = classInfo.specs.map(s => `
      <button class="spec-btn" data-spec="${s.id}" style="--class-color: ${classInfo.color}">
        <span class="spec-name">${s.name}</span>
        <span class="spec-role">${s.role}</span>
      </button>
    `).join('');

    specGrid.addEventListener('click', async (e) => {
      const btn = (e.target as HTMLElement).closest('.spec-btn') as HTMLElement;
      if (!btn) return;
      document.querySelectorAll('.spec-btn').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      this.selectedSpec = parseInt(btn.dataset.spec!);
      await this.loadBuild();
    });

    specGrid.style.display = 'flex';
  }

  private async loadBuild() {
    if (!this.selectedSpec) return;
    const build = await window.api.getSpecBuild(this.selectedSpec, this.selectedGameMode);
    this.renderBuild(build);
  }

  private renderBuild(build: SpecBuild) {
    const container = document.getElementById('build-content')!;

    container.innerHTML = `
      <div class="build-section">
        <h3>Stat Priority</h3>
        <div class="stat-bars">
          ${build.stats.map(s => `
            <div class="stat-bar">
              <span class="stat-name">${s.stat}</span>
              <div class="bar-track"><div class="bar-fill" style="width: ${s.percent}%"></div></div>
              <span class="stat-pct">${s.percent}%</span>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="build-section">
        <h3>Talent Heatmap</h3>
        <div class="talent-grid">
          ${build.talents.map(t => `
            <div class="talent-node" style="--usage: ${t.usagePercent}%" title="${t.name}: ${t.usagePercent}%">
              <div class="talent-icon"></div>
              <div class="talent-usage">${t.usagePercent}%</div>
            </div>
          `).join('')}
        </div>
        <div class="heatmap-legend">
          <span>0%</span><div class="legend-bar"></div><span>100%</span>
        </div>
      </div>

      <div class="build-section">
        <h3>PvP Talents</h3>
        <div class="pvp-talents">
          ${build.pvpTalents.map(t => `
            <div class="pvp-talent">
              <span class="pvp-name">${t.name}</span>
              <span class="pvp-usage">${t.usagePercent}%</span>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="build-section">
        <h3>Gear</h3>
        <div class="gear-grid">
          ${build.gear.map(g => `
            <div class="gear-item">
              <span class="gear-slot">${g.slot}</span>
              <span class="gear-name">${g.name}</span>
              <span class="gear-ilvl">${g.itemLevel}</span>
              <span class="gear-source">${g.source}</span>
              <span class="gear-usage">${g.usagePercent}%</span>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="build-columns">
        <div class="build-section">
          <h3>Enchants</h3>
          ${build.enchants.map(e => `
            <div class="enchant-row">
              <span class="enchant-slot">${e.slot}</span>
              <span class="enchant-name">${e.name}</span>
              <span class="enchant-usage">${e.usagePercent}%</span>
            </div>
          `).join('')}
        </div>

        <div class="build-section">
          <h3>Gems</h3>
          ${build.gems.map(g => `
            <div class="gem-row">
              <span class="gem-name">${g.name}</span>
              <span class="gem-stat">${g.stat}</span>
              <span class="gem-usage">${g.usagePercent}%</span>
            </div>
          `).join('')}
        </div>

        <div class="build-section">
          <h3>Races</h3>
          ${build.races.map(r => `
            <div class="race-row">
              <span class="race-name">${r.name}</span>
              <span class="race-pct">${r.percent}%</span>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="build-footer">
        <span>Sample: ${build.sampleSize} top players</span>
        <span>Updated: ${new Date(build.lastUpdated).toLocaleDateString()}</span>
      </div>
    `;
  }

  // === META RANKINGS ===
  private setupMeta() {
    document.querySelectorAll('.meta-mode-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.meta-mode-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.loadMeta();
      });
    });

    document.querySelectorAll('.meta-role-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.meta-role-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.loadMeta();
      });
    });

    // Load default
    this.loadMeta();
  }

  private async loadMeta() {
    const mode = document.querySelector('.meta-mode-btn.active')?.getAttribute('data-mode') || 'solo';
    const role = document.querySelector('.meta-role-btn.active')?.getAttribute('data-role') || 'dps';
    const data = await window.api.getMetaRankings(mode, role);
    this.renderMeta(data);
  }

  private renderMeta(data: MetaSnapshot) {
    const container = document.getElementById('meta-list')!;

    const tiers = ['S', 'A', 'B', 'C', 'D'] as const;
    const byTier = tiers.map(tier => ({
      tier,
      specs: data.specs.filter(s => s.tier === tier),
    }));

    container.innerHTML = byTier.map(({ tier, specs }) => specs.length > 0 ? `
      <div class="tier-section tier-${tier}">
        <div class="tier-label">${tier}</div>
        <div class="tier-specs">
          ${specs.map(s => `
            <div class="spec-card" style="border-color: ${s.classColor}">
              <div class="spec-header" style="color: ${s.classColor}">
                <span class="spec-name">${s.specName}</span>
                <span class="class-name">${s.className}</span>
              </div>
              <div class="spec-stats">
                <span class="repr">${s.representation.toFixed(1)}% repr</span>
                <span class="wr">${s.winRate.toFixed(1)}% WR</span>
                <span class="trend trend-${s.trend}">${s.trend === 'up' ? '↑' : s.trend === 'down' ? '↓' : '→'}</span>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : '').join('');
  }

  // === LEADERBOARD ===
  private setupLeaderboard() {
    document.querySelectorAll('.lb-bracket-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        document.querySelectorAll('.lb-bracket-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const bracket = (btn as HTMLElement).dataset.bracket as any;
        this.showLoader(true);
        const data = await window.api.getLeaderboard(bracket);
        this.showLoader(false);
        this.renderLeaderboard(data);
      });
    });
  }

  private renderLeaderboard(data: LeaderboardEntry[] | { error: string }) {
    const container = document.getElementById('leaderboard-content')!;
    if ('error' in data) {
      container.innerHTML = `<div class="error-box">${data.error}</div>`;
      return;
    }
    if (!data.length) {
      container.innerHTML = '<div class="no-data">No data available</div>';
      return;
    }

    container.innerHTML = `
      <table class="lb-table">
        <thead>
          <tr><th>Rank</th><th>Player</th><th>Rating</th><th>Record</th><th>Win Rate</th></tr>
        </thead>
        <tbody>
          ${data.map(e => `
            <tr>
              <td class="rank">#${e.rank}</td>
              <td class="player">
                <span class="name">${e.character.name}</span>
                <span class="realm">${e.character.realm}</span>
              </td>
              <td class="rating" style="color: ${getRatingColor(e.rating)}">${e.rating}</td>
              <td class="record">${e.wins}W - ${e.losses}L</td>
              <td class="wr">${e.winRate}%</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  // === SETTINGS ===
  private setupSettings() {
    const form = document.getElementById('settings-form') as HTMLFormElement;
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const clientId = (document.getElementById('client-id') as HTMLInputElement).value;
      const clientSecret = (document.getElementById('client-secret') as HTMLInputElement).value;
      const region = (document.getElementById('region-select') as HTMLSelectElement).value;
      await window.api.setConfig({ clientId, clientSecret, region });
      this.showMessage('Settings saved!');
      await this.loadConfig();
    });
  }

  private async loadConfig() {
    const config = await window.api.getConfig();
    (document.getElementById('region-select') as HTMLSelectElement).value = config.region;
    const status = document.getElementById('api-status')!;
    status.innerHTML = config.hasSecret
      ? '<span class="status-ok">✓ API configured</span>'
      : '<span class="status-warn">⚠ API credentials required</span>';
  }

  // === UTILS ===
  private showLoader(show: boolean) {
    const loader = document.getElementById('loader')!;
    loader.style.display = show ? 'flex' : 'none';
  }

  private showMessage(msg: string) {
    const el = document.getElementById('toast')!;
    el.textContent = msg;
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 3000);
  }

  private winRate(wins: number, losses: number): number {
    const total = wins + losses;
    return total > 0 ? Math.round((wins / total) * 100) : 0;
  }
}

window.addEventListener('DOMContentLoaded', () => new App());
