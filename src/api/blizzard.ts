/**
 * Blizzard API Client - Full implementation for WoW PvP data
 * Connects to all relevant Blizzard API endpoints for player profiles,
 * equipment, talents, statistics, achievements, and leaderboards.
 */

import axios, { AxiosInstance } from 'axios';
import {
  Region, Character, PlayerProfile, RatingEntry, Achievement,
  AltCharacter, LeaderboardEntry, LeaderboardResponse,
  SpecBuild, MetaSnapshot, SpecRanking, CharacterEquipment, CharacterStats,
  EquippedItem, TalentLoadout, TalentNode, RatingHistory,
  CLASSES, GameMode, WowClass, GAME_MODES, getSpecInfo, normalizeClassName,
  formatWinRate, getBracketName, getTierForRating, getClassById,
  ActivityTracker, ActivityEntry, RepresentationStats, ClassRepresentation,
  TopPlayer, TopPlayersResponse, TalentHeatmap, TalentHeatmapNode,
  GearAnalysis, PopularItem, PopularEnchant, PopularGem, PopularEmbellishment,
  LFGListing, LFGFilters, LFGPost, StoredPlayerData, LocalDatabase,
  getRaceName, getRaceFaction, RACES,
  // New imports for additional API features
  GuildInfo, GuildRoster, GuildMember, GuildAchievements, GuildAchievement,
  MythicPlusProfile, MythicPlusRun, MythicPlusDungeon, MythicPlusAffixes,
  MythicPlusLeaderboardEntry,
  SpellDetails, PvPTalentDetails, TalentTree, TalentTreeNode,
  ItemDetails,
  RaidProgress, RaidInstance, RaidBoss, CharacterRaidProgress,
  CharacterSummary,
} from '../types/wow';

interface ApiConfig {
  clientId: string;
  clientSecret: string;
  region: Region;
}

interface CachedData<T> {
  data: T;
  timestamp: number;
}

export class BlizzardAPI {
  private config: ApiConfig;
  private token: string | null = null;
  private tokenExpiry: number = 0;
  private client: AxiosInstance;
  private cache: Map<string, CachedData<any>> = new Map();
  private currentSeasonId: number | null = null;
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  constructor(config: ApiConfig) {
    this.config = config;
    this.client = axios.create({ timeout: 20000 });
  }

  // === OAuth Token ===

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

  // === API Request Helpers ===

  private async request<T>(endpoint: string, params: Record<string, string> = {}, namespace?: string): Promise<T> {
    const token = await this.getToken();
    const ns = namespace || `profile-${this.config.region}`;
    const response = await this.client.get<T>(
      `https://${this.config.region}.api.blizzard.com${endpoint}`,
      {
        params: { ...params, locale: 'en_US', namespace: ns },
        headers: { Authorization: `Bearer ${token}` },
      }
    );
    return response.data;
  }

  private async requestCached<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
      return cached.data;
    }
    const data = await fetcher();
    this.cache.set(key, { data, timestamp: Date.now() });
    return data;
  }

  // === Current PvP Season ===

  async getCurrentSeasonId(): Promise<number> {
    if (this.currentSeasonId !== null) return this.currentSeasonId;

    try {
      const data = await this.request<any>(
        '/data/wow/pvp-season/index',
        {},
        `dynamic-${this.config.region}`
      );
      const seasonId = data.current_season?.id || 38;
      this.currentSeasonId = seasonId;
      return seasonId;
    } catch {
      return 38; // Fallback to known season
    }
  }

  // === Player Profile (Full) ===

  async getPlayerProfile(name: string, realm: string): Promise<PlayerProfile | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-').replace(/'/g, '');
      const charSlug = name.toLowerCase();

      // Fetch all character data in parallel
      const [profile, media, pvpSummary, equipment, stats, specializations, achievements] = await Promise.all([
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}`),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/character-media`).catch(() => null),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/pvp-summary`).catch(() => null),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/equipment`).catch(() => null),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/statistics`).catch(() => null),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/specializations`).catch(() => null),
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/achievements`).catch(() => null),
      ]);

      // Parse character info
      const character = this.parseCharacter(profile, media, realmSlug);

      // Get PvP ratings for all brackets
      const ratings = await this.getRatings(realmSlug, charSlug);

      // Parse achievements
      const pvpAchievements = this.parsePvPAchievements(achievements);

      // Parse equipment
      const characterEquipment = equipment ? this.parseEquipment(equipment) : undefined;

      // Parse stats
      const characterStats = stats ? this.parseStats(stats) : undefined;

      // Parse talents
      const talents = specializations ? this.parseTalents(specializations, profile) : undefined;

      // Get rating history (stored locally in production)
      const ratingHistory = this.generateRatingHistory(ratings);

      // Get alts (would require account-wide API in production)
      const alts: AltCharacter[] = [];

      // Find highest PvP tier
      const highestRating = Math.max(...ratings.map(r => r.seasonHigh), 0);
      const highestTier = getTierForRating(highestRating);

      return {
        character,
        ratings,
        ratingHistory,
        achievements: pvpAchievements,
        alts,
        equipment: characterEquipment,
        stats: characterStats,
        talents,
        honorLevel: pvpSummary?.honor_level || 0,
        honorableKills: pvpSummary?.honorable_kills || 0,
        highestPvPTier: highestTier.name,
      };
    } catch (error: any) {
      console.error('Player profile fetch failed:', error.message);
      return null;
    }
  }

  private parseCharacter(profile: any, media: any, realmSlug: string): Character {
    const avatarAsset = media?.assets?.find((a: any) => a.key === 'avatar');
    const insetAsset = media?.assets?.find((a: any) => a.key === 'inset');
    const mainRawAsset = media?.assets?.find((a: any) => a.key === 'main-raw');

    return {
      name: profile.name,
      realm: profile.realm.name,
      realmSlug,
      region: this.config.region,
      class: normalizeClassName(profile.character_class.name),
      className: profile.character_class.name,
      spec: profile.active_spec?.name || '',
      specId: profile.active_spec?.id || 0,
      faction: profile.faction.type.toLowerCase() as 'alliance' | 'horde',
      race: profile.race.name,
      level: profile.level,
      itemLevel: profile.average_item_level || 0,
      equippedItemLevel: profile.equipped_item_level || 0,
      avatarUrl: avatarAsset?.value,
      insetUrl: insetAsset?.value,
      mainRawUrl: mainRawAsset?.value,
      guild: profile.guild ? {
        name: profile.guild.name,
        realm: profile.guild.realm.name,
        faction: profile.faction.type.toLowerCase(),
      } : undefined,
      title: profile.active_title?.display_string?.replace('{name}', profile.name),
      achievementPoints: profile.achievement_points,
      lastLogin: profile.last_login_timestamp
        ? new Date(profile.last_login_timestamp).toISOString()
        : undefined,
    };
  }

  // === PvP Ratings ===

  private async getRatings(realmSlug: string, charSlug: string): Promise<RatingEntry[]> {
    const brackets = [
      { api: 'shuffle', name: 'Solo Shuffle' },
      { api: 'arena-2v2', name: '2v2 Arena' },
      { api: 'arena-3v3', name: '3v3 Arena' },
      { api: 'rbg', name: 'Rated BG' },
      { api: 'battlegrounds/blitz', name: 'Blitz' },
    ];

    const ratings: RatingEntry[] = [];

    const results = await Promise.allSettled(
      brackets.map(b =>
        this.request<any>(`/profile/wow/character/${realmSlug}/${charSlug}/pvp-bracket/${b.api}`)
      )
    );

    for (let i = 0; i < brackets.length; i++) {
      const result = results[i];
      const bracket = brackets[i];

      if (result.status === 'fulfilled' && result.value) {
        const data = result.value;
        const wins = data.season_match_statistics?.won || 0;
        const losses = data.season_match_statistics?.lost || 0;
        const current = data.rating || 0;
        const seasonBest = data.season_best_rating || current;
        const weeklyBest = data.weekly_match_statistics?.best_rating || current;
        const tier = getTierForRating(current);

        ratings.push({
          bracket: bracket.api.replace('arena-', '').replace('battlegrounds/', ''),
          bracketName: bracket.name,
          current,
          seasonHigh: seasonBest,
          weeklyHigh: weeklyBest,
          allTimeHigh: seasonBest, // API doesn't provide, would need local tracking
          wins,
          losses,
          winRate: formatWinRate(wins, losses),
          tier: { id: tier.id, name: tier.name },
          rank: data.rank,
        });
      }
    }

    return ratings;
  }

  // === Equipment ===

  private parseEquipment(data: any): CharacterEquipment {
    const items: EquippedItem[] = [];

    for (const item of data.equipped_items || []) {
      const stats: { type: string; value: number }[] = [];
      for (const stat of item.stats || []) {
        stats.push({
          type: stat.type?.name || stat.type?.type || 'Unknown',
          value: stat.value || 0,
        });
      }

      const gems: { id: number; name: string; icon: string }[] = [];
      for (const socket of item.sockets || []) {
        if (socket.item) {
          gems.push({
            id: socket.item.id,
            name: socket.item.name || 'Gem',
            icon: socket.display_string || '',
          });
        }
      }

      items.push({
        id: item.item?.id || 0,
        name: item.name || 'Unknown Item',
        slot: item.slot?.name || 'Unknown',
        slotType: item.slot?.type || 'UNKNOWN',
        icon: item.media?.assets?.[0]?.value || '',
        itemLevel: item.level?.value || 0,
        quality: (item.quality?.type?.toLowerCase() || 'common') as EquippedItem['quality'],
        stats,
        enchant: item.enchantments?.[0] ? {
          id: item.enchantments[0].enchantment_id || 0,
          name: item.enchantments[0].display_string || 'Enchant',
          description: item.enchantments[0].source_item?.name || '',
        } : undefined,
        gems: gems.length > 0 ? gems : undefined,
        setInfo: item.set ? {
          name: item.set.item_set?.name || 'Set',
          itemsEquipped: item.set.items?.filter((i: any) => i.is_equipped).length || 0,
          itemsRequired: item.set.items?.length || 0,
        } : undefined,
        bonusIds: item.bonus_list,
      });
    }

    return {
      items,
      averageItemLevel: data.character?.average_item_level || 0,
      equippedItemLevel: data.character?.equipped_item_level || 0,
    };
  }

  // === Character Stats ===

  private parseStats(data: any): CharacterStats {
    return {
      health: data.health || 0,
      power: data.power || 0,
      powerType: data.power_type?.name || 'Mana',
      primaryStat: {
        name: this.getPrimaryStat(data),
        value: data.intellect?.effective || data.agility?.effective || data.strength?.effective || 0,
        bonus: data.intellect?.bonus || data.agility?.bonus || data.strength?.bonus || 0,
      },
      stamina: {
        value: data.stamina?.effective || 0,
        bonus: data.stamina?.bonus || 0,
      },
      criticalStrike: {
        rating: data.melee_crit?.rating || data.spell_crit?.rating || 0,
        percent: data.melee_crit?.value || data.spell_crit?.value || 0,
      },
      haste: {
        rating: data.melee_haste?.rating || data.spell_haste?.rating || 0,
        percent: data.melee_haste?.value || data.spell_haste?.value || 0,
      },
      mastery: {
        rating: data.mastery?.rating || 0,
        percent: data.mastery?.value || 0,
      },
      versatility: {
        rating: data.versatility || 0,
        damagePercent: data.versatility_damage_done_bonus || 0,
        healingPercent: data.versatility_healing_done_bonus || 0,
        drPercent: data.versatility_damage_taken_bonus || 0,
      },
      leech: {
        rating: data.lifesteal?.rating || 0,
        percent: data.lifesteal?.value || 0,
      },
      avoidance: {
        rating: data.avoidance?.rating || 0,
        percent: data.avoidance?.value || 0,
      },
      speed: {
        rating: data.speed?.rating || 0,
        percent: data.speed?.value || 0,
      },
      armor: data.armor?.effective || 0,
      dodgePercent: data.dodge?.value || 0,
      parryPercent: data.parry?.value || 0,
      blockPercent: data.block?.value || 0,
    };
  }

  private getPrimaryStat(data: any): string {
    if (data.intellect?.effective > (data.agility?.effective || 0) &&
        data.intellect?.effective > (data.strength?.effective || 0)) {
      return 'Intellect';
    }
    if (data.agility?.effective > (data.strength?.effective || 0)) {
      return 'Agility';
    }
    return 'Strength';
  }

  // === Talents ===

  private parseTalents(data: any, profile: any): TalentLoadout {
    const activeSpec = data.active_specialization;
    const specId = activeSpec?.id || profile.active_spec?.id || 0;
    const specInfo = getSpecInfo(specId);

    const classTalents: TalentNode[] = [];
    const specTalents: TalentNode[] = [];
    const heroTalents: TalentNode[] = [];
    const pvpTalents: TalentNode[] = [];

    // Find active loadout
    const activeLoadout = data.specializations?.find((s: any) =>
      s.specialization?.id === specId
    );

    if (activeLoadout) {
      // Parse selected talents
      for (const selected of activeLoadout.loadouts?.[0]?.selected_class_talents || []) {
        classTalents.push(this.parseTalentNode(selected, 'class'));
      }
      for (const selected of activeLoadout.loadouts?.[0]?.selected_spec_talents || []) {
        specTalents.push(this.parseTalentNode(selected, 'spec'));
      }
      for (const selected of activeLoadout.loadouts?.[0]?.selected_hero_talents || []) {
        heroTalents.push(this.parseTalentNode(selected, 'hero'));
      }

      // Parse PvP talents
      for (const pvp of activeLoadout.pvp_talent_slots || []) {
        if (pvp.selected?.talent) {
          pvpTalents.push({
            id: pvp.selected.talent.id,
            name: pvp.selected.talent.name || 'PvP Talent',
            icon: '',
            row: pvp.slot_number || 0,
            col: 0,
            usagePercent: 100,
            maxRank: 1,
            currentRank: 1,
            description: pvp.selected.spell_tooltip?.description || '',
            type: 'pvp',
          });
        }
      }
    }

    return {
      specId,
      className: specInfo?.className || '',
      specName: specInfo?.name || '',
      classTalents,
      specTalents,
      heroTalents,
      pvpTalents,
    };
  }

  private parseTalentNode(data: any, type: 'class' | 'spec' | 'hero'): TalentNode {
    return {
      id: data.talent?.id || data.id || 0,
      name: data.talent?.name || data.name || 'Talent',
      icon: '',
      row: data.tooltip?.talent?.tier_index || 0,
      col: data.tooltip?.talent?.column_index || 0,
      usagePercent: 100,
      maxRank: data.talent?.rank || 1,
      currentRank: data.rank || 1,
      description: data.tooltip?.spell_tooltip?.description || '',
      type,
    };
  }

  // === Achievements ===

  private parsePvPAchievements(data: any): Achievement[] {
    if (!data?.achievements) return [];

    const pvpKeywords = [
      'Gladiator', 'Legend', 'Duelist', 'Rival', 'Challenger', 'Combatant',
      'Elite', 'Arena', 'Rated', 'Hero of the', 'Soldier of the',
      'Veteran of the', 'Battlemaster', 'Warlord', 'High Warlord',
      'Grand Marshal', 'Khan', 'of the Alliance', 'of the Horde',
    ];

    const achievements: Achievement[] = [];

    for (const ach of data.achievements) {
      const name = ach.achievement?.name || '';
      const isPvP = pvpKeywords.some(kw => name.includes(kw));

      if (isPvP && ach.completed_timestamp) {
        achievements.push({
          id: ach.achievement.id,
          name,
          description: ach.achievement.description || '',
          icon: '',
          earnedDate: new Date(ach.completed_timestamp).toISOString().split('T')[0],
          points: ach.achievement.points || 0,
          category: this.getAchievementCategory(name),
          isAccountWide: ach.achievement.is_account_wide || false,
        });
      }
    }

    // Sort by date (newest first) and limit
    achievements.sort((a, b) => new Date(b.earnedDate).getTime() - new Date(a.earnedDate).getTime());
    return achievements.slice(0, 50);
  }

  private getAchievementCategory(name: string): Achievement['category'] {
    if (name.includes('Legend')) return 'legend';
    if (name.includes('Gladiator')) return 'gladiator';
    if (name.includes('Hero of the')) return 'hero';
    if (name.includes('Duelist')) return 'duelist';
    if (name.includes('Rival')) return 'rival';
    if (name.includes('Challenger')) return 'challenger';
    if (name.includes('Combatant')) return 'combatant';
    if (name.includes('Elite')) return 'elite';
    return 'other';
  }

  // === Leaderboard ===

  async getLeaderboard(
    bracket: GameMode,
    filters?: { page?: number; pageSize?: number }
  ): Promise<LeaderboardResponse> {
    try {
      const seasonId = await this.getCurrentSeasonId();
      const gameMode = GAME_MODES.find(m => m.id === bracket);
      const bracketSlug = gameMode?.bracket || bracket;

      const data = await this.request<any>(
        `/data/wow/pvp-season/${seasonId}/pvp-leaderboard/${bracketSlug}`,
        {},
        `dynamic-${this.config.region}`
      );

      const page = filters?.page || 1;
      const pageSize = filters?.pageSize || 100;
      const start = (page - 1) * pageSize;
      const entries = (data.entries || []).slice(start, start + pageSize);

      const leaderboardEntries: LeaderboardEntry[] = entries.map((entry: any) => {
        const wins = entry.season_match_statistics?.won || 0;
        const losses = entry.season_match_statistics?.lost || 0;
        const tier = getTierForRating(entry.rating);

        return {
          rank: entry.rank,
          character: {
            name: entry.character.name,
            realm: entry.character.realm?.name || entry.character.realm?.slug || '',
            realmSlug: entry.character.realm?.slug || '',
            region: this.config.region,
            faction: (entry.faction?.type?.toLowerCase() || 'alliance') as 'alliance' | 'horde',
          },
          rating: entry.rating,
          wins,
          losses,
          winRate: formatWinRate(wins, losses),
          tier: { id: tier.id, name: tier.name },
        };
      });

      return {
        bracket: bracketSlug,
        season: seasonId,
        entries: leaderboardEntries,
        totalCount: data.entries?.length || 0,
        lastUpdated: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error('Leaderboard fetch failed:', error.message);
      return {
        bracket,
        season: 0,
        entries: [],
        totalCount: 0,
        lastUpdated: new Date().toISOString(),
      };
    }
  }

  // Fetch character info for leaderboard entries (batch)
  async enrichLeaderboardWithClasses(entries: LeaderboardEntry[]): Promise<LeaderboardEntry[]> {
    const enriched = await Promise.allSettled(
      entries.slice(0, 20).map(async (entry) => {
        try {
          const profile = await this.request<any>(
            `/profile/wow/character/${entry.character.realmSlug}/${entry.character.name.toLowerCase()}`
          );
          return {
            ...entry,
            character: {
              ...entry.character,
              class: normalizeClassName(profile.character_class?.name || ''),
              className: profile.character_class?.name,
              spec: profile.active_spec?.name,
              specId: profile.active_spec?.id,
              race: profile.race?.name,
            },
          };
        } catch {
          return entry;
        }
      })
    );

    return enriched.map((r, i) =>
      r.status === 'fulfilled' ? r.value : entries[i]
    );
  }

  // === Spec Build (Aggregated Data - would need backend in production) ===

  async getSpecBuild(specId: number, gameMode: GameMode): Promise<SpecBuild> {
    const specInfo = getSpecInfo(specId);
    if (!specInfo) {
      throw new Error(`Unknown spec ID: ${specId}`);
    }

    // In production, this would fetch from a backend that aggregates top player data
    // For now, generate realistic sample data based on the spec
    return {
      specId,
      className: specInfo.className,
      specName: specInfo.name,
      classColor: specInfo.classColor,
      gameMode,
      talents: this.generateSampleTalentLoadout(specId, specInfo),
      statPriority: this.generateStatPriority(specInfo.role),
      gear: this.generateGearRecommendations(),
      enchants: this.generateEnchantRecommendations(),
      gems: this.generateGemRecommendations(),
      embellishments: this.generateEmbellishmentRecommendations(),
      racialDistribution: this.generateRacialDistribution(),
      sampleSize: 50,
      lastUpdated: new Date().toISOString(),
    };
  }

  private generateSampleTalentLoadout(specId: number, specInfo: any): TalentLoadout {
    return {
      specId,
      className: specInfo.className,
      specName: specInfo.name,
      classTalents: this.generateTalentNodes(10, 'class'),
      specTalents: this.generateTalentNodes(10, 'spec'),
      heroTalents: this.generateTalentNodes(5, 'hero'),
      pvpTalents: this.generateTalentNodes(3, 'pvp'),
    };
  }

  private generateTalentNodes(count: number, type: 'class' | 'spec' | 'hero' | 'pvp'): TalentNode[] {
    const talents: TalentNode[] = [];
    for (let i = 0; i < count; i++) {
      talents.push({
        id: Math.floor(Math.random() * 100000),
        name: `${type.charAt(0).toUpperCase() + type.slice(1)} Talent ${i + 1}`,
        icon: 'spell_nature_lightning',
        row: Math.floor(i / 4),
        col: i % 4,
        usagePercent: 50 + Math.floor(Math.random() * 50),
        maxRank: Math.random() > 0.7 ? 2 : 1,
        currentRank: 1,
        description: 'Talent description',
        type,
      });
    }
    return talents;
  }

  private generateStatPriority(role: string): any[] {
    const priorities = role === 'healer'
      ? ['Versatility', 'Haste', 'Critical Strike', 'Mastery']
      : role === 'tank'
      ? ['Versatility', 'Mastery', 'Haste', 'Critical Strike']
      : ['Versatility', 'Haste', 'Mastery', 'Critical Strike'];

    return priorities.map((stat, i) => ({
      stat,
      percent: [45, 30, 15, 10][i],
      avgRating: [400, 300, 200, 100][i],
    }));
  }

  private generateGearRecommendations(): any[] {
    const slots = ['Head', 'Neck', 'Shoulder', 'Chest', 'Waist', 'Legs', 'Feet', 'Wrist', 'Hands', 'Finger', 'Trinket', 'Main Hand'];
    return slots.map(slot => ({
      slot,
      items: [{
        id: 200000 + Math.floor(Math.random() * 10000),
        name: `${slot} of the Gladiator`,
        icon: 'inv_helm_plate_raidpaladin',
        itemLevel: 639,
        usagePercent: 60 + Math.floor(Math.random() * 40),
        source: ['PvP Vendor', 'Raid', 'M+', 'Crafted'][Math.floor(Math.random() * 4)],
      }],
    }));
  }

  private generateEnchantRecommendations(): any[] {
    return [
      { slot: 'Weapon', enchants: [{ id: 1, name: 'Authority of Radiant Power', stat: 'Primary Stat', usagePercent: 78 }] },
      { slot: 'Chest', enchants: [{ id: 2, name: 'Crystalline Radiance', stat: 'Primary Stat', usagePercent: 95 }] },
      { slot: 'Back', enchants: [{ id: 3, name: 'Chant of Burrowing Rapidity', stat: 'Speed', usagePercent: 80 }] },
      { slot: 'Wrist', enchants: [{ id: 4, name: 'Chant of Armored Speed', stat: 'Speed', usagePercent: 75 }] },
      { slot: 'Legs', enchants: [{ id: 5, name: 'Sunset Spellthread', stat: 'Int/Stam', usagePercent: 88 }] },
      { slot: 'Boots', enchants: [{ id: 6, name: "Scout's March", stat: 'Speed', usagePercent: 82 }] },
      { slot: 'Ring', enchants: [{ id: 7, name: 'Cursed Versatility', stat: 'Versatility', usagePercent: 90 }] },
    ];
  }

  private generateGemRecommendations(): any[] {
    return [
      { type: 'Algari Diamond', gems: [{ id: 1, name: 'Culminating Blasphemite', stat: 'Primary + Crit', usagePercent: 72 }] },
      { type: 'Prismatic', gems: [
        { id: 2, name: 'Versatile Onyx', stat: 'Versatility', usagePercent: 65 },
        { id: 3, name: 'Quick Emerald', stat: 'Haste', usagePercent: 25 },
      ] },
    ];
  }

  private generateEmbellishmentRecommendations(): any[] {
    return [
      { name: 'Elemental Focusing Lens', effect: 'Damage proc on abilities', usagePercent: 75 },
      { name: 'Duskthread Lining', effect: 'Versatility when above 80% health', usagePercent: 35 },
      { name: 'Writhing Armor Banding', effect: 'Tentacle damage proc', usagePercent: 28 },
    ];
  }

  private generateRacialDistribution(): any[] {
    return [
      { race: 'Human', faction: 'alliance', percent: 22 },
      { race: 'Night Elf', faction: 'alliance', percent: 18 },
      { race: 'Orc', faction: 'horde', percent: 16 },
      { race: 'Blood Elf', faction: 'horde', percent: 14 },
      { race: 'Undead', faction: 'horde', percent: 12 },
      { race: 'Pandaren', faction: 'both', percent: 8 },
      { race: 'Void Elf', faction: 'alliance', percent: 6 },
      { race: 'Other', faction: 'both', percent: 4 },
    ];
  }

  // === Meta Rankings ===

  async getMetaRankings(gameMode: GameMode, role: 'dps' | 'healer' | 'tank' | 'all'): Promise<MetaSnapshot> {
    // In production, this would aggregate data from leaderboards
    // For now, generate realistic sample data
    const specs: SpecRanking[] = [];

    for (const cls of CLASSES) {
      for (const spec of cls.specs) {
        if (role !== 'all' && spec.role !== role) continue;

        const representation = 1 + Math.random() * 12;
        const winRate = 45 + Math.random() * 15;

        specs.push({
          specId: spec.id,
          className: cls.name,
          specName: spec.name,
          classColor: cls.color,
          tier: this.calculateTier(representation, winRate),
          representation,
          winRate,
          avgRating: 1800 + Math.floor(Math.random() * 600),
          gamesPlayed: Math.floor(Math.random() * 50000),
          trend: ['up', 'down', 'stable'][Math.floor(Math.random() * 3)] as any,
          changePercent: Math.random() * 5 - 2.5,
        });
      }
    }

    // Sort by representation
    specs.sort((a, b) => b.representation - a.representation);

    return {
      gameMode,
      role,
      specs,
      totalGames: specs.reduce((sum, s) => sum + s.gamesPlayed, 0),
      lastUpdated: new Date().toISOString(),
    };
  }

  private calculateTier(representation: number, winRate: number): 'S' | 'A' | 'B' | 'C' | 'D' {
    const score = representation * 0.7 + (winRate - 50) * 0.3;
    if (score > 10) return 'S';
    if (score > 7) return 'A';
    if (score > 4) return 'B';
    if (score > 1) return 'C';
    return 'D';
  }

  // === Rating History ===

  private generateRatingHistory(ratings: RatingEntry[]): RatingHistory[] {
    return ratings.map(r => ({
      bracket: r.bracket,
      data: Array.from({ length: 30 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - (29 - i));
        const baseRating = r.current > 0 ? r.current - 200 : 0;
        const variance = Math.floor(Math.random() * 300);
        const trend = i * 7; // Upward trend
        return {
          date: date.toISOString().split('T')[0],
          rating: Math.max(0, baseRating + variance + trend),
          wins: Math.floor(Math.random() * 10),
          losses: Math.floor(Math.random() * 8),
        };
      }),
    }));
  }

  // === Realm Search ===

  async searchRealms(query: string): Promise<{ id: number; name: string; slug: string }[]> {
    try {
      const data = await this.request<any>(
        '/data/wow/realm/index',
        {},
        `dynamic-${this.config.region}`
      );

      const realms = data.realms || [];
      const queryLower = query.toLowerCase();

      return realms
        .filter((r: any) => r.name.toLowerCase().includes(queryLower))
        .slice(0, 10)
        .map((r: any) => ({
          id: r.id,
          name: r.name,
          slug: r.slug,
        }));
    } catch {
      return [];
    }
  }

  // === Activity Tracker (Drustvar style) ===

  private leaderboardSnapshots: Map<string, { entries: LeaderboardEntry[]; timestamp: number }> = new Map();

  async getActivityTracker(bracket: GameMode): Promise<ActivityTracker> {
    const snapshotKey = `${this.config.region}-${bracket}`;
    const previous = this.leaderboardSnapshots.get(snapshotKey);
    const current = await this.getLeaderboard(bracket, { page: 1, pageSize: 5000 });

    // Store current snapshot for next comparison
    this.leaderboardSnapshots.set(snapshotKey, {
      entries: current.entries,
      timestamp: Date.now(),
    });

    const climbers: ActivityEntry[] = [];
    const fallers: ActivityEntry[] = [];
    const mostActive: ActivityEntry[] = [];
    const newEntries: ActivityEntry[] = [];

    // Build lookup maps
    const previousMap = new Map(
      (previous?.entries || []).map(e => [`${e.character.name}-${e.character.realmSlug}`, e])
    );

    for (const entry of current.entries.slice(0, 500)) {
      const key = `${entry.character.name}-${entry.character.realmSlug}`;
      const prev = previousMap.get(key);

      const activity: ActivityEntry = {
        rank: entry.rank,
        previousRank: prev?.rank || 0,
        rankChange: prev ? prev.rank - entry.rank : 0,
        character: {
          name: entry.character.name,
          realm: entry.character.realm,
          realmSlug: entry.character.realmSlug,
          region: this.config.region,
          class: entry.character.class || 'warrior',
          className: entry.character.className || 'Warrior',
          spec: entry.character.spec || '',
          faction: entry.character.faction,
        },
        rating: entry.rating,
        previousRating: prev?.rating || 0,
        ratingChange: prev ? entry.rating - prev.rating : entry.rating,
        wins: entry.wins,
        losses: entry.losses,
        gamesPlayed: entry.wins + entry.losses,
        timestamp: new Date().toISOString(),
      };

      if (!prev) {
        newEntries.push(activity);
      } else if (activity.ratingChange > 50) {
        climbers.push(activity);
      } else if (activity.ratingChange < -50) {
        fallers.push(activity);
      }

      mostActive.push(activity);
    }

    // Sort by relevant metrics
    climbers.sort((a, b) => b.ratingChange - a.ratingChange);
    fallers.sort((a, b) => a.ratingChange - b.ratingChange);
    mostActive.sort((a, b) => b.gamesPlayed - a.gamesPlayed);

    return {
      bracket,
      region: this.config.region,
      climbers: climbers.slice(0, 25),
      fallers: fallers.slice(0, 25),
      mostActive: mostActive.slice(0, 25),
      newEntries: newEntries.slice(0, 25),
      lastUpdated: new Date().toISOString(),
    };
  }

  // === Class Representation Stats ===

  async getRepresentationStats(bracket: GameMode, minRating: number = 0): Promise<RepresentationStats> {
    const leaderboard = await this.getLeaderboard(bracket, { page: 1, pageSize: 5000 });

    // Enrich with class data (first 100 for speed)
    const enriched = await this.enrichLeaderboardWithClasses(
      leaderboard.entries.filter(e => e.rating >= minRating).slice(0, 500)
    );

    const classStats = new Map<WowClass, { players: number; totalRating: number; specs: Map<number, { name: string; count: number; totalRating: number }> }>();
    const raceStats = new Map<string, { count: number; faction: string }>();
    let allianceCount = 0;
    let hordeCount = 0;

    for (const entry of enriched) {
      if (!entry.character.class) continue;

      const cls = entry.character.class;
      const classData = classStats.get(cls) || { players: 0, totalRating: 0, specs: new Map() };
      classData.players++;
      classData.totalRating += entry.rating;

      if (entry.character.specId) {
        const specData = classData.specs.get(entry.character.specId) || {
          name: entry.character.spec || 'Unknown',
          count: 0,
          totalRating: 0,
        };
        specData.count++;
        specData.totalRating += entry.rating;
        classData.specs.set(entry.character.specId, specData);
      }

      classStats.set(cls, classData);

      // Faction
      if (entry.character.faction === 'alliance') allianceCount++;
      else hordeCount++;

      // Race
      if (entry.character.race) {
        const raceData = raceStats.get(entry.character.race) || {
          count: 0,
          faction: entry.character.faction,
        };
        raceData.count++;
        raceStats.set(entry.character.race, raceData);
      }
    }

    const totalPlayers = enriched.length;
    const classes: ClassRepresentation[] = [];

    for (const cls of CLASSES) {
      const data = classStats.get(cls.id);
      if (!data) continue;

      const specs = Array.from(data.specs.entries()).map(([specId, specData]) => ({
        specId,
        specName: specData.name,
        players: specData.count,
        percentage: (specData.count / totalPlayers) * 100,
        avgRating: Math.round(specData.totalRating / specData.count),
      }));

      classes.push({
        class: cls.id,
        className: cls.name,
        classColor: cls.color,
        totalPlayers: data.players,
        percentage: (data.players / totalPlayers) * 100,
        avgRating: Math.round(data.totalRating / data.players),
        specs,
      });
    }

    classes.sort((a, b) => b.percentage - a.percentage);

    const raceSplit = Array.from(raceStats.entries()).map(([race, data]) => ({
      race,
      faction: data.faction,
      count: data.count,
      percentage: (data.count / totalPlayers) * 100,
    }));
    raceSplit.sort((a, b) => b.percentage - a.percentage);

    return {
      bracket,
      region: this.config.region,
      minRating,
      totalPlayers,
      classes,
      factionSplit: {
        alliance: (allianceCount / totalPlayers) * 100,
        horde: (hordeCount / totalPlayers) * 100,
      },
      raceSplit,
      lastUpdated: new Date().toISOString(),
    };
  }

  // === Top Players (Multi-bracket rankings) ===

  async getTopPlayers(limit: number = 50): Promise<TopPlayersResponse> {
    const brackets: GameMode[] = ['shuffle', '2v2', '3v3', 'rbg', 'blitz'];
    const leaderboards = await Promise.all(
      brackets.map(b => this.getLeaderboard(b, { page: 1, pageSize: 200 }))
    );

    // Aggregate player data across brackets
    const playerMap = new Map<string, {
      character: any;
      brackets: Map<GameMode, { rating: number; rank: number; wins: number; losses: number }>;
    }>();

    for (let i = 0; i < brackets.length; i++) {
      const bracket = brackets[i];
      for (const entry of leaderboards[i].entries) {
        const key = `${entry.character.name.toLowerCase()}-${entry.character.realmSlug}`;
        const existing = playerMap.get(key) || {
          character: entry.character,
          brackets: new Map(),
        };
        existing.brackets.set(bracket, {
          rating: entry.rating,
          rank: entry.rank,
          wins: entry.wins,
          losses: entry.losses,
        });
        playerMap.set(key, existing);
      }
    }

    // Calculate total rating score and create top players list
    const players: TopPlayer[] = [];
    for (const [_, data] of playerMap) {
      const bracketData = Array.from(data.brackets.entries()).map(([bracket, stats]) => ({
        bracket,
        ...stats,
      }));

      const totalRating = bracketData.reduce((sum, b) => sum + b.rating, 0);
      const avgRating = totalRating / bracketData.length;

      // Only include players with multiple brackets or high rating
      if (bracketData.length >= 2 || avgRating >= 2400) {
        players.push({
          rank: 0,
          character: {
            name: data.character.name,
            realm: data.character.realm,
            realmSlug: data.character.realmSlug,
            region: this.config.region,
            class: data.character.class || 'warrior',
            className: data.character.className || 'Warrior',
            spec: data.character.spec || '',
            faction: data.character.faction,
          },
          brackets: bracketData,
          totalRating,
        });
      }
    }

    // Sort by total rating and assign ranks
    players.sort((a, b) => b.totalRating - a.totalRating);
    players.forEach((p, i) => p.rank = i + 1);

    return {
      region: this.config.region,
      players: players.slice(0, limit),
      lastUpdated: new Date().toISOString(),
    };
  }

  // === Talent Heatmap (Aggregated from top players) ===

  async getTalentHeatmap(specId: number, bracket: GameMode): Promise<TalentHeatmap> {
    const specInfo = getSpecInfo(specId);
    if (!specInfo) throw new Error(`Unknown spec: ${specId}`);

    // In production, aggregate from top 50 players of this spec
    // For now, generate realistic sample data
    const classTalents = this.generateHeatmapNodes(20, 'class');
    const specTalents = this.generateHeatmapNodes(20, 'spec');
    const heroTalents = this.generateHeatmapNodes(10, 'hero');
    const pvpTalents = this.generateHeatmapNodes(6, 'pvp');

    return {
      specId,
      className: specInfo.className,
      specName: specInfo.name,
      classColor: specInfo.classColor,
      bracket,
      sampleSize: 50,
      classTalents,
      specTalents,
      heroTalents,
      pvpTalents,
      popularBuilds: [
        {
          name: 'Standard Build',
          pickRate: 65,
          talentString: 'BAAAAAAA...',
          description: 'Most popular build for ' + bracket,
        },
        {
          name: 'Burst Build',
          pickRate: 25,
          talentString: 'CAAAAAAA...',
          description: 'High burst damage variant',
        },
        {
          name: 'Survivability Build',
          pickRate: 10,
          talentString: 'DAAAAAAA...',
          description: 'Defensive focused build',
        },
      ],
      lastUpdated: new Date().toISOString(),
    };
  }

  private generateHeatmapNodes(count: number, type: 'class' | 'spec' | 'hero' | 'pvp'): TalentHeatmapNode[] {
    const nodes: TalentHeatmapNode[] = [];
    for (let i = 0; i < count; i++) {
      const pickRate = Math.random() * 100;
      nodes.push({
        nodeId: 10000 + i,
        talentId: 50000 + i,
        name: `${type.charAt(0).toUpperCase() + type.slice(1)} Talent ${i + 1}`,
        icon: 'spell_nature_lightning',
        row: Math.floor(i / 4),
        col: i % 4,
        type,
        pickRate,
        avgRank: pickRate > 50 ? 2 : 1,
        maxRank: Math.random() > 0.7 ? 2 : 1,
        popularity: pickRate > 80 ? 'meta' : pickRate > 50 ? 'common' : pickRate > 20 ? 'situational' : 'rare',
        description: 'Talent effect description',
      });
    }
    return nodes;
  }

  // === Gear Analysis (murlok.io style) ===

  async getGearAnalysis(specId: number, bracket: GameMode): Promise<GearAnalysis> {
    const specInfo = getSpecInfo(specId);
    if (!specInfo) throw new Error(`Unknown spec: ${specId}`);

    const slots = ['HEAD', 'NECK', 'SHOULDER', 'BACK', 'CHEST', 'WRIST', 'HANDS', 'WAIST', 'LEGS', 'FEET', 'FINGER_1', 'FINGER_2', 'TRINKET_1', 'TRINKET_2', 'MAIN_HAND', 'OFF_HAND'];
    const popularItems: Record<string, PopularItem[]> = {};

    for (const slot of slots) {
      popularItems[slot] = [
        {
          id: 200000 + Math.floor(Math.random() * 10000),
          name: `${slot.replace('_', ' ')} of the Gladiator`,
          icon: 'inv_helm_plate_raidpaladin',
          itemLevel: 636 + Math.floor(Math.random() * 10),
          quality: 'epic',
          pickRate: 40 + Math.floor(Math.random() * 50),
          source: ['PvP Vendor', 'Raid', 'M+', 'Crafted'][Math.floor(Math.random() * 4)],
          stats: [
            { type: 'Versatility', value: 200 + Math.floor(Math.random() * 100) },
            { type: 'Haste', value: 150 + Math.floor(Math.random() * 100) },
          ],
        },
        {
          id: 200000 + Math.floor(Math.random() * 10000),
          name: `${slot.replace('_', ' ')} of Conquest`,
          icon: 'inv_helm_plate_raidpaladin',
          itemLevel: 633 + Math.floor(Math.random() * 10),
          quality: 'epic',
          pickRate: 20 + Math.floor(Math.random() * 30),
          source: 'PvP Vendor',
          stats: [
            { type: 'Critical Strike', value: 180 + Math.floor(Math.random() * 100) },
            { type: 'Mastery', value: 160 + Math.floor(Math.random() * 100) },
          ],
        },
      ];
    }

    return {
      specId,
      className: specInfo.className,
      specName: specInfo.name,
      bracket,
      sampleSize: 50,
      avgItemLevel: 636,
      statPriority: [
        { stat: 'Versatility', avgPercentage: 35, avgRating: 4500 },
        { stat: 'Haste', avgPercentage: 28, avgRating: 3200 },
        { stat: 'Mastery', avgPercentage: 22, avgRating: 2800 },
        { stat: 'Critical Strike', avgPercentage: 15, avgRating: 1900 },
      ],
      popularItems,
      popularEnchants: [
        { id: 1, name: 'Authority of Radiant Power', slot: 'Weapon', stat: 'Primary', pickRate: 85 },
        { id: 2, name: 'Crystalline Radiance', slot: 'Chest', stat: 'Primary', pickRate: 92 },
        { id: 3, name: 'Chant of Leeching Fangs', slot: 'Wrist', stat: 'Leech', pickRate: 78 },
        { id: 4, name: 'Cursed Versatility', slot: 'Ring', stat: 'Versatility', pickRate: 95 },
        { id: 5, name: "Defender's March", slot: 'Boots', stat: 'Stamina', pickRate: 72 },
        { id: 6, name: 'Sunset Spellthread', slot: 'Legs', stat: 'Int/Stam', pickRate: 88 },
      ],
      popularGems: [
        { id: 1, name: 'Culminating Blasphemite', icon: 'inv_misc_gem_diamond', stat: 'Primary + Crit', pickRate: 78, type: 'primary' },
        { id: 2, name: 'Masterful Onyx', icon: 'inv_misc_gem_onyx', stat: 'Mastery', pickRate: 45, type: 'secondary' },
        { id: 3, name: 'Versatile Ruby', icon: 'inv_misc_gem_ruby', stat: 'Versatility', pickRate: 65, type: 'secondary' },
        { id: 4, name: 'Quick Topaz', icon: 'inv_misc_gem_topaz', stat: 'Haste', pickRate: 55, type: 'secondary' },
      ],
      popularEmbellishments: [
        { id: 1, name: 'Elemental Focusing Lens', effect: 'Damage proc based on element used', pickRate: 72, slot: 'Helm' },
        { id: 2, name: 'Duskthread Lining', effect: '+Vers when above 80% HP', pickRate: 45, slot: 'Cloak' },
        { id: 3, name: 'Writhing Armor Banding', effect: 'Tentacle attack proc', pickRate: 28, slot: 'Chest' },
        { id: 4, name: 'Darkmoon Sigil: Ascension', effect: 'Primary stat proc', pickRate: 35, slot: 'Trinket' },
      ],
      setBonuses: [
        { setName: 'Gladiator\'s Thundering Set', pieces: 4, pickRate: 75 },
        { setName: 'Tier Set', pieces: 2, pickRate: 60 },
      ],
      lastUpdated: new Date().toISOString(),
    };
  }

  // === Alts Detection ===

  async detectAlts(name: string, realm: string): Promise<AltCharacter[]> {
    // In production, this would use heuristics:
    // - Same guild across characters
    // - Similar naming patterns
    // - Achievement timestamps
    // - Same achievements earned on same days
    // For now, return empty (would need account-level API access)
    return [];
  }

  // === LFG System (Local Storage) ===

  private lfgListings: LFGListing[] = [];

  async getLFGListings(filters: LFGFilters): Promise<LFGListing[]> {
    let results = this.lfgListings.filter(l => {
      if (filters.bracket && l.bracket !== filters.bracket) return false;
      if (filters.region !== 'all' && l.character.region !== filters.region) return false;
      if (filters.faction !== 'all' && l.character.faction !== filters.faction) return false;
      if (filters.role && filters.role !== 'all' && l.role !== filters.role) return false;
      if (filters.class && l.character.class !== filters.class) return false;
      if (filters.minRating && l.currentRating < filters.minRating) return false;
      if (filters.maxRating && l.currentRating > filters.maxRating) return false;
      if (filters.hasVoice && !l.voiceChat) return false;
      if (filters.language && l.language !== filters.language) return false;
      return true;
    });

    // Sort by rating descending
    results.sort((a, b) => b.currentRating - a.currentRating);
    return results;
  }

  async createLFGListing(post: LFGPost, characterName: string, realm: string): Promise<LFGListing | null> {
    const profile = await this.getPlayerProfile(characterName, realm);
    if (!profile) return null;

    const bracketRating = profile.ratings.find(r =>
      r.bracket === post.bracket || r.bracketName.toLowerCase().includes(post.bracket)
    );

    const listing: LFGListing = {
      id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      character: {
        name: profile.character.name,
        realm: profile.character.realm,
        realmSlug: profile.character.realmSlug,
        region: profile.character.region,
        class: profile.character.class,
        className: profile.character.className,
        spec: profile.character.spec,
        specId: profile.character.specId,
        faction: profile.character.faction,
        itemLevel: profile.character.equippedItemLevel,
      },
      bracket: post.bracket,
      role: post.role,
      currentRating: bracketRating?.current || 0,
      seasonHigh: bracketRating?.seasonHigh || 0,
      allTimeHigh: bracketRating?.allTimeHigh || 0,
      lookingFor: post.lookingFor,
      minRating: post.minRating,
      maxRating: post.maxRating,
      description: post.description,
      voiceChat: post.voiceChat,
      language: post.language,
      schedule: post.schedule,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours
      isOnline: true,
      achievements: profile.achievements.slice(0, 5).map(a => ({
        name: a.name,
        season: a.earnedDate.split('-')[0],
      })),
    };

    this.lfgListings.push(listing);
    return listing;
  }

  async deleteLFGListing(id: string): Promise<boolean> {
    const index = this.lfgListings.findIndex(l => l.id === id);
    if (index >= 0) {
      this.lfgListings.splice(index, 1);
      return true;
    }
    return false;
  }

  // === Local Database (Rating History Tracking) ===

  private localDb: LocalDatabase = {
    players: {},
    lfgListings: [],
    favoriteCharacters: [],
    lastSync: new Date().toISOString(),
  };

  async trackPlayer(name: string, realm: string): Promise<StoredPlayerData | null> {
    const profile = await this.getPlayerProfile(name, realm);
    if (!profile) return null;

    const key = `${name.toLowerCase()}-${realm.toLowerCase()}-${this.config.region}`;
    const existing = this.localDb.players[key];

    const snapshot = {
      timestamp: new Date().toISOString(),
      ratings: profile.ratings.map(r => ({
        bracket: r.bracket,
        rating: r.current,
        wins: r.wins,
        losses: r.losses,
      })),
      itemLevel: profile.character.equippedItemLevel,
    };

    if (existing) {
      existing.snapshots.push(snapshot);
      existing.lastUpdated = snapshot.timestamp;
      // Keep only last 90 days of snapshots
      const cutoff = Date.now() - 90 * 24 * 60 * 60 * 1000;
      existing.snapshots = existing.snapshots.filter(s =>
        new Date(s.timestamp).getTime() > cutoff
      );
    } else {
      this.localDb.players[key] = {
        name: profile.character.name,
        realm: profile.character.realm,
        region: this.config.region,
        snapshots: [snapshot],
        firstSeen: snapshot.timestamp,
        lastUpdated: snapshot.timestamp,
      };
    }

    return this.localDb.players[key];
  }

  getTrackedPlayer(name: string, realm: string): StoredPlayerData | null {
    const key = `${name.toLowerCase()}-${realm.toLowerCase()}-${this.config.region}`;
    return this.localDb.players[key] || null;
  }

  getTrackedPlayers(): StoredPlayerData[] {
    return Object.values(this.localDb.players);
  }

  addFavorite(name: string, realm: string): void {
    const key = `${name.toLowerCase()}-${realm.toLowerCase()}-${this.config.region}`;
    if (!this.localDb.favoriteCharacters.includes(key)) {
      this.localDb.favoriteCharacters.push(key);
    }
  }

  removeFavorite(name: string, realm: string): void {
    const key = `${name.toLowerCase()}-${realm.toLowerCase()}-${this.config.region}`;
    const index = this.localDb.favoriteCharacters.indexOf(key);
    if (index >= 0) {
      this.localDb.favoriteCharacters.splice(index, 1);
    }
  }

  getFavorites(): StoredPlayerData[] {
    return this.localDb.favoriteCharacters
      .map(key => this.localDb.players[key])
      .filter(Boolean);
  }

  // === Configuration ===

  setConfig(config: Partial<ApiConfig>): void {
    Object.assign(this.config, config);
    this.token = null;
    this.currentSeasonId = null;
    this.cache.clear();
  }

  getRegion(): Region {
    return this.config.region;
  }

  isConfigured(): boolean {
    return !!(this.config.clientId && this.config.clientSecret);
  }

  // ===========================================
  // === GUILD API ===
  // ===========================================

  async getGuildInfo(guildName: string, realm: string): Promise<GuildInfo | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-').replace(/'/g, '');
      const guildSlug = guildName.toLowerCase().replace(/\s+/g, '-');

      const data = await this.request<any>(
        `/data/wow/guild/${realmSlug}/${guildSlug}`,
        {},
        `profile-${this.config.region}`
      );

      return {
        name: data.name,
        realm: data.realm?.name || realm,
        realmSlug,
        region: this.config.region,
        faction: data.faction?.type?.toLowerCase() as 'alliance' | 'horde',
        memberCount: data.member_count || 0,
        achievementPoints: data.achievement_points || 0,
        createdTimestamp: data.created_timestamp,
        crest: data.crest ? {
          emblem: { id: data.crest.emblem?.id || 0, color: this.parseColor(data.crest.emblem?.color) },
          border: { id: data.crest.border?.id || 0, color: this.parseColor(data.crest.border?.color) },
          background: { color: this.parseColor(data.crest.background?.color) },
        } : undefined,
      };
    } catch (error: any) {
      console.error('Guild info fetch failed:', error.message);
      return null;
    }
  }

  private parseColor(color: any): string {
    if (!color) return '#000000';
    if (typeof color === 'string') return color;
    const { r, g, b, a } = color;
    return `rgba(${r || 0}, ${g || 0}, ${b || 0}, ${a !== undefined ? a : 1})`;
  }

  async getGuildRoster(guildName: string, realm: string): Promise<GuildRoster | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-').replace(/'/g, '');
      const guildSlug = guildName.toLowerCase().replace(/\s+/g, '-');

      const [guildData, rosterData] = await Promise.all([
        this.request<any>(`/data/wow/guild/${realmSlug}/${guildSlug}`, {}, `profile-${this.config.region}`),
        this.request<any>(`/data/wow/guild/${realmSlug}/${guildSlug}/roster`, {}, `profile-${this.config.region}`),
      ]);

      const members: GuildMember[] = (rosterData.members || []).map((m: any) => ({
        character: {
          name: m.character?.name || 'Unknown',
          realm: m.character?.realm?.name || realm,
          realmSlug: m.character?.realm?.slug || realmSlug,
          level: m.character?.level || 0,
          class: getClassById(m.character?.playable_class?.id) || 'warrior',
          className: m.character?.playable_class?.name || 'Unknown',
          race: m.character?.playable_race?.name || 'Unknown',
        },
        rank: m.rank || 0,
      }));

      const guild: GuildInfo = {
        name: guildData.name,
        realm: guildData.realm?.name || realm,
        realmSlug,
        region: this.config.region,
        faction: guildData.faction?.type?.toLowerCase() as 'alliance' | 'horde',
        memberCount: members.length,
        achievementPoints: guildData.achievement_points || 0,
      };

      return {
        guild,
        members,
        lastUpdated: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error('Guild roster fetch failed:', error.message);
      return null;
    }
  }

  async getGuildAchievements(guildName: string, realm: string): Promise<GuildAchievements | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-').replace(/'/g, '');
      const guildSlug = guildName.toLowerCase().replace(/\s+/g, '-');

      const [guildData, achData] = await Promise.all([
        this.request<any>(`/data/wow/guild/${realmSlug}/${guildSlug}`, {}, `profile-${this.config.region}`),
        this.request<any>(`/data/wow/guild/${realmSlug}/${guildSlug}/achievements`, {}, `profile-${this.config.region}`),
      ]);

      const achievements: GuildAchievement[] = (achData.achievements || [])
        .filter((a: any) => a.completed_timestamp)
        .map((a: any) => ({
          id: a.achievement?.id || a.id,
          name: a.achievement?.name || 'Unknown',
          description: a.achievement?.description || '',
          points: a.achievement?.points || 0,
          completedTimestamp: a.completed_timestamp,
          criteria: a.criteria?.child_criteria?.map((c: any) => ({
            id: c.id,
            amount: c.amount || 0,
            isCompleted: c.is_completed || false,
          })),
        }));

      const guild: GuildInfo = {
        name: guildData.name,
        realm: guildData.realm?.name || realm,
        realmSlug,
        region: this.config.region,
        faction: guildData.faction?.type?.toLowerCase() as 'alliance' | 'horde',
        memberCount: guildData.member_count || 0,
        achievementPoints: achData.total_points || guildData.achievement_points || 0,
      };

      return {
        guild,
        achievements,
        totalPoints: achData.total_points || 0,
        lastUpdated: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error('Guild achievements fetch failed:', error.message);
      return null;
    }
  }

  // ===========================================
  // === MYTHIC+ API ===
  // ===========================================

  async getMythicPlusProfile(name: string, realm: string): Promise<MythicPlusProfile | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-').replace(/'/g, '');
      const charSlug = name.toLowerCase();

      const profile = await this.request<any>(
        `/profile/wow/character/${realmSlug}/${charSlug}/mythic-keystone-profile`
      );

      const currentSeason = profile.current_period?.best_runs || profile.seasons?.[0];

      if (!currentSeason && !profile.current_mythic_rating) {
        return {
          currentSeason: {
            id: 0,
            rating: 0,
            ratingColor: '#9d9d9d',
            bestRuns: [],
            recentRuns: [],
          },
        };
      }

      // Try to get current season details
      let seasonBestRuns: MythicPlusRun[] = [];
      try {
        const seasonId = profile.current_period?.period?.id || profile.seasons?.[0]?.season?.id;
        if (seasonId) {
          const seasonData = await this.request<any>(
            `/profile/wow/character/${realmSlug}/${charSlug}/mythic-keystone-profile/season/${seasonId}`
          );
          seasonBestRuns = this.parseMythicPlusRuns(seasonData.best_runs || []);
        }
      } catch {
        // Season data not available
      }

      return {
        currentSeason: {
          id: profile.current_period?.period?.id || 0,
          rating: profile.current_mythic_rating?.rating || 0,
          ratingColor: this.getMythicPlusRatingColor(profile.current_mythic_rating?.rating || 0),
          bestRuns: seasonBestRuns,
          recentRuns: [], // Would need additional API calls
        },
      };
    } catch (error: any) {
      console.error('Mythic+ profile fetch failed:', error.message);
      return null;
    }
  }

  private parseMythicPlusRuns(runs: any[]): MythicPlusRun[] {
    return runs.map(run => ({
      dungeon: {
        id: run.dungeon?.id || 0,
        name: run.dungeon?.name || 'Unknown',
        shortName: this.getDungeonShortName(run.dungeon?.name || ''),
      },
      keystoneLevel: run.keystone_level || 0,
      completedTimestamp: run.completed_timestamp || 0,
      duration: run.duration || 0,
      timedDuration: run.timed_duration || run.duration || 0,
      isCompleted: true,
      isChested: run.is_completed_within_time || false,
      affixes: (run.keystone_affixes || []).map((a: any) => ({
        id: a.id,
        name: a.name || 'Unknown',
        description: '',
      })),
      rating: run.mythic_rating?.rating || 0,
      members: (run.members || []).map((m: any) => ({
        name: m.character?.name || 'Unknown',
        realm: m.character?.realm?.slug || '',
        class: getClassById(m.character?.playable_class?.id) || 'warrior',
        spec: m.specialization?.name || '',
        role: this.getMythicPlusRole(m.specialization?.id),
      })),
    }));
  }

  private getMythicPlusRole(specId: number): 'tank' | 'healer' | 'dps' {
    const specInfo = getSpecInfo(specId);
    return specInfo?.role || 'dps';
  }

  private getDungeonShortName(name: string): string {
    const shortNames: Record<string, string> = {
      'The Stonevault': 'SV',
      'The Dawnbreaker': 'DB',
      'Ara-Kara, City of Echoes': 'AK',
      "City of Threads": 'COT',
      'Mists of Tirna Scithe': 'MISTS',
      'The Necrotic Wake': 'NW',
      'Siege of Boralus': 'SOB',
      'Grim Batol': 'GB',
    };
    return shortNames[name] || name.split(' ').map(w => w[0]).join('').toUpperCase();
  }

  private getMythicPlusRatingColor(rating: number): string {
    if (rating >= 3000) return '#ff8000'; // Orange (Mythic)
    if (rating >= 2500) return '#a335ee'; // Purple (Heroic)
    if (rating >= 2000) return '#0070dd'; // Blue (Rare)
    if (rating >= 1500) return '#1eff00'; // Green (Uncommon)
    if (rating >= 750) return '#ffffff';  // White (Common)
    return '#9d9d9d'; // Gray
  }

  async getMythicPlusAffixes(): Promise<MythicPlusAffixes | null> {
    try {
      const data = await this.request<any>(
        '/data/wow/mythic-keystone/period/index',
        {},
        `dynamic-${this.config.region}`
      );

      const currentPeriod = data.current_period;
      if (!currentPeriod) return null;

      // Get current period details
      const periodData = await this.request<any>(
        `/data/wow/mythic-keystone/period/${currentPeriod.id}`,
        {},
        `dynamic-${this.config.region}`
      );

      return {
        currentWeek: {
          affixes: (periodData.mythic_rating_season?.affixes || []).map((a: any) => ({
            id: a.keystone_affix?.id || a.id,
            name: a.keystone_affix?.name || a.name || 'Unknown',
            description: '',
            icon: '',
          })),
          startTimestamp: periodData.start_timestamp || 0,
          endTimestamp: periodData.end_timestamp || 0,
        },
      };
    } catch (error: any) {
      console.error('Mythic+ affixes fetch failed:', error.message);
      return null;
    }
  }

  async getMythicPlusDungeons(): Promise<MythicPlusDungeon[]> {
    try {
      const data = await this.request<any>(
        '/data/wow/mythic-keystone/dungeon/index',
        {},
        `dynamic-${this.config.region}`
      );

      return (data.dungeons || []).map((d: any) => ({
        id: d.id,
        name: d.name || 'Unknown',
        shortName: this.getDungeonShortName(d.name || ''),
      }));
    } catch {
      return [];
    }
  }

  // ===========================================
  // === SPELL/TALENT API ===
  // ===========================================

  async getSpellDetails(spellId: number): Promise<SpellDetails | null> {
    try {
      const [spellData, mediaData] = await Promise.all([
        this.request<any>(`/data/wow/spell/${spellId}`, {}, `static-${this.config.region}`),
        this.request<any>(`/data/wow/media/spell/${spellId}`, {}, `static-${this.config.region}`).catch(() => null),
      ]);

      return {
        id: spellData.id,
        name: spellData.name || 'Unknown Spell',
        description: spellData.description || '',
        icon: mediaData?.assets?.[0]?.key || '',
        iconUrl: mediaData?.assets?.[0]?.value || '',
        castTime: spellData.cast_time || 'Instant',
        cooldown: spellData.cooldown,
        range: spellData.range,
        powerCost: spellData.power_cost,
      };
    } catch (error: any) {
      console.error('Spell details fetch failed:', error.message);
      return null;
    }
  }

  async getPvPTalentDetails(pvpTalentId: number): Promise<PvPTalentDetails | null> {
    try {
      const data = await this.request<any>(
        `/data/wow/pvp-talent/${pvpTalentId}`,
        {},
        `static-${this.config.region}`
      );

      let spellDetails: SpellDetails | undefined;
      if (data.spell?.id) {
        const spell = await this.getSpellDetails(data.spell.id);
        if (spell) spellDetails = spell;
      }

      return {
        id: data.id,
        name: data.spell?.name || data.name || 'Unknown',
        description: data.description || '',
        icon: spellDetails?.icon || '',
        iconUrl: spellDetails?.iconUrl || '',
        spell: spellDetails,
        unlockLevel: data.unlock_player_level,
      };
    } catch (error: any) {
      console.error('PvP talent details fetch failed:', error.message);
      return null;
    }
  }

  async getTalentTree(specId: number): Promise<TalentTree | null> {
    try {
      const specInfo = getSpecInfo(specId);
      if (!specInfo) return null;

      // Get talent tree data
      const data = await this.request<any>(
        `/data/wow/talent-tree/index`,
        {},
        `static-${this.config.region}`
      );

      // Find the tree for this spec's class
      const classTree = data.talent_trees?.find((t: any) =>
        t.playable_specialization?.id === specId
      );

      if (!classTree) {
        return {
          specId,
          className: specInfo.className,
          specName: specInfo.name,
          classTalents: [],
          specTalents: [],
          heroTalents: [],
          pvpTalents: [],
        };
      }

      // Get detailed tree data
      const treeData = await this.request<any>(
        `/data/wow/talent-tree/${classTree.id}`,
        {},
        `static-${this.config.region}`
      );

      const classTalents = this.parseTalentTreeNodes(treeData.class_talent_nodes || [], 'class');
      const specTalents = this.parseTalentTreeNodes(treeData.spec_talent_nodes || [], 'spec');
      const heroTalents = this.parseTalentTreeNodes(treeData.hero_talent_nodes || [], 'hero');

      // Get PvP talents
      const pvpTalents = await this.getPvPTalentsForSpec(specId);

      return {
        specId,
        className: specInfo.className,
        specName: specInfo.name,
        classTalents,
        specTalents,
        heroTalents,
        pvpTalents,
      };
    } catch (error: any) {
      console.error('Talent tree fetch failed:', error.message);
      return null;
    }
  }

  private parseTalentTreeNodes(nodes: any[], type: 'class' | 'spec' | 'hero'): TalentTreeNode[] {
    return nodes.map(node => ({
      id: node.id,
      name: node.name || 'Unknown',
      type,
      posX: node.pos_x || 0,
      posY: node.pos_y || 0,
      maxRank: node.max_rank || 1,
      unlocks: node.unlocks?.map((u: any) => u.id) || [],
      lockedBy: node.locked_by?.map((l: any) => l.id) || [],
      spells: (node.entries || []).map((entry: any) => ({
        rank: entry.rank || 1,
        spell: {
          id: entry.spell?.id || entry.talent?.id || 0,
          name: entry.spell?.name || entry.talent?.name || 'Unknown',
          description: entry.spell?.description || entry.talent?.description || '',
          icon: '',
        },
      })),
    }));
  }

  private async getPvPTalentsForSpec(specId: number): Promise<PvPTalentDetails[]> {
    try {
      const data = await this.request<any>(
        `/data/wow/pvp-talent/index`,
        {},
        `static-${this.config.region}`
      );

      const specPvPTalents = (data.pvp_talents || []).filter((t: any) =>
        t.playable_specialization?.id === specId
      );

      const details = await Promise.allSettled(
        specPvPTalents.slice(0, 20).map((t: any) => this.getPvPTalentDetails(t.id))
      );

      return details
        .filter((r): r is PromiseFulfilledResult<PvPTalentDetails | null> => r.status === 'fulfilled' && r.value !== null)
        .map(r => r.value as PvPTalentDetails);
    } catch {
      return [];
    }
  }

  // ===========================================
  // === ITEM API ===
  // ===========================================

  async getItemDetails(itemId: number): Promise<ItemDetails | null> {
    try {
      const [itemData, mediaData] = await Promise.all([
        this.request<any>(`/data/wow/item/${itemId}`, {}, `static-${this.config.region}`),
        this.request<any>(`/data/wow/media/item/${itemId}`, {}, `static-${this.config.region}`).catch(() => null),
      ]);

      const stats = (itemData.preview_item?.stats || []).map((s: any) => ({
        type: s.type?.name || s.type?.type || 'Unknown',
        value: s.value || 0,
      }));

      return {
        id: itemData.id,
        name: itemData.name || 'Unknown Item',
        quality: (itemData.quality?.type?.toLowerCase() || 'common') as ItemDetails['quality'],
        itemLevel: itemData.level || itemData.preview_item?.level?.value || 0,
        requiredLevel: itemData.required_level || 0,
        itemClass: itemData.item_class?.name || '',
        itemSubclass: itemData.item_subclass?.name || '',
        inventoryType: itemData.inventory_type?.name || '',
        binding: this.parseBinding(itemData.preview_item?.binding?.type),
        icon: mediaData?.assets?.[0]?.key || '',
        iconUrl: mediaData?.assets?.[0]?.value || '',
        stats: stats.length > 0 ? stats : undefined,
        armor: itemData.preview_item?.armor?.value,
        weaponInfo: itemData.preview_item?.weapon ? {
          damage: {
            min: itemData.preview_item.weapon.damage?.min_value || 0,
            max: itemData.preview_item.weapon.damage?.max_value || 0,
          },
          speed: itemData.preview_item.weapon.attack_speed?.value || 0,
          dps: itemData.preview_item.weapon.dps?.value || 0,
        } : undefined,
        socketInfo: itemData.preview_item?.sockets ? {
          sockets: (itemData.preview_item.sockets || []).map((s: any) => ({
            type: s.socket_type?.name || 'Prismatic',
          })),
          bonus: itemData.preview_item.socket_bonus,
        } : undefined,
        setInfo: itemData.preview_item?.set ? {
          id: itemData.preview_item.set.item_set?.id || 0,
          name: itemData.preview_item.set.item_set?.name || '',
          items: (itemData.preview_item.set.items || []).map((i: any) => ({
            id: i.item?.id || 0,
            name: i.item?.name || '',
          })),
          bonuses: (itemData.preview_item.set.effects || []).map((e: any) => ({
            threshold: e.required_count || 0,
            description: e.display_string || '',
          })),
        } : undefined,
        spellEffects: (itemData.preview_item?.spells || []).map((s: any) => ({
          description: s.description || '',
          trigger: this.parseSpellTrigger(s.spell?.name),
        })),
        description: itemData.preview_item?.description,
        sellPrice: itemData.preview_item?.sell_price?.value,
        isUnique: itemData.preview_item?.is_unique || false,
        isUniqueEquipped: itemData.preview_item?.unique_equipped || false,
      };
    } catch (error: any) {
      console.error('Item details fetch failed:', error.message);
      return null;
    }
  }

  private parseBinding(binding: string): ItemDetails['binding'] {
    if (!binding) return undefined;
    const lower = binding.toLowerCase();
    if (lower.includes('pickup') || lower.includes('acquire')) return 'on_pickup';
    if (lower.includes('equip')) return 'on_equip';
    if (lower.includes('use')) return 'on_use';
    return undefined;
  }

  private parseSpellTrigger(name?: string): 'on_equip' | 'on_use' | 'on_proc' {
    if (!name) return 'on_proc';
    const lower = name.toLowerCase();
    if (lower.includes('equip')) return 'on_equip';
    if (lower.includes('use')) return 'on_use';
    return 'on_proc';
  }

  async searchItems(query: string, limit: number = 20): Promise<ItemDetails[]> {
    try {
      const data = await this.request<any>(
        '/data/wow/search/item',
        { name: query, orderby: 'id', _pageSize: String(limit) },
        `static-${this.config.region}`
      );

      const items = await Promise.allSettled(
        (data.results || []).slice(0, limit).map((r: any) =>
          this.getItemDetails(r.data?.id || r.id)
        )
      );

      return items
        .filter((r): r is PromiseFulfilledResult<ItemDetails | null> => r.status === 'fulfilled' && r.value !== null)
        .map(r => r.value as ItemDetails);
    } catch (error: any) {
      console.error('Item search failed:', error.message);
      return [];
    }
  }

  // ===========================================
  // === RAID PROGRESS API ===
  // ===========================================

  async getRaidProgress(name: string, realm: string): Promise<CharacterRaidProgress | null> {
    try {
      const realmSlug = realm.toLowerCase().replace(/\s+/g, '-').replace(/'/g, '');
      const charSlug = name.toLowerCase();

      const data = await this.request<any>(
        `/profile/wow/character/${realmSlug}/${charSlug}/encounters/raids`
      );

      const currentTier: RaidProgress[] = [];

      for (const expansion of data.expansions || []) {
        for (const instance of expansion.instances || []) {
          for (const mode of instance.modes || []) {
            const difficulty = this.parseDifficulty(mode.difficulty?.type);
            const encounters = (mode.progress?.encounters || []).map((enc: any) => ({
              boss: {
                id: enc.encounter?.id || 0,
                name: enc.encounter?.name || 'Unknown',
                [`${difficulty}Kills`]: enc.completed_count || 0,
                [`last${difficulty.charAt(0).toUpperCase() + difficulty.slice(1)}Kill`]: enc.last_kill_timestamp,
              },
              isKilled: (enc.completed_count || 0) > 0,
              kills: enc.completed_count || 0,
              lastKill: enc.last_kill_timestamp,
            }));

            const bossesKilled = encounters.filter((e: any) => e.isKilled).length;
            const totalBosses = encounters.length;

            if (totalBosses > 0) {
              currentTier.push({
                instance: {
                  id: instance.instance?.id || 0,
                  name: instance.instance?.name || 'Unknown',
                  expansion: expansion.expansion?.name || '',
                  bosses: encounters.map((e: any) => e.boss),
                },
                difficulty,
                bossesKilled,
                totalBosses,
                progress: `${bossesKilled}/${totalBosses}`,
                encounters,
              });
            }
          }
        }
      }

      return {
        character: {
          name,
          realm,
          region: this.config.region,
        },
        currentTier,
        lastUpdated: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error('Raid progress fetch failed:', error.message);
      return null;
    }
  }

  private parseDifficulty(type: string): 'normal' | 'heroic' | 'mythic' | 'lfr' {
    const lower = (type || '').toLowerCase();
    if (lower.includes('mythic')) return 'mythic';
    if (lower.includes('heroic')) return 'heroic';
    if (lower.includes('lfr') || lower.includes('finder')) return 'lfr';
    return 'normal';
  }

  async getRaidInstances(): Promise<RaidInstance[]> {
    try {
      const data = await this.request<any>(
        '/data/wow/journal-instance/index',
        {},
        `static-${this.config.region}`
      );

      const raids: RaidInstance[] = [];

      for (const instance of data.instances || []) {
        if (instance.category?.type === 'RAID') {
          const details = await this.request<any>(
            `/data/wow/journal-instance/${instance.id}`,
            {},
            `static-${this.config.region}`
          ).catch(() => null);

          if (details) {
            raids.push({
              id: details.id,
              name: details.name || 'Unknown',
              expansion: details.expansion?.name || '',
              minLevel: details.minimum_level,
              bosses: (details.encounters || []).map((e: any) => ({
                id: e.id,
                name: e.name || 'Unknown',
                description: e.description,
              })),
            });
          }
        }
      }

      return raids;
    } catch (error: any) {
      console.error('Raid instances fetch failed:', error.message);
      return [];
    }
  }

  // ===========================================
  // === CONNECTED TALENT HEATMAP (Real Data) ===
  // ===========================================

  async getTalentHeatmapFromLeaderboard(specId: number, bracket: GameMode): Promise<TalentHeatmap> {
    const specInfo = getSpecInfo(specId);
    if (!specInfo) throw new Error(`Unknown spec: ${specId}`);

    // Get leaderboard and filter to this spec
    const leaderboard = await this.getLeaderboard(bracket, { page: 1, pageSize: 500 });

    // Enrich with class data
    const enriched = await this.enrichLeaderboardWithClasses(
      leaderboard.entries.filter(e => e.rating >= 2400).slice(0, 100)
    );

    // Filter to the specific spec
    const specPlayers = enriched.filter(e => e.character.specId === specId);

    // Fetch talents for top players of this spec
    const talentData = await Promise.allSettled(
      specPlayers.slice(0, 20).map(async (player) => {
        const profile = await this.getPlayerProfile(player.character.name, player.character.realm);
        return profile?.talents;
      })
    );

    // Aggregate talent usage
    const talentUsage = new Map<number, { name: string; type: string; count: number; ranks: number[] }>();

    for (const result of talentData) {
      if (result.status !== 'fulfilled' || !result.value) continue;
      const talents = result.value;

      for (const talent of [...talents.classTalents, ...talents.specTalents, ...talents.heroTalents, ...talents.pvpTalents]) {
        const existing = talentUsage.get(talent.id) || { name: talent.name, type: talent.type || 'class', count: 0, ranks: [] };
        existing.count++;
        existing.ranks.push(talent.currentRank || 1);
        talentUsage.set(talent.id, existing);
      }
    }

    const sampleSize = talentData.filter(r => r.status === 'fulfilled' && r.value).length;

    // Convert to heatmap nodes
    const createNodes = (type: 'class' | 'spec' | 'hero' | 'pvp'): TalentHeatmapNode[] => {
      const nodes: TalentHeatmapNode[] = [];
      let index = 0;
      for (const [id, data] of talentUsage) {
        if (data.type !== type) continue;
        const pickRate = sampleSize > 0 ? (data.count / sampleSize) * 100 : 0;
        const avgRank = data.ranks.length > 0 ? data.ranks.reduce((a, b) => a + b, 0) / data.ranks.length : 1;
        nodes.push({
          nodeId: id,
          talentId: id,
          name: data.name,
          icon: '',
          row: Math.floor(index / 4),
          col: index % 4,
          type,
          pickRate,
          avgRank,
          maxRank: Math.max(...data.ranks, 1),
          popularity: pickRate > 80 ? 'meta' : pickRate > 50 ? 'common' : pickRate > 20 ? 'situational' : 'rare',
          description: '',
        });
        index++;
      }
      return nodes;
    };

    return {
      specId,
      className: specInfo.className,
      specName: specInfo.name,
      classColor: specInfo.classColor,
      bracket,
      sampleSize,
      classTalents: createNodes('class'),
      specTalents: createNodes('spec'),
      heroTalents: createNodes('hero'),
      pvpTalents: createNodes('pvp'),
      popularBuilds: [],
      lastUpdated: new Date().toISOString(),
    };
  }

  // ===========================================
  // === CONNECTED GEAR ANALYSIS (Real Data) ===
  // ===========================================

  async getGearAnalysisFromLeaderboard(specId: number, bracket: GameMode): Promise<GearAnalysis> {
    const specInfo = getSpecInfo(specId);
    if (!specInfo) throw new Error(`Unknown spec: ${specId}`);

    // Get leaderboard and filter to this spec
    const leaderboard = await this.getLeaderboard(bracket, { page: 1, pageSize: 500 });

    // Enrich with class data
    const enriched = await this.enrichLeaderboardWithClasses(
      leaderboard.entries.filter(e => e.rating >= 2400).slice(0, 100)
    );

    // Filter to the specific spec
    const specPlayers = enriched.filter(e => e.character.specId === specId);

    // Fetch equipment for top players
    const equipmentData = await Promise.allSettled(
      specPlayers.slice(0, 15).map(async (player) => {
        const profile = await this.getPlayerProfile(player.character.name, player.character.realm);
        return { equipment: profile?.equipment, stats: profile?.stats };
      })
    );

    // Aggregate item usage
    const itemUsage = new Map<string, Map<number, { item: EquippedItem; count: number }>>();
    const enchantUsage = new Map<string, Map<string, { name: string; stat: string; count: number }>>();
    const gemUsage = new Map<string, { name: string; stat: string; count: number }>();
    const statTotals = new Map<string, number[]>();
    let totalItemLevel = 0;
    let sampleSize = 0;

    for (const result of equipmentData) {
      if (result.status !== 'fulfilled' || !result.value?.equipment) continue;
      sampleSize++;
      const { equipment, stats } = result.value;
      totalItemLevel += equipment.equippedItemLevel || 0;

      for (const item of equipment.items) {
        if (!itemUsage.has(item.slotType)) {
          itemUsage.set(item.slotType, new Map());
        }
        const slotMap = itemUsage.get(item.slotType)!;
        const existing = slotMap.get(item.id) || { item, count: 0 };
        existing.count++;
        slotMap.set(item.id, existing);

        if (item.enchant) {
          if (!enchantUsage.has(item.slotType)) {
            enchantUsage.set(item.slotType, new Map());
          }
          const enchantKey = `${item.enchant.id}-${item.enchant.name}`;
          const enchantMap = enchantUsage.get(item.slotType)!;
          const existingEnchant = enchantMap.get(enchantKey) || { name: item.enchant.name, stat: item.enchant.description, count: 0 };
          existingEnchant.count++;
          enchantMap.set(enchantKey, existingEnchant);
        }

        for (const gem of item.gems || []) {
          const existingGem = gemUsage.get(gem.name) || { name: gem.name, stat: '', count: 0 };
          existingGem.count++;
          gemUsage.set(gem.name, existingGem);
        }
      }

      // Aggregate stats
      if (stats) {
        const addStat = (name: string, value: number) => {
          if (!statTotals.has(name)) statTotals.set(name, []);
          statTotals.get(name)!.push(value);
        };
        addStat('Versatility', stats.versatility.rating);
        addStat('Haste', stats.haste.rating);
        addStat('Mastery', stats.mastery.rating);
        addStat('Critical Strike', stats.criticalStrike.rating);
      }
    }

    // Convert to output format
    const popularItems: Record<string, PopularItem[]> = {};
    for (const [slot, items] of itemUsage) {
      popularItems[slot] = Array.from(items.values())
        .sort((a, b) => b.count - a.count)
        .slice(0, 3)
        .map(({ item, count }) => ({
          id: item.id,
          name: item.name,
          icon: item.icon,
          itemLevel: item.itemLevel,
          quality: item.quality,
          pickRate: sampleSize > 0 ? (count / sampleSize) * 100 : 0,
          source: item.source || 'Unknown',
          stats: item.stats,
        }));
    }

    const popularEnchants: PopularEnchant[] = [];
    for (const [slot, enchants] of enchantUsage) {
      const sorted = Array.from(enchants.values()).sort((a, b) => b.count - a.count);
      if (sorted.length > 0) {
        popularEnchants.push({
          id: 0,
          name: sorted[0].name,
          slot,
          stat: sorted[0].stat,
          pickRate: sampleSize > 0 ? (sorted[0].count / sampleSize) * 100 : 0,
        });
      }
    }

    const popularGems: PopularGem[] = Array.from(gemUsage.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map((gem, i) => ({
        id: i,
        name: gem.name,
        icon: '',
        stat: gem.stat,
        pickRate: sampleSize > 0 ? (gem.count / sampleSize) * 100 : 0,
        type: 'secondary' as const,
      }));

    // Calculate stat priority
    const totalStats = Array.from(statTotals.entries())
      .map(([stat, values]) => ({
        stat,
        avgRating: values.length > 0 ? Math.round(values.reduce((a, b) => a + b, 0) / values.length) : 0,
        total: values.reduce((a, b) => a + b, 0),
      }))
      .sort((a, b) => b.avgRating - a.avgRating);

    const totalStatRating = totalStats.reduce((sum, s) => sum + s.avgRating, 0);
    const statPriority = totalStats.map(s => ({
      stat: s.stat,
      avgPercentage: totalStatRating > 0 ? Math.round((s.avgRating / totalStatRating) * 100) : 0,
      avgRating: s.avgRating,
    }));

    return {
      specId,
      className: specInfo.className,
      specName: specInfo.name,
      bracket,
      sampleSize,
      avgItemLevel: sampleSize > 0 ? Math.round(totalItemLevel / sampleSize) : 0,
      statPriority,
      popularItems,
      popularEnchants,
      popularGems,
      popularEmbellishments: [],
      setBonuses: [],
      lastUpdated: new Date().toISOString(),
    };
  }

  // ===========================================
  // === CHARACTER SUMMARY (Extended Info) ===
  // ===========================================

  async getCharacterSummary(name: string, realm: string): Promise<CharacterSummary | null> {
    try {
      const [profile, mythicPlus, raidProgress] = await Promise.all([
        this.getPlayerProfile(name, realm),
        this.getMythicPlusProfile(name, realm).catch(() => null),
        this.getRaidProgress(name, realm).catch(() => null),
      ]);

      if (!profile) return null;

      // Find best raid progress
      let raidSummary: { currentProgress: string; bestDifficulty: string } | undefined;
      if (raidProgress?.currentTier.length) {
        const mythicProgress = raidProgress.currentTier.find(p => p.difficulty === 'mythic');
        const heroicProgress = raidProgress.currentTier.find(p => p.difficulty === 'heroic');
        const normalProgress = raidProgress.currentTier.find(p => p.difficulty === 'normal');

        const best = mythicProgress || heroicProgress || normalProgress;
        if (best) {
          const diffSuffix = best.difficulty === 'mythic' ? 'M' : best.difficulty === 'heroic' ? 'H' : 'N';
          raidSummary = {
            currentProgress: `${best.bossesKilled}/${best.totalBosses} ${diffSuffix}`,
            bestDifficulty: best.difficulty,
          };
        }
      }

      return {
        name: profile.character.name,
        realm: profile.character.realm,
        realmSlug: profile.character.realmSlug,
        region: profile.character.region,
        class: profile.character.class,
        className: profile.character.className,
        spec: profile.character.spec,
        specId: profile.character.specId,
        race: profile.character.race,
        faction: profile.character.faction,
        level: profile.character.level,
        itemLevel: profile.character.equippedItemLevel,
        avatarUrl: profile.character.avatarUrl,
        insetUrl: profile.character.insetUrl,
        mainRawUrl: profile.character.mainRawUrl,
        guild: profile.character.guild ? {
          name: profile.character.guild.name,
          realm: profile.character.guild.realm,
          realmSlug: profile.character.realmSlug,
          region: profile.character.region,
          faction: profile.character.faction,
          memberCount: 0,
          achievementPoints: 0,
        } : undefined,
        pvp: {
          honorLevel: profile.honorLevel,
          honorableKills: profile.honorableKills,
          ratings: profile.ratings,
          highestTier: profile.highestPvPTier || 'Unranked',
        },
        mythicPlus: mythicPlus?.currentSeason ? {
          rating: mythicPlus.currentSeason.rating,
          ratingColor: mythicPlus.currentSeason.ratingColor,
          bestRun: mythicPlus.currentSeason.bestRuns[0],
        } : undefined,
        raid: raidSummary,
        achievementPoints: profile.character.achievementPoints || 0,
        recentAchievements: profile.achievements.slice(0, 5),
        lastUpdated: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error('Character summary fetch failed:', error.message);
      return null;
    }
  }
}

export function createAPI(config?: Partial<ApiConfig>): BlizzardAPI {
  return new BlizzardAPI({
    clientId: config?.clientId || '',
    clientSecret: config?.clientSecret || '',
    region: config?.region || 'eu',
  });
}
