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
});
