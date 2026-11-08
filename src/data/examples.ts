// The three marquee examples (2026-11-07, for KubeCon NA): copy shared by the home band
// (components/ExamplesTeaser.astro) and the demos hub (pages/demo.astro), so each one is described
// once. `blurb` is the card's line on home; `body` the paragraphs on /demo/. Facts come from each
// repository's README (turf-examples use-cases/datacenter/aicr-stack, turf-kagent,
// turf-agentic-workflows); re-check them there before changing a number. Marks carry no symbols
// here: the symbols belong to each page's first prominent use, which both pages make before this
// text renders.
export interface ExampleLink {
  label: string;
  href: string;
}
export interface Example {
  id: string;
  tagline: string;
  title: string;
  blurb: string;
  body: string[];
  links: ExampleLink[];
}

export const examples: Example[] = [
  {
    id: 'aicr',
    tagline: 'A GPU cloud’s runtime, on your laptop',
    title: 'The AI Cluster Runtime stack on kind',
    blurb:
      'Seventeen Helm releases generated from one NVIDIA AI Cluster Runtime recipe, with the cluster in the graph: one up brings it all up on kind in two rounds, pausing at the certify step.',
    body: [
      'NVIDIA’s AI Cluster Runtime publishes validated, version-locked recipes of GPU drivers, operators and system configuration, and is explicit that it is not a cluster provisioner. Turf’s Terraform deployer puts the cluster in the graph: two hand-written files create a kind cluster and hand it to a generated bundle of seventeen Helm releases, which come up behind it in one run.',
      'Round 1 creates the cluster and defers the releases, whose provider needs its endpoint; round 2 installs them, pausing at the certify step, a turf action, for a person or an agent. The console still beside is that run, on Turf 1.4.',
    ],
    links: [
      { label: 'the example on GitHub', href: 'https://github.com/turfbuild/turf-examples/tree/main/use-cases/datacenter/aicr-stack' },
      { label: 'Metal to Tokens, the paper', href: '/reference-architectures/' },
    ],
  },
  {
    id: 'kagent',
    tagline: 'An agent in the cluster it manages',
    title: 'Turf and kagent 1.0, one cluster',
    blurb:
      'kagent runs the agent in a gVisor sandbox that holds no credential; Turf’s engine scales from zero on Knative; state stays in the cluster. Every apply waits for a person in the kagent UI.',
    body: [
      'kagent 1.0 runs the agent in a gVisor sandbox beside Turf, and the agent reaches Turf’s MCP server over HTTP like any other client, through an egress gateway that adds the bearer token: no credential crosses into the sandbox. The engine is a Knative service on restate-server, scaling from zero when a round starts and back to zero after. State stays in the cluster, a Secret per stack.',
      'One script builds the whole setup on a kind cluster. Every apply waits for a person in the kagent UI, and a step that needs eyes pauses the apply for the agent, inside the approved plan.',
    ],
    links: [
      { label: 'the repository on GitHub', href: 'https://github.com/turfbuild/turf-kagent' },
      { label: 'the walkthrough in the docs', href: '/docs/cluster/example-kagent/' },
    ],
  },
  {
    id: 'gh-aw',
    tagline: 'A pull request that applies itself',
    title: 'Turf on GitHub Agentic Workflows',
    blurb:
      'An agent in the pipeline reviews the plan on every pull request, approves that exact plan under your policy after the merge, verifies from inside the apply and reports back on the pull request.',
    body: [
      'Turf plans and applies a Terraform configuration from inside GitHub Agentic Workflows, and the agent driving it reviews the plan, checks the providers against GitHub’s Advisory Database, approves under a per-environment policy written in plain language, verifies the rollout by calling what it deployed, and reports on the pull request.',
      'Three workflows, two policies, and a fleet of AWS Lambda functions as the configuration. The paper walks the loop through three real pull requests of the repository, the agent’s transcripts included.',
    ],
    links: [
      { label: 'the repository on GitHub', href: 'https://github.com/turfbuild/turf-agentic-workflows' },
      { label: 'Pull Request to Production, the paper', href: '/reference-architectures/pull-request-to-production/' },
    ],
  },
];
