// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://turf.build', // apex custom domain — canonical URLs + sitemap. No `base`: served from root.
  // Default compressHTML (true) trims whitespace at text↔inline-element boundaries, gluing words
  // together when the source wraps a <strong>/<a>/<code> onto its own line (e.g. "is<strong>planned").
  // Disable it so the browser's normal whitespace collapsing keeps a single space at those seams.
  compressHTML: false,
  integrations: [sitemap()],
});
