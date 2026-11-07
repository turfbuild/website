// Copy the built docs (docs/dist, a Starlight site with base /docs) into the marketing site's dist/docs,
// so one GitHub Pages artifact serves turf.build and turf.build/docs/. Run by `npm run build` after both
// builds; fails loudly if either output is missing.
import { cpSync, existsSync, rmSync } from 'node:fs';

const src = new URL('../docs/dist/', import.meta.url);
const dst = new URL('../dist/docs/', import.meta.url);
if (!existsSync(src)) throw new Error('docs/dist is missing: run `npm --prefix docs run build` first');
if (!existsSync(new URL('../dist/', import.meta.url))) throw new Error('dist is missing: run `astro build` first');
rmSync(dst, { recursive: true, force: true });
cpSync(src, dst, { recursive: true });
console.log('docs merged into dist/docs');
