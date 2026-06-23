import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  base: '/veritask-main/',
  preview: {
    port: 5173,
    host: '127.0.0.1',
    strictPort: true
  },
  build: {
    outDir: 'dist'
  }
});
