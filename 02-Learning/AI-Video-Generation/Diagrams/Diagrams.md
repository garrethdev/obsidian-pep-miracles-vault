---
tags: [diagram, index, hub, architecture, n8n, curated]
description: "Index of the Peptide Miracles system diagrams: what exists, what is auto-generated, and how to refresh."
updated: 2026-07-23
status: curated, landing page for this folder

---


# Diagrams

*The landing page for every system diagram in the vault. Open this first, then jump to the diagram you want. Diagrams are Mermaid, which Obsidian renders on its own with no plugin.*

Every diagram here draws on three sources: Obsidian is the surface you read them on, n8n is the workflow automation being drawn, and Geelark is the cloud-phone layer that actually posts. The facts come from the live n8n REST API and the account-ops Supabase project (`qlcmgxgwpzmiebzxflai`).

## Curated diagrams (hand-maintained)

These are written by hand because they need judgement about altitude and grouping. They will not auto-refresh, so re-check them against the live notes before you trust a number.

- [[System Overview]]: the whole spine end to end, generate to post to health. Start here.
- [[Account Ops & Geelark Flow]]: a close-up of the posting and health layer, including the ~20% fail path and the inferred-ban story.
- [[Content Pipelines by Character]]: the active content-generation lanes, grouped by character, feeding the shared posting layer.
- [[Account Lifecycle — New Profile to Retirement]]: the journey of one account from deciding to add a profile, through phone setup, warmup, posting, and retirement. Colored by who does each step, and honest about what is live versus built but off. CURATED.

## Auto-generated diagrams (do not hand-edit)

These are machine output. A generator pulls each workflow live from the n8n REST API and converts it to a Mermaid `flowchart LR`, one note per workflow. It also builds the account-ops data model note from live Supabase row counts. Do not hand-edit these, since a re-run overwrites them.

- [[_Workflows — Index]]: one node graph per account-ops workflow (Posting Agent, Scheduling Agent, the health checks, the warmup, and the rest).
- [[Account Ops Data Model]]: the Supabase tables, their convention-only string join keys, and which workflow writes each one.

### The generator

The generator lives outside the vault at `~/Claude/arch-diagrams/` (`generate.py` plus its `README.md`). Refresh every auto-generated note in place with one command:

```
python3 generate.py --all
```

It reads `N8N_API_KEY` from the environment or the local secrets file. It never stores a secret in any note. To pick up new or renamed workflows, or to correct a stale row count, re-run it.

## How Obsidian renders these

- Obsidian renders a ```mermaid fenced code block natively. No community plugin is needed. This vault runs Obsidian 1.12.7 and these are the first Mermaid diagrams in it.
- The theme adapts to your system, so any diagram may be read in light or dark. Every node is given an explicit fill, stroke, and text color so it stays legible either way.
- The color code is the same across diagrams: blue is content generation, green is a Supabase table, yellow is scheduling, purple is posting and the Geelark device layer, red is health and monitoring, grey is an outside service.
- If a diagram ever shows a raw code box instead of a picture, the Mermaid syntax broke. The usual cause is a label with an unquoted bracket or a stray character. Every label here is wrapped in double quotes to avoid that.

## Convention for new diagrams

- Curated overviews go in this folder as their own note. Auto-generated per-workflow graphs go under `Workflows/`. That split keeps the hand-written diagrams separate from the machine output in the session index.
- Give every diagram note frontmatter with `tags`, `description`, `updated`, and `status`, so the session hook indexes it with a meaningful line.
- Use only the safe Mermaid subset: `flowchart`, `subgraph`, `classDef`, and `erDiagram`. Avoid the newer beta diagram types, which the bundled Mermaid build cannot render.

## Related

- [[AI Video Generation - Hub]]: the parent hub for these learning notes
- [[Architecture — How The System Fits Together]]: the prose version of the System Overview
- [[n8n — System State 2026-07-21]]: the workflow-by-workflow snapshot the diagrams draw from
