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
    width: 1600,
    height: 1000,
    minWidth: 1200,
    minHeight: 800,
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

// Configuration
ipcMain.handle('api:setConfig', async (_, newConfig: Partial<typeof config>) => {
  config = { ...config, ...newConfig };
  api.setConfig(config);
  return { success: true };
});

ipcMain.handle('api:getConfig', async () => ({
  clientId: config.clientId ? '••••••••' : '',
  hasSecret: !!config.clientSecret,
  region: config.region,
  isConfigured: api.isConfigured(),
}));

// Player profile with full data (ratings, achievements, equipment, stats, talents)
ipcMain.handle('api:getPlayerProfile', async (_, name: string, realm: string) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured. Go to Settings and enter your Blizzard API credentials.' };
  }
  try {
    const profile = await api.getPlayerProfile(name, realm);
    if (!profile) {
      return { error: 'Character not found. Check the name and realm spelling.' };
    }
    return profile;
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch player profile' };
  }
});

// Leaderboard with pagination
ipcMain.handle('api:getLeaderboard', async (_, bracket: GameMode, filters?: { page?: number; pageSize?: number }) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured' };
  }
  try {
    return await api.getLeaderboard(bracket, filters);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch leaderboard' };
  }
});

// Enrich leaderboard entries with class/spec data
ipcMain.handle('api:enrichLeaderboard', async (_, entries: any[]) => {
  if (!api.isConfigured()) {
    return entries;
  }
  try {
    return await api.enrichLeaderboardWithClasses(entries);
  } catch {
    return entries;
  }
});

// Spec build (talents, gear, stats recommendations)
ipcMain.handle('api:getSpecBuild', async (_, specId: number, gameMode: GameMode) => {
  try {
    return await api.getSpecBuild(specId, gameMode);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch spec build' };
  }
});

// Meta rankings
ipcMain.handle('api:getMetaRankings', async (_, gameMode: GameMode, role: 'dps' | 'healer' | 'tank' | 'all') => {
  try {
    return await api.getMetaRankings(gameMode, role);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch meta rankings' };
  }
});

// Current PvP season
ipcMain.handle('api:getCurrentSeason', async () => {
  if (!api.isConfigured()) {
    return { id: 38, name: 'Season 1' };
  }
  try {
    const seasonId = await api.getCurrentSeasonId();
    return { id: seasonId, name: `Season ${seasonId - 37}` };
  } catch {
    return { id: 38, name: 'Season 1' };
  }
});

// Realm search
ipcMain.handle('api:searchRealms', async (_, query: string) => {
  if (!api.isConfigured() || query.length < 2) {
    return [];
  }
  try {
    return await api.searchRealms(query);
  } catch {
    return [];
  }
});

// Get current region
ipcMain.handle('api:getRegion', async () => {
  return api.getRegion();
});
