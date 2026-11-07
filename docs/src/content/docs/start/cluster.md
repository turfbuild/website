---
title: Install in a cluster
description: Turf runs in Kubernetes as the same three pieces, deployed as workloads, with any MCP client talking HTTP to the server. The cluster chapter has the topology, images and manifests.
sidebar:
  order: 5
---

The server, the engine and the console run in a cluster as ordinary workloads: the server over HTTP
behind a bearer token, restate-server and the engine replicas behind it, the console beside them. Any
MCP client connects: an agent in the cluster, Claude Code through a port-forward, a CI job.

The chapter [Running Turf in a cluster](/docs/cluster/topology/) has it all:

- [Topology](/docs/cluster/topology/): the pieces and how they connect.
- [Images](/docs/cluster/images/): the server image, configuration images, verification.
- [Minimal manifests](/docs/cluster/manifests/): the smallest working set.
- [Credentials in a cluster](/docs/cluster/credentials/): what goes on the engine, what on the server.
- [Connecting clients](/docs/cluster/clients/).
- [An agent in the cluster, with kagent](/docs/cluster/example-kagent/): one worked example.
