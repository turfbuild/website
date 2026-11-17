// The papers (three since 2026-11-16), described once for the two places that list them: the home
// band (components/Papers.astro) and the index at /reference-architectures/. Each abstract follows the
// paper's own page (pages/reference-architectures/*.astro), which follows the text of record in
// headquarters/marketing/launch/refarch-*.md: change those first. Titles carry no marks here; the
// papers' pages carry the marks notes. `pdf` is the Scarf link without a tag: each page that lists the
// papers adds its own `?src=` (CLAUDE.md, "Papers").
export interface Paper {
  id: string;
  tagline: string;
  title: string;
  abstract: string;
  page: string;
  pdf: string;
  cover: string;
  alt: string;
}

export const papers: Paper[] = [
  {
    id: 'metal-to-tokens',
    tagline: 'For neocloud providers · 17 pages',
    title: 'Metal to Tokens',
    abstract:
      'A reference architecture for managed GPU cloud infrastructure, as code: a neocloud from pools of inventory to a cluster that has passed NVCRE certification and a served model, in one convergence loop, with day 2 on the provider’s runbook.',
    page: '/reference-architectures/metal-to-tokens/',
    pdf: 'https://get.turf.build/papers/turf-neocloud-reference-architecture.pdf',
    cover: '/papers/turf-neocloud-reference-architecture-cover.jpg',
    alt: 'The cover of Metal to Tokens: the title over an isometric data hall, with the stack rising out of it, control planes to hardware, labelled as code.',
  },
  {
    id: 'pull-request-to-production',
    tagline: 'For platform engineers · 13 pages',
    title: 'Pull Request to Production',
    abstract:
      'A reference architecture for Terraform delivery on GitHub Agentic Workflows, with an agent in the pipeline: the plan judged by a policy in plain language on every pull request, approved as that exact plan after the merge, verified from inside the apply, promoted by GitHub Environment.',
    page: '/reference-architectures/pull-request-to-production/',
    pdf: 'https://get.turf.build/papers/turf-pull-request-to-production.pdf',
    cover: '/papers/turf-pull-request-to-production-cover.jpg',
    alt: 'The cover of Pull Request to Production: the title over a commit graph, with the pipeline’s stops, open, plan, comment, review, merge, apply, verify, promote, drawn along a branch merging into main.',
  },
  {
    id: 'agentic-infrastructure-control-plane',
    tagline: 'For Kubernetes platform teams · 7 pages',
    title: 'An Agentic Infrastructure Control Plane',
    abstract:
      'A reference architecture for Turf on kagent 1.0: ask for infrastructure in chat, approve the plan, and your cluster provisions it, whether cloud resources, clusters or anything with a Terraform provider. The agent plans, a person approves, and only the engine touches the cloud.',
    page: '/reference-architectures/agentic-infrastructure-control-plane/',
    pdf: 'https://get.turf.build/papers/turf-agentic-infrastructure-control-plane.pdf',
    cover: '/papers/turf-agentic-infrastructure-control-plane-cover.jpg',
    alt: 'The cover of An Agentic Infrastructure Control Plane: the title over a cluster, labelled kagent and Turf, with three arrows out of it to cloud resources, clusters, and anything with a provider.',
  },
];
