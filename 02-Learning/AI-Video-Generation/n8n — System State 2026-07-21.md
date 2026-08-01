---
tags: [n8n, automation, system-state, account-health, geelark, snapshot]
description: "Snapshot of every n8n workflow: what is active, what is broken, and what changed since July 4."
updated: 2026-07-21
status: snapshot — a point-in-time picture, re-pull before trusting the numbers

---
# n8n — System State 2026-07-21

*A snapshot of the whole n8n estate on `czed.app.n8n.cloud`, pulled live on 2026-07-21 and cross-checked against Supabase (`story-finder` / `qlcmgxgwpzmiebzxflai`). This is a photograph, not a living document. Anything here older than a few weeks should be re-pulled before you act on it.*

---

## TL;DR — the one thing

**The estate is 249 workflows, 115 of them active, and the biggest single problem is not a broken workflow, it is three forgotten ones.** Three [Universal Refs] migration workflows have been firing every 5 minutes since 2026-05-07 and have burned roughly 16,200 executions. They all report success, so nothing has ever alerted. That is the cheapest win available.

The good news: the Geelark data-blindness problem from the July 4 brief is **fixed**. Task detail now lands in Supabase, health verdicts now land in Supabase, and warmup runs are now logged. The autopsy that used to require raw Geelark calls is now runnable in SQL.

---

## 1. Headline numbers

| Metric | Value |
|---|---|
| Workflows total | 249 (n8n MCP count; the REST API reports 253) |
| Active | 115 |
| Inactive | 134 |
| Created span | 2025-10-15 to 2026-07-21 |
| Tags in use | **0** instance-wide |
| Projects | 2 |
| Folders | 24 (all in the personal project) |

Tags are unusable as a grouping axis because none exist. Folders are the only real organisation.

**The folder reorg has actually been executed.** Memory said it was blocked on user decisions. It is not. The live tree is:

- Character 2 (BW Woman 30s-50s) with Embarrassed Angle, 2-Slide BA
- Character 3 (EW-Dating Face) with Eat Whatever, Dating Genre
- Character 4 (Grandma 50-63) with Yoga and Divorce Story, Cooking Conspiracy, Grandma BA
- Analysis Engine with Instagram, TikTok
- Retired with Full BA Transformation, Carousels
- Top level: Covered Eye, Test and One-offs, Other Brands, Account Ops, Research and Hook Mining, Universal, Filler for All Characters, Mass Content

---

## 2. Grouped by functional system

### Account operations and Geelark

This is the layer that changed most in July.

| Workflow | ID | State | Cadence |
|---|---|---|---|
| [Health] View-Collapse Detector | `2Goujvw8qSvVzIfo` | ACTIVE | Tue + Fri, observed 12:00 UTC |
| Account Health Check (IG and TT) | `CXVxRMOUkLluRdBc` | ACTIVE | ~every 3-4 days, 11:00 UTC |
| Account Health Check (For Posting) | `CJQKNXIBPB0B8LF5` | ACTIVE | daily 03:00 UTC, writes to a Google Sheet only |
| Geelark Task Detail Poller | `ARmIDPrV77c0k4zA` | ACTIVE | hourly, 414 runs all success |
| [Geelark] Save Receipt | `coizHIeUHRV5zOyd` | ACTIVE | webhook |
| Geelark Auth Code API | `cUqz566KYTXio9LF` | ACTIVE | created 2026-07-21 |
| [Ops] Factory Reset - On Demand | `aB24JEEA8COgeoeA` | ACTIVE | created 2026-07-21 |
| Device Warmup - Auto | `3AsUAUOwUgXa60cy` | ACTIVE | the only active warmup workflow |
| Geelark Ban Analysis | `ZWQ4kUJHB4pL5d2X` | inactive, never run |

All the legacy warmup schedulers are inactive: IG, TikTok, Facebook, viral-repost, plus two newer ones built and retired within two weeks (TT Ramp and Maintenance, and [Warmup] Unified Scheduler).

### Posting and scheduling

The unified layer has taken over from the per-type posters.

- `lioNzkWRocyDvZS5` [Unified] Posting Agent, ACTIVE, daily 14:00, 19 runs all success
- `rMWqyc60gPL7gVG0` [Unified] Scheduling Agent, ACTIVE
- `Q5VXmY5RFMXX2uBZ` [Unified] Inventory Monitor, ACTIVE, hourly-ish
- `gHoiFBpQkrkGvTto` [Reconcile] Nightly Failed Posts, ACTIVE, new on 2026-07-15

Most legacy per-type posters are now inactive (Filler, Dating Genre, Eat Whatever, 2-slide BA, GBA, BA Full Reel). Still active: 2 BA Slider Poster, BA Journey Carousel Posting Agent.

### Content generation, by character

- **Character 2 (BW woman):** 2-slide BA Scriptwriter, Director, Hook Auditor, Music Selector all active. BA Older Woman Hook Generator active. Embarrassed Angle Find+Vet, Hook Writer, Scriptwriter active.
- **Character 3:** Eat Whatever Scriptwriter, Director, Voiceover active. Dating Genre Hookmaker, Creator Content Scanner, Source Discovery active.
- **Character 4 (Grandma):** Divorce Collector, Scriptwriter, Director and Divorce Yoga Director active. Conspiracy Story Finder active, but Conspiracy Scriptwriter and Hook Writer are inactive. The whole GBA cluster is inactive.
- **Covered Eye:** Hookmaker and Scriptwriter active.
- **Glow-Up:** Writer, Director and Render all active, all created 2026-07-09.
- **Filler:** Creator Ingest and Stage active. Render, Assembler, Hookmaker and Library Ingest inactive because rendering moved local.
- **Carousel:** Unified Renderer, Carousel Quality Gate and Image Uploader v2 active. Rich Life poster v8 through v13 all inactive.
- **Universal shared services:** Caption Maker, Music Recommender, UGC Image Prompt Writer, Seedance UGC Prompt Writer all active.

### Analytics and monitoring

Analysis Engine, TikTok Analytics Engine, Combined Weekly Analytics Report, Bi-Monthly Winner-Pattern Analysis, Content Analysis Heartbeat, Virlo Webhook Heartbeat, Content Audit pair, Content Quality pair. The Pillar A Promoter Heartbeat is inactive, which matches the note that it was retired for false-alarming.

### Ingestion and research

Virlo Webhook Receiver, content_posts to machine_hooks bridge (Mon and Thu), Machine Hooks Tag Labeler on Opus, the GLP-1 story and hook discovery cluster, PubMed scrape and synthesise, and the ScrapeCreators Weekly Budget credit guard.

### Other brands (not peptide)

The Healtsy cluster of seven workflows, plus LinkedIn, Contra Pipeline, Calendly Lifecycle, and Gmail Quality Check.

---

## 3. Most recently updated

| Updated | State | ID | Name |
|---|---|---|---|
| 2026-07-21 23:42 | inactive | `0P5mVaI2XVv3VIGa` | Daily Study Digest Email |
| 2026-07-21 23:14 | ACTIVE | `984XgfQ7EZmnYDCL` | Gmail Quality Check (IPQS + Firecrawl) |
| 2026-07-21 18:17 | ACTIVE | `3AsUAUOwUgXa60cy` | Device Warmup - Auto |
| 2026-07-21 16:57 | ACTIVE | `cUqz566KYTXio9LF` | Geelark Auth Code API |
| 2026-07-21 14:24 | ACTIVE | `bkzTbkymrX0Ukp0M` | [Healtsy] Newsletter Agent |
| 2026-07-21 13:20 | ACTIVE | `aB24JEEA8COgeoeA` | [Ops] Factory Reset - On Demand |
| 2026-07-19 00:13 | ACTIVE | `YrVGDxC6G1F2urSl` | [BA Older Woman] Hook Generator |
| 2026-07-19 00:12 | ACTIVE | `zeMbOTbgRqcowz3g` | [2-slide BA] Scriptwriter |
| 2026-07-19 00:10 | ACTIVE | `ifZTXFEXX1dqNMfD` | Divorce Scriptwriter |
| 2026-07-19 00:10 | ACTIVE | `RhKnoezTuMqp1EKZ` | Glow-Up Writer / Hook Maker |
| 2026-07-18 18:49 | ACTIVE | `a0Htu5qcQtTzl6jM` | [Universal] Music Recommender |
| 2026-07-17 13:07 | ACTIVE | `qCDbw8FyA6hxev9G` | Divorce Story Collector |
| 2026-07-17 02:41 | ACTIVE | `KtSJskq288XEEHoD` | [Dating Genre] Source Discovery |
| 2026-07-16 11:22 | ACTIVE | `rMWqyc60gPL7gVG0` | [Unified] Scheduling Agent |
| 2026-07-15 17:05 | ACTIVE | `ARmIDPrV77c0k4zA` | Geelark Task Detail Poller |

25 workflows have been created since 2026-07-05.

---

## 4. Known broken and at-risk

### A. The zombie migration trio (biggest cleanup win)

Three ACTIVE workflows, untouched since 2026-05-07, each firing **every 5 minutes** and still ticking:

| Workflow | ID | Executions |
|---|---|---|
| [Universal Refs] Migration Runner | `51Kw9K1EVxv9TYqH` | 5,400 |
| [Universal Refs] Phase 1 Done Watcher | `wNwzQK9a7Vl0t1PU` | 5,400 |
| [Universal Refs] Phase 3 Audience Tagging | `kbI74D4b1tZA2KMn` | 5,401 |

Roughly 16,200 executions. All report success, so no alert has ever fired. A sibling, References Promoter, is also active and stale.

### B. A workflow failing 100 percent of the time, unnoticed

`w5cJVATP7uS3QSds` Healtsy Content Calendar Automation is ACTIVE with 19 executions and **every single daily run from 2026-07-07 through 2026-07-21 errored**. Fifteen consecutive failures. Nobody is watching it.

`bkzTbkymrX0Ukp0M` [Healtsy] Newsletter Agent is also ACTIVE with about 23 errors since 2026-07-10. Its batch companion accumulated 18 errors and has since been switched off.

### C. Device Warmup - Auto has a label mismatch and a leak risk

This one deserves a human read because warmup method is the strongest ban predictor we have.

- The workflow is ACTIVE and it powers Geelark phones on, sets GPS, and powers them off across the whole fleet.
- Its own embedded sticky note still says "DRAFT, inactive. Inactive until activated."
- Three manual runs errored on 2026-07-19 and 2026-07-20.
- The code skips any phone with no matching US city or timezone, and a skipped phone **bypasses the Stop Phone step**. The code comment itself flags that this would leave the phone powered on.

### D. Intermittent failures on live workflows

These are real trigger or webhook failures, not development iteration:

- Virlo Webhook Receiver: 8 errors of 52 runs, consistent with the known empty-body dud pattern
- [Unified] Inventory Monitor: errors on 2026-07-16 and 2026-07-20
- Dating Source Discovery: 3 errors, each a clean 60 second timeout
- Dating Genre Hookmaker: 3 webhook errors
- [Universal] Caption Maker: 2 errors, both 60 second timeouts
- Embarrassed Angle Hook Writer, Conspiracy Story Finder, Divorce Story Collector, Covered Eye Scriptwriter, Notion DB Probe: one error each
- On 2026-07-14 a three-workflow cascade errored together: Content Audit Daily Scheduler into Content Audit Pre-Publish Gate into Content Risk Gate

The 60 second timeouts are a pattern worth chasing. Several different workflows hit exactly the same wall.

### E. Duplicates and clutter

- `Carousel Image Uploader v2` exists three times, one of them active
- `Original Prompts` exists twice, **both active, both with zero triggers**
- Triple and double copies of Cleanup Rich Life Carousel Output, Chatterbox Voiceover Generator, Creator Intelligence Research Agent, Test GS Delete, Strong Informational Scriptwriter
- Versioned sprawl: the GLP scriptwriter family spans v2.0 to v5.1 across about 15 inactive workflows, and Rich Life Carousel Poster spans v8 to v13
- Still ACTIVE despite throwaway names: Delete May30+ Rows, Sheet Bulk Append helper, Notion DB Probe, [Temp] Drive Image Uploader, three [Image Test] workflows, three temp-job workflows

22 active workflows have not been edited since 2026-06-01. The oldest is from 2026-03-22. Not all of them are dead. Pillar A Promoter has not been touched since May and is still firing successfully every 4 hours. But that set is where abandoned automation hides.

---

## 5. What changed since the July 4 snapshot

### FIXED: the Geelark task poller now lands its payload

This was the headline data-blindness bug in the July 4 brief.

| Column in `geelark_tasks` | July 4 | 2026-07-21 |
|---|---|---|
| total rows | 1,321 | **2,988** |
| status populated | 1 | **2,957** |
| fail_code populated | **0** | **266** |
| logs populated | 1 | **2,009** |

The warmup autopsy is now runnable against Supabase instead of requiring raw Geelark calls.

### FIXED: health verdicts reach Supabase, not just a Google Sheet

New table `geelark_health_log`, 141 rows, all from the health check workflow, running on a Tue and Fri cadence since 2026-07-04. Verdicts so far are only ALIVE, OTHER_FAILURE and UNKNOWN. **No BANNED verdict has landed yet**, so the ban-forensics half is captured in schema but still unproven in data.

### FIXED: warmup runs are no longer unlogged

`geelark_tasks.source_workflow` now attributes rows to named schedulers, with a task category and the Geelark response code attached.

### NEW: posting failure rate is measurable and it is high

The unified posting agent has written 1,035 Geelark task rows. 724 succeeded and **212 failed. That is roughly a 22 percent hard-fail rate on posts.** This only became visible because the poller was fixed. [Reconcile] Nightly Failed Posts appears to be the response to it.

### CHANGED: the warmup layer was rebuilt twice in two weeks

The July 4 brief listed five schedulers, all inactive. Since then one was deleted outright, two new ones were built and already retired, and one new one went live on 2026-07-19.

### NEW: two Geelark ops workflows on 2026-07-21

Geelark Auth Code API and [Ops] Factory Reset - On Demand. A factory-reset endpoint pointed at live cloud phones is a destructive capability. Worth a human confirming who and what can trigger it.

### STILL OPEN from the July 4 brief

- `account_age_days` is still unpopulated, so lifespan-by-warmup is still not computable
- RLS is still disabled across roughly 60 public tables. Still rated critical.
- Both Sheet to Supabase account sync workflows are still inactive
- Geelark Ban Analysis is still inactive and has still never run

### Correction to the July 4 brief

It recorded the View-Collapse Detector as running at 13:00 UTC. Observed executions are at **12:00 UTC**. Either the cron was edited or the brief recorded a local-time offset. The recipients are unchanged.

---

## Related notes
- [[Peptide Miracles API — Swagger & OpenAPI]]
- [[Architecture — How The System Fits Together]]
- [[account-health-system]]
- [[content-system-map]]
- [[n8n-reorg-project]]
- [[pipeline-alert-monitors]]
