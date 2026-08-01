---
tags: [hub, ai-video]
description: Map of the AI video pipeline. Start here for architecture, current n8n state, the diagrams, and the API docs.
updated: 2026-07-23

---
# AI Video Generation — Hub

Durable notes on the AI video pipeline. Write things here in your own words once you understand them — that's what makes them stick.

## Start here (system state, updated 2026-07-21)
- How the whole thing fits together — [[Architecture — How The System Fits Together]]
- What n8n looks like right now — [[n8n — System State 2026-07-21]]
- The API docs and how stale they are — [[Peptide Miracles API — Swagger & OpenAPI]]

## Diagrams (Mermaid, render in Obsidian)
- Index of every system diagram: [[Diagrams]]
- The whole spine end to end: [[System Overview]]
- The posting and health close-up: [[Account Ops & Geelark Flow]]
- Content generation lanes by character: [[Content Pipelines by Character]]
- One account from new profile to retirement: [[Account Lifecycle — New Profile to Retirement]]
- The account-ops tables and join keys: [[Account Ops Data Model]]
- Auto-generated per-workflow node graphs: [[_Workflows — Index]]

## Account health and proxies (project folder, not auto-loaded)
- What the biweekly proxy audit checks, rule by rule — [[01 — Proxy & Account Health Audit — What We Check]]
- The 2026-07-04 evidence pack behind it — [[00 — Geelark Warmup & Account Health — Investigation Brief]]
- Both live in `03-Projects/Account Health & Warmup 2026-07/`. The session hook does not load that folder, so open them by name when the topic comes up.

## Live systems (code in ~/Claude)
- Viral Filler local render — see AI memory: [[viral-filler-local-render]]
- Carousel render style (Satori, caption style) — [[carousel-render-style]]
- Before/After transformation pipeline (scriptwriter → voiceover → director → stitcher)
- Architecture docs live in `/Users/garrethdottin/Claude/Projects/AI Video Generation/`

## What I'm learning
- [ ] How the local ffmpeg render replaces Creatomate
- [ ] Filler "analyze-once" cache logic
- [ ] Caption auto-fit / halo style

## Open questions
-

## Linked AI memories
These live in `04-AI-Memory` and are written by Claude:
- [[viral-filler-local-render]]
- [[carousel-render-style]]
- [[carousel-autonomy-system]]
- [[content-system-map]]
- [[unified-posting-architecture]]
- [[account-health-system]]
