/**
 * Electron Main Process - Handles Blizzard API and window management
 */

import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'path';
import { BlizzardAPI, createAPI } from './api/blizzard';
import { Region, GameMode, LFGFilters, LFGPost } from './types/wow';

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

// Activity tracker (Drustvar style - climbers/fallers)
ipcMain.handle('api:getActivityTracker', async (_, bracket: GameMode) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured' };
  }
  try {
    return await api.getActivityTracker(bracket);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch activity data' };
  }
});

// Class representation stats
ipcMain.handle('api:getRepresentationStats', async (_, bracket: GameMode, minRating: number) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured' };
  }
  try {
    return await api.getRepresentationStats(bracket, minRating);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch representation stats' };
  }
});

// Top players across all brackets
ipcMain.handle('api:getTopPlayers', async (_, limit: number) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured' };
  }
  try {
    return await api.getTopPlayers(limit);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch top players' };
  }
});

// Talent heatmap for spec
ipcMain.handle('api:getTalentHeatmap', async (_, specId: number, bracket: GameMode) => {
  try {
    return await api.getTalentHeatmap(specId, bracket);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch talent heatmap' };
  }
});

// Gear analysis for spec
ipcMain.handle('api:getGearAnalysis', async (_, specId: number, bracket: GameMode) => {
  try {
    return await api.getGearAnalysis(specId, bracket);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch gear analysis' };
  }
});

// LFG - Get listings
ipcMain.handle('api:getLFGListings', async (_, filters: LFGFilters) => {
  try {
    return await api.getLFGListings(filters);
  } catch (error: any) {
    return { error: error.message || 'Failed to fetch LFG listings' };
  }
});

// LFG - Create listing
ipcMain.handle('api:createLFGListing', async (_, post: LFGPost, characterName: string, realm: string) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured' };
  }
  try {
    const listing = await api.createLFGListing(post, characterName, realm);
    if (!listing) {
      return { error: 'Failed to create listing - character not found' };
    }
    return listing;
  } catch (error: any) {
    return { error: error.message || 'Failed to create LFG listing' };
  }
});

// LFG - Delete listing
ipcMain.handle('api:deleteLFGListing', async (_, id: string) => {
  try {
    const success = await api.deleteLFGListing(id);
    return { success };
  } catch (error: any) {
    return { error: error.message || 'Failed to delete listing' };
  }
});

// Track player (rating history)
ipcMain.handle('api:trackPlayer', async (_, name: string, realm: string) => {
  if (!api.isConfigured()) {
    return { error: 'API not configured' };
  }
  try {
    return await api.trackPlayer(name, realm);
  } catch (error: any) {
    return { error: error.message || 'Failed to track player' };
  }
});

// Get tracked player data
ipcMain.handle('api:getTrackedPlayer', async (_, name: string, realm: string) => {
  return api.getTrackedPlayer(name, realm);
});

// Get all tracked players
ipcMain.handle('api:getTrackedPlayers', async () => {
  return api.getTrackedPlayers();
});

// Favorites
ipcMain.handle('api:addFavorite', async (_, name: string, realm: string) => {
  api.addFavorite(name, realm);
  return { success: true };
});

ipcMain.handle('api:removeFavorite', async (_, name: string, realm: string) => {
  api.removeFavorite(name, realm);
  return { success: true };
});

ipcMain.handle('api:getFavorites', async () => {
  return api.getFavorites();
});
