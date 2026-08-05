// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://turf.build', // apex custom domain — canonical URLs + sitemap. No `base`: served from root.
  integrations: [sitemap()],
});
