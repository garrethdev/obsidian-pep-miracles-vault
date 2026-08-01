---
tags: [api, swagger, openapi, n8n, docs, infrastructure]
description: What the n8n API docs cover, how to rebuild them, and how far they have drifted from live.
updated: 2026-07-21
status: reference — read this before trusting the swagger page

---
# Peptide Miracles API — Swagger & OpenAPI

*What the API documentation actually is, how it gets built, and how stale it is right now. Checked live against n8n (`czed.app.n8n.cloud`), the local files in `/Users/garrethdottin/Claude/`, the hosted Vercel site, and Supabase (`story-finder` / `qlcmgxgwpzmiebzxflai`) on 2026-07-21.*

---

## TL;DR — the one thing

**The swagger page is real, live, and password protected, but it is behind reality.** The hosted version is 6 days stale and documents 43 endpoints. The copy on this Mac is 27 days stale and documents 35. Live n8n is running 67 webhook endpoints right now. So **25 production endpoints exist that the local docs have never heard of**, and 4 endpoints the local docs advertise are switched off and would 404 if anyone called them.

---

## 1. What the swagger actually covers

It documents **n8n webhook endpoints only**. Not the Geelark API, not Supabase, not the local render scripts. If a workflow has a Webhook trigger node, it can appear in the docs. If a workflow runs on a cron or is called by another workflow, it never appears.

Think of it as "the list of URLs you can POST to in order to make the content system do something."

Live counts on 2026-07-21:

| Thing | Count |
|---|---|
| n8n workflows total | 253 (via REST) |
| Active workflows | 115 |
| Webhook trigger nodes | 98 |
| Webhook paths on active workflows | 67 |
| Documented in the hosted spec | 43 |
| Documented in the local `openapi.json` | 35 |

One security fact worth sitting with: **all 67 live webhook endpoints have authentication set to none.** That has not changed since the June baseline. Anyone who knows a URL can fire it.

---

## 2. How it is generated, and from what

There are **two separate builds of the same docs**. This is the part that trips people up.

### The local build (on this Mac, in `/Users/garrethdottin/Claude/`)

| File | What it does |
|---|---|
| `n8n-to-swagger.js` | The fresh-pull path. Reads every workflow from the n8n REST API, keeps the ones with webhook triggers, and infers each endpoint's path, method, auth and request shape. |
| `build-openapi.js` | The path that actually produced today's local files. It does **not** call n8n. It reads a frozen snapshot, `discovery-raw.json`, captured 2026-06-24. |
| `biweekly-check.js` | A cheap no-LLM drift scan. Signatures each webhook and diffs against `docs-baseline.json`. |
| `build-protected-docs.js` | Encrypts the spec with a password so the published page is not public. |

Three hand-maintained inputs get merged in and always win over the automatic inference:
- `verified-endpoints.json` (only **4** real curated entries)
- `simple-descriptions.json` (36 plain-English descriptions)
- an `EXCLUDE_PATHS` list of 11 throwaway test webhooks

So hand-verified coverage is about 11 percent of what is documented. Everything else is inferred.

### The hosted build (Vercel, project `peptide-n8n-docs`)

This is the one that is actually alive. It runs a cron on the 1st and 15th of each month that hits its own `/api/refresh`, pulls live n8n, diffs against a stored baseline, and only rebuilds when something changed. Its state lives in Supabase in the table `public.api_docs_state`.

The local scheduled task that used to do this is explicitly marked DISABLED and says it was superseded by the Vercel cron. There is no crontab entry and no LaunchAgent for it. **Nothing on this Mac refreshes the docs.**

---

## 3. Where the output lives

| Output | Location |
|---|---|
| Local spec | `/Users/garrethdottin/Claude/openapi.json` |
| Local viewer | `/Users/garrethdottin/Claude/swagger.html` (self-contained Swagger UI) |
| Local drift report | `/Users/garrethdottin/Claude/last-check-report.json` |
| Local baseline | `/Users/garrethdottin/Claude/docs-baseline.json` |
| Password-gated build | `/Users/garrethdottin/Claude/dist/index.html` |
| Published site | https://peptide-n8n-docs.vercel.app (returns 200, page is noindex) |
| Hosted state store | Supabase table `public.api_docs_state` |

The site is password protected. The spec is encrypted client-side and only decrypts in the browser after you type the password. The password itself is never stored in the page. The variable names live in a local env file with permissions 600. **No key values are written in this vault, and none should ever be.**

---

## 4. How stale it is right now

### Local `openapi.json`
- Version stamp: **2026-06-24**. That is **27 days old**.
- Documents 35 paths across 16 tags.
- `last-check-report.json` still says `firstRun: true`, meaning `biweekly-check.js` has run exactly once ever, its seed run.

### Hosted spec
- Last refreshed **2026-07-15**. That is **6 days old**.
- Documents 43 endpoints, but only **31 of those have a real contract**. The other 12 are auto-generated stubs with no request fields and no examples. The cron can spot a new endpoint but cannot write its description. That still needs a human or an LLM pass.

The 12 stub endpoints: `account-health-collapse`, `batch-approved`, `before-after-evidence-builder`, `carousel-quality-gate`, `covered-eye-hookmaker`, `covered-eye-scriptwriter`, `iphoneify`, `machine-hooks-tagger`, `rich-life-card-renderer`, `seedance-prompt`, `ugc-image-prompt`, `vision-repair`.

---

## 5. The concrete drift list

### A. Live in n8n but MISSING from the local `openapi.json` (25 production endpoints)

Eleven more are missing on purpose because they are the test webhooks on the exclude list. These 25 are real:

| Method | Path | Workflow |
|---|---|---|
| POST | account-health-collapse | [Health] View-Collapse Detector |
| POST | ba-2slide-scriptwriter | [2-slide BA] Scriptwriter |
| POST | ba-ow-hook-generator | [BA Older Woman] Hook Generator |
| POST | batch-approved | [Batch Approval] Notify + Export |
| POST | before-after-evidence-builder | [Before/After Evidence] Builder |
| GET | captcha-list | Geelark Auth Code API |
| POST | carousel-quality-gate | [Universal] Carousel Quality Gate |
| POST | covered-eye-hookmaker | Covered Eye Hookmaker |
| POST | covered-eye-scriptwriter | Covered Eye Scriptwriter |
| POST | divorce-collector | Divorce Story Collector |
| POST | divorce-director | Divorce Director |
| POST | divorce-scriptwriter | Divorce Scriptwriter |
| GET | geelark-authcode | Geelark Auth Code API |
| POST | glowup-director | Glow-Up Director / Image Organizer |
| POST | glowup-render | Glow-Up Render (Satori) |
| POST | glowup-writer | Glow-Up Writer / Hook Maker |
| GET | gmail-quality | Gmail Quality Check (IPQS + Firecrawl) |
| POST | iphoneify | [Footage] iPhone-ify Prep |
| POST | iphoneify-status | [Footage] iPhone-ify Prep |
| POST | machine-hooks-tagger | Machine Hooks Tag Labeler (Opus) |
| POST | rich-life-card-renderer | [Carousel] Unified Renderer |
| POST | seedance-prompt | [Seedance] UGC Prompt Writer |
| POST | ugc-image-prompt | [UGC] Image Prompt Writer |
| POST | universal-music-selector | [Universal] Music Recommender (mood-match) |
| POST | vision-repair | [Repair] Vision backfill for null hooks |

Three of these were created on 2026-07-21 itself: `captcha-list`, `geelark-authcode` and `gmail-quality`.

### B. Documented locally but NO LONGER LIVE (4 endpoints, would 404)

All four workflows still exist in n8n but are switched off. This matches the known "scriptwriters are deactivated" state. The docs never caught up. The hosted spec has already dropped all four.

- `peptide-miracles-bw-gatekeeping-scriptwriter`
- `peptide-miracles-rich-life-scriptwriter`
- `peptide-miracles-strong-informational-scriptwriter`
- `peptide-miracles-video-judge`

### C. New since the hosted 2026-07-15 refresh (12 added, 0 removed)

`ba-2slide-scriptwriter`, `ba-ow-hook-generator`, `captcha-list`, `divorce-collector`, `divorce-director`, `divorce-scriptwriter`, `geelark-authcode`, `glowup-director`, `glowup-render`, `glowup-writer`, `gmail-quality`, `universal-music-selector`.

Worth noting: `universal-music-selector` and `rich-life-card-renderer` were both created back in April. They are "new to the docs" only because they were inactive at baseline time and have since been switched back on. New to the docs is not the same as newly built.

---

## 6. Known bugs in the refresh system

These are real defects found by reading the refresh code, not guesses.

1. **Workflows with two webhook nodes lose one.** The refresh only creates a docs entry if the workflow id is not already present. Proof: `iphoneify-status` is in the hosted baseline but absent from the hosted spec, because `iphoneify` claimed the slot first.
2. **The test-endpoint filter is too broad.** It treats any path starting with `/webhook/` as test or experimental, so a genuinely mis-pathed production endpoint gets silently skipped instead of flagged.
3. **The hardcoded-key report shrank without anything being fixed.** The local report counted 48 workflows with inline keys on 2026-06-24. The hosted version now lists 29, but only because it stopped scanning non-webhook workflows. Do not read that as 19 workflows cleaned up.
4. **The local fallback is dead.** The scheduled task is disabled, there is no cron, and the report still says first run. If the Vercel cron ever breaks, nothing here will notice.
5. **There is a stale twin folder.** `n8n-docs-cloud/` looks like the deployed project but is not linked to Vercel and its own URL 404s. The real one is `peptide-n8n-docs/`. Editing the wrong one is an easy mistake.

---

## 7. How to refresh this (runbook)

Pick the path that matches what you want.

**Just want to see what changed, no rebuild:**
1. `cd /Users/garrethdottin/Claude`
2. Source the local env file so `N8N_API_KEY` is set.
3. Run `node biweekly-check.js`.
4. Read `last-check-report.json`. If `changed` is false, stop. If it lists added or changed endpoints, continue.

**Want to rebuild the local spec from live n8n:**
1. Run `node n8n-to-swagger.js` (this is the one that actually calls n8n, unlike `build-openapi.js` which reads the frozen June snapshot).
2. Add or fix entries in `verified-endpoints.json` for anything new. This file wins over the automatic inference, so it is where good descriptions belong.
3. Add plain-English lines to `simple-descriptions.json`.
4. Run `node build-openapi.js` to emit `openapi.json` and `swagger.html`.
5. Open `swagger.html` in a browser to eyeball it.

**Want to refresh the published site:**
The Vercel cron does this on the 1st and 15th automatically. To force it early, call the project's `/api/refresh` route with its bearer secret. The secret lives in Vercel's environment settings, not here.

**Want to rebuild the password-gated page:**
Run `node build-protected-docs.js` with the docs password set in the environment. It writes `dist/index.html`.

**The one thing to do first if you only do one thing:** run `node n8n-to-swagger.js` then `node build-openapi.js`. That alone closes the 27-day local gap and pulls in the 25 missing production endpoints.

---

## Related notes
- [[n8n — System State 2026-07-21]]
- [[Architecture — How The System Fits Together]]
- [[n8n-webhook-api]]
- [[content-system-map]]
