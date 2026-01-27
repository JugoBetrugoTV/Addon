/**
 * WoW PvP Types - Complete data structures
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

// === GAME MODES ===

export type GameMode = 'solo' | '2v2' | '3v3' | 'rbg' | 'blitz' | 'm+';

export const GAME_MODES: { id: GameMode; name: string; isPvP: boolean }[] = [
  { id: 'solo', name: 'Solo Shuffle', isPvP: true },
  { id: '2v2', name: '2v2 Arena', isPvP: true },
  { id: '3v3', name: '3v3 Arena', isPvP: true },
  { id: 'rbg', name: 'Rated BG', isPvP: true },
  { id: 'blitz', name: 'Blitz', isPvP: true },
  { id: 'm+', name: 'Mythic+', isPvP: false },
];

// === TALENTS ===

export interface TalentNode {
  id: number;
  name: string;
  icon: string;
  row: number;
  col: number;
  usagePercent: number;  // 0-100, for heatmap coloring
  maxRank: number;
  description: string;
}

export interface TalentBuild {
  specId: number;
  gameMode: GameMode;
  talents: TalentNode[];
  pvpTalents: TalentNode[];
  popularity: number;
  winRate: number;
  sampleSize: number;
}

// === GEAR & STATS ===

export interface GearItem {
  id: number;
  name: string;
  slot: string;
  icon: string;
  itemLevel: number;
  usagePercent: number;
  source: string;  // "Raid", "M+", "PvP Vendor", "Crafted", etc.
}

export interface StatPriority {
  stat: string;
  percent: number;  // How many top players prioritize this
}

export interface Enchant {
  slot: string;
  name: string;
  stat: string;
  usagePercent: number;
}

export interface Gem {
  name: string;
  stat: string;
  usagePercent: number;
}

export interface Embellishment {
  name: string;
  effect: string;
  usagePercent: number;
}

export interface SpecBuild {
  specId: number;
  gameMode: GameMode;
  talents: TalentNode[];
  pvpTalents: TalentNode[];
  stats: StatPriority[];
  gear: GearItem[];
  enchants: Enchant[];
  gems: Gem[];
  embellishments: Embellishment[];
  races: { name: string; percent: number }[];
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
  representation: number;  // % of ladder
  winRate: number;
  avgRating: number;
  trend: 'up' | 'down' | 'stable';
}

export interface MetaSnapshot {
  gameMode: GameMode;
  role: 'dps' | 'healer' | 'tank' | 'all';
  specs: SpecRanking[];
  lastUpdated: string;
}

// === PLAYER PROFILE ===

export interface Character {
  name: string;
  realm: string;
  region: 'eu' | 'us' | 'kr' | 'tw';
  class: WowClass;
  spec: string;
  specId: number;
  faction: 'alliance' | 'horde';
  race: string;
  level: number;
  itemLevel: number;
  avatarUrl?: string;
}

export interface RatingEntry {
  bracket: string;
  current: number;
  seasonHigh: number;
  allTimeHigh: number;
  wins: number;
  losses: number;
}

export interface RatingHistory {
  bracket: string;
  data: { date: string; rating: number }[];
}

export interface Achievement {
  id: number;
  name: string;
  description: string;
  icon: string;
  earnedDate: string;
  category: 'gladiator' | 'duelist' | 'rival' | 'challenger' | 'combatant' | 'elite' | 'other';
}

export interface AltCharacter {
  name: string;
  realm: string;
  class: WowClass;
  spec: string;
  ratings: { bracket: string; current: number; high: number }[];
}

export interface PlayerProfile {
  character: Character;
  ratings: RatingEntry[];
  ratingHistory: RatingHistory[];
  achievements: Achievement[];
  alts: AltCharacter[];
  honorLevel: number;
  honorableKills: number;
}

// === LEADERBOARD ===

export interface LeaderboardEntry {
  rank: number;
  character: Character;
  rating: number;
  wins: number;
  losses: number;
  winRate: number;
  lastPlayed?: string;
}

export interface LeaderboardFilters {
  bracket: string;
  region: 'eu' | 'us' | 'kr' | 'tw' | 'all';
  faction: 'alliance' | 'horde' | 'all';
  class?: WowClass;
  spec?: number;
}

// === REGIONS ===

export const REGIONS = [
  { id: 'eu', name: 'Europe' },
  { id: 'us', name: 'US' },
  { id: 'kr', name: 'Korea' },
  { id: 'tw', name: 'Taiwan' },
] as const;

export type Region = typeof REGIONS[number]['id'];

// === UTILITY ===

export function getClassInfo(classId: WowClass) {
  return CLASSES.find(c => c.id === classId);
}

export function getSpecInfo(specId: number) {
  for (const cls of CLASSES) {
    const spec = cls.specs.find(s => s.id === specId);
    if (spec) return { ...spec, classId: cls.id, className: cls.name, classColor: cls.color };
  }
  return null;
}

export function getRatingColor(rating: number): string {
  if (rating >= 2400) return '#ff8000';  // Gladiator - Orange
  if (rating >= 2100) return '#a335ee';  // Duelist - Purple
  if (rating >= 1800) return '#0070dd';  // Rival - Blue
  if (rating >= 1600) return '#1eff00';  // Challenger - Green
  if (rating >= 1400) return '#ffffff';  // Combatant - White
  return '#9d9d9d';  // Unranked - Gray
}

export function getRatingTitle(rating: number): string {
  if (rating >= 2400) return 'Gladiator';
  if (rating >= 2100) return 'Duelist';
  if (rating >= 1800) return 'Rival';
  if (rating >= 1600) return 'Challenger';
  if (rating >= 1400) return 'Combatant';
  return 'Unranked';
}
