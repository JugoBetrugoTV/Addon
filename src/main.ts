/**
 * Electron Main Process - Handles Blizzard API and window management
 */

import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'path';
import { BlizzardAPI, createAPI } from './api/blizzard';
import { Region, GameMode } from './types/wow';

let mainWindow: BrowserWindow | null = null;
let api: BlizzardAPI = createAPI();

let config = {
  clientId: '',
  clientSecret: '',
  region: 'eu' as Region,
};

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1500,
    height: 950,
    minWidth: 1100,
    minHeight: 750,
    title: 'WoW PvP Analyzer',
    backgroundColor: '#0d1117',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'index.html'));
  mainWindow.setMenu(null);
  mainWindow.on('closed', () => { mainWindow = null; });
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());
app.on('activate', () => { if (!mainWindow) createWindow(); });

// === IPC Handlers ===

ipcMain.handle('api:setConfig', async (_, newConfig: Partial<typeof config>) => {
  config = { ...config, ...newConfig };
  api.setConfig(config);
  return { success: true };
});

ipcMain.handle('api:getConfig', async () => ({
  clientId: config.clientId ? '••••••••' : '',
  hasSecret: !!config.clientSecret,
  region: config.region,
}));

// Player profile with ratings, achievements, alts, history
ipcMain.handle('api:getPlayerProfile', async (_, name: string, realm: string) => {
  if (!config.clientId || !config.clientSecret) {
    return { error: 'API not configured. Go to Settings and enter your Blizzard API credentials.' };
  }
  return await api.getPlayerProfile(name, realm) || { error: 'Character not found' };
});

// Leaderboard
ipcMain.handle('api:getLeaderboard', async (_, bracket: '2v2' | '3v3' | 'rbg' | 'shuffle') => {
  if (!config.clientId || !config.clientSecret) {
    return { error: 'API not configured' };
  }
  return await api.getLeaderboard(bracket);
});

// Spec build (talents, gear, stats, etc.)
ipcMain.handle('api:getSpecBuild', async (_, specId: number, gameMode: GameMode) => {
  return api.getSpecBuild(specId, gameMode);
});

// Meta rankings
ipcMain.handle('api:getMetaRankings', async (_, gameMode: GameMode, role: 'dps' | 'healer' | 'tank' | 'all') => {
  return api.getMetaRankings(gameMode, role);
});
