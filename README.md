# turf.build

The product marketing site for **Turf** — a drop-in replacement for Terraform that lets an AI
agent operate your infrastructure, governed by the plan.

Built with [Astro](https://astro.build), deployed to **GitHub Pages** at the apex domain
`turf.build`. Ships as a static site with zero client JS except one small inlined hero animation.

## Develop

```bash
npm install
npm run dev        # http://localhost:4321
npm run build      # → dist/
npm run preview    # serve the built site
npm run check      # astro check (types + templates)
```

Node 22+ (CI pins Node 22).

## Structure

```
public/           CNAME, favicon.svg, og.png, robots.txt, fonts/*.woff2
src/
  styles/global.css     the whole design system (:root tokens, components) — imported once
  layouts/Layout.astro  <head>, Turf-leading <title>, footer disclaimer on every page
  components/*.astro     Hero (+ animation), FearStrip, HowItWorks, Compatibility, Solutions,
                         Pillars, Flexibility, Partner, TopNav, Footer
  pages/*.astro          index, compatibility, get-started, pricing, contact, docs, 404
scripts/og.svg           source for public/og.png (see "Regenerate the OG image")
```

The design system comes from the approved home mockup. The Compatibility page is adapted from the
internal language-feature conformance report (FU-ids and code anchors stripped).

## Go-live runbook (GitHub Pages + custom domain)

The build/deploy is automated by `.github/workflows/deploy.yml`. The one-time hosting setup:

1. **Create the repo** (public — free Pages custom domains): `turfbuild/website`, push `main`.
2. **Repo → Settings → Pages → Source = GitHub Actions.** The workflow builds and deploys on every
   push to `main`.
3. **Verify the domain (org-level, prevents takeover):** GitHub → Org Settings → Pages →
   *Verify a domain* → `turf.build` → add the `_github-pages-challenge-turfbuild` TXT record it
   gives you at GoDaddy → Verify.
4. **DNS at GoDaddy** — remove the "Launching Soon" parking/forwarding, then add:
   - Four **A** records, host `@` → `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - Four **AAAA** records, host `@` → `2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`
   - One **CNAME**, host `www` → `turfbuild.github.io`
5. **Repo → Settings → Pages → Custom domain = `turf.build`.** (`public/CNAME` already carries this
   into every build — keep it.)
6. **Enforce HTTPS** once GitHub finishes provisioning the Let's Encrypt cert (minutes–24h).

Verify:

```bash
dig +short turf.build A
dig +short www.turf.build CNAME
curl -sI https://turf.build         # expect HTTP/2 200
curl -sI https://www.turf.build     # expect 301 → https://turf.build
```

## Newsletter

The footer form posts to Buttondown. Before launch, create the newsletter handle **`turf`** at
buttondown.com (the form action is `https://buttondown.email/api/emails/embed-subscribe/turf`).
Until then the "or email contact@turf.build" fallback works.

## Regenerate the OG image

`public/og.png` (1200×630) is rasterized from `scripts/og.svg`:

```bash
qlmanage -t -s 1200 -o /tmp/ogout scripts/og.svg
cp /tmp/ogout/og.svg.png public/og.png
sips -c 630 1200 public/og.png       # crop the square to 1200×630
```

The SVG is authored on a 1200×1200 canvas with the content in the middle 630-row band so the
crop lands correctly.
