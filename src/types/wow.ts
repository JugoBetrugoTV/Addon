/**
 * WoW PvP Types - Complete data structures for murlok.io/check-pvp style app
 */

// === CLASSES & SPECS ===

export type WowClass =
  | 'death-knight' | 'demon-hunter' | 'druid' | 'evoker' | 'hunter'
  | 'mage' | 'monk' | 'paladin' | 'priest' | 'rogue'
  | 'shaman' | 'warlock' | 'warrior';

export interface SpecInfo {
  id: number;
  name: string;
  role: 'dps' | 'healer' | 'tank';
  icon: string;
}

export const CLASSES: { id: WowClass; name: string; color: string; specs: SpecInfo[] }[] = [
  { id: 'death-knight', name: 'Death Knight', color: '#C41F3B', specs: [
    { id: 250, name: 'Blood', role: 'tank', icon: 'spell_deathknight_bloodpresence' },
    { id: 251, name: 'Frost', role: 'dps', icon: 'spell_deathknight_frostpresence' },
    { id: 252, name: 'Unholy', role: 'dps', icon: 'spell_deathknight_unholypresence' },
  ]},
  { id: 'demon-hunter', name: 'Demon Hunter', color: '#A330C9', specs: [
    { id: 577, name: 'Havoc', role: 'dps', icon: 'ability_demonhunter_specdps' },
    { id: 581, name: 'Vengeance', role: 'tank', icon: 'ability_demonhunter_spectank' },
  ]},
  { id: 'druid', name: 'Druid', color: '#FF7D0A', specs: [
    { id: 102, name: 'Balance', role: 'dps', icon: 'spell_nature_starfall' },
    { id: 103, name: 'Feral', role: 'dps', icon: 'ability_druid_catform' },
    { id: 104, name: 'Guardian', role: 'tank', icon: 'ability_racial_bearform' },
    { id: 105, name: 'Restoration', role: 'healer', icon: 'spell_nature_healingtouch' },
  ]},
  { id: 'evoker', name: 'Evoker', color: '#33937F', specs: [
    { id: 1467, name: 'Devastation', role: 'dps', icon: 'classicon_evoker_devastation' },
    { id: 1468, name: 'Preservation', role: 'healer', icon: 'classicon_evoker_preservation' },
    { id: 1473, name: 'Augmentation', role: 'dps', icon: 'classicon_evoker_augmentation' },
  ]},
  { id: 'hunter', name: 'Hunter', color: '#ABD473', specs: [
    { id: 253, name: 'Beast Mastery', role: 'dps', icon: 'ability_hunter_bestialdiscipline' },
    { id: 254, name: 'Marksmanship', role: 'dps', icon: 'ability_hunter_focusedaim' },
    { id: 255, name: 'Survival', role: 'dps', icon: 'ability_hunter_camouflage' },
  ]},
  { id: 'mage', name: 'Mage', color: '#69CCF0', specs: [
    { id: 62, name: 'Arcane', role: 'dps', icon: 'spell_holy_magicalsentry' },
    { id: 63, name: 'Fire', role: 'dps', icon: 'spell_fire_firebolt02' },
    { id: 64, name: 'Frost', role: 'dps', icon: 'spell_frost_frostbolt02' },
  ]},
  { id: 'monk', name: 'Monk', color: '#00FF96', specs: [
    { id: 268, name: 'Brewmaster', role: 'tank', icon: 'spec_monk_brewmaster' },
    { id: 270, name: 'Mistweaver', role: 'healer', icon: 'spec_monk_mistweaver' },
    { id: 269, name: 'Windwalker', role: 'dps', icon: 'spec_monk_windwalker' },
  ]},
  { id: 'paladin', name: 'Paladin', color: '#F58CBA', specs: [
    { id: 65, name: 'Holy', role: 'healer', icon: 'spell_holy_holybolt' },
    { id: 66, name: 'Protection', role: 'tank', icon: 'ability_paladin_shieldofthetemplar' },
    { id: 70, name: 'Retribution', role: 'dps', icon: 'spell_holy_auraoflight' },
  ]},
  { id: 'priest', name: 'Priest', color: '#FFFFFF', specs: [
    { id: 256, name: 'Discipline', role: 'healer', icon: 'spell_holy_powerwordshield' },
    { id: 257, name: 'Holy', role: 'healer', icon: 'spell_holy_guardianspirit' },
    { id: 258, name: 'Shadow', role: 'dps', icon: 'spell_shadow_shadowwordpain' },
  ]},
  { id: 'rogue', name: 'Rogue', color: '#FFF569', specs: [
    { id: 259, name: 'Assassination', role: 'dps', icon: 'ability_rogue_deadlybrew' },
    { id: 260, name: 'Outlaw', role: 'dps', icon: 'ability_rogue_waylay' },
    { id: 261, name: 'Subtlety', role: 'dps', icon: 'ability_stealth' },
  ]},
  { id: 'shaman', name: 'Shaman', color: '#0070DE', specs: [
    { id: 262, name: 'Elemental', role: 'dps', icon: 'spell_nature_lightning' },
    { id: 263, name: 'Enhancement', role: 'dps', icon: 'spell_shaman_improvedstormstrike' },
    { id: 264, name: 'Restoration', role: 'healer', icon: 'spell_nature_magicimmunity' },
  ]},
  { id: 'warlock', name: 'Warlock', color: '#9482C9', specs: [
    { id: 265, name: 'Affliction', role: 'dps', icon: 'spell_shadow_deathcoil' },
    { id: 266, name: 'Demonology', role: 'dps', icon: 'spell_shadow_metamorphosis' },
    { id: 267, name: 'Destruction', role: 'dps', icon: 'spell_shadow_rainoffire' },
  ]},
  { id: 'warrior', name: 'Warrior', color: '#C79C6E', specs: [
    { id: 71, name: 'Arms', role: 'dps', icon: 'ability_warrior_savageblow' },
    { id: 72, name: 'Fury', role: 'dps', icon: 'ability_warrior_innerrage' },
    { id: 73, name: 'Protection', role: 'tank', icon: 'ability_warrior_defensivestance' },
  ]},
];

// === GAME MODES (all PvP brackets) ===

export type GameMode = 'shuffle' | '2v2' | '3v3' | 'rbg' | 'blitz';

export const GAME_MODES: { id: GameMode; name: string; bracket: string }[] = [
  { id: 'shuffle', name: 'Solo Shuffle', bracket: 'shuffle' },
  { id: '2v2', name: '2v2 Arena', bracket: 'arena-2v2' },
  { id: '3v3', name: '3v3 Arena', bracket: 'arena-3v3' },
  { id: 'rbg', name: 'Rated BG', bracket: 'rbg' },
  { id: 'blitz', name: 'Blitz', bracket: 'blitz' },
];

// === TALENTS ===

export interface TalentNode {
  id: number;
  name: string;
  icon: string;
  row: number;
  col: number;
  usagePercent: number;
  maxRank: number;
  currentRank?: number;
  description: string;
  type?: 'class' | 'spec' | 'hero' | 'pvp';
}

export interface TalentLoadout {
  specId: number;
  className: string;
  specName: string;
  classTalents: TalentNode[];
  specTalents: TalentNode[];
  heroTalents: TalentNode[];
  pvpTalents: TalentNode[];
  talentString?: string; // Export string for in-game import
}

// === EQUIPMENT ===

export interface EquippedItem {
  id: number;
  name: string;
  slot: string;
  slotType: string;
  icon: string;
  itemLevel: number;
  quality: 'poor' | 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary' | 'artifact';
  stats: { type: string; value: number }[];
  enchant?: { id: number; name: string; description: string };
  gems?: { id: number; name: string; icon: string }[];
  setInfo?: { name: string; itemsEquipped: number; itemsRequired: number };
  bonusIds?: number[];
  source?: string;
}

export interface CharacterEquipment {
  items: EquippedItem[];
  averageItemLevel: number;
  equippedItemLevel: number;
}

// === CHARACTER STATS ===

export interface CharacterStats {
  health: number;
  power: number;
  powerType: string;
  primaryStat: { name: string; value: number; bonus: number };
  stamina: { value: number; bonus: number };
  // Secondary stats
  criticalStrike: { rating: number; percent: number };
  haste: { rating: number; percent: number };
  mastery: { rating: number; percent: number };
  versatility: { rating: number; damagePercent: number; healingPercent: number; drPercent: number };
  // Tertiary
  leech: { rating: number; percent: number };
  avoidance: { rating: number; percent: number };
  speed: { rating: number; percent: number };
  // Defense
  armor: number;
  dodgePercent: number;
  parryPercent: number;
  blockPercent: number;
}

// === GEAR RECOMMENDATIONS (for murlok.io style) ===

export interface GearRecommendation {
  slot: string;
  items: {
    id: number;
    name: string;
    icon: string;
    itemLevel: number;
    usagePercent: number;
    source: string;
  }[];
}

export interface StatPriority {
  stat: string;
  percent: number;
  avgRating: number;
}

export interface EnchantRecommendation {
  slot: string;
  enchants: {
    id: number;
    name: string;
    stat: string;
    usagePercent: number;
  }[];
}

export interface GemRecommendation {
  type: string; // "Algari Diamond", "Prismatic", etc.
  gems: {
    id: number;
    name: string;
    stat: string;
    usagePercent: number;
  }[];
}

export interface EmbellishmentRecommendation {
  name: string;
  effect: string;
  usagePercent: number;
}

export interface SpecBuild {
  specId: number;
  className: string;
  specName: string;
  classColor: string;
  gameMode: GameMode;
  talents: TalentLoadout;
  statPriority: StatPriority[];
  gear: GearRecommendation[];
  enchants: EnchantRecommendation[];
  gems: GemRecommendation[];
  embellishments: EmbellishmentRecommendation[];
  racialDistribution: { race: string; faction: string; percent: number }[];
  sampleSize: number;
  lastUpdated: string;
}

// === META RANKINGS ===

export interface SpecRanking {
  specId: number;
  className: string;
  specName: string;
  classColor: string;
  tier: 'S' | 'A' | 'B' | 'C' | 'D';
  representation: number;
  winRate: number;
  avgRating: number;
  gamesPlayed: number;
  trend: 'up' | 'down' | 'stable';
  changePercent?: number;
}

export interface MetaSnapshot {
  gameMode: GameMode;
  role: 'dps' | 'healer' | 'tank' | 'all';
  specs: SpecRanking[];
  totalGames: number;
  lastUpdated: string;
}

// === PLAYER PROFILE ===

export interface Character {
  name: string;
  realm: string;
  realmSlug: string;
  region: Region;
  class: WowClass;
  className: string;
  spec: string;
  specId: number;
  faction: 'alliance' | 'horde';
  race: string;
  level: number;
  itemLevel: number;
  equippedItemLevel: number;
  avatarUrl?: string;
  insetUrl?: string; // Full character render
  mainRawUrl?: string;
  guild?: { name: string; realm: string; faction: string };
  title?: string;
  achievementPoints?: number;
  lastLogin?: string;
}

export interface RatingEntry {
  bracket: string;
  bracketName: string;
  current: number;
  seasonHigh: number;
  weeklyHigh: number;
  allTimeHigh: number;
  wins: number;
  losses: number;
  winRate: number;
  tier?: { id: number; name: string };
  rank?: number; // Position on leaderboard
}

export interface RatingHistory {
  bracket: string;
  data: { date: string; rating: number; wins: number; losses: number }[];
}

export interface Achievement {
  id: number;
  name: string;
  description: string;
  icon: string;
  earnedDate: string;
  points: number;
  category: 'gladiator' | 'duelist' | 'rival' | 'challenger' | 'combatant' | 'elite' | 'hero' | 'legend' | 'other';
  isAccountWide: boolean;
}

export interface AltCharacter {
  name: string;
  realm: string;
  realmSlug: string;
  class: WowClass;
  className: string;
  spec: string;
  level: number;
  faction: 'alliance' | 'horde';
  ratings: { bracket: string; current: number; seasonHigh: number }[];
  achievementPoints: number;
  lastPlayed?: string;
}

export interface MatchHistory {
  bracket: string;
  timestamp: string;
  result: 'win' | 'loss';
  ratingChange: number;
  newRating: number;
  mmr?: number;
  duration?: number;
  map?: string;
  teammates?: { name: string; class: WowClass; spec: string }[];
  enemies?: { name: string; class: WowClass; spec: string }[];
}

export interface PlayerProfile {
  character: Character;
  ratings: RatingEntry[];
  ratingHistory: RatingHistory[];
  achievements: Achievement[];
  alts: AltCharacter[];
  equipment?: CharacterEquipment;
  stats?: CharacterStats;
  talents?: TalentLoadout;
  matchHistory?: MatchHistory[];
  honorLevel: number;
  honorableKills: number;
  highestPvPTier?: string;
  pvpTitles?: string[];
}

// === LEADERBOARD ===

export interface LeaderboardEntry {
  rank: number;
  character: {
    name: string;
    realm: string;
    realmSlug: string;
    region: Region;
    class?: WowClass;
    className?: string;
    spec?: string;
    specId?: number;
    faction: 'alliance' | 'horde';
    race?: string;
  };
  rating: number;
  seasonHigh?: number;
  wins: number;
  losses: number;
  winRate: number;
  tier?: { id: number; name: string };
}

export interface LeaderboardFilters {
  bracket: GameMode;
  region: Region | 'all';
  faction: 'alliance' | 'horde' | 'all';
  class?: WowClass;
  spec?: number;
  minRating?: number;
  page?: number;
  pageSize?: number;
}

export interface LeaderboardResponse {
  bracket: string;
  season: number;
  entries: LeaderboardEntry[];
  totalCount: number;
  lastUpdated: string;
}

// === PVP SEASON ===

export interface PvPSeason {
  id: number;
  name: string;
  startDate: string;
  endDate?: string;
  isCurrent: boolean;
}

export interface PvPTier {
  id: number;
  name: string;
  minRating: number;
  maxRating: number;
  color: string;
  rewards?: string[];
}

export const PVP_TIERS: PvPTier[] = [
  { id: 1, name: 'Unranked', minRating: 0, maxRating: 1399, color: '#9d9d9d' },
  { id: 2, name: 'Combatant', minRating: 1400, maxRating: 1599, color: '#1eff00' },
  { id: 3, name: 'Challenger', minRating: 1600, maxRating: 1799, color: '#1eff00' },
  { id: 4, name: 'Rival', minRating: 1800, maxRating: 2099, color: '#0070dd' },
  { id: 5, name: 'Duelist', minRating: 2100, maxRating: 2399, color: '#a335ee' },
  { id: 6, name: 'Elite', minRating: 2400, maxRating: 2599, color: '#ff8000' },
  { id: 7, name: 'Gladiator', minRating: 2600, maxRating: 2999, color: '#ff8000' },
  { id: 8, name: 'Legend', minRating: 3000, maxRating: 9999, color: '#e6cc80' },
];

// === REGIONS ===

export const REGIONS = [
  { id: 'eu', name: 'Europe', apiHost: 'eu.api.blizzard.com' },
  { id: 'us', name: 'US', apiHost: 'us.api.blizzard.com' },
  { id: 'kr', name: 'Korea', apiHost: 'kr.api.blizzard.com' },
  { id: 'tw', name: 'Taiwan', apiHost: 'tw.api.blizzard.com' },
] as const;

export type Region = typeof REGIONS[number]['id'];

// === UTILITY FUNCTIONS ===

export function getClassInfo(classId: WowClass) {
  return CLASSES.find(c => c.id === classId);
}

export function getClassById(classId: number) {
  // WoW class IDs
  const classMap: Record<number, WowClass> = {
    1: 'warrior', 2: 'paladin', 3: 'hunter', 4: 'rogue', 5: 'priest',
    6: 'death-knight', 7: 'shaman', 8: 'mage', 9: 'warlock', 10: 'monk',
    11: 'druid', 12: 'demon-hunter', 13: 'evoker',
  };
  return classMap[classId];
}

export function getSpecInfo(specId: number) {
  for (const cls of CLASSES) {
    const spec = cls.specs.find(s => s.id === specId);
    if (spec) return { ...spec, classId: cls.id, className: cls.name, classColor: cls.color };
  }
  return null;
}

export function normalizeClassName(name: string): WowClass {
  return name.toLowerCase().replace(/\s+/g, '-') as WowClass;
}

export function getTierForRating(rating: number): PvPTier {
  for (let i = PVP_TIERS.length - 1; i >= 0; i--) {
    if (rating >= PVP_TIERS[i].minRating) return PVP_TIERS[i];
  }
  return PVP_TIERS[0];
}

export function getRatingColor(rating: number): string {
  return getTierForRating(rating).color;
}

export function getRatingTitle(rating: number): string {
  return getTierForRating(rating).name;
}

export function formatWinRate(wins: number, losses: number): number {
  const total = wins + losses;
  return total > 0 ? Math.round((wins / total) * 100) : 0;
}

export function formatNumber(num: number): string {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
  return num.toString();
}

export function getBracketName(bracket: string): string {
  const names: Record<string, string> = {
    'shuffle': 'Solo Shuffle',
    'arena-2v2': '2v2 Arena',
    'arena-3v3': '3v3 Arena',
    '2v2': '2v2 Arena',
    '3v3': '3v3 Arena',
    'rbg': 'Rated BG',
    'blitz': 'Blitz',
  };
  return names[bracket] || bracket;
}

export function getItemQualityColor(quality: string): string {
  const colors: Record<string, string> = {
    poor: '#9d9d9d',
    common: '#ffffff',
    uncommon: '#1eff00',
    rare: '#0070dd',
    epic: '#a335ee',
    legendary: '#ff8000',
    artifact: '#e6cc80',
  };
  return colors[quality] || '#ffffff';
}
