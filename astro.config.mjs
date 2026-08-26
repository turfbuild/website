// @ts-check
import { execFileSync } from 'node:child_process';
import { defineConfig } from 'astro/config';
import sitemap, { ChangeFreqEnum } from '@astrojs/sitemap';

// Per-page `lastmod` from git, so the sitemap says which pages actually changed
// rather than stamping the whole site with the build time. `/` maps to the repo
// HEAD (the home page composes eight components — any of them changing changes
// the page); every other URL maps to its own page source.
//
// NOTE: this needs real history. The deploy workflow sets `fetch-depth: 0` on
// checkout for exactly this reason — under the default shallow clone `git log`
// returns nothing for most paths and the lastmod would silently vanish in CI
// while still working locally. The `?? headDate()` fallback keeps the build green
// in any environment without git, at the cost of a coarse date.
/** @param {string[]} args */
const git = (args) => {
  try {
    const out = execFileSync('git', args, { encoding: 'utf8' }).trim();
    return out || undefined;
  } catch {
    return undefined;
  }
};
const headDate = () => git(['log', '-1', '--format=%cI']);
/** @param {string} path */
const fileDate = (path) => git(['log', '-1', '--format=%cI', '--', path]);

/** @param {string} pathname */
const sourceFor = (pathname) => {
  const rest = pathname.replace(/^\/|\/$/g, '');
  return rest === '' ? null : `src/pages/${rest}.astro`;
};

// Google ignores changefreq/priority; Bing and other crawlers still read them.
// Cheap to carry, so they're set to reflect real update cadence and importance.
const { WEEKLY, MONTHLY, YEARLY } = ChangeFreqEnum;
/** @type {Record<string, {priority: number, changefreq: ChangeFreqEnum}>} */
const WEIGHTS = {
  '/': { priority: 1.0, changefreq: WEEKLY },
  '/compatibility/': { priority: 0.9, changefreq: WEEKLY },
  '/get-started/': { priority: 0.9, changefreq: WEEKLY },
  '/demo/': { priority: 0.7, changefreq: MONTHLY },
  '/demo/scalr/': { priority: 0.7, changefreq: MONTHLY },
  '/docs/': { priority: 0.6, changefreq: MONTHLY },
  '/pricing/': { priority: 0.6, changefreq: MONTHLY },
  '/contact/': { priority: 0.5, changefreq: YEARLY },
  '/privacy/': { priority: 0.3, changefreq: YEARLY },
};

// https://astro.build/config
export default defineConfig({
  site: 'https://turf.build', // apex custom domain — canonical URLs + sitemap. No `base`: served from root.
  // The build emits directory-style routes (`/docs/index.html`), so the canonical
  // and the sitemap both carry a trailing slash. `always` makes the dev server
  // enforce the same shape, so an internal link written without one fails locally
  // instead of silently costing a GitHub Pages 301 in production.
  trailingSlash: 'always',
  // Default compressHTML (true) trims whitespace at text↔inline-element boundaries, gluing words
  // together when the source wraps a <strong>/<a>/<code> onto its own line (e.g. "is<strong>planned").
  // Disable it so the browser's normal whitespace collapsing keeps a single space at those seams.
  compressHTML: false,
  integrations: [
    sitemap({
      serialize(item) {
        const { pathname } = new URL(item.url);
        const source = sourceFor(pathname);
        const lastmod = (source ? fileDate(source) : headDate()) ?? headDate();
        return { ...item, ...WEIGHTS[pathname], ...(lastmod ? { lastmod } : {}) };
      },
    }),
  ],
});
