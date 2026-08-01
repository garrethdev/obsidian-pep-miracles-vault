---
tags: [account-health, geelark, questions, data-integrity, open-questions]
description: "Ten questions the Geelark task data raises, each grounded in a live number pulled 2026-07-23."
updated: 2026-07-23
status: questions — grounded in live data, waiting on human answers and decisions
---
# Questions About The Geelark System

*Read the vault account-health notes, then read the live Geelark data in Supabase (`story-finder` / `qlcmgxgwpzmiebzxflai`), pulled 2026-07-23. These are the questions the data raises. Every one is tied to a real number so it is answerable, not hand-waving. Related: [[00 — Geelark Warmup & Account Health — Investigation Brief]], [[01 — Proxy & Account Health Audit — What We Check]], [[n8n — System State 2026-07-21]].*

---

## TL;DR — the one thing

**Only 6 of 32 accounts are healthy. 14 are banned.** The task data is now rich, 3,127 rows with real statuses and plain-English fail reasons. A 2026-07-23 follow-up resolved four of the original ten questions, some because I had misread the data. What survives is real: the View-Collapse Detector infers bans from views and has never been confirmed against Geelark, most posting failures are our own content and hosting, and we cannot yet judge the new warmup process. Resolved items are marked below.

---

## 1. RESOLVED — the join works, I used the wrong column

*Correction, 2026-07-23. My original claim here was wrong.* `geelark_tasks` also has a `serial_name` column, and it holds the same `Profile 11` label as `accounts.geelark_profile`. Joining on `serial_name` matches 3,117 of 3,127 task rows, which is 99.7 percent. I had joined on `env_id`, the numeric device id, which is the wrong key. There is no join problem and no schema change needed. Use `serial_name`.

- The only real residue: 10 task rows do not match, most likely from phones deleted at Geelark. Minor.
- Worth confirming that the audit workflow and any other consumer join on `serial_name`, not `env_id`.

## 2. Bans are INFERRED from views, never confirmed at Geelark

*Clarified 2026-07-23. The View-Collapse Detector is the intended ban recorder, confirmed by the user.* The 25 ban records split into `backfill` 15, all hand-entered on 2026-07-03, and `detector` 10, from 2026-07-07 to 2026-07-15. The detector is the View-Collapse Detector. It calls a ban when an account's views collapse.

That works, but it means a ban is really "the views went to zero." Separately, the Geelark login health check (`geelark_health_log`) can confirm a real ban at the source, and it has produced 124 ALIVE and **zero BANNED** across 141 checks. So nothing has ever confirmed a ban at Geelark itself.

- A view collapse can be a soft mute or a shadowban, not a hard ban. Of the 14 marked banned, how many are hard-banned at Geelark versus just dark?
- Should the Geelark login check confirm the detector's call, so "banned" means confirmed dead, not just quiet?
- This is the one on your list you already said needs a fix. The fix is to make the two agree.

## 3. What is the plan for a roster that is mostly dead?

Live roster health: 14 banned, 10 unknown, 6 healthy, 1 muted, 1 idle. Only 6 of 32 accounts are healthy. Active count has dropped from 21 to 18 to now.

- What is the account intake rate, and does it exceed the death rate, or are we shrinking?
- The 10 "unknown" accounts are the biggest blind spot. What are they? New and unmeasured, or dead and unconfirmed?
- Is there a target fleet size, and are we above or below it?

## 4. Which warmup PROCESS is safest, and is the old data even valid now?

*Reframed 2026-07-23 after user correction. The labels Superwarm, Tokportal and so on are the proxy or account SOURCE, not the warmup method. The real variable is the warmup PROCESS, which was recently rebuilt entirely.*

Ban counts by source label from `account_events`: Superwarm 9, Geelark Automation 6, Tokportal 5, Bran's Scripts 4. But every one of these bans happened under the OLD warmup process. So this table describes a process we no longer run.

- What is the exact date the warmup process changed? Everything before it is a different experiment.
- How many accounts have been warmed under the NEW process, and how many of those have died? That is the only cohort that tells us if the new process is better.
- `account_events.account_age_days` is still empty, so we still cannot measure lifespan at death for either process. See question 7.

## 5. RESOLVED — the fail codes were never unmapped, the descriptions were always there

*Correction, 2026-07-23.* Every failed task carries a plain-English `fail_desc` from Geelark. All 279 failed rows have one. The lookup table `geelark_fail_codes` is just incomplete, which is cosmetic. The real meanings:

| Code | What it actually means | Count | Fault |
|---|---|---|---|
| 29997 | **Insufficient balance** (the Geelark wallet ran dry, mostly on 2026-07-06) | 48 | Billing, ours |
| 20201 | Failed to upload video, network | 18 | Network |
| 29998 | **The cloud phone has been deleted** (we posted to phones that no longer exist) | 12 | Roster drift |
| 20268 | Unknown error | 6 | Geelark |
| 20230 | Handle video timeout | 2 | Network |
| 20242 | Failed to jump to video details | 1 | Geelark |

So 29997 was not a mystery ban signal. It was the Geelark account running out of credit. The open questions are now about two of those rows: are we watching the Geelark balance, and why are we posting to deleted phones?

## 6. One in five posts fails, and most of it is our own content and hosting

`unified-posting-agent`: 1,107 task rows, 225 failures, a 20 percent hard-fail rate across 28 profiles. Broken down by the real reason Geelark gave:

| Reason | Count | Share of fails | Profiles | Fault |
|---|---|---|---|---|
| REEL is empty | 62 | 27.6% | 5 | Our content |
| Video download file not found | 55 | 24.4% | 6 | Our hosting |
| Insufficient balance | 40 | 17.8% | 17 | Geelark billing |
| Cannot use the same music | 25 | 11.1% | 4 | Our content |
| Failed to upload video, network | 18 | 8.0% | 6 | Network |
| The cloud phone has been deleted | 12 | 5.3% | 6 | Roster drift |
| Everything else | 13 | 5.8% | small | mixed |

The story: **roughly 39 percent of the failures are our content pipeline shipping empty reels or duplicate music. Another 24 percent are our video URLs 404ing before Geelark can download them.** Only a small slice is genuine Geelark or network flakiness. The empty-reel and dup-music failures concentrate on just 4 to 6 profiles.

- Empty reels and duplicate music are our generator producing bad output. Which content type and which 5 profiles?
- "Download file not found" means the video URL died before posting. Are our render outputs expiring or being cleaned up too early?
- Does `[Reconcile] Nightly Failed Posts` requeue any of these, or is a fifth of output just lost?

## 7. Why can we still not compute how long an account lived before it died?

`accounts.account_created_on` is now populated on every row, which is progress since the July 4 brief. But `account_events.account_age_days` is still 0 of 62 rows filled. So even though we now know when each account was created, the ban event does not record the age at death.

- Why is the ban-writing step not stamping age, when the creation date it needs now exists?
- Is lifespan-at-death the number we most need to pick a warmup method, and are we one small join away from finally having it?

## 8. Are banned accounts truly excluded from posting, or just flagged?

All 14 banned accounts are correctly marked `is_active = false`. Good. But that is the flag, not proof of behavior.

- Does the posting agent actually skip `is_active = false`, or does it still attempt them and burn a Geelark action and possibly a fail code on a dead account?
- How quickly after a ban is detected does the account stop receiving tasks?

## 9. Which single profiles are dragging the failure rate?

29997 hit 21 of 33 profiles, so failure is spread wide, but the posting failures may concentrate. We have not yet asked which specific profiles carry the most failures.

- Are the failures spread evenly, or is a small set of bad profiles (bad proxy, bad device, bad login) generating most of them?
- If it concentrates, those profiles are the cheapest thing to retire or repair.

## 10. Do the fixed pipes actually stay fixed?

The July 4 data-blindness bug is fixed: status now lands on 2,957 of 3,127 rows, logs on most, fail codes on 279. But 43 rows are still polled-with-no-status, the exact signature of the poller silently dropping a payload.

- Is 43 a stable residue of genuinely statusless tasks, or is the poller starting to miss payloads again?
- What is the expected floor for that number, so we know when it is drifting?

---

## What would answer most of these at once

Three moves collapse most of the list:

1. **Store the numeric Geelark env id on `accounts`.** Fixes question 1, and makes 8, 9 and the whole audit joinable in SQL.
2. **Complete the fail-code map, starting with 29997.** Fixes question 5, and makes the failure reporting in questions 6 and 10 trustworthy.
3. **Confirm one real ban end to end at Geelark and write a BANNED verdict.** Fixes question 2, and tells us whether the ban numbers in questions 3 and 4 are real.
