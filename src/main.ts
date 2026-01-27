/**
 * Electron Main Process - Handles Blizzard API and window management
 */

import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'path';
import { BlizzardAPI, createAPI } from './api/blizzard';
import { Region } from './types/wow';

let mainWindow: BrowserWindow | null = null;
let api: BlizzardAPI = createAPI();

// Store config (in production, use electron-store or similar)
let config = {
  clientId: '',
  clientSecret: '',
  region: 'eu' as Region,
};

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1000,
    minHeight: 700,
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

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());
app.on('activate', () => {
  if (mainWindow === null) createWindow();
});

// === IPC Handlers ===

ipcMain.handle('api:setConfig', async (_, newConfig: Partial<typeof config>) => {
  config = { ...config, ...newConfig };
  api.setConfig(config);
  return { success: true };
});

ipcMain.handle('api:getConfig', async () => {
  return {
    clientId: config.clientId ? '••••••••' : '',
    hasSecret: !!config.clientSecret,
    region: config.region,
  };
});

ipcMain.handle('api:searchCharacter', async (_, name: string, realm: string) => {
  if (!config.clientId || !config.clientSecret) {
    return { error: 'API not configured. Go to Settings and enter your Blizzard API credentials.' };
  }
  const character = await api.searchCharacter(name, realm);
  return character || { error: 'Character not found' };
});

ipcMain.handle('api:getPvPStats', async (_, name: string, realm: string) => {
  if (!config.clientId || !config.clientSecret) {
    return { error: 'API not configured' };
  }
  const stats = await api.getPvPStats(name, realm);
  return stats || { error: 'PvP stats not found' };
});

ipcMain.handle('api:getLeaderboard', async (_, bracket: '2v2' | '3v3' | 'rbg') => {
  if (!config.clientId || !config.clientSecret) {
    return { error: 'API not configured' };
  }
  return await api.getLeaderboard(bracket);
});
