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
});
