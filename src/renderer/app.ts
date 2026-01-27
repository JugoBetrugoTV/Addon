/**
 * WoW PvP Analyzer - Complete UI with all features
 * Including: Activity Tracker, Class Representation, Top Players,
 * Talent Heatmaps, Gear Analysis, LFG System
 */

import {
  CLASSES, GAME_MODES, REGIONS, getRatingColor, getRatingTitle, getClassInfo, getSpecInfo,
  getItemQualityColor, formatNumber, formatWinRate, getTierForRating, getBracketName,
  PlayerProfile, SpecBuild, MetaSnapshot, LeaderboardResponse, LeaderboardEntry,
  GameMode, WowClass, CharacterStats, CharacterEquipment, TalentLoadout,
  ActivityTracker, RepresentationStats, TopPlayersResponse, TalentHeatmap, GearAnalysis,
  LFGListing, LFGFilters,
  GuildRoster, GuildAchievements, MythicPlusProfile, ItemDetails, CharacterRaidProgress,
  CharacterSummary,
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
      getActivityTracker: (bracket: string) => Promise<ActivityTracker | { error: string }>;
      getRepresentationStats: (bracket: string, minRating: number) => Promise<RepresentationStats | { error: string }>;
      getTopPlayers: (limit: number) => Promise<TopPlayersResponse | { error: string }>;
      getTalentHeatmap: (specId: number, bracket: string) => Promise<TalentHeatmap | { error: string }>;
      getGearAnalysis: (specId: number, bracket: string) => Promise<GearAnalysis | { error: string }>;
      getLFGListings: (filters: any) => Promise<LFGListing[] | { error: string }>;
      createLFGListing: (post: any, name: string, realm: string) => Promise<LFGListing | { error: string }>;
      deleteLFGListing: (id: string) => Promise<{ success: boolean }>;
      trackPlayer: (name: string, realm: string) => Promise<any>;
      getTrackedPlayer: (name: string, realm: string) => Promise<any>;
      getTrackedPlayers: () => Promise<any[]>;
      addFavorite: (name: string, realm: string) => Promise<any>;
      removeFavorite: (name: string, realm: string) => Promise<any>;
      getFavorites: () => Promise<any[]>;
      // New APIs
      getGuildInfo: (guildName: string, realm: string) => Promise<any>;
      getGuildRoster: (guildName: string, realm: string) => Promise<GuildRoster | { error: string }>;
      getGuildAchievements: (guildName: string, realm: string) => Promise<GuildAchievements | { error: string }>;
      getMythicPlusProfile: (name: string, realm: string) => Promise<MythicPlusProfile | { error: string }>;
      getMythicPlusAffixes: () => Promise<any>;
      getMythicPlusDungeons: () => Promise<any[]>;
      getSpellDetails: (spellId: number) => Promise<any>;
      getPvPTalentDetails: (pvpTalentId: number) => Promise<any>;
      getTalentTree: (specId: number) => Promise<any>;
      getItemDetails: (itemId: number) => Promise<ItemDetails | { error: string }>;
      searchItems: (query: string, limit?: number) => Promise<ItemDetails[]>;
      getRaidProgress: (name: string, realm: string) => Promise<CharacterRaidProgress | { error: string }>;
      getRaidInstances: () => Promise<any[]>;
      getTalentHeatmapReal: (specId: number, bracket: string) => Promise<TalentHeatmap | { error: string }>;
      getGearAnalysisReal: (specId: number, bracket: string) => Promise<GearAnalysis | { error: string }>;
      getCharacterSummary: (name: string, realm: string) => Promise<CharacterSummary | { error: string }>;
      // App updates
      checkForUpdates: () => Promise<{ updateAvailable: boolean; error?: string }>;
      getVersion: () => Promise<string>;
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
    this.setupActivity();
    this.setupRepresentation();
    this.setupTopPlayers();
    this.setupLFG();
    this.setupGuild();
    this.setupMythicPlus();
    this.setupItemSearch();
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

    // Load data when switching views
    if (view === 'meta') this.loadMeta();
    if (view === 'leaderboard') this.loadLeaderboard();
    if (view === 'activity') this.loadActivity();
    if (view === 'representation') this.loadRepresentation();
    if (view === 'top-players') this.loadTopPlayers();
    if (view === 'lfg') this.loadLFG();
    if (view === 'mythicplus') this.loadMythicPlusAffixes();
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
          <div class="profile-actions">
            <button class="btn-action btn-favorite" data-name="${c.name}" data-realm="${c.realmSlug}">★ Favorite</button>
            <button class="btn-action btn-track" data-name="${c.name}" data-realm="${c.realmSlug}">📈 Track</button>
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

    // Favorite/Track buttons
    container.querySelector('.btn-favorite')?.addEventListener('click', async (e) => {
      const btn = e.target as HTMLElement;
      await window.api.addFavorite(btn.dataset.name!, btn.dataset.realm!);
      this.showMessage('Added to favorites!');
    });

    container.querySelector('.btn-track')?.addEventListener('click', async (e) => {
      const btn = e.target as HTMLElement;
      await window.api.trackPlayer(btn.dataset.name!, btn.dataset.realm!);
      this.showMessage('Now tracking player ratings!');
    });

    // Setup rating history chart
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
      legend: '#e6cc80', gladiator: '#ff8000', hero: '#ff8000',
      duelist: '#a335ee', elite: '#a335ee', rival: '#0070dd',
      challenger: '#1eff00', combatant: '#1eff00', other: '#ffffff',
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
                </div>
                <div class="spec-trend trend-${s.trend}">
                  ${s.trend === 'up' ? '↑' : s.trend === 'down' ? '↓' : '→'}
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

  // === ACTIVITY TRACKER (Drustvar style) ===
  private setupActivity() {
    document.querySelectorAll('.activity-bracket-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        document.querySelectorAll('.activity-bracket-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        await this.loadActivity();
      });
    });
  }

  private async loadActivity() {
    const bracket = document.querySelector('.activity-bracket-btn.active')?.getAttribute('data-bracket') || 'shuffle';
    this.showLoader(true);
    const data = await window.api.getActivityTracker(bracket);
    this.showLoader(false);
    this.renderActivity(data);
  }

  private renderActivity(data: ActivityTracker | { error: string }) {
    const container = document.getElementById('activity-content')!;

    if ('error' in data) {
      container.innerHTML = `<div class="error-box">${data.error}</div>`;
      return;
    }

    const renderActivityList = (entries: any[], title: string, icon: string, valueKey: 'ratingChange' | 'gamesPlayed') => `
      <div class="activity-section">
        <h3>${icon} ${title}</h3>
        <div class="activity-list">
          ${entries.slice(0, 15).map(e => {
            const classInfo = e.character.class ? getClassInfo(e.character.class) : null;
            const value = valueKey === 'ratingChange' ? e.ratingChange : e.gamesPlayed;
            const valueClass = valueKey === 'ratingChange' ? (value > 0 ? 'positive' : 'negative') : '';
            return `
              <div class="activity-entry" data-name="${e.character.name}" data-realm="${e.character.realmSlug}">
                <span class="rank">#${e.rank}</span>
                <span class="name" style="color: ${classInfo?.color || '#fff'}">${e.character.name}</span>
                <span class="realm">${e.character.realm}</span>
                <span class="rating" style="color: ${getRatingColor(e.rating)}">${e.rating}</span>
                <span class="change ${valueClass}">${valueKey === 'ratingChange' ? (value > 0 ? '+' : '') : ''}${value}${valueKey === 'gamesPlayed' ? ' games' : ''}</span>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;

    container.innerHTML = `
      <div class="activity-header">
        <span class="activity-region">${data.region.toUpperCase()}</span>
        <span class="last-updated">Updated: ${new Date(data.lastUpdated).toLocaleString()}</span>
      </div>
      <div class="activity-grid">
        ${renderActivityList(data.climbers, 'Biggest Climbers', '📈', 'ratingChange')}
        ${renderActivityList(data.fallers, 'Biggest Drops', '📉', 'ratingChange')}
        ${renderActivityList(data.mostActive, 'Most Active', '🎮', 'gamesPlayed')}
        ${renderActivityList(data.newEntries, 'New to Leaderboard', '🆕', 'ratingChange')}
      </div>
    `;

    // Click to view profile
    container.querySelectorAll('.activity-entry').forEach(entry => {
      entry.addEventListener('click', () => {
        const name = (entry as HTMLElement).dataset.name;
        const realm = (entry as HTMLElement).dataset.realm;
        if (name && realm) {
          (document.getElementById('search-name') as HTMLInputElement).value = name;
          (document.getElementById('search-realm') as HTMLInputElement).value = realm;
          this.switchView('search');
          document.getElementById('search-form')?.dispatchEvent(new Event('submit'));
        }
      });
    });
  }

  // === CLASS REPRESENTATION ===
  private setupRepresentation() {
    document.querySelectorAll('.rep-bracket-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        document.querySelectorAll('.rep-bracket-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        await this.loadRepresentation();
      });
    });

    document.getElementById('rep-min-rating')?.addEventListener('change', async () => {
      await this.loadRepresentation();
    });
  }

  private async loadRepresentation() {
    const bracket = document.querySelector('.rep-bracket-btn.active')?.getAttribute('data-bracket') || 'shuffle';
    const minRating = parseInt((document.getElementById('rep-min-rating') as HTMLSelectElement)?.value || '0');
    this.showLoader(true);
    const data = await window.api.getRepresentationStats(bracket, minRating);
    this.showLoader(false);
    this.renderRepresentation(data);
  }

  private renderRepresentation(data: RepresentationStats | { error: string }) {
    const container = document.getElementById('representation-content')!;

    if ('error' in data) {
      container.innerHTML = `<div class="error-box">${data.error}</div>`;
      return;
    }

    container.innerHTML = `
      <div class="rep-header">
        <span class="rep-total">Total Players: ${formatNumber(data.totalPlayers)}</span>
        <span class="rep-min">Min Rating: ${data.minRating}+</span>
        <span class="last-updated">Updated: ${new Date(data.lastUpdated).toLocaleString()}</span>
      </div>

      <div class="rep-faction-split">
        <div class="faction-bar">
          <div class="alliance-bar" style="width: ${data.factionSplit.alliance}%">
            <span>Alliance ${data.factionSplit.alliance.toFixed(1)}%</span>
          </div>
          <div class="horde-bar" style="width: ${data.factionSplit.horde}%">
            <span>Horde ${data.factionSplit.horde.toFixed(1)}%</span>
          </div>
        </div>
      </div>

      <div class="rep-classes">
        <h3>Class Representation</h3>
        <div class="class-rep-grid">
          ${data.classes.map(c => `
            <div class="class-rep-card" style="border-color: ${c.classColor}">
              <div class="class-rep-header">
                <span class="class-name" style="color: ${c.classColor}">${c.className}</span>
                <span class="class-pct">${c.percentage.toFixed(1)}%</span>
              </div>
              <div class="class-bar">
                <div class="class-fill" style="width: ${c.percentage * 5}%; background: ${c.classColor}"></div>
              </div>
              <div class="class-stats">
                <span class="players">${formatNumber(c.totalPlayers)} players</span>
                <span class="avg-rating" style="color: ${getRatingColor(c.avgRating)}">Avg: ${c.avgRating}</span>
              </div>
              <div class="spec-breakdown">
                ${c.specs.map(s => `
                  <div class="spec-rep">
                    <span class="spec-name">${s.specName}</span>
                    <span class="spec-pct">${s.percentage.toFixed(1)}%</span>
                  </div>
                `).join('')}
              </div>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="rep-races">
        <h3>Race Distribution</h3>
        <div class="race-rep-grid">
          ${data.raceSplit.slice(0, 20).map(r => `
            <div class="race-rep-row">
              <span class="race-name">${r.race}</span>
              <span class="race-faction faction-${r.faction}">${r.faction}</span>
              <div class="race-bar"><div class="race-fill" style="width: ${r.percentage * 5}%"></div></div>
              <span class="race-pct">${r.percentage.toFixed(1)}%</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }

  // === TOP PLAYERS ===
  private setupTopPlayers() {
    document.getElementById('top-players-refresh')?.addEventListener('click', () => {
      this.loadTopPlayers();
    });
  }

  private async loadTopPlayers() {
    this.showLoader(true);
    const data = await window.api.getTopPlayers(50);
    this.showLoader(false);
    this.renderTopPlayers(data);
  }

  private renderTopPlayers(data: TopPlayersResponse | { error: string }) {
    const container = document.getElementById('top-players-content')!;

    if ('error' in data) {
      container.innerHTML = `<div class="error-box">${data.error}</div>`;
      return;
    }

    container.innerHTML = `
      <div class="top-header">
        <span class="top-region">${data.region.toUpperCase()} Top Players</span>
        <span class="last-updated">Updated: ${new Date(data.lastUpdated).toLocaleString()}</span>
      </div>
      <table class="top-table">
        <thead>
          <tr>
            <th>Rank</th>
            <th>Player</th>
            <th>Shuffle</th>
            <th>2v2</th>
            <th>3v3</th>
            <th>RBG</th>
            <th>Blitz</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          ${data.players.map(p => {
            const classInfo = p.character.class ? getClassInfo(p.character.class) : null;
            const getBracketRating = (bracket: GameMode) => {
              const b = p.brackets.find(x => x.bracket === bracket);
              return b ? `<span style="color: ${getRatingColor(b.rating)}">${b.rating}</span>` : '-';
            };
            return `
              <tr class="top-row" data-name="${p.character.name}" data-realm="${p.character.realmSlug}">
                <td class="rank">#${p.rank}</td>
                <td class="player">
                  <span class="name" style="color: ${classInfo?.color || '#fff'}">${p.character.name}</span>
                  <span class="realm">${p.character.realm}</span>
                  ${p.isStreaming ? '<span class="streaming">🔴 LIVE</span>' : ''}
                </td>
                <td>${getBracketRating('shuffle')}</td>
                <td>${getBracketRating('2v2')}</td>
                <td>${getBracketRating('3v3')}</td>
                <td>${getBracketRating('rbg')}</td>
                <td>${getBracketRating('blitz')}</td>
                <td class="total-rating">${formatNumber(p.totalRating)}</td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    `;

    container.querySelectorAll('.top-row').forEach(row => {
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

  // === LFG SYSTEM ===
  private setupLFG() {
    document.querySelectorAll('.lfg-bracket-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        document.querySelectorAll('.lfg-bracket-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        await this.loadLFG();
      });
    });

    document.getElementById('lfg-create-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      await this.createLFGListing();
    });
  }

  private async loadLFG() {
    const bracket = document.querySelector('.lfg-bracket-btn.active')?.getAttribute('data-bracket') || 'shuffle';
    const region = await window.api.getRegion();

    this.showLoader(true);
    const listings = await window.api.getLFGListings({
      bracket,
      region,
      faction: 'all',
    });
    this.showLoader(false);
    this.renderLFG(listings);
  }

  private renderLFG(listings: LFGListing[] | { error: string }) {
    const container = document.getElementById('lfg-listings')!;

    if ('error' in listings) {
      container.innerHTML = `<div class="error-box">${listings.error}</div>`;
      return;
    }

    if (listings.length === 0) {
      container.innerHTML = `
        <div class="lfg-empty">
          <p>No LFG listings found. Be the first to create one!</p>
        </div>
      `;
      return;
    }

    container.innerHTML = `
      <div class="lfg-list">
        ${listings.map(l => {
          const classInfo = getClassInfo(l.character.class);
          return `
            <div class="lfg-card" style="border-color: ${classInfo?.color || '#444'}">
              <div class="lfg-header">
                <span class="lfg-name" style="color: ${classInfo?.color}">${l.character.name}</span>
                <span class="lfg-realm">${l.character.realm}</span>
                <span class="lfg-spec">${l.character.spec} ${l.character.className}</span>
                <span class="lfg-ilvl">iLvl ${l.character.itemLevel}</span>
              </div>
              <div class="lfg-ratings">
                <span class="lfg-current" style="color: ${getRatingColor(l.currentRating)}">
                  Current: ${l.currentRating}
                </span>
                <span class="lfg-season-high">Season High: ${l.seasonHigh}</span>
                ${l.allTimeHigh > l.seasonHigh ? `<span class="lfg-peak">Peak: ${l.allTimeHigh}</span>` : ''}
              </div>
              <div class="lfg-looking">
                <span class="looking-label">Looking for:</span>
                ${l.lookingFor.map(r => `<span class="role-tag role-${r}">${r}</span>`).join('')}
                ${l.minRating ? `<span class="min-rating">${l.minRating}+ rating</span>` : ''}
              </div>
              ${l.description ? `<div class="lfg-desc">${l.description}</div>` : ''}
              <div class="lfg-meta">
                ${l.voiceChat ? '<span class="voice-yes">🎙 Voice Chat</span>' : ''}
                ${l.language ? `<span class="language">${l.language}</span>` : ''}
                ${l.schedule ? `<span class="schedule">${l.schedule}</span>` : ''}
                <span class="lfg-time">Posted ${this.timeAgo(l.createdAt)}</span>
              </div>
              ${l.achievements && l.achievements.length > 0 ? `
                <div class="lfg-achievements">
                  ${l.achievements.map(a => `<span class="ach-tag">${a.name}</span>`).join('')}
                </div>
              ` : ''}
            </div>
          `;
        }).join('')}
      </div>
    `;
  }

  private async createLFGListing() {
    const name = (document.getElementById('lfg-char-name') as HTMLInputElement).value;
    const realm = (document.getElementById('lfg-char-realm') as HTMLInputElement).value;
    const bracket = (document.getElementById('lfg-bracket') as HTMLSelectElement).value;
    const role = (document.getElementById('lfg-role') as HTMLSelectElement).value;
    const lookingForDps = (document.getElementById('lfg-lf-dps') as HTMLInputElement).checked;
    const lookingForHealer = (document.getElementById('lfg-lf-healer') as HTMLInputElement).checked;
    const lookingForTank = (document.getElementById('lfg-lf-tank') as HTMLInputElement).checked;
    const minRating = parseInt((document.getElementById('lfg-min-rating') as HTMLInputElement).value) || 0;
    const description = (document.getElementById('lfg-description') as HTMLTextAreaElement).value;
    const voiceChat = (document.getElementById('lfg-voice') as HTMLInputElement).checked;

    const lookingFor: ('dps' | 'healer' | 'tank')[] = [];
    if (lookingForDps) lookingFor.push('dps');
    if (lookingForHealer) lookingFor.push('healer');
    if (lookingForTank) lookingFor.push('tank');

    if (!name || !realm) {
      this.showMessage('Please enter character name and realm');
      return;
    }

    this.showLoader(true);
    const result = await window.api.createLFGListing({
      bracket: bracket as GameMode,
      role: role as 'dps' | 'healer' | 'tank',
      lookingFor,
      minRating,
      description,
      voiceChat,
    }, name, realm);
    this.showLoader(false);

    if ('error' in result) {
      this.showMessage(result.error);
    } else {
      this.showMessage('LFG listing created!');
      await this.loadLFG();
    }
  }

  private timeAgo(dateStr: string): string {
    const now = Date.now();
    const then = new Date(dateStr).getTime();
    const diff = now - then;
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
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

    // Version display
    this.loadVersion();

    // Update check button
    document.getElementById('check-update-btn')?.addEventListener('click', async () => {
      const statusEl = document.getElementById('update-status')!;
      statusEl.textContent = 'Checking for updates...';
      try {
        const result = await window.api.checkForUpdates();
        if (result.error) {
          statusEl.textContent = result.error;
        } else if (result.updateAvailable) {
          statusEl.textContent = 'Update available! Download will start...';
        } else {
          statusEl.textContent = 'You have the latest version.';
        }
      } catch {
        statusEl.textContent = 'Could not check for updates';
      }
    });
  }

  private async loadVersion() {
    try {
      const version = await window.api.getVersion();
      const versionEl = document.getElementById('app-version');
      if (versionEl) versionEl.textContent = `v${version}`;
    } catch { /* ignore */ }
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

  // === GUILD ===
  private setupGuild() {
    document.getElementById('guild-search-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const guildName = (document.getElementById('guild-name') as HTMLInputElement)?.value.trim();
      const realm = (document.getElementById('guild-realm') as HTMLInputElement)?.value.trim();
      if (!guildName || !realm) return;

      this.showLoader(true);
      const [roster, achievements] = await Promise.all([
        window.api.getGuildRoster(guildName, realm),
        window.api.getGuildAchievements(guildName, realm),
      ]);
      this.showLoader(false);
      this.renderGuild(roster, achievements);
    });
  }

  private renderGuild(roster: GuildRoster | { error: string }, achievements: GuildAchievements | { error: string }) {
    const container = document.getElementById('guild-result')!;

    if ('error' in roster) {
      container.innerHTML = `<div class="error-box">${roster.error}</div>`;
      return;
    }

    const g = roster.guild;
    const pvpMembers = roster.members.filter(m => m.character.level >= 70).slice(0, 50);

    container.innerHTML = `
      <div class="guild-card">
        <div class="guild-header">
          <h2 class="guild-name faction-${g.faction}">&lt;${g.name}&gt;</h2>
          <div class="guild-meta">
            <span class="realm">${g.realm}</span>
            <span class="region">${g.region.toUpperCase()}</span>
            <span class="faction faction-${g.faction}">${g.faction}</span>
          </div>
          <div class="guild-stats">
            <span class="members">${g.memberCount} members</span>
            <span class="achpts">${formatNumber(g.achievementPoints)} achievement points</span>
          </div>
        </div>

        <div class="guild-tabs">
          <button class="guild-tab active" data-tab="roster">Roster</button>
          <button class="guild-tab" data-tab="achievements">Achievements</button>
        </div>

        <div class="guild-tab-content">
          <div class="guild-panel active" id="guild-roster">
            <h3>Members (Level 70+)</h3>
            <div class="guild-roster-list">
              ${pvpMembers.map(m => {
                const classInfo = getClassInfo(m.character.class);
                return `
                  <div class="guild-member" data-name="${m.character.name}" data-realm="${m.character.realmSlug}">
                    <span class="rank-badge">Rank ${m.rank}</span>
                    <span class="member-name" style="color: ${classInfo?.color || '#fff'}">${m.character.name}</span>
                    <span class="member-class">${m.character.className}</span>
                    <span class="member-level">Lv${m.character.level}</span>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
          <div class="guild-panel" id="guild-achievements">
            ${'error' in achievements ? `<div class="error-box">${achievements.error}</div>` : `
              <h3>Guild Achievements</h3>
              <p class="total-points">Total: ${formatNumber(achievements.totalPoints)} points</p>
              <div class="guild-ach-list">
                ${achievements.achievements.slice(0, 30).map(a => `
                  <div class="guild-ach">
                    <span class="ach-name">${a.name}</span>
                    <span class="ach-points">${a.points} pts</span>
                    ${a.completedTimestamp ? `<span class="ach-date">${new Date(a.completedTimestamp).toLocaleDateString()}</span>` : ''}
                  </div>
                `).join('')}
              </div>
            `}
          </div>
        </div>
      </div>
    `;

    // Tab switching
    container.querySelectorAll('.guild-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        container.querySelectorAll('.guild-tab').forEach(t => t.classList.remove('active'));
        container.querySelectorAll('.guild-panel').forEach(p => p.classList.remove('active'));
        tab.classList.add('active');
        const tabId = (tab as HTMLElement).dataset.tab;
        document.getElementById(`guild-${tabId}`)?.classList.add('active');
      });
    });

    // Click member to view profile
    container.querySelectorAll('.guild-member').forEach(member => {
      member.addEventListener('click', () => {
        const name = (member as HTMLElement).dataset.name;
        const realm = (member as HTMLElement).dataset.realm;
        if (name && realm) {
          (document.getElementById('search-name') as HTMLInputElement).value = name;
          (document.getElementById('search-realm') as HTMLInputElement).value = realm;
          this.switchView('search');
          document.getElementById('search-form')?.dispatchEvent(new Event('submit'));
        }
      });
    });
  }

  // === MYTHIC+ ===
  private setupMythicPlus() {
    document.getElementById('mplus-search-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = (document.getElementById('mplus-char-name') as HTMLInputElement)?.value.trim();
      const realm = (document.getElementById('mplus-char-realm') as HTMLInputElement)?.value.trim();
      if (!name || !realm) return;

      this.showLoader(true);
      const profile = await window.api.getMythicPlusProfile(name, realm);
      this.showLoader(false);
      this.renderMythicPlusProfile(profile);
    });
  }

  private async loadMythicPlusAffixes() {
    const affixContainer = document.getElementById('mplus-affixes');
    if (!affixContainer) return;

    const affixes = await window.api.getMythicPlusAffixes();
    if ('error' in affixes) {
      affixContainer.innerHTML = `<div class="error-box">${affixes.error}</div>`;
      return;
    }

    affixContainer.innerHTML = `
      <h3>This Week's Affixes</h3>
      <div class="affix-list">
        ${affixes.currentWeek.affixes.map((a: any) => `
          <div class="affix-card">
            <span class="affix-name">${a.name}</span>
            ${a.description ? `<span class="affix-desc">${a.description}</span>` : ''}
          </div>
        `).join('')}
      </div>
    `;
  }

  private renderMythicPlusProfile(profile: MythicPlusProfile | { error: string }) {
    const container = document.getElementById('mplus-result')!;

    if ('error' in profile) {
      container.innerHTML = `<div class="error-box">${profile.error}</div>`;
      return;
    }

    const season = profile.currentSeason;

    container.innerHTML = `
      <div class="mplus-card">
        <div class="mplus-header">
          <div class="mplus-rating" style="color: ${season.ratingColor}">
            <span class="rating-value">${season.rating}</span>
            <span class="rating-label">M+ Rating</span>
          </div>
        </div>

        ${season.bestRuns.length > 0 ? `
          <div class="mplus-runs">
            <h3>Best Runs</h3>
            <div class="runs-grid">
              ${season.bestRuns.map(run => `
                <div class="run-card ${run.isChested ? 'timed' : ''}">
                  <div class="run-header">
                    <span class="dungeon-name">${run.dungeon.shortName || run.dungeon.name}</span>
                    <span class="key-level">+${run.keystoneLevel}</span>
                  </div>
                  <div class="run-details">
                    <span class="run-rating" style="color: ${this.getMythicPlusColor(run.rating)}">${run.rating.toFixed(0)}</span>
                    <span class="run-time">${this.formatDuration(run.duration)}</span>
                    ${run.isChested ? '<span class="timed-badge">⏱ Timed</span>' : ''}
                  </div>
                  <div class="run-affixes">
                    ${run.affixes.map(a => `<span class="affix-tag">${a.name}</span>`).join('')}
                  </div>
                </div>
              `).join('')}
            </div>
          </div>
        ` : '<p class="no-data">No Mythic+ runs recorded this season</p>'}
      </div>
    `;
  }

  private getMythicPlusColor(rating: number): string {
    if (rating >= 300) return '#ff8000';
    if (rating >= 250) return '#a335ee';
    if (rating >= 200) return '#0070dd';
    if (rating >= 150) return '#1eff00';
    return '#ffffff';
  }

  private formatDuration(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  // === ITEM SEARCH ===
  private setupItemSearch() {
    document.getElementById('item-search-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const query = (document.getElementById('item-search-query') as HTMLInputElement)?.value.trim();
      if (!query) return;

      this.showLoader(true);
      const items = await window.api.searchItems(query, 20);
      this.showLoader(false);
      this.renderItemSearchResults(items);
    });

    document.getElementById('item-id-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const itemId = parseInt((document.getElementById('item-id-input') as HTMLInputElement)?.value);
      if (!itemId) return;

      this.showLoader(true);
      const item = await window.api.getItemDetails(itemId);
      this.showLoader(false);
      this.renderItemDetails(item);
    });
  }

  private renderItemSearchResults(items: ItemDetails[]) {
    const container = document.getElementById('item-search-results')!;

    if (items.length === 0) {
      container.innerHTML = '<p class="no-data">No items found</p>';
      return;
    }

    container.innerHTML = `
      <div class="item-results-grid">
        ${items.map(item => `
          <div class="item-result-card" style="border-color: ${getItemQualityColor(item.quality)}" data-item-id="${item.id}">
            ${item.iconUrl ? `<img src="${item.iconUrl}" class="item-icon" alt="">` : '<div class="item-icon-placeholder"></div>'}
            <div class="item-info">
              <span class="item-name" style="color: ${getItemQualityColor(item.quality)}">${item.name}</span>
              <span class="item-type">${item.itemSubclass} ${item.inventoryType}</span>
              <span class="item-ilvl">Item Level ${item.itemLevel}</span>
            </div>
          </div>
        `).join('')}
      </div>
    `;

    // Click to view full details
    container.querySelectorAll('.item-result-card').forEach(card => {
      card.addEventListener('click', async () => {
        const itemId = parseInt((card as HTMLElement).dataset.itemId!);
        this.showLoader(true);
        const item = await window.api.getItemDetails(itemId);
        this.showLoader(false);
        this.renderItemDetails(item);
      });
    });
  }

  private renderItemDetails(item: ItemDetails | { error: string }) {
    const container = document.getElementById('item-details')!;

    if ('error' in item) {
      container.innerHTML = `<div class="error-box">${item.error}</div>`;
      return;
    }

    container.innerHTML = `
      <div class="item-detail-card" style="border-color: ${getItemQualityColor(item.quality)}">
        <div class="item-detail-header">
          ${item.iconUrl ? `<img src="${item.iconUrl}" class="item-detail-icon" alt="">` : ''}
          <div class="item-detail-main">
            <h2 style="color: ${getItemQualityColor(item.quality)}">${item.name}</h2>
            <span class="item-id">ID: ${item.id}</span>
          </div>
        </div>

        <div class="item-detail-body">
          <div class="item-meta">
            <span class="item-ilvl">Item Level ${item.itemLevel}</span>
            ${item.binding ? `<span class="item-binding">${item.binding.replace('_', ' ')}</span>` : ''}
            <span class="item-type">${item.itemClass} - ${item.itemSubclass}</span>
            <span class="item-slot">${item.inventoryType}</span>
            ${item.requiredLevel > 0 ? `<span class="req-level">Requires Level ${item.requiredLevel}</span>` : ''}
          </div>

          ${item.armor ? `<div class="item-armor">${item.armor} Armor</div>` : ''}

          ${item.weaponInfo ? `
            <div class="item-weapon">
              <span class="damage">${item.weaponInfo.damage.min} - ${item.weaponInfo.damage.max} Damage</span>
              <span class="speed">Speed ${item.weaponInfo.speed.toFixed(2)}</span>
              <span class="dps">(${item.weaponInfo.dps.toFixed(1)} DPS)</span>
            </div>
          ` : ''}

          ${item.stats && item.stats.length > 0 ? `
            <div class="item-stats">
              ${item.stats.map(s => `<div class="stat-line">+${s.value} ${s.type}</div>`).join('')}
            </div>
          ` : ''}

          ${item.socketInfo ? `
            <div class="item-sockets">
              ${item.socketInfo.sockets.map(s => `<span class="socket socket-${s.type.toLowerCase()}">${s.type} Socket</span>`).join('')}
              ${item.socketInfo.bonus ? `<span class="socket-bonus">Bonus: ${item.socketInfo.bonus}</span>` : ''}
            </div>
          ` : ''}

          ${item.spellEffects && item.spellEffects.length > 0 ? `
            <div class="item-effects">
              ${item.spellEffects.map(e => `<div class="effect-line"><span class="trigger">${e.trigger}:</span> ${e.description}</div>`).join('')}
            </div>
          ` : ''}

          ${item.setInfo ? `
            <div class="item-set">
              <h4 style="color: #1eff00">${item.setInfo.name}</h4>
              <div class="set-items">
                ${item.setInfo.items.map(i => `<span class="set-item">${i.name}</span>`).join('')}
              </div>
              <div class="set-bonuses">
                ${item.setInfo.bonuses.map(b => `<div class="set-bonus">(${b.threshold}) ${b.description}</div>`).join('')}
              </div>
            </div>
          ` : ''}

          ${item.description ? `<div class="item-flavor">"${item.description}"</div>` : ''}

          ${item.sellPrice ? `<div class="item-sell">Sell Price: ${formatNumber(item.sellPrice)} gold</div>` : ''}
        </div>
      </div>
    `;
  }
}

window.addEventListener('DOMContentLoaded', () => new App());
