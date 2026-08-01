---
tags: [architecture, overview, pipeline, supabase, n8n, geelark, doc-drift]
description: How the system fits together end to end, plus where the written architecture docs have gone stale.
updated: 2026-07-21
status: orientation — read this first if you are trying to understand the whole system

---
# Architecture — How The System Fits Together

*A plain-language summary of the architecture docs in `/Users/garrethdottin/Claude/Projects/AI Video Generation/` (CLAUDE.md, HANDOVER_Hermes_Nous.md, CONSULTANT_ROADMAP_2026-07.md, plus peptide-content-system, peptide-ops and proposed-skills), reconciled against what is actually running as of 2026-07-21. Where the written docs and live reality disagree, section 8 says so.*

---

## TL;DR — the one thing

**Content is written by n8n workflows, stored in Supabase, rendered locally on this Mac with ffmpeg, and posted through Geelark cloud phones. Health is monitored by two n8n jobs that email a report twice a week.** That is the whole loop in one sentence. The architecture docs describe most of this correctly, but they are three weeks behind on the account-health layer, which did not exist when they were written.

---

## 1. What the business actually is

Peptide Miracles is a GLP-1 telehealth **referral** brand. It does not sell the product. It sends people to a quiz.

- Audience: Black women roughly 35 to 58
- Method: a lot of short-form video and image carousels, posted from many warmed social accounts
- The single call to action: "Type QUIZ in the comments"
- Site: peptidemiracles.io, hosted on Vercel

Healtsy, a European skincare brand, is a **separate paying client** running a parallel carousel pipeline in the same workspace. Brand conventions must never cross between the two. Per the consultant roadmap, Healtsy is currently the only thing bringing in money.

---

## 2. Where content is generated

Content is written by n8n workflows on `czed.app.n8n.cloud`, grouped by character. Each character has its own writer chain.

| Character | Content types |
|---|---|
| Character 2, BW woman 30s to 50s | 2-slide Before/After, Embarrassed Angle |
| Character 3, EW and dating face | Eat Whatever, Dating Genre reactions |
| Character 4, Grandma 50 to 63 | Divorce stories, Cooking Conspiracy, Grandma BA |
| Covered Eye | Hookmaker plus Scriptwriter pair |
| Glow-Up | Writer, Director, Renderer trio |

Shared services sit above all of them: a Caption Maker, a Music Recommender, a UGC Image Prompt Writer and a Seedance UGC Prompt Writer. Those are called by many chains rather than belonging to one.

Separately there is a **local skill chain** for the flagship Before/After video, run on this Mac rather than in n8n. Nine steps in order: scriptwriter, voiceover generator (ElevenLabs), script supervisor (whisper timing), director (builds the edit decision list), quality control, video stitcher (ffmpeg), text hook overlay, captions generator, content scheduler (Notion). State for that chain lives in a Google Sheet written through an Apps Script endpoint.

---

## 3. Where content is stored

Everything lands in one Supabase project, `story-finder` (`qlcmgxgwpzmiebzxflai`).

**Content tables** hold the written scripts and their status: `ba_2slide_content`, `grandma_before_after`, `ew_content`, `dating_reaction_posts`, `filler_contents`, `viral_filler_content`, plus newer ones for the formats added since (embarrassed angle, divorce, conspiracy, glow-up decks).

**Asset tables** hold the raw material: `carousel_images`, `video_library`, `eat_whatever_clips`, `filler_library`, `music_library`, `dating_reaction_sources`, `gold_exemplars`, `carousel_copy`.

**Routing tables** decide what goes where: `content_type_registry` holds the per-type endpoints, cadence and day pattern. `unified_posts` is the normalised view the unified poster reads.

**Status flow:** pending, then review, then approved, then rendering, then done. Anything can be discarded from any stage. Done and discarded are read-only.

Two gotchas worth remembering. Caption column naming drifted, so you will see `caption`, `caption_clean` and `Captions` depending on the table. And **row counts in every architecture doc are stale by design**. The docs themselves say to re-query rather than trust them.

**Row-level security is disabled on roughly 60 public tables.** The docs frame this as a convenience. It is an open critical risk.

---

## 4. How content gets rendered

Rendering moved off cloud services and onto this Mac. That is the single biggest architectural shift.

- Video renders are **local ffmpeg**, 1080 by 1920 at 30fps, libx264 crf 23
- Working files for the Before/After chain live in `/tmp/ba-assets/`
- Carousel rendering uses Satori, not librsvg, for font reasons
- Viral Filler render was pulled out of Creatomate and rebuilt locally
- The Glow-Up decks render locally too

The Healtsy carousel path is different: it goes through Figma templates filled by a builder skill, then audited by a separate skill, at 1080 by 1350.

There are three **built but not installed** skills sitting in `proposed-skills/`: text-hook-overlay, carousel-image-factory and viral-filler-render. They have been run at least once (compiled artefacts exist) but they are not part of the installed skill set.

---

## 5. How content gets posted

Posting goes through **Geelark cloud phones**. Each phone runs one social account.

- The [Unified] Posting Agent reads `unified_posts` and routes by platform, media shape and custom flow id
- Older per-type posters have mostly been retired in favour of the unified one
- Proxies come from two vendors: Proxy-Cheap ISP proxies for Instagram, Geonix mobile proxies for TikTok
- SMS verification comes from TextVerified
- The content calendar lives in Notion

**Important schema fact:** proxy and IP assignment exists **only inside Geelark**. There is no proxy column and no IP column anywhere in Supabase. Any proxy question has to be answered by calling the Geelark API. It cannot be answered in SQL. None of the written architecture docs warn you about this.

Current measured posting reliability: of 1,035 Geelark post tasks written by the unified agent, 724 succeeded and 212 failed. Roughly a 22 percent hard-fail rate.

---

## 6. How health is monitored

This is the newest layer and the one the architecture docs know nothing about.

| Job | What it does | Cadence |
|---|---|---|
| [Health] View-Collapse Detector | Compares 7-day against 28-day median views per account, emails a styled report | Tue and Fri |
| Account Health Check (IG and TT) | Fires a Geelark warmup probe per account, classifies the result, writes verdicts to Supabase | roughly every 3-4 days |
| Geelark Task Detail Poller | Pulls the outcome of every Geelark task into Supabase | hourly |
| [Reconcile] Nightly Failed Posts | Flips posts marked Posted back to Failed when Geelark says otherwise | nightly |

Supporting tables: `geelark_tasks` (2,988 rows), `geelark_health_log` (141), `geelark_fail_codes` (51), `account_events` (62), `accounts` (32).

Verdicts recorded so far are only ALIVE, OTHER_FAILURE and UNKNOWN. No BANNED verdict has landed yet, because the probe is a warmup task and warmup tasks do not surface proxy or ban failures as such.

The health email goes to two recipients and is sent as "Peptide Health Bot". That is the canonical pattern any new health email should copy.

---

## 7. The other pieces

**peptide-ops** is a local ops tracker: a React and Vite front end on port 5173, an Express and SQLite server on port 3001, with an OpenAI chat agent that can move tasks around a board. Board streams are Create, Content, Post, Maintain, Engineering. See section 8 for why this one is contested.

**peptide-content-system/** is specs rather than code. Three documents: VIDEO_CREATION.md (the type to table to character matrix), GPT_IMAGE2_CREATION.md (the carousel image library schema and house image style), and VIRAL_FILLER_RENDER_HANDOVER.md (the tested split-screen ffmpeg runbook).

**CONSULTANT_ROADMAP_2026-07.md** is strategy, not architecture. Its five ranked moves are: wire up conversion tracking, concentrate on the two accounts that actually perform, turn Healtsy into a productised retainer, flush the inventory glut, and shrink the n8n estate to 60 or fewer active workflows. Its three "stop doing" items are: stop adding new content formats, stop building internal tools, and stop unpaid side ventures.

---

## 8. Doc drift — where the written architecture is now wrong

Every item below is a place where the docs in `/Users/garrethdottin/Claude/Projects/AI Video Generation/` disagree with what is live.

| # | The docs say | Live reality |
|---|---|---|
| 1 | 9 Geelark cloud phones | The `accounts` table has 32 rows, the July checkpoint had 27, and the roadmap itself says 21. The figure of 9 predates the fleet expansion. |
| 2 | Nothing at all about Geelark's API or the health tables | `geelark_tasks`, `geelark_health_log`, `geelark_fail_codes` and `account_events` all exist and are populated. The entire account-health telemetry layer built since July 4 is invisible to the docs. |
| 3 | Proxy-Cheap and Geonix are listed as vendors | The docs never say that proxy and IP data lives **only** inside Geelark and cannot be queried in SQL. A reader would waste time looking for a column that does not exist. |
| 4 | "No dedicated skill for the text-hook overlay" | `proposed-skills/text-hook-overlay/` now exists and has been run. |
| 5 | Six video content types | Live reality includes embarrassed angle, divorce stories, medical conspiracy, glow-up decks and BA older-woman on top of that. The registry covers 14 types. The operating manual never absorbed the four formats added in five weeks. |
| 6 | "RLS off on working tables" framed as a convenience note | RLS is disabled on roughly 60 public tables and is an open critical risk. |
| 7 | Row counts for every content table | Stale by design. The docs themselves say to re-query. |
| 8 | The read-first file map | It omits CONSULTANT_ROADMAP_2026-07.md entirely, and omits the `proposed-skills/` folder, despite the roadmap being written the same day. |

**One live contradiction inside the folder itself.** CLAUDE.md and HANDOVER both tell a newcomer to go run peptide-ops. CONSULTANT_ROADMAP's "Stop #2" says peptide-ops should never receive another hour of work and names it specifically as negative-compounding. Both are in the same folder, written days apart. That needs a human decision, not a guess.

**Two undocumented files.** `accsmarket_scanner.py` and `accsmarket_results.json` appeared on 2026-07-21. They are newer than every markdown file in the folder and are referenced nowhere.

**One known security exception.** VIRAL_FILLER_RENDER_HANDOVER.md contains a plaintext Supabase key. It is the publishable key, not the service-role secret, so it is less severe than it first looks. It is still a real risk here, because row-level security is off on roughly 60 tables, which means a publishable key reads almost everything. It is logged as a known accepted exception. Do not copy it anywhere and do not create new ones. Nothing of that kind belongs in this vault.

**One structural gap.** No vault note previously referenced the architecture folder at all. The link between the vault and the code has been one-directional. These three notes are the first pointers back.

---

## 9. The end-to-end flow, in one pass

1. An n8n writer workflow generates a hook and a script for a given character and content type
2. It writes the row to the matching Supabase content table with status `pending`
3. A quality gate or review board evaluates the copy and moves it to `approved`. Copy is judged **before** rendering, never after.
4. A Director workflow picks the assets: clips, images, music
5. A **local** ffmpeg or Satori renderer on this Mac produces the finished file and uploads it to Supabase storage
6. The row moves to `unified_posts`
7. The [Unified] Posting Agent picks it up on schedule and fires it at a Geelark cloud phone
8. Geelark posts to Instagram or TikTok from that phone, over that account's proxy
9. The Geelark Task Detail Poller writes the outcome back into `geelark_tasks` hourly
10. Twice a week the two health jobs read the results and email a report

The three places this loop breaks today: the 22 percent post failure rate at step 7, the missing ban verdict at step 10, and the fact that step 8 depends on proxy quality nobody can see from SQL.

---

## Related notes
- [[n8n — System State 2026-07-21]]
- [[Peptide Miracles API — Swagger & OpenAPI]]
- [[content-system-map]]
- [[unified-posting-architecture]]
- [[account-health-system]]
- [[peptide-content-system]]
