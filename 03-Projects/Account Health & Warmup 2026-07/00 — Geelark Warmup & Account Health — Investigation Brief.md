---
tags: [account-health, warmup, geelark, ban-forensics, investigation]
description: "2026-07-04 evidence pack on warmup and bans: death rate by warmup method, and the Geelark data gaps."
updated: 2026-07-04
status: prep doc — walk into the warmup review with this

---
# Geelark Warmup & Account Health — Investigation Brief

*Everything to go over the Geelark warmup problem in one place: the ban evidence, what our health detection actually does, and — the key gap — how little of Geelark's own activity we capture. Pulled live from Supabase (`story-finder` / `qlcmgxgwpzmiebzxflai`) and n8n (`czed.app.n8n.cloud`) on 2026-07-04.*

---

## TL;DR — the one thing
**How an account is warmed up is the single biggest predictor of whether it dies. Geelark's automated warmup is 100% fatal — every account we warmed that way is gone.** But we can't yet prove *why*, because we store almost nothing about what Geelark actually did. The warmup runs, device/proxy history, ban timestamps, and fail codes all live inside Geelark — not in our database. To do the autopsy you have to pull from Geelark directly.

---

## 1. The evidence — ban rate by warmup method (confirmed with real numbers)

Cohort = surviving accounts (roster) + banned accounts (event log), grouped by how they were warmed:

| Warmup method | Surviving | Banned | Total run | **Death rate** |
|---|---|---|---|---|
| **Geelark Automation** | 0 | 6 | 6 | **100%** ☠️ |
| Bran's Scripts | 3 | 3 | 6 | 50% |
| Tokportal | 4 | 2 | 6 | 33% |
| **Superwarm (all)** | 14 | 4 | 18 | **22%** ✅ best |

- **Geelark Automation: 6 warmed, 6 dead, 0 survivors.** The dead handles: `fayah.amari`, `heyimtobie`, `desireevance_`, `imserene_parks`, `gauffalicia`, `simplykatiet`. All Instagram, all hard bans.
- **The cleanest cohort in the whole fleet:** the 3 `Superwarm (manual warmup exp)` accounts — all healthy, zero bans. Manual, careful warmup is the opposite end from Geelark auto.
- **Platform pattern holds:** Instagram = hard bans; TikTok = shadowbans/mutes (Tokportal on TT: 0 bans, 2 shadowbans). IG kicks you out, TikTok quietly hides you.

**Caveats (say these out loud in the review):**
- Small samples — cohorts of 6, 6, 6, 18. The 100% is real but it's 6 accounts.
- The `accounts` table only holds survivors (21, all `is_active=true`). Dead accounts exist *only* as rows in `account_events`. True fleet ever run ≈ 21 survivors + 15 banned ≈ **36 accounts**.
- **We can't compute lifespan-at-death** — `account_created_on` and `account_events.account_age_days` are NULL everywhere, and 15 of the ban events were backfilled on 2026-07-03 with the same date. So "how fast did Geelark accounts die" isn't answerable from the DB yet — that answer is in Geelark.

---

## 2. Geelark warmup process — what we actually run

All warmup is fired through Geelark RPA templates from n8n schedulers. **Every one of these is currently Inactive** — worth confirming what's actually warming accounts today.

| Workflow (n8n id) | What it does | Template / flowId |
|---|---|---|
| IG Warmup – Batch Scheduler (`VAgGvPmzUbE37Ium`) | Schedules Geelark IG Warmup V2, jittered params | IG warmup `623243712180256961` |
| TikTok Warmup – Batch Scheduler (`Rtnr65ioYTSFDYpl`) | Same, TikTok | — |
| TikTok Warmup (+ Martin Steps) (`z63n7VJLwdd2cyWz`) | TikTok variant with "Martin Steps" | `626270319530737995` |
| Facebook Warmup – Batch Scheduler (`SV6gipJfJVPy3TV2`) | Same, Facebook | `617362051542548769` |
| [Warmup] Posting Viral Content on New Accounts (`k3EwfcKFW5TwHlRl`) | Seeds new accounts with proven viral reposts (IG, no music) over N days | — |

**How the schedulers work:** they compute jittered warmup params in memory — `totalMinutes` 15–35, `interactionChance` 20–30, 8–14 niche keywords per task, timing jitter — and send them to Geelark. **None of this is stored.** We don't keep which keywords ran, how long, how many interactions, or whether the warmup run succeeded. We fire warmup blind.

> ⚠️ **This is the crux.** "Geelark Automation warmup = 100% dead" is the *label* on the account, but the *behavior* that got them banned (the automated interaction pattern Geelark's own warmup performs) is exactly what we don't record. The thing most likely killing accounts is the least-observed thing we do.

---

## 3. Account health detection — how it works today

Two layers. Neither is sourced from Geelark — both run off **ScrapeCreators view data** (`post_performance` for IG + `tt_post_performance` for TikTok).

### Layer 1 — the classifier (Supabase)
`v_account_view_health` (a view) + `run_account_health_check()` (a function). For each account it compares **recent 7-day median views vs the 28-day baseline** and buckets it. The thresholds (worth knowing):

| Status | Rule | Meaning |
|---|---|---|
| `banned` | `is_active = false` | dead (flag set elsewhere) |
| `muted` (shadowban) | posting ≥3/wk **but** 7d median <20 views (or best-of-14d <50) | posting into the void |
| `collapsing` | 28d median ≥50 **and** 7d median < **40%** of it | had reach, just fell off a cliff |
| `watch` | 7d median <60 **or** ≥3 zero-view posts in 21d | soft warning |
| `idle` | posted in 28d but nothing in 7d | stopped posting |
| `unknown` | no posts in 28d | no data |
| `healthy` | everything else | fine |

`run_account_health_check()` runs the view, writes the status back onto `accounts`, and logs any *change* to `account_events`. There's **no database scheduler** — it's triggered by n8n.

### Layer 2 — the alert (n8n)
**[Health] View-Collapse Detector** (`2Goujvw8qSvVzIfo`, Active):
- **Runs Tue & Fri at 13:00 UTC** (cron `0 13 * * 2,5`) + an on-demand webhook.
- Calls the Supabase RPC → formats an HTML email → sends via Gmail as "Peptide Health Bot."
- **To:** czedrickjhake.cc@gmail.com · **CC:** garreth@cryptomiami.net
- Subject: `⚠ Account Health — {N} of {total} need attention — {date}`. "Needs attention" = banned + muted + collapsing.
- Body: alert banner, untracked-but-posting handles, per-account table (status pill, handle, profile, platform, 7d/28d views), and a change log since last check.

### The weakness in the current forensic log
`account_events` has only ~22–24 rows, and every one is `source=backfill` or `source=detector`. **None come from Geelark.** The ban timestamps in there were entered by hand, not pulled from Geelark's action logs. So our "forensic log" currently reconstructs bans from view-collapse + manual backfill — it does not know *when Geelark saw the account go down* or *why*.

---

## 4. The Geelark logs gap — what we have vs. what you must pull

**Our database is a fire ledger, not a Geelark mirror.** We reliably record *what we told Geelark to do*; we capture almost nothing of *what Geelark did back*.

**What we have:** `geelark_tasks` — 1,321 rows, one per post we scheduled (task_id, env_id, profile, handle, what content, when). Written at fire-time by the `geelark-save-receipt` webhook.

**What's broken / empty:**
- `status` NULL on 1,320 of 1,321 rows · `fail_code` NULL on **all** 1,321 · `cost` NULL · `logs` on **1** row · `result_images` on 1 row.
- 685 rows have a `detail_polled_at` timestamp but still no payload — **the hourly "Geelark Task Detail Poller" is stamping the time but not writing Geelark's response into the columns. The poller is effectively broken.**
- The **Account Health Check** workflows (`CXVxRMOUkLluRdBc` IG+TT, `CJQKNXIBPB0B8LF5` For-Posting) *do* pull Geelark `/task/detail` and classify ALIVE / BANNED / FLAGGED / LOGIN_ISSUE — but they **write the verdict to a Google Sheet ("Account Health"), not to Supabase.** That sheet is your best existing secondary copy of Geelark ban data.

**What lives ONLY in Geelark — pull these directly:**
1. **Warmup activity & logs** — what each warmup run browsed, how long, interactions, success/fail → `/open/v1/task/query` + `/task/detail`
2. **Warmup schedule history** — actual scheduled/executed warmup tasks per profile over time (computed in-memory, never saved)
3. **Device / cloud-phone inventory** — profile↔envId map, serialName, model, settings → `/open/v1/phone/list`
4. **Proxy assignment & history** — which proxy/IP each profile used, and changes → Geelark dashboard / phone detail
5. **Action & RPA execution logs + screenshots** → `/open/v1/task/detail` (`logs`, `result_images`)
6. **Ban / flag timestamps & fail codes** — Geelark `failCode`/`failDesc` (BANNED 20136/20137/20145; LOGIN_ISSUE 20116/20128/20144) and *when* → `/task/detail` + the Account Health Google Sheet
7. **Cost / billing per task** → Geelark dashboard
8. **Post-outcome confirmation** — did the scheduled post actually publish? → `/task/query`

**Access:** two n8n credentials exist — **"Geelark API"** and **"Geelark API 2"** (httpBearerAuth). A raw key may also be in `~/.config/peptide-secrets/.env`. Base URL: `https://openapi.geelark.com/open/v1/`.

---

## 5. What to investigate next (the warmup autopsy)

The hypothesis is sound; here's how to actually prove and fix it:

1. **Pull the 6 dead Geelark accounts' full task history from Geelark** (`/task/query` + `/task/detail` for those env_ids) — read the actual warmup runs and the fail codes. Compare the interaction pattern against a surviving Superwarm account. *This is the direct autopsy.*
2. **Get the Account Health Google Sheet** — it already holds Geelark ALIVE/BANNED verdicts the DB never captured. Fastest existing evidence.
3. **Compare warmup behavior:** Geelark auto vs Superwarm-manual — session length, interaction rate, keyword breadth, cadence. The difference in behavior is the likely ban trigger.
4. **Decision:** if Geelark auto-warmup is confirmed as the killer, kill it as a warmup method entirely and move all new accounts to Superwarm (manual) — the 22% cohort, and 0% on the manual-exp variant.
5. **Fix the data blindness** so the next cohort is observable (see §6) — otherwise we're guessing again next month.

---

## 6. Bugs & fixes this surfaced (so warmup becomes observable)

- **Geelark Task Detail Poller is not landing its payload** — fix so `geelark_tasks.status/fail_code/logs/cost` actually populate. Without this we never see post outcomes or fail codes.
- **Account Health Check writes to a Google Sheet, not Supabase** — repoint (or dual-write) into `account_events`/`geelark_tasks` so Geelark's ban verdicts join the forensic log.
- **`account_age_days` / `account_created_on` never populated** — backfill an account-created date so lifespan-by-warmup becomes computable.
- **Warmup schedulers store nothing** — log each warmup run (params + Geelark task_id + outcome) so warmup behavior is auditable per account.
- **🔒 Security (separate but urgent):** `story-finder` has **RLS disabled on 49 public tables including `accounts`**, which stores per-account Instagram long-lived `access_token`s. Anyone with the anon key can read them. Supabase flags this **critical**. n8n uses the service role (bypasses RLS), so locking it down shouldn't break pipelines — but validate first.

---

## Appendix — system map

**Supabase** (`story-finder` / `qlcmgxgwpzmiebzxflai`, schema `public`)
- `accounts` (21 survivors) — roster + health fields + `warmup_source`, `geelark_profile`
- `account_events` (~24 rows) — forensic log (backfill + detector only)
- `geelark_tasks` (1,321 rows) — fire ledger; outcome columns empty
- `v_account_view_health` — the classifier view · `run_account_health_check()` — the runner function
- Feeds: `post_performance` (IG views), `tt_post_performance` (TT views) via ScrapeCreators

**n8n** (`czed.app.n8n.cloud`)
- Health: `2Goujvw8qSvVzIfo` View-Collapse Detector (active) · `CXVxRMOUkLluRdBc` + `CJQKNXIBPB0B8LF5` Geelark login-health checks (active, → Google Sheet)
- Poller: "Geelark Task Detail Poller" (active, hourly, **payload not landing**)
- Warmup schedulers: `VAgGvPmzUbE37Ium` IG · `Rtnr65ioYTSFDYpl` TT · `z63n7VJLwdd2cyWz` TT+Martin · `SV6gipJfJVPy3TV2` FB · `k3EwfcKFW5TwHlRl` viral-repost warmup (all Inactive)
- Ban tooling: `w3YwEhm5CZtHts0P` Content Risk Gate (active) · `ZWQ4kUJHB4pL5d2X` Geelark Ban Analysis (inactive) · `lU6CmUdoYb94uJI4` Sheet→Supabase account sync (inactive)

**Geelark:** `https://openapi.geelark.com/open/v1/` — creds "Geelark API" / "Geelark API 2" in n8n; key possibly in `~/.config/peptide-secrets/.env`.
