/**
 * WoW PvP Analyzer - Complete UI
 * Full implementation with equipment, stats, talents, and all features
 */

import {
  CLASSES, GAME_MODES, REGIONS, getRatingColor, getRatingTitle, getClassInfo, getSpecInfo,
  getItemQualityColor, formatNumber, formatWinRate, getTierForRating, getBracketName,
  PlayerProfile, SpecBuild, MetaSnapshot, LeaderboardResponse, LeaderboardEntry,
  GameMode, WowClass, CharacterStats, CharacterEquipment, TalentLoadout,
} from '../types/wow';

declare global {
  interface Window {
    api: {
      setConfig: (c: any) => Promise<any>;
      getConfig: () => Promise<any>;
      getRegion: () => Promise<string>;
      getPlayerProfile: (name: string, realm: string) => Promise<any>;
      getLeaderboard: (bracket: string, filters?: any) => Promise<LeaderboardResponse | { error: string }>;
      enrichLeaderboard: (entries: any[]) => Promise<any[]>;
      getSpecBuild: (specId: number, gameMode: string) => Promise<SpecBuild>;
      getMetaRankings: (gameMode: string, role: string) => Promise<MetaSnapshot>;
      getCurrentSeason: () => Promise<{ id: number; name: string }>;
      searchRealms: (query: string) => Promise<{ id: number; name: string; slug: string }[]>;
    };
  }
}

class App {
  private currentView = 'search';
  private selectedClass: WowClass | null = null;
  private selectedSpec: number | null = null;
  private selectedGameMode: GameMode = 'shuffle';
  private currentProfile: PlayerProfile | null = null;
  private leaderboardPage = 1;
  private currentBracket: GameMode = 'shuffle';

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
    await this.loadSeason();
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

    // Load data when switching to certain views
    if (view === 'meta') this.loadMeta();
    if (view === 'leaderboard' && !document.querySelector('.lb-table')) {
      this.loadLeaderboard();
    }
  }

  private async loadSeason() {
    try {
      const season = await window.api.getCurrentSeason();
      const seasonEl = document.getElementById('current-season');
      if (seasonEl) seasonEl.textContent = season.name;
    } catch { /* ignore */ }
  }

  // === PLAYER SEARCH ===
  private setupSearch() {
    const form = document.getElementById('search-form') as HTMLFormElement;
    const realmInput = document.getElementById('search-realm') as HTMLInputElement;
    const realmList = document.getElementById('realm-suggestions') as HTMLElement;

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = (document.getElementById('search-name') as HTMLInputElement).value.trim();
      const realm = realmInput.value.trim();
      if (!name || !realm) return;

      this.showLoader(true);
      const profile = await window.api.getPlayerProfile(name, realm);
      this.showLoader(false);
      this.renderProfile(profile);
    });

    // Realm autocomplete
    let debounce: number;
    realmInput.addEventListener('input', () => {
      clearTimeout(debounce);
      debounce = window.setTimeout(async () => {
        const query = realmInput.value.trim();
        if (query.length < 2) {
          realmList.style.display = 'none';
          return;
        }
        const realms = await window.api.searchRealms(query);
        if (realms.length > 0) {
          realmList.innerHTML = realms.map(r =>
            `<div class="realm-suggestion" data-slug="${r.slug}">${r.name}</div>`
          ).join('');
          realmList.style.display = 'block';
        } else {
          realmList.style.display = 'none';
        }
      }, 300);
    });

    realmList.addEventListener('click', (e) => {
      const item = (e.target as HTMLElement).closest('.realm-suggestion') as HTMLElement;
      if (item) {
        realmInput.value = item.dataset.slug || item.textContent || '';
        realmList.style.display = 'none';
      }
    });

    document.addEventListener('click', (e) => {
      if (!realmList.contains(e.target as Node) && e.target !== realmInput) {
        realmList.style.display = 'none';
      }
    });
  }

  private renderProfile(data: PlayerProfile | { error: string }) {
    const container = document.getElementById('search-result')!;
    if ('error' in data) {
      container.innerHTML = `<div class="error-box">${data.error}</div>`;
      return;
    }

    this.currentProfile = data;
    const c = data.character;
    const classInfo = getClassInfo(c.class);

    container.innerHTML = `
      <div class="profile-card">
        <div class="profile-header">
          <div class="avatar-section">
            ${c.avatarUrl ? `<img src="${c.avatarUrl}" class="avatar" alt="">` : '<div class="avatar-placeholder"></div>'}
            ${c.insetUrl ? `<img src="${c.insetUrl}" class="inset-image" alt="">` : ''}
          </div>
          <div class="profile-info">
            <h2 style="color: ${classInfo?.color || '#fff'}">
              ${c.title || c.name}
            </h2>
            <div class="profile-meta">
              <span class="spec">${c.spec}</span>
              <span class="class-name" style="color: ${classInfo?.color}">${c.className}</span>
            </div>
            <div class="profile-location">
              <span class="realm">${c.realm}</span>
              <span class="region">${c.region.toUpperCase()}</span>
              <span class="faction faction-${c.faction}">${c.faction}</span>
            </div>
            <div class="profile-extra">
              <span class="level">Level ${c.level}</span>
              <span class="ilvl">iLvl ${c.equippedItemLevel}</span>
              <span class="race">${c.race}</span>
              ${c.guild ? `<span class="guild">&lt;${c.guild.name}&gt;</span>` : ''}
            </div>
            ${data.highestPvPTier ? `<div class="highest-tier tier-badge" style="color: ${getRatingColor(getTierForRating(2400).minRating)}">${data.highestPvPTier}</div>` : ''}
          </div>
          <div class="honor-stats">
            <div class="honor-level"><span class="label">Honor Level</span><span class="value">${data.honorLevel}</span></div>
            <div class="hks"><span class="label">Honorable Kills</span><span class="value">${formatNumber(data.honorableKills)}</span></div>
            ${c.achievementPoints ? `<div class="achpts"><span class="label">Achievement Points</span><span class="value">${formatNumber(c.achievementPoints)}</span></div>` : ''}
          </div>
        </div>

        <!-- Ratings Section -->
        <div class="section ratings-section">
          <h3>PvP Ratings</h3>
          <div class="ratings-grid">
            ${data.ratings.length > 0 ? data.ratings.map(r => `
              <div class="rating-card">
                <div class="bracket-name">${r.bracketName}</div>
                <div class="current-rating" style="color: ${getRatingColor(r.current)}">${r.current}</div>
                <div class="rating-tier" style="color: ${getRatingColor(r.current)}">${r.tier?.name || getRatingTitle(r.current)}</div>
                <div class="rating-details">
                  <div class="detail"><span class="label">Season Best</span><span class="value">${r.seasonHigh}</span></div>
                  <div class="detail"><span class="label">This Week</span><span class="value">${r.weeklyHigh}</span></div>
                  ${r.rank ? `<div class="detail"><span class="label">Rank</span><span class="value">#${r.rank}</span></div>` : ''}
                </div>
                <div class="record">
                  <span class="wins">${r.wins}W</span>
                  <span class="losses">${r.losses}L</span>
                  <span class="winrate">${r.winRate}%</span>
                </div>
              </div>
            `).join('') : '<p class="no-data">No rated PvP data this season</p>'}
          </div>
        </div>

        <!-- Profile Tabs -->
        <div class="profile-tabs">
          <button class="profile-tab active" data-tab="history">Rating History</button>
          <button class="profile-tab" data-tab="equipment">Equipment</button>
          <button class="profile-tab" data-tab="stats">Stats</button>
          <button class="profile-tab" data-tab="talents">Talents</button>
          <button class="profile-tab" data-tab="achievements">Achievements</button>
        </div>

        <div class="profile-tab-content">
          <div class="tab-panel active" id="tab-history">
            ${this.renderRatingHistory(data)}
          </div>
          <div class="tab-panel" id="tab-equipment">
            ${data.equipment ? this.renderEquipment(data.equipment) : '<p class="no-data">Equipment data unavailable</p>'}
          </div>
          <div class="tab-panel" id="tab-stats">
            ${data.stats ? this.renderStats(data.stats) : '<p class="no-data">Stats data unavailable</p>'}
          </div>
          <div class="tab-panel" id="tab-talents">
            ${data.talents ? this.renderTalents(data.talents) : '<p class="no-data">Talents data unavailable</p>'}
          </div>
          <div class="tab-panel" id="tab-achievements">
            ${this.renderAchievements(data.achievements)}
          </div>
        </div>
      </div>
    `;

    // Setup tab switching
    container.querySelectorAll('.profile-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        container.querySelectorAll('.profile-tab').forEach(t => t.classList.remove('active'));
        container.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        tab.classList.add('active');
        const tabId = (tab as HTMLElement).dataset.tab;
        document.getElementById(`tab-${tabId}`)?.classList.add('active');
      });
    });

    // Setup rating history chart tabs
    if (data.ratingHistory.length > 0) {
      this.renderRatingChart(data.ratingHistory[0].data);
      container.querySelectorAll('.history-tab').forEach(tab => {
        tab.addEventListener('click', () => {
          container.querySelectorAll('.history-tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          const bracket = (tab as HTMLElement).dataset.bracket;
          const history = data.ratingHistory.find(h => h.bracket === bracket);
          if (history) this.renderRatingChart(history.data);
        });
      });
    }
  }

  private renderRatingHistory(data: PlayerProfile): string {
    if (data.ratingHistory.length === 0) {
      return '<p class="no-data">No rating history available</p>';
    }

    return `
      <div class="history-tabs">
        ${data.ratingHistory.map((h, i) => `
          <button class="history-tab ${i === 0 ? 'active' : ''}" data-bracket="${h.bracket}">
            ${getBracketName(h.bracket)}
          </button>
        `).join('')}
      </div>
      <div class="history-chart" id="rating-chart"></div>
    `;
  }

  private renderRatingChart(chartData: { date: string; rating: number }[]) {
    const chart = document.getElementById('rating-chart');
    if (!chart || chartData.length === 0) return;

    const maxR = Math.max(...chartData.map(d => d.rating));
    const minR = Math.min(...chartData.map(d => d.rating));
    const range = maxR - minR || 100;
    const lastRating = chartData[chartData.length - 1].rating;

    const points = chartData.map((d, i) => {
      const x = (i / (chartData.length - 1)) * 100;
      const y = 100 - ((d.rating - minR) / range) * 80 - 10;
      return `${x},${y}`;
    }).join(' ');

    chart.innerHTML = `
      <svg viewBox="0 0 100 100" preserveAspectRatio="none" class="chart-svg">
        <defs>
          <linearGradient id="chartGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" style="stop-color:${getRatingColor(lastRating)};stop-opacity:0.3"/>
            <stop offset="100%" style="stop-color:${getRatingColor(lastRating)};stop-opacity:0"/>
          </linearGradient>
        </defs>
        <polygon points="0,100 ${points} 100,100" fill="url(#chartGradient)"/>
        <polyline points="${points}" fill="none" stroke="${getRatingColor(lastRating)}" stroke-width="0.8"/>
      </svg>
      <div class="chart-labels">
        <span class="max-label">${maxR}</span>
        <span class="min-label">${minR}</span>
      </div>
      <div class="chart-dates">
        <span>${chartData[0].date}</span>
        <span>${chartData[chartData.length - 1].date}</span>
      </div>
    `;
  }

  private renderEquipment(equipment: CharacterEquipment): string {
    const slots = ['Head', 'Neck', 'Shoulder', 'Back', 'Chest', 'Wrist', 'Hands', 'Waist', 'Legs', 'Feet', 'Finger', 'Finger', 'Trinket', 'Trinket', 'Main Hand', 'Off Hand'];

    return `
      <div class="equipment-grid">
        ${equipment.items.map(item => `
          <div class="equipment-item" style="border-color: ${getItemQualityColor(item.quality)}">
            <div class="item-header">
              <span class="item-slot">${item.slot}</span>
              <span class="item-ilvl">${item.itemLevel}</span>
            </div>
            <div class="item-name" style="color: ${getItemQualityColor(item.quality)}">${item.name}</div>
            ${item.enchant ? `<div class="item-enchant">Enchant: ${item.enchant.name}</div>` : ''}
            ${item.gems && item.gems.length > 0 ? `<div class="item-gems">Gems: ${item.gems.map(g => g.name).join(', ')}</div>` : ''}
            ${item.setInfo ? `<div class="item-set">${item.setInfo.name} (${item.setInfo.itemsEquipped}/${item.setInfo.itemsRequired})</div>` : ''}
            <div class="item-stats">
              ${item.stats.slice(0, 4).map(s => `<span class="stat">${s.type}: +${s.value}</span>`).join('')}
            </div>
          </div>
        `).join('')}
      </div>
      <div class="equipment-summary">
        <span>Average Item Level: <b>${equipment.averageItemLevel}</b></span>
        <span>Equipped Item Level: <b>${equipment.equippedItemLevel}</b></span>
      </div>
    `;
  }

  private renderStats(stats: CharacterStats): string {
    return `
      <div class="stats-grid">
        <div class="stats-section">
          <h4>Resources</h4>
          <div class="stat-row"><span>Health</span><span>${formatNumber(stats.health)}</span></div>
          <div class="stat-row"><span>${stats.powerType}</span><span>${formatNumber(stats.power)}</span></div>
        </div>

        <div class="stats-section">
          <h4>Primary</h4>
          <div class="stat-row"><span>${stats.primaryStat.name}</span><span>${formatNumber(stats.primaryStat.value)}</span></div>
          <div class="stat-row"><span>Stamina</span><span>${formatNumber(stats.stamina.value)}</span></div>
          <div class="stat-row"><span>Armor</span><span>${formatNumber(stats.armor)}</span></div>
        </div>

        <div class="stats-section">
          <h4>Secondary</h4>
          <div class="stat-row">
            <span>Versatility</span>
            <span class="highlight">${stats.versatility.damagePercent.toFixed(2)}% / ${stats.versatility.drPercent.toFixed(2)}%</span>
          </div>
          <div class="stat-row"><span>Haste</span><span>${stats.haste.percent.toFixed(2)}%</span></div>
          <div class="stat-row"><span>Mastery</span><span>${stats.mastery.percent.toFixed(2)}%</span></div>
          <div class="stat-row"><span>Critical Strike</span><span>${stats.criticalStrike.percent.toFixed(2)}%</span></div>
        </div>

        <div class="stats-section">
          <h4>Tertiary</h4>
          <div class="stat-row"><span>Leech</span><span>${stats.leech.percent.toFixed(2)}%</span></div>
          <div class="stat-row"><span>Avoidance</span><span>${stats.avoidance.percent.toFixed(2)}%</span></div>
          <div class="stat-row"><span>Speed</span><span>${stats.speed.percent.toFixed(2)}%</span></div>
        </div>

        <div class="stats-section">
          <h4>Defense</h4>
          <div class="stat-row"><span>Dodge</span><span>${stats.dodgePercent.toFixed(2)}%</span></div>
          <div class="stat-row"><span>Parry</span><span>${stats.parryPercent.toFixed(2)}%</span></div>
          <div class="stat-row"><span>Block</span><span>${stats.blockPercent.toFixed(2)}%</span></div>
        </div>
      </div>
    `;
  }

  private renderTalents(talents: TalentLoadout): string {
    const renderTalentList = (nodes: any[], title: string) => {
      if (!nodes || nodes.length === 0) return '';
      return `
        <div class="talent-section">
          <h4>${title}</h4>
          <div class="talent-list">
            ${nodes.map(t => `
              <div class="talent-item" title="${t.description || ''}">
                <span class="talent-name">${t.name}</span>
                ${t.currentRank && t.maxRank > 1 ? `<span class="talent-rank">${t.currentRank}/${t.maxRank}</span>` : ''}
              </div>
            `).join('')}
          </div>
        </div>
      `;
    };

    return `
      <div class="talents-container">
        <div class="talents-header">
          <span class="spec-info">${talents.specName} ${talents.className}</span>
        </div>
        ${renderTalentList(talents.classTalents, 'Class Talents')}
        ${renderTalentList(talents.specTalents, 'Spec Talents')}
        ${renderTalentList(talents.heroTalents, 'Hero Talents')}
        ${renderTalentList(talents.pvpTalents, 'PvP Talents')}
      </div>
    `;
  }

  private renderAchievements(achievements: any[]): string {
    if (achievements.length === 0) {
      return '<p class="no-data">No PvP achievements found</p>';
    }

    const categoryColors: Record<string, string> = {
      legend: '#e6cc80',
      gladiator: '#ff8000',
      hero: '#ff8000',
      duelist: '#a335ee',
      elite: '#a335ee',
      rival: '#0070dd',
      challenger: '#1eff00',
      combatant: '#1eff00',
      other: '#ffffff',
    };

    return `
      <div class="achievements-list">
        ${achievements.map(a => `
          <div class="achievement achievement-${a.category}" style="border-color: ${categoryColors[a.category] || '#fff'}">
            <div class="ach-main">
              <span class="ach-name" style="color: ${categoryColors[a.category]}">${a.name}</span>
              ${a.description ? `<span class="ach-desc">${a.description}</span>` : ''}
            </div>
            <div class="ach-meta">
              <span class="ach-date">${a.earnedDate}</span>
              ${a.points ? `<span class="ach-points">${a.points} pts</span>` : ''}
            </div>
          </div>
        `).join('')}
      </div>
    `;
  }

  // === BUILDS ===
  private setupBuilds() {
    const classGrid = document.getElementById('class-grid')!;
    classGrid.innerHTML = CLASSES.map(c => `
      <button class="class-btn" data-class="${c.id}" style="--class-color: ${c.color}">
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
        <span class="spec-role role-${s.role}">${s.role}</span>
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
    this.showLoader(true);
    const build = await window.api.getSpecBuild(this.selectedSpec, this.selectedGameMode);
    this.showLoader(false);
    this.renderBuild(build);
  }

  private renderBuild(build: SpecBuild) {
    const container = document.getElementById('build-content')!;

    container.innerHTML = `
      <div class="build-header" style="border-color: ${build.classColor}">
        <h2 style="color: ${build.classColor}">${build.specName} ${build.className}</h2>
        <span class="game-mode">${GAME_MODES.find(m => m.id === build.gameMode)?.name}</span>
        <span class="sample-size">Data from ${build.sampleSize} top players</span>
      </div>

      <div class="build-grid">
        <div class="build-section">
          <h3>Stat Priority</h3>
          <div class="stat-bars">
            ${build.statPriority.map(s => `
              <div class="stat-bar">
                <span class="stat-name">${s.stat}</span>
                <div class="bar-track"><div class="bar-fill" style="width: ${s.percent}%; background: ${build.classColor}"></div></div>
                <span class="stat-pct">${s.percent}%</span>
              </div>
            `).join('')}
          </div>
        </div>

        <div class="build-section">
          <h3>PvP Talents</h3>
          <div class="pvp-talents">
            ${build.talents.pvpTalents.map(t => `
              <div class="pvp-talent">
                <span class="pvp-name">${t.name}</span>
                <div class="usage-bar"><div class="usage-fill" style="width: ${t.usagePercent}%"></div></div>
                <span class="pvp-usage">${t.usagePercent}%</span>
              </div>
            `).join('')}
          </div>
        </div>

        <div class="build-section">
          <h3>Recommended Gear</h3>
          <div class="gear-recommendations">
            ${build.gear.map(g => `
              <div class="gear-rec">
                <span class="gear-slot">${g.slot}</span>
                <div class="gear-items">
                  ${g.items.map(item => `
                    <div class="gear-item">
                      <span class="item-name">${item.name}</span>
                      <span class="item-ilvl">${item.itemLevel}</span>
                      <span class="item-source">${item.source}</span>
                      <span class="item-usage">${item.usagePercent}%</span>
                    </div>
                  `).join('')}
                </div>
              </div>
            `).join('')}
          </div>
        </div>

        <div class="build-section">
          <h3>Enchants</h3>
          <div class="enchant-list">
            ${build.enchants.map(e => `
              <div class="enchant-row">
                <span class="enchant-slot">${e.slot}</span>
                ${e.enchants.map(enc => `
                  <span class="enchant-name">${enc.name}</span>
                  <span class="enchant-stat">${enc.stat}</span>
                  <span class="enchant-usage">${enc.usagePercent}%</span>
                `).join('')}
              </div>
            `).join('')}
          </div>
        </div>

        <div class="build-section">
          <h3>Gems</h3>
          <div class="gem-list">
            ${build.gems.map(g => `
              <div class="gem-category">
                <span class="gem-type">${g.type}</span>
                ${g.gems.map(gem => `
                  <div class="gem-row">
                    <span class="gem-name">${gem.name}</span>
                    <span class="gem-stat">${gem.stat}</span>
                    <span class="gem-usage">${gem.usagePercent}%</span>
                  </div>
                `).join('')}
              </div>
            `).join('')}
          </div>
        </div>

        <div class="build-section">
          <h3>Embellishments</h3>
          <div class="embellishment-list">
            ${build.embellishments.map(e => `
              <div class="embellishment-row">
                <span class="emb-name">${e.name}</span>
                <span class="emb-effect">${e.effect}</span>
                <span class="emb-usage">${e.usagePercent}%</span>
              </div>
            `).join('')}
          </div>
        </div>

        <div class="build-section">
          <h3>Racial Distribution</h3>
          <div class="race-list">
            ${build.racialDistribution.map(r => `
              <div class="race-row">
                <span class="race-name">${r.race}</span>
                <span class="race-faction faction-${r.faction}">${r.faction}</span>
                <div class="race-bar"><div class="race-fill" style="width: ${r.percent * 4}%"></div></div>
                <span class="race-pct">${r.percent}%</span>
              </div>
            `).join('')}
          </div>
        </div>
      </div>

      <div class="build-footer">
        <span>Last updated: ${new Date(build.lastUpdated).toLocaleString()}</span>
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
  }

  private async loadMeta() {
    const mode = document.querySelector('.meta-mode-btn.active')?.getAttribute('data-mode') || 'shuffle';
    const role = document.querySelector('.meta-role-btn.active')?.getAttribute('data-role') || 'all';
    this.showLoader(true);
    const data = await window.api.getMetaRankings(mode, role);
    this.showLoader(false);
    this.renderMeta(data);
  }

  private renderMeta(data: MetaSnapshot) {
    const container = document.getElementById('meta-list')!;
    const tiers = ['S', 'A', 'B', 'C', 'D'] as const;
    const tierColors = { S: '#ff8000', A: '#a335ee', B: '#0070dd', C: '#1eff00', D: '#9d9d9d' };

    const byTier = tiers.map(tier => ({
      tier,
      specs: data.specs.filter(s => s.tier === tier),
    }));

    container.innerHTML = `
      <div class="meta-header">
        <span class="total-games">Total Games: ${formatNumber(data.totalGames)}</span>
        <span class="last-updated">Updated: ${new Date(data.lastUpdated).toLocaleString()}</span>
      </div>
      ${byTier.map(({ tier, specs }) => specs.length > 0 ? `
        <div class="tier-section">
          <div class="tier-label" style="background: ${tierColors[tier]}">${tier}</div>
          <div class="tier-specs">
            ${specs.map(s => `
              <div class="spec-card" style="border-color: ${s.classColor}">
                <div class="spec-header">
                  <span class="spec-name" style="color: ${s.classColor}">${s.specName}</span>
                  <span class="class-name">${s.className}</span>
                </div>
                <div class="spec-stats">
                  <div class="stat-item">
                    <span class="stat-label">Representation</span>
                    <span class="stat-value">${s.representation.toFixed(1)}%</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Win Rate</span>
                    <span class="stat-value ${s.winRate >= 50 ? 'positive' : 'negative'}">${s.winRate.toFixed(1)}%</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Avg Rating</span>
                    <span class="stat-value" style="color: ${getRatingColor(s.avgRating)}">${s.avgRating}</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Games</span>
                    <span class="stat-value">${formatNumber(s.gamesPlayed)}</span>
                  </div>
                </div>
                <div class="spec-trend trend-${s.trend}">
                  ${s.trend === 'up' ? '↑' : s.trend === 'down' ? '↓' : '→'}
                  ${s.changePercent ? `${s.changePercent > 0 ? '+' : ''}${s.changePercent.toFixed(1)}%` : ''}
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      ` : '').join('')}
    `;
  }

  // === LEADERBOARD ===
  private setupLeaderboard() {
    document.querySelectorAll('.lb-bracket-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        document.querySelectorAll('.lb-bracket-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.currentBracket = (btn as HTMLElement).dataset.bracket as GameMode;
        this.leaderboardPage = 1;
        await this.loadLeaderboard();
      });
    });

    document.getElementById('lb-prev')?.addEventListener('click', async () => {
      if (this.leaderboardPage > 1) {
        this.leaderboardPage--;
        await this.loadLeaderboard();
      }
    });

    document.getElementById('lb-next')?.addEventListener('click', async () => {
      this.leaderboardPage++;
      await this.loadLeaderboard();
    });
  }

  private async loadLeaderboard() {
    this.showLoader(true);
    const response = await window.api.getLeaderboard(this.currentBracket, {
      page: this.leaderboardPage,
      pageSize: 50,
    });
    this.showLoader(false);
    this.renderLeaderboard(response);
  }

  private async renderLeaderboard(response: LeaderboardResponse | { error: string }) {
    const container = document.getElementById('leaderboard-content')!;
    const pageInfo = document.getElementById('lb-page-info')!;

    if ('error' in response) {
      container.innerHTML = `<div class="error-box">${response.error}</div>`;
      return;
    }

    if (!response.entries.length) {
      container.innerHTML = '<div class="no-data">No data available</div>';
      return;
    }

    // Enrich with class data (async, update later)
    const enriched = await window.api.enrichLeaderboard(response.entries);

    pageInfo.textContent = `Page ${this.leaderboardPage} (${response.totalCount} total)`;

    container.innerHTML = `
      <div class="lb-header">
        <span class="lb-season">Season ${response.season}</span>
        <span class="lb-bracket">${getBracketName(response.bracket)}</span>
      </div>
      <table class="lb-table">
        <thead>
          <tr>
            <th>Rank</th>
            <th>Player</th>
            <th>Class/Spec</th>
            <th>Rating</th>
            <th>Record</th>
            <th>Win Rate</th>
          </tr>
        </thead>
        <tbody>
          ${enriched.map(e => {
            const classInfo = e.character.class ? getClassInfo(e.character.class) : null;
            return `
              <tr class="lb-row" data-name="${e.character.name}" data-realm="${e.character.realmSlug}">
                <td class="rank">#${e.rank}</td>
                <td class="player">
                  <span class="name" style="color: ${classInfo?.color || '#fff'}">${e.character.name}</span>
                  <span class="realm">${e.character.realm}</span>
                </td>
                <td class="class-spec">
                  ${e.character.className ? `<span style="color: ${classInfo?.color}">${e.character.spec || ''} ${e.character.className}</span>` : '-'}
                </td>
                <td class="rating" style="color: ${getRatingColor(e.rating)}">${e.rating}</td>
                <td class="record">${e.wins}W - ${e.losses}L</td>
                <td class="wr ${e.winRate >= 50 ? 'positive' : ''}">${e.winRate}%</td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    `;

    // Click to view profile
    container.querySelectorAll('.lb-row').forEach(row => {
      row.addEventListener('click', () => {
        const name = (row as HTMLElement).dataset.name;
        const realm = (row as HTMLElement).dataset.realm;
        if (name && realm) {
          (document.getElementById('search-name') as HTMLInputElement).value = name;
          (document.getElementById('search-realm') as HTMLInputElement).value = realm;
          this.switchView('search');
          document.getElementById('search-form')?.dispatchEvent(new Event('submit'));
        }
      });
    });
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
      this.showMessage('Settings saved successfully!');
      await this.loadConfig();
    });
  }

  private async loadConfig() {
    const config = await window.api.getConfig();
    (document.getElementById('region-select') as HTMLSelectElement).value = config.region;
    const status = document.getElementById('api-status')!;
    status.innerHTML = config.isConfigured
      ? '<span class="status-ok">API configured</span>'
      : '<span class="status-warn">API credentials required</span>';
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
}

window.addEventListener('DOMContentLoaded', () => new App());
