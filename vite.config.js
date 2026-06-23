import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  base: '/Veritask-project/',
  preview: {
    port: 5173,
    host: '127.0.0.1',
    strictPort: true
  },
  build: {
    outDir: 'dist'
  }
});
