/**
 * Preload Script - Exposes safe IPC methods to renderer
 */

import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  setConfig: (config: { clientId?: string; clientSecret?: string; region?: string }) =>
    ipcRenderer.invoke('api:setConfig', config),

  getConfig: () =>
    ipcRenderer.invoke('api:getConfig'),

  getPlayerProfile: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getPlayerProfile', name, realm),

  getLeaderboard: (bracket: '2v2' | '3v3' | 'rbg' | 'shuffle') =>
    ipcRenderer.invoke('api:getLeaderboard', bracket),

  getSpecBuild: (specId: number, gameMode: string) =>
    ipcRenderer.invoke('api:getSpecBuild', specId, gameMode),

  getMetaRankings: (gameMode: string, role: string) =>
    ipcRenderer.invoke('api:getMetaRankings', gameMode, role),
});
