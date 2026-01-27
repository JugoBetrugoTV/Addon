/**
 * WoW PvP Types - Data structures for Blizzard API responses
 */

export interface Character {
  name: string;
  realm: string;
  region: string;
  class: WowClass;
  spec: string;
  faction: 'alliance' | 'horde';
  race: string;
  level: number;
  itemLevel: number;
  avatarUrl?: string;
}

export interface PvPRating {
  bracket: '2v2' | '3v3' | 'rbg' | 'shuffle';
  rating: number;
  seasonHighest: number;
  weeklyWins: number;
  weeklyLosses: number;
  seasonWins: number;
  seasonLosses: number;
  rank?: number;
}

export interface PvPStats {
  honorableKills: number;
  honorLevel: number;
  ratings: PvPRating[];
}

export interface ArenaMatch {
  timestamp: number;
  bracket: '2v2' | '3v3' | 'shuffle';
  result: 'win' | 'loss';
  ratingChange: number;
  duration: number;
  enemyTeam: MatchPlayer[];
  playerTeam: MatchPlayer[];
  map?: string;
}

export interface MatchPlayer {
  name: string;
  realm: string;
  class: WowClass;
  spec: string;
  rating: number;
  damage?: number;
  healing?: number;
}

export interface TalentBuild {
  specId: number;
  talents: number[];  // talent node IDs
  pvpTalents: number[];
  popularity: number;  // percentage
  winRate: number;
  sampleSize: number;
}

export interface LeaderboardEntry {
  rank: number;
  character: Character;
  rating: number;
  wins: number;
  losses: number;
  winRate: number;
}

export interface SpecStats {
  specId: number;
  className: string;
  specName: string;
  representation: number;  // percentage in bracket
  winRate: number;
  avgRating: number;
  topBuilds: TalentBuild[];
}

export type WowClass =
  | 'warrior' | 'paladin' | 'hunter' | 'rogue' | 'priest'
  | 'death-knight' | 'shaman' | 'mage' | 'warlock' | 'monk'
  | 'druid' | 'demon-hunter' | 'evoker';

export const CLASS_SPECS: Record<WowClass, string[]> = {
  'warrior': ['Arms', 'Fury', 'Protection'],
  'paladin': ['Holy', 'Protection', 'Retribution'],
  'hunter': ['Beast Mastery', 'Marksmanship', 'Survival'],
  'rogue': ['Assassination', 'Outlaw', 'Subtlety'],
  'priest': ['Discipline', 'Holy', 'Shadow'],
  'death-knight': ['Blood', 'Frost', 'Unholy'],
  'shaman': ['Elemental', 'Enhancement', 'Restoration'],
  'mage': ['Arcane', 'Fire', 'Frost'],
  'warlock': ['Affliction', 'Demonology', 'Destruction'],
  'monk': ['Brewmaster', 'Mistweaver', 'Windwalker'],
  'druid': ['Balance', 'Feral', 'Guardian', 'Restoration'],
  'demon-hunter': ['Havoc', 'Vengeance'],
  'evoker': ['Devastation', 'Preservation', 'Augmentation'],
};

export const CLASS_COLORS: Record<WowClass, string> = {
  'warrior': '#C79C6E',
  'paladin': '#F58CBA',
  'hunter': '#ABD473',
  'rogue': '#FFF569',
  'priest': '#FFFFFF',
  'death-knight': '#C41F3B',
  'shaman': '#0070DE',
  'mage': '#69CCF0',
  'warlock': '#9482C9',
  'monk': '#00FF96',
  'druid': '#FF7D0A',
  'demon-hunter': '#A330C9',
  'evoker': '#33937F',
};

export type Region = 'eu' | 'us' | 'kr' | 'tw';

export const REGIONS: { id: Region; name: string; apiHost: string }[] = [
  { id: 'eu', name: 'Europe', apiHost: 'eu.api.blizzard.com' },
  { id: 'us', name: 'US', apiHost: 'us.api.blizzard.com' },
  { id: 'kr', name: 'Korea', apiHost: 'kr.api.blizzard.com' },
  { id: 'tw', name: 'Taiwan', apiHost: 'tw.api.blizzard.com' },
];
