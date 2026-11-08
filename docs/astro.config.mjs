// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// The Turf docs: a Starlight site served at turf.build/docs/. It is built on its own (this
// directory has its own package.json) and copied into the marketing site's dist/docs by the root
// `npm run build`, so one GitHub Pages deploy carries both. `base` makes every asset and link
// resolve under /docs; the marketing site keeps the apex.
export default defineConfig({
  site: 'https://turf.build',
  base: '/docs',
  trailingSlash: 'always',
  integrations: [
    starlight({
      title: 'Turf',
      titleDelimiter: '—',
      description:
        'Turf documentation: install the MCP server and engine, connect your agent, deploy and tear down with up and destroy, the provider environment, running Turf in a cluster, and the MCP reference.',
      favicon: '/favicon.svg',
      logo: { src: './src/assets/wordmark.svg', alt: 'turf.build', replacesTitle: true },
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/turfbuild/turf' },
        { icon: 'discord', label: 'Discord', href: 'https://turf.build/discord/' },
      ],
      editLink: {},
      lastUpdated: false,
      pagination: true,
      customCss: ['./src/styles/docs.css'],
      components: {
        Footer: './src/components/Footer.astro',
        SiteTitle: './src/components/SiteTitle.astro',
      },
      head: [
        { tag: 'meta', attrs: { property: 'og:site_name', content: 'Turf' } },
        { tag: 'meta', attrs: { name: 'twitter:site', content: '@turfbuild' } },
      ],
      sidebar: [
        { label: 'Start here', items: [{ autogenerate: { directory: 'start' } }] },
        { label: 'Concepts', items: [{ autogenerate: { directory: 'concepts' } }] },
        { label: 'Using Turf', items: [{ autogenerate: { directory: 'using' } }] },
        { label: 'Provider environment and credentials', items: [{ autogenerate: { directory: 'environment' } }] },
        { label: 'Authoring configurations', items: [{ autogenerate: { directory: 'authoring' } }] },
        { label: 'The Turf CLI', items: [{ autogenerate: { directory: 'cli' } }] },
        { label: 'Running Turf in a cluster', items: [{ autogenerate: { directory: 'cluster' } }] },
        {
          label: 'MCP reference',
          items: [
            { slug: 'reference/server' },
            { slug: 'reference/result-shape' },
            {
              label: 'Tools',
              collapsed: true,
              items: [
                { label: 'Configuration', items: ['reference/tools/init'] },
                { label: 'Workspaces', items: ['reference/tools/open', 'reference/tools/close', 'reference/tools/status', 'reference/tools/list', 'reference/tools/delete'] },
                { label: 'Convergence', items: ['reference/tools/up', 'reference/tools/destroy', 'reference/tools/refresh', 'reference/tools/import', 'reference/tools/invoke', 'reference/tools/plan', 'reference/tools/apply', 'reference/tools/cancel'] },
                { label: 'State', items: ['reference/tools/show', 'reference/tools/output', 'reference/tools/state_list', 'reference/tools/taint', 'reference/tools/untaint'] },
                { label: 'Providers', items: ['reference/tools/provider_search', 'reference/tools/provider_describe'] },
                { label: 'Skills', items: ['reference/tools/skill_deployment', 'reference/tools/skill_authoring', 'reference/tools/skill_guide', 'reference/tools/read_skill_file'] },
              ],
            },
            { slug: 'reference/prompts' },
            { slug: 'reference/resources' },
            {
              label: 'Skills',
              collapsed: true,
              items: [
                { label: 'Deployment', items: ['reference/skills/deployment', { label: 'References', items: [{ autogenerate: { directory: 'reference/skills/deployment' } }] }] },
                { label: 'Authoring', items: ['reference/skills/authoring', { label: 'References', items: [{ autogenerate: { directory: 'reference/skills/authoring' } }] }] },
                { label: 'Guide', items: ['reference/skills/guide', { label: 'References', items: [{ autogenerate: { directory: 'reference/skills/guide' } }] }] },
              ],
            },
            { slug: 'reference/instructions' },
            { slug: 'reference/slash-commands' },
          ],
        },
        { label: 'Release notes', collapsed: true, items: [{ autogenerate: { directory: 'releases' } }] },
        {
          label: 'More',
          items: [
            { label: 'Telemetry', link: 'https://turf.build/telemetry/' },
            { label: 'Licensing', link: 'https://turf.build/licensing/' },
            { label: 'Pricing', link: 'https://turf.build/pricing/' },
            { label: 'Compatibility', link: 'https://turf.build/compatibility/' },
            { label: 'Examples', link: 'https://github.com/turfbuild/turf-examples' },
          ],
        },
      ],
    }),
  ],
});
