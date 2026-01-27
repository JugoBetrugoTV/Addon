/**
 * Blizzard API Client - Handles OAuth and API requests
 * Requires client_id and client_secret from https://develop.battle.net/
 */

import axios, { AxiosInstance } from 'axios';
import { Region, Character, PvPStats, LeaderboardEntry, PvPRating } from '../types/wow';

interface TokenResponse {
  access_token: string;
  expires_in: number;
}

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
    this.client = axios.create({
      timeout: 15000,
    });
  }

  /** Get or refresh OAuth token */
  private async getToken(): Promise<string> {
    if (this.token && Date.now() < this.tokenExpiry - 60000) {
      return this.token;
    }

    const authUrl = `https://${this.config.region}.battle.net/oauth/token`;
    const response = await this.client.post<TokenResponse>(
      authUrl,
      'grant_type=client_credentials',
      {
        auth: {
          username: this.config.clientId,
          password: this.config.clientSecret,
        },
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );

    this.token = response.data.access_token;
    this.tokenExpiry = Date.now() + response.data.expires_in * 1000;
    return this.token;
  }

  private get apiHost(): string {
    return `https://${this.config.region}.api.blizzard.com`;
  }

  private async request<T>(endpoint: string, params: Record<string, string> = {}): Promise<T> {
    const token = await this.getToken();
    const response = await this.client.get<T>(`${this.apiHost}${endpoint}`, {
      params: { ...params, locale: 'en_US' },
      headers: { Authorization: `Bearer ${token}` },
    });
    return response.data;
  }

  /** Search for a character by name */
  async searchCharacter(name: string, realm: string): Promise<Character | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-');
      const charSlug = name.toLowerCase();

      const profile = await this.request<any>(
        `/profile/wow/character/${realmSlug}/${charSlug}`
      );

      const media = await this.request<any>(
        `/profile/wow/character/${realmSlug}/${charSlug}/character-media`
      ).catch(() => null);

      return {
        name: profile.name,
        realm: profile.realm.name,
        region: this.config.region,
        class: this.normalizeClass(profile.character_class.name),
        spec: profile.active_spec?.name || 'Unknown',
        faction: profile.faction.type.toLowerCase(),
        race: profile.race.name,
        level: profile.level,
        itemLevel: profile.equipped_item_level || 0,
        avatarUrl: media?.assets?.find((a: any) => a.key === 'avatar')?.value,
      };
    } catch (error) {
      console.error('Character search failed:', error);
      return null;
    }
  }

  /** Get PvP statistics for a character */
  async getPvPStats(name: string, realm: string): Promise<PvPStats | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-');
      const charSlug = name.toLowerCase();

      const [summary, brackets] = await Promise.all([
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/pvp-summary`),
        this.getPvPBrackets(realmSlug, charSlug),
      ]);

      return {
        honorableKills: summary.honorable_kills || 0,
        honorLevel: summary.honor_level || 0,
        ratings: brackets,
      };
    } catch (error) {
      console.error('PvP stats fetch failed:', error);
      return null;
    }
  }

  private async getPvPBrackets(realmSlug: string, charSlug: string): Promise<PvPRating[]> {
    const brackets: ('2v2' | '3v3' | 'rbg' | 'shuffle')[] = ['2v2', '3v3', 'rbg'];
    const ratings: PvPRating[] = [];

    for (const bracket of brackets) {
      try {
        const bracketSlug = bracket === 'rbg' ? 'rbg' : `arena-${bracket}`;
        const data = await this.request<any>(
          `/profile/wow/character/${realmSlug}/${charSlug}/pvp-bracket/${bracketSlug}`
        );

        ratings.push({
          bracket,
          rating: data.rating || 0,
          seasonHighest: data.season_match_statistics?.rating || data.rating || 0,
          weeklyWins: data.weekly_match_statistics?.won || 0,
          weeklyLosses: data.weekly_match_statistics?.lost || 0,
          seasonWins: data.season_match_statistics?.won || 0,
          seasonLosses: data.season_match_statistics?.lost || 0,
        });
      } catch {
        // Bracket not played
      }
    }

    return ratings;
  }

  /** Get PvP leaderboard for a bracket */
  async getLeaderboard(bracket: '2v2' | '3v3' | 'rbg', season?: number): Promise<LeaderboardEntry[]> {
    try {
      const seasonId = season || 37; // Current season
      const bracketSlug = bracket === 'rbg' ? 'rbg' : `${bracket}`;

      const data = await this.request<any>(
        `/data/wow/pvp-season/${seasonId}/pvp-leaderboard/${bracketSlug}`
      );

      return (data.entries || []).slice(0, 100).map((entry: any, index: number) => ({
        rank: entry.rank || index + 1,
        character: {
          name: entry.character.name,
          realm: entry.character.realm.slug,
          region: this.config.region,
          class: 'warrior' as any, // API doesn't include class in leaderboard
          spec: '',
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

  private calcWinRate(wins: number, losses: number): number {
    const total = wins + losses;
    return total > 0 ? Math.round((wins / total) * 100) : 0;
  }

  private normalizeClass(className: string): any {
    return className.toLowerCase().replace(/\s+/g, '-');
  }

  /** Update configuration */
  setConfig(config: Partial<ApiConfig>): void {
    Object.assign(this.config, config);
    this.token = null; // Force re-auth on next request
  }
}

/** Create API instance with saved or default config */
export function createAPI(config?: Partial<ApiConfig>): BlizzardAPI {
  return new BlizzardAPI({
    clientId: config?.clientId || '',
    clientSecret: config?.clientSecret || '',
    region: config?.region || 'eu',
  });
}
