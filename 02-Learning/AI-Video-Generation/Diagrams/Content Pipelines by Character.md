---
tags: [diagram, content, n8n, characters, curated]
description: "Active content-generation workflows grouped by character, all feeding the shared Unified posting layer."
updated: 2026-07-23
status: curated, active workflows only

---


# Content Pipelines by Character

*Hand-authored map of the content-generation lanes, grouped by character, grounded in the live n8n estate as of 2026-07-23. Every workflow shown was confirmed ACTIVE. Dark lanes are left out on purpose, so the diagram does not imply work that is not running. For the shared posting and health path these lanes feed, see [[System Overview]] and [[Account Ops & Geelark Flow]].*

Each character is its own writer lane. The workflows inside a lane do not call each other directly. They hand off through Supabase row status, so a Hookmaker writes a row, a Scriptwriter picks it up, a Director picks that up, and so on. That is why the lanes are drawn as groups feeding one shared content store, rather than as one long chain.

All lanes end the same way. Finished content lands in a Supabase content table, the Scheduling Agent times it, and the Unified Posting Agent posts single-video types while separate carousel posters handle the slider formats.

```mermaid
flowchart LR
    classDef gen   fill:#DCE7FB,stroke:#2E5AAC,color:#10233F,stroke-width:1.5px;
    classDef store fill:#DDF3E4,stroke:#2E8B57,color:#14331F,stroke-width:1.5px;
    classDef sched fill:#FFF1CC,stroke:#C8860A,color:#3A2A05,stroke-width:1.5px;
    classDef post  fill:#F3E1F7,stroke:#8A3FA0,color:#331338,stroke-width:1.5px;

    subgraph sg_c2["Character 2 - BW Woman 30s-50s"]
    direction TB
    c2_1["[2-slide BA] Scriptwriter"]
    c2_2["[2-slide BA] Director"]
    c2_3["[2-slide BA] Hook Auditor"]
    c2_4["[2-slide BA] Music Selector"]
    c2_5["[BA Older Woman] Hook Generator"]
    c2_6["[Before/After Evidence] Builder"]
    c2_7["[Embarrassed Angle] Scriptwriter"]
    c2_8["[Embarrassed Angle] Hook Writer"]
    c2_9["[Embarrassed Angle] Find + Vet (Weekly)"]
    end

    subgraph sg_c3["Character 3 - EW / Dating Face"]
    direction TB
    c3_1["[Eat Whatever] Scriptwriter Agent"]
    c3_2["[Eat Whatever] Director"]
    c3_3["[Eat Whatever] Voiceover Generator"]
    c3_4["Dating Genre Hookmaker"]
    c3_5["[Dating Genre] Creator Content Scanner"]
    c3_6["[Dating Genre] Source Discovery"]
    end

    subgraph sg_c4["Character 4 - Grandma 50-63"]
    direction TB
    c4_1["Divorce Story Collector"]
    c4_2["Divorce Scriptwriter"]
    c4_3["Divorce Director"]
    c4_4["[Divorce Yoga] Director"]
    c4_5["Divorce Leads - Waitlist Email"]
    c4_6["[Conspiracy] Story Finder"]
    end

    subgraph sg_ce["Covered Eye"]
    direction TB
    ce_1["Covered Eye - Scriptwriter"]
    ce_2["Covered Eye - Hookmaker"]
    end

    subgraph sg_gu["Glow-Up Weight-Loss Decks"]
    direction TB
    gu_1["Glow-Up Writer / Hook Maker"]
    gu_2["Glow-Up Director / Image Organizer"]
    gu_3["Glow-Up Render (Satori)"]
    end

    subgraph sg_fil["Filler - All Characters"]
    direction TB
    fil_1["Viral Filler - Stage"]
    fil_2["Viral Filler - Creator Ingest (TikTok)"]
    end

    t_store[("Supabase content tables")]
    a_sched["[Unified] Scheduling Agent"]
    a_post["[Unified] Posting Agent<br/>single-video types"]
    a_car["Carousel posters<br/>2 BA Slider, BA Journey"]
    a_geelark["Geelark cloud phones"]

    sg_c2 --> t_store
    sg_c3 --> t_store
    sg_c4 --> t_store
    sg_ce --> t_store
    sg_gu --> t_store
    sg_fil --> t_store

    t_store --> a_sched
    a_sched --> a_post
    t_store -->|"carousels"| a_car
    a_post --> a_geelark
    a_car --> a_geelark

    class c2_1,c2_2,c2_3,c2_4,c2_5,c2_6,c2_7,c2_8,c2_9 gen;
    class c3_1,c3_2,c3_3,c3_4,c3_5,c3_6 gen;
    class c4_1,c4_2,c4_3,c4_4,c4_5,c4_6 gen;
    class ce_1,ce_2 gen;
    class gu_1,gu_2,gu_3 gen;
    class fil_1,fil_2 gen;
    class t_store store;
    class a_sched sched;
    class a_post,a_car,a_geelark post;
```

## What is deliberately not here

These lanes look like they should exist but are dark as of 2026-07-23, so drawing them would be a lie.

- Grandma BA (GBA). The whole GBA content-generation lane is off. No active writer, director, music, or poster.
- Cooking Conspiracy writers. Only `[Conspiracy] Story Finder` runs. The Conspiracy Hook Writer and Scriptwriter are off, so the lane finds stories but does not currently write them.
- Per-character posters. Every single-video per-character poster is off. Their posting was folded into the Unified Posting Agent. Carousels are the exception and keep their own posters.

## Notes on a few nodes

- Filler is staging, not scripting. `Viral Filler - Stage` matches clips and writes hooks into the render queue. `Creator Ingest` pulls new source clips. The local worker renders them.
- Glow-Up Render (Satori) is a render step, kept in the lane because it is the Glow-Up lane's own active workflow rather than a shared renderer.
- Filler posts through the Unified Posting Agent as the FIL type, so it shares the same posting box as the other single-video lanes.

## Related

- [[System Overview]]: where these lanes sit in the whole loop
- [[Account Ops & Geelark Flow]]: what happens after the post is fired
- [[Diagrams]]: index for this folder
- [[content-system-map]]: the AI-memory note on the content type registry
