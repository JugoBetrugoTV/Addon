/**
 * Preload Script - Exposes safe IPC methods to renderer
 */

import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  setConfig: (config: { clientId?: string; clientSecret?: string; region?: string }) =>
    ipcRenderer.invoke('api:setConfig', config),

  getConfig: () => ipcRenderer.invoke('api:getConfig'),

  searchCharacter: (name: string, realm: string) =>
    ipcRenderer.invoke('api:searchCharacter', name, realm),

  getPvPStats: (name: string, realm: string) =>
    ipcRenderer.invoke('api:getPvPStats', name, realm),

  getLeaderboard: (bracket: '2v2' | '3v3' | 'rbg') =>
    ipcRenderer.invoke('api:getLeaderboard', bracket),
});

contextBridge.exposeInMainWorld('platform', {
  isElectron: true,
});
