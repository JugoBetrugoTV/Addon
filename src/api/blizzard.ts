/**
 * Blizzard API Client + Data Aggregation
 * Handles OAuth, player data, and generates sample data for features
 * that would require a backend (talent stats, meta rankings, etc.)
 */

import axios, { AxiosInstance } from 'axios';
import {
  Region, Character, PlayerProfile, RatingEntry, Achievement,
  AltCharacter, LeaderboardEntry, SpecBuild, MetaSnapshot, SpecRanking,
  TalentNode, CLASSES, GameMode, WowClass,
} from '../types/wow';

interface ApiConfig {
  clientId: string;
  clientSecret: string;
  region: Region;
}

export class BlizzardAPI {
  private config: ApiConfig;
  private token: string | null = null;
  private tokenExpiry: number = 0;
  private client: AxiosInstance;

  constructor(config: ApiConfig) {
    this.config = config;
    this.client = axios.create({ timeout: 15000 });
  }

  private async getToken(): Promise<string> {
    if (this.token && Date.now() < this.tokenExpiry - 60000) return this.token;

    const response = await this.client.post(
      `https://${this.config.region}.battle.net/oauth/token`,
      'grant_type=client_credentials',
      {
        auth: { username: this.config.clientId, password: this.config.clientSecret },
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );
    const token = response.data.access_token as string;
    this.token = token;
    this.tokenExpiry = Date.now() + response.data.expires_in * 1000;
    return token;
  }

  private async request<T>(endpoint: string, params: Record<string, string> = {}): Promise<T> {
    const token = await this.getToken();
    const response = await this.client.get<T>(
      `https://${this.config.region}.api.blizzard.com${endpoint}`,
      { params: { ...params, locale: 'en_US' }, headers: { Authorization: `Bearer ${token}` } }
    );
    return response.data;
  }

  /** Get full player profile with ratings, achievements, alts */
  async getPlayerProfile(name: string, realm: string): Promise<PlayerProfile | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-');
      const charSlug = name.toLowerCase();

      const [profile, media, pvpSummary] = await Promise.all([
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}`),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/character-media`).catch(() => null),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/pvp-summary`).catch(() => null),
      ]);

      const character: Character = {
        name: profile.name,
        realm: profile.realm.name,
        region: this.config.region,
        class: this.normalizeClass(profile.character_class.name),
        spec: profile.active_spec?.name || '',
        specId: profile.active_spec?.id || 0,
        faction: profile.faction.type.toLowerCase(),
        race: profile.race.name,
        level: profile.level,
        itemLevel: profile.equipped_item_level || 0,
        avatarUrl: media?.assets?.find((a: any) => a.key === 'avatar')?.value,
      };

      // Get ratings for each bracket
      const ratings = await this.getRatings(realmSlug, charSlug);

      // Get achievements
      const achievements = await this.getPvPAchievements(realmSlug, charSlug);

      // Generate sample rating history (would need backend tracking in production)
      const ratingHistory = this.generateSampleRatingHistory(ratings);

      // Generate sample alts (would need account-wide lookup in production)
      const alts = this.generateSampleAlts(character);

      return {
        character,
        ratings,
        ratingHistory,
        achievements,
        alts,
        honorLevel: pvpSummary?.honor_level || 0,
        honorableKills: pvpSummary?.honorable_kills || 0,
      };
    } catch (error) {
      console.error('Player profile fetch failed:', error);
      return null;
    }
  }

  private async getRatings(realmSlug: string, charSlug: string): Promise<RatingEntry[]> {
    const brackets = ['arena-2v2', 'arena-3v3', 'rbg', 'shuffle'];
    const ratings: RatingEntry[] = [];

    for (const bracket of brackets) {
      try {
        const data = await this.request<any>(
          `/profile/wow/character/${realmSlug}/${charSlug}/pvp-bracket/${bracket}`
        );
        ratings.push({
          bracket: bracket.replace('arena-', '').replace('shuffle', 'solo'),
          current: data.rating || 0,
          seasonHigh: data.season_match_statistics?.rating || data.rating || 0,
          allTimeHigh: data.rating || 0, // API doesn't provide all-time, would need tracking
          wins: data.season_match_statistics?.won || 0,
          losses: data.season_match_statistics?.lost || 0,
        });
      } catch {
        // Bracket not played
      }
    }
    return ratings;
  }

  private async getPvPAchievements(realmSlug: string, charSlug: string): Promise<Achievement[]> {
    try {
      const data = await this.request<any>(
        `/profile/wow/character/${realmSlug}/${charSlug}/achievements`
      );

      const pvpCategories = [15266, 15267, 15268, 15269, 15270]; // PvP achievement category IDs
      const achievements: Achievement[] = [];

      for (const ach of data.achievements || []) {
        if (this.isPvPAchievement(ach.achievement?.name || '')) {
          achievements.push({
            id: ach.achievement.id,
            name: ach.achievement.name,
            description: '',
            icon: '',
            earnedDate: ach.completed_timestamp
              ? new Date(ach.completed_timestamp).toISOString().split('T')[0]
              : '',
            category: this.getAchievementCategory(ach.achievement.name),
          });
        }
      }
      return achievements.slice(0, 20); // Limit to most relevant
    } catch {
      return [];
    }
  }

  private isPvPAchievement(name: string): boolean {
    const keywords = ['Gladiator', 'Duelist', 'Rival', 'Challenger', 'Combatant', 'Elite', 'Arena', 'Rated'];
    return keywords.some(kw => name.includes(kw));
  }

  private getAchievementCategory(name: string): Achievement['category'] {
    if (name.includes('Gladiator')) return 'gladiator';
    if (name.includes('Duelist')) return 'duelist';
    if (name.includes('Rival')) return 'rival';
    if (name.includes('Challenger')) return 'challenger';
    if (name.includes('Combatant')) return 'combatant';
    if (name.includes('Elite')) return 'elite';
    return 'other';
  }

  /** Get leaderboard with optional filters */
  async getLeaderboard(
    bracket: '2v2' | '3v3' | 'rbg' | 'shuffle',
    limit: number = 100
  ): Promise<LeaderboardEntry[]> {
    try {
      const seasonId = 38; // Current season
      const bracketSlug = bracket === 'shuffle' ? 'shuffle' : bracket === 'rbg' ? 'rbg' : bracket;

      const data = await this.request<any>(
        `/data/wow/pvp-season/${seasonId}/pvp-leaderboard/${bracketSlug}`
      );

      return (data.entries || []).slice(0, limit).map((entry: any, index: number) => ({
        rank: entry.rank || index + 1,
        character: {
          name: entry.character.name,
          realm: entry.character.realm.slug,
          region: this.config.region,
          class: 'warrior' as WowClass, // API doesn't include class
          spec: '',
          specId: 0,
          faction: entry.faction?.type?.toLowerCase() || 'alliance',
          race: '',
          level: 80,
          itemLevel: 0,
        },
        rating: entry.rating,
        wins: entry.season_match_statistics?.won || 0,
        losses: entry.season_match_statistics?.lost || 0,
        winRate: this.calcWinRate(
          entry.season_match_statistics?.won || 0,
          entry.season_match_statistics?.lost || 0
        ),
      }));
    } catch (error) {
      console.error('Leaderboard fetch failed:', error);
      return [];
    }
  }

  /** Get spec build data (sample data - would need external source in production) */
  getSpecBuild(specId: number, gameMode: GameMode): SpecBuild {
    // This would normally fetch from a backend that aggregates top player data
    return {
      specId,
      gameMode,
      talents: this.generateSampleTalents(),
      pvpTalents: this.generateSamplePvPTalents(),
      stats: [
        { stat: 'Versatility', percent: 45 },
        { stat: 'Haste', percent: 30 },
        { stat: 'Critical Strike', percent: 15 },
        { stat: 'Mastery', percent: 10 },
      ],
      gear: this.generateSampleGear(),
      enchants: [
        { slot: 'Weapon', name: 'Authority of Radiant Power', stat: 'Primary Stat', usagePercent: 78 },
        { slot: 'Chest', name: 'Crystalline Radiance', stat: 'Primary Stat', usagePercent: 92 },
        { slot: 'Cloak', name: 'Chant of Leeching Fangs', stat: 'Leech', usagePercent: 65 },
        { slot: 'Legs', name: 'Sunset Spellthread', stat: 'Int/Stam', usagePercent: 88 },
        { slot: 'Boots', name: 'Scout\'s March', stat: 'Speed', usagePercent: 71 },
        { slot: 'Ring', name: 'Cursed Versatility', stat: 'Versatility', usagePercent: 84 },
      ],
      gems: [
        { name: 'Culminating Blasphemite', stat: 'Primary + Crit', usagePercent: 67 },
        { name: 'Masterful Ruby', stat: 'Mastery', usagePercent: 45 },
        { name: 'Quick Emerald', stat: 'Haste', usagePercent: 38 },
      ],
      embellishments: [
        { name: 'Writhing Armor Banding', effect: 'Tentacle damage proc', usagePercent: 56 },
        { name: 'Potion Absorption Inhibitor', effect: 'Longer potion duration', usagePercent: 34 },
      ],
      races: [
        { name: 'Human', percent: 28 },
        { name: 'Night Elf', percent: 22 },
        { name: 'Orc', percent: 18 },
        { name: 'Blood Elf', percent: 15 },
        { name: 'Undead', percent: 12 },
      ],
      sampleSize: 50,
      lastUpdated: new Date().toISOString(),
    };
  }

  /** Get meta rankings (sample data) */
  getMetaRankings(gameMode: GameMode, role: 'dps' | 'healer' | 'tank' | 'all'): MetaSnapshot {
    const specs: SpecRanking[] = [];

    for (const cls of CLASSES) {
      for (const spec of cls.specs) {
        if (role !== 'all' && spec.role !== role) continue;

        specs.push({
          specId: spec.id,
          className: cls.name,
          specName: spec.name,
          classColor: cls.color,
          tier: this.randomTier(),
          representation: Math.random() * 10 + 1,
          winRate: 45 + Math.random() * 15,
          avgRating: 1800 + Math.floor(Math.random() * 600),
          trend: ['up', 'down', 'stable'][Math.floor(Math.random() * 3)] as any,
        });
      }
    }

    // Sort by representation
    specs.sort((a, b) => b.representation - a.representation);

    return {
      gameMode,
      role,
      specs,
      lastUpdated: new Date().toISOString(),
    };
  }

  // === Helper methods ===

  private normalizeClass(className: string): WowClass {
    return className.toLowerCase().replace(/\s+/g, '-') as WowClass;
  }

  private calcWinRate(wins: number, losses: number): number {
    const total = wins + losses;
    return total > 0 ? Math.round((wins / total) * 100) : 0;
  }

  private randomTier(): 'S' | 'A' | 'B' | 'C' | 'D' {
    const r = Math.random();
    if (r < 0.1) return 'S';
    if (r < 0.3) return 'A';
    if (r < 0.6) return 'B';
    if (r < 0.85) return 'C';
    return 'D';
  }

  private generateSampleTalents(): TalentNode[] {
    const talents: TalentNode[] = [];
    for (let row = 0; row < 10; row++) {
      for (let col = 0; col < 4; col++) {
        if (Math.random() > 0.3) {
          talents.push({
            id: row * 10 + col,
            name: `Talent ${row}-${col}`,
            icon: 'spell_nature_lightning',
            row, col,
            usagePercent: Math.floor(Math.random() * 100),
            maxRank: Math.random() > 0.7 ? 2 : 1,
            description: 'Sample talent description',
          });
        }
      }
    }
    return talents;
  }

  private generateSamplePvPTalents(): TalentNode[] {
    return Array.from({ length: 3 }, (_, i) => ({
      id: 1000 + i,
      name: `PvP Talent ${i + 1}`,
      icon: 'ability_pvp',
      row: 0, col: i,
      usagePercent: 60 + Math.floor(Math.random() * 40),
      maxRank: 1,
      description: 'PvP talent description',
    }));
  }

  private generateSampleGear(): any[] {
    const slots = ['Head', 'Neck', 'Shoulder', 'Chest', 'Waist', 'Legs', 'Feet', 'Wrist', 'Hands', 'Ring', 'Trinket', 'Weapon'];
    return slots.map((slot, i) => ({
      id: 200000 + i,
      name: `${slot} of the Champion`,
      slot,
      icon: 'inv_helm_plate_raidpaladin',
      itemLevel: 639,
      usagePercent: 50 + Math.floor(Math.random() * 50),
      source: ['Raid', 'M+', 'PvP Vendor', 'Crafted'][Math.floor(Math.random() * 4)],
    }));
  }

  private generateSampleRatingHistory(ratings: RatingEntry[]): any[] {
    return ratings.map(r => ({
      bracket: r.bracket,
      data: Array.from({ length: 30 }, (_, i) => ({
        date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        rating: Math.max(0, r.current - 200 + Math.floor(Math.random() * 400) + i * 5),
      })),
    }));
  }

  private generateSampleAlts(main: Character): AltCharacter[] {
    if (Math.random() > 0.7) return []; // 30% chance of no alts
    const numAlts = Math.floor(Math.random() * 3) + 1;
    return Array.from({ length: numAlts }, (_, i) => {
      const cls = CLASSES[Math.floor(Math.random() * CLASSES.length)];
      const spec = cls.specs[Math.floor(Math.random() * cls.specs.length)];
      return {
        name: `Alt${i + 1}`,
        realm: main.realm,
        class: cls.id,
        spec: spec.name,
        ratings: [
          { bracket: '2v2', current: Math.floor(Math.random() * 1000) + 1400, high: Math.floor(Math.random() * 1200) + 1600 },
          { bracket: '3v3', current: Math.floor(Math.random() * 1000) + 1400, high: Math.floor(Math.random() * 1200) + 1600 },
        ],
      };
    });
  }

  setConfig(config: Partial<ApiConfig>): void {
    Object.assign(this.config, config);
    this.token = null;
  }
}

export function createAPI(config?: Partial<ApiConfig>): BlizzardAPI {
  return new BlizzardAPI({
    clientId: config?.clientId || '',
    clientSecret: config?.clientSecret || '',
    region: config?.region || 'eu',
  });
}
