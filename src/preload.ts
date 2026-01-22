import { contextBridge } from 'electron';

contextBridge.exposeInMainWorld('platform', {
  isElectron: true,
});
