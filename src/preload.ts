/**
 * Preload Script - Exposes safe IPC methods to renderer
 */

import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  // Configuration
  setConfig: (config: { clientId?: string; clientSecret?: string; region?: string }) =>
    ipcRenderer.invoke('api:setConfig', config),

  getConfig: () =>
    ipcRenderer.invoke('api:getConfig'),

  getRegion: () =>
    ipcRenderer.invoke('api:getRegion'),

  // Player Profile (full data: ratings, achievements, equipment, stats, talents)
  getPlayerProfile: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getPlayerProfile', name, realm),

  // Leaderboard
  getLeaderboard: (bracket: string, filters?: { page?: number; pageSize?: number }) =>
    ipcRenderer.invoke('api:getLeaderboard', bracket, filters),

  enrichLeaderboard: (entries: any[]) =>
    ipcRenderer.invoke('api:enrichLeaderboard', entries),

  // Spec Build (talents, gear, stats)
  getSpecBuild: (specId: number, gameMode: string) =>
    ipcRenderer.invoke('api:getSpecBuild', specId, gameMode),

  // Meta Rankings
  getMetaRankings: (gameMode: string, role: string) =>
    ipcRenderer.invoke('api:getMetaRankings', gameMode, role),

  // PvP Season
  getCurrentSeason: () =>
    ipcRenderer.invoke('api:getCurrentSeason'),

  // Realm Search
  searchRealms: (query: string) =>
    ipcRenderer.invoke('api:searchRealms', query),

  // Activity Tracker (Drustvar style)
  getActivityTracker: (bracket: string) =>
    ipcRenderer.invoke('api:getActivityTracker', bracket),

  // Class Representation Stats
  getRepresentationStats: (bracket: string, minRating: number) =>
    ipcRenderer.invoke('api:getRepresentationStats', bracket, minRating),

  // Top Players (multi-bracket rankings)
  getTopPlayers: (limit: number) =>
    ipcRenderer.invoke('api:getTopPlayers', limit),

  // Talent Heatmap
  getTalentHeatmap: (specId: number, bracket: string) =>
    ipcRenderer.invoke('api:getTalentHeatmap', specId, bracket),

  // Gear Analysis
  getGearAnalysis: (specId: number, bracket: string) =>
    ipcRenderer.invoke('api:getGearAnalysis', specId, bracket),

  // LFG System
  getLFGListings: (filters: any) =>
    ipcRenderer.invoke('api:getLFGListings', filters),

  createLFGListing: (post: any, characterName: string, realm: string) =>
    ipcRenderer.invoke('api:createLFGListing', post, characterName, realm),

  deleteLFGListing: (id: string) =>
    ipcRenderer.invoke('api:deleteLFGListing', id),

  // Player Tracking
  trackPlayer: (name: string, realm: string) =>
    ipcRenderer.invoke('api:trackPlayer', name, realm),

  getTrackedPlayer: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getTrackedPlayer', name, realm),

  getTrackedPlayers: () =>
    ipcRenderer.invoke('api:getTrackedPlayers'),

  // Favorites
  addFavorite: (name: string, realm: string) =>
    ipcRenderer.invoke('api:addFavorite', name, realm),

  removeFavorite: (name: string, realm: string) =>
    ipcRenderer.invoke('api:removeFavorite', name, realm),

  getFavorites: () =>
    ipcRenderer.invoke('api:getFavorites'),

  // ===========================================
  // === GUILD API ===
  // ===========================================

  getGuildInfo: (guildName: string, realm: string) =>
    ipcRenderer.invoke('api:getGuildInfo', guildName, realm),

  getGuildRoster: (guildName: string, realm: string) =>
    ipcRenderer.invoke('api:getGuildRoster', guildName, realm),

  getGuildAchievements: (guildName: string, realm: string) =>
    ipcRenderer.invoke('api:getGuildAchievements', guildName, realm),

  // ===========================================
  // === MYTHIC+ API ===
  // ===========================================

  getMythicPlusProfile: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getMythicPlusProfile', name, realm),

  getMythicPlusAffixes: () =>
    ipcRenderer.invoke('api:getMythicPlusAffixes'),

  getMythicPlusDungeons: () =>
    ipcRenderer.invoke('api:getMythicPlusDungeons'),

  // ===========================================
  // === SPELL/TALENT API ===
  // ===========================================

  getSpellDetails: (spellId: number) =>
    ipcRenderer.invoke('api:getSpellDetails', spellId),

  getPvPTalentDetails: (pvpTalentId: number) =>
    ipcRenderer.invoke('api:getPvPTalentDetails', pvpTalentId),

  getTalentTree: (specId: number) =>
    ipcRenderer.invoke('api:getTalentTree', specId),

  // ===========================================
  // === ITEM API ===
  // ===========================================

  getItemDetails: (itemId: number) =>
    ipcRenderer.invoke('api:getItemDetails', itemId),

  searchItems: (query: string, limit?: number) =>
    ipcRenderer.invoke('api:searchItems', query, limit),

  // ===========================================
  // === RAID API ===
  // ===========================================

  getRaidProgress: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getRaidProgress', name, realm),

  getRaidInstances: () =>
    ipcRenderer.invoke('api:getRaidInstances'),

  // ===========================================
  // === REAL DATA TALENT/GEAR ===
  // ===========================================

  getTalentHeatmapReal: (specId: number, bracket: string) =>
    ipcRenderer.invoke('api:getTalentHeatmapReal', specId, bracket),

  getGearAnalysisReal: (specId: number, bracket: string) =>
    ipcRenderer.invoke('api:getGearAnalysisReal', specId, bracket),

  // ===========================================
  // === CHARACTER SUMMARY ===
  // ===========================================

  getCharacterSummary: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getCharacterSummary', name, realm),

  // ===========================================
  // === APP UPDATES ===
  // ===========================================

  checkForUpdates: () =>
    ipcRenderer.invoke('app:checkForUpdates'),

  getVersion: () =>
    ipcRenderer.invoke('app:getVersion'),
});
