---
tags: [account-health, warmup, geelark, proxy, audit, spec, ban-forensics]
description: Every check the biweekly proxy and account health audit runs, with its threshold and the action to take.
updated: 2026-07-26
status: spec doc, the definitive list of what the biweekly proxy and account health audit checks

---
# Proxy & Account Health Audit — What We Check

*The exact check list for the biweekly proxy and account health audit. Every rule, threshold, data source and action is written down here so the audit email is never a black box. Grounded in a live pull from Geelark (`openapi.geelark.com`), Supabase (`story-finder` / `qlcmgxgwpzmiebzxflai`) and n8n (`czed.app.n8n.cloud`).*

*This file lives in two places and the two copies must stay byte-identical:*
- *Vault: `03-Projects/Account Health & Warmup 2026-07/01 — Proxy & Account Health Audit — What We Check.md`*
- *Code: `/Users/garrethdottin/Claude/proxy-audit/AUDIT_SPEC.md` (this is the copy the n8n workflow references)*

*Implemented by n8n workflow `FknqQM7GNJJmViRP`, `[Audit] Proxy & Account Health — Biweekly`. **Activated 2026-07-26** (active version `ddced05b`). First live run and email went out 2026-07-26.*

> **2026-07-22 reconciliation.** This document and the workflow had drifted apart badly. The check ids meant different things in each, the workflow was missing six checks this document promised, and this document described a snapshot table that was never created and a config node that never existed. Section 9 records exactly what changed and which side won each disagreement. The rule going forward: this document owns the check ids, the thresholds, the severity names and the subject line. The workflow owns nothing that is written down here.

---

## TL;DR, the one thing

**Proxy and IP data does not exist anywhere in our database. It lives only inside Geelark.** So this audit is the only place we can see which accounts are sitting on a genuine hosting-provider exit, which are on the fleet's normal ISP proxies, and whether the dead accounts cluster on the same network. The first live pull flagged `is_datacenter` on many exits, but on 2026-07-26 P2 was corrected to key off the ASN the platform actually resolves: of 24 profiles, exactly **1 is on a true hosting ASN** (Rockion/WebNet, also a VPN exit) and the rest are datacenter-hosted **ISP** proxies, which is the intended setup. That reclassification, plus dead-cluster correlation, is the whole reason this audit exists.

Thirteen checks. Seven on proxies, six on account health plumbing. Each one fires or stays quiet on a fixed rule, and each one tells you what to do about it.

The single most valuable one is **P6**, dead-cluster correlation. Everything else describes state. P6 asks whether the state is killing accounts.

---

## 0. Did we already have this audit? No.

The question was asked directly, so here is the direct answer, with what was searched and what was found. Verified against the n8n REST API on `czed.app.n8n.cloud` and the Supabase `story-finder` schema on 2026-07-21.

| Question | Answer |
|---|---|
| Is there an existing scheduled audit that checks proxies, shared IPs or datacenter exits? | **No.** All 254 workflows were listed and every workflow whose name matches proxy, audit or ban was opened. Nothing calls `phone/list` for proxy data, nothing calls any IP reputation service, and nothing groups profiles by exit IP. |
| Is any of it stored, so it could be checked in SQL instead? | **No.** `information_schema.columns` has no column matching `%proxy%` or `%ip%` anywhere in the public schema. Proxy and IP assignment exist only inside Geelark. |
| What is the closest thing that exists? | `Geelark - Account Ban Analysis`, n8n `ZWQ4kUJHB4pL5d2X`. Created 2026-05-22, last touched 2026-05-27, **inactive, and it has never executed once** (0 executions). It was never finished. Its `phoneSlim()` helper and proxy fail-code list were reused as the starting point for the proxy checks. |
| So what already runs in this area? | Three live workflows, none of which look at proxies: `[Health] View-Collapse Detector` (`2Goujvw8qSvVzIfo`), `Account Health Check (IG and TT)` (`CXVxRMOUkLluRdBc`) and `Geelark Task Detail Poller` (`ARmIDPrV77c0k4zA`). Section 4 lists exactly what each one owns so this audit never duplicates or contradicts them. |

**Conclusion: this is new work, not a rebuild.** The proxy half of it has never been possible before, because the data was never pulled out of Geelark.

---

## 1. Severity meanings

| Severity | Meaning | Email treatment |
|---|---|---|
| **critical** | Active ban vector or data loss. Act this week. | Red pill, listed at the top, forces the warning subject line |
| **warn** | Degrading or drifting. Act within two runs. | Amber pill, listed in the body |
| **info** | Worth knowing. No action required unless it repeats. | Grey pill, collapsed into a separate section at the bottom |

There are only these three. Any use of high, medium or low is a bug.

**info never triggers the warning subject line.** This matters because P6 always prints its full table at info level, so an audit where nothing is wrong still produces info rows. The headline count in the subject and the banner counts critical and warn findings only.

Subject line, in the house convention borrowed from the View-Collapse Detector:

```
⚠ Proxy and Account Health Audit — N findings — YYYY-MM-DD
✓ Proxy and Account Health Audit — all clear — YYYY-MM-DD
```

`N` is the number of critical plus warn findings. The warning form is used whenever `N > 0`.

---

## 2. Proxy checks

All seven read from Geelark. None of them can be answered in SQL, because there is no proxy column and no ip column anywhere in the Supabase public schema.

### P1, proxy sharing and subnet clustering

| Field | Value |
|---|---|
| **Question** | How many separate accounts are running through the same IP, or the same /24 block? |
| **Source** | `POST /open/v1/phone/list`, body `{"page":1,"pageSize":100}`. Read `data.items[].proxy.server`, `data.items[].proxy.port`, `data.items[].serialName`, `data.items[].id` |
| **Rule** | Group all profiles by exact `server:port`. When `SHARED_PROXY_MIN_PROFILES` (2) or more distinct profiles share one pair, report it. Severity of that exact-match report is controlled by `SHARED_PROXY_INTENTIONAL`: **info** when true (the current setting, because proxy sharing is deliberate in this fleet), **critical** when false. Then group by /24, meaning the first three octets of the exit IP. Fire **warn** when `SUBNET_CLUSTER_MIN_PROFILES` (3) or more distinct profiles share one /24 and at least one of them is not already named in the exact-match report. |
| **Severity** | info for an exact IP and port match while `SHARED_PROXY_INTENTIONAL` is true (critical when false), warn for /24 clustering |
| **What to do** | Exact match means two accounts look like one device to the platform. In this fleet that is on purpose, so it is logged at info only. If sharing ever stops being intentional, flip `SHARED_PROXY_INTENTIONAL` to false, reassign one of each pair to a fresh proxy in Geelark, then let it sit idle for at least 48 hours before posting again. For a /24 cluster, spread the accounts across different vendors rather than buying more IPs from the same block. |

Baseline from 2026-07-21: two exact collisions found. `48.45.244.180:45909` shared by Profile 38 and Profile 39. `82.47.5.43:45103` shared by Profile 35 and Profile 36. Both are intentional, so on the current setting they report at info, not critical.

**2026-07-26 change.** The exact-match leg was reported critical until sharing was confirmed deliberate. It is now gated behind `SHARED_PROXY_INTENTIONAL` (default true → info). The /24 clustering warn is unchanged.

Note: the audit reports on 24 phones across 22 distinct `server:port` pairs, so a clean run should show 24 profiles on 24 unique pairs.

### P2, datacenter and hosting proxy detection

| Field | Value |
|---|---|
| **Question** | Which profiles are posting from a genuine hosting/datacenter exit, as opposed to the fleet's normal ISP proxies? |
| **Source** | Exit IPs from `phone/list` `proxy.server`, enriched via `POST https://api.ipapi.is/` with body `{"ips":[...]}`, max 100 IPs per call, no API key needed |
| **Rule** | Classify each exit into one `dc_class` and report by tier. **critical** (`hosting_asn`) when `asn.type === "hosting"`. **warn** (`hosting_company`) when `asn.type` is not hosting but `company.type === "hosting"`. **info** (`datacenter_only`) when neither of those holds but `is_datacenter === true`. Each leg can still be switched off through `DATACENTER_RULE`. Evidence string is `company.name`, ASN, `asn.type`, `company.type`, and any reputation flags. |
| **Severity** | critical on a hosting ASN, warn on a hosting company over ISP-announced space, info on a bare `is_datacenter` flag |
| **What to do** | A hosting **ASN** is what actually reads as a datacenter to Instagram and TikTok, so that is the only critical: move the profile to a residential, ISP or mobile proxy from Proxy-Cheap (Instagram, ISP proxies) or Geonix (TikTok, mobile proxies) and do not post until the swap is done. A hosting **company** on an ISP ASN (a datacenter reselling residential space) is a warn: verify it before trusting it. A bare `is_datacenter` flag on an ISP ASN is the normal signature of an ISP proxy and needs no action. |

Why severity is keyed to `asn.type` and not `is_datacenter`: **ISP proxies are physically datacenter-hosted by design**, so ipapi.is reports `is_datacenter: true` on nearly all of them. The field that a platform actually resolves and bans on is the announced ASN. On 2026-07-21 the old rule fired 6 criticals off `is_datacenter`; 5 of those 6 announce under an ISP ASN (Comcast, Lumina Broadband) and are the fleet's intended setup. Flagging them critical was a false positive. The corrected rule on 2026-07-26 leaves exactly one true hosting-ASN exit critical.

Baseline recomputed 2026-07-26 under the corrected rule (over the enriched exit IPs):

| dc_class | Severity | Example exits |
|---|---|---|
| `hosting_asn` (1) | **critical** | Profile 47 — `162.244.211.30` Rockion LLC / WebNet, `asn.type=hosting`, also `is_vpn` |
| `hosting_company` (2) | **warn** | `166.88.179.166` / `.33` Ace Data Centers II on Comcast ASN |
| `datacenter_only` | **info** | Lumina Broadband (`82.47.x`), Neurial (`77.111.118.219`) — datacenter-hosted ISP proxies, expected |

Also reported at **info** severity from the same enrichment call, because they signal a reused or burned IP: `is_vpn`, `is_proxy`, `is_abuser`, `is_tor`. The list is `REPUTATION_FLAGS`. Any of those true on an active profile gets one line in the info section.

### P3, geo coherence

| Field | Value |
|---|---|
| **Question** | Does the proxy's real location match the device's declared location and timezone? |
| **Source** | Geelark `phone/list` `equipmentInfo.countryName`, `equipmentInfo.timeZone`, `equipmentInfo.city`, `equipmentInfo.province`. Proxy location from ipapi.is `location.country_code`, `location.timezone`, `location.city`. Confirmed where available with `POST /open/v1/proxy/check` fields `countryCode`, `city`, `timezone` |
| **Rule** | Compare in three tiers. Fire **critical** when the proxy country code does not equal `EXPECTED_COUNTRY`. Fire **warn** when the country is fine but the proxy timezone does not equal the device `timeZone`, gated by `GEO_CHECK_TIMEZONE`. Fire **info** when country and timezone match but the city differs, gated by `GEO_CHECK_CITY`. |
| **Severity** | critical on country mismatch, warn on timezone mismatch, info on city mismatch |
| **What to do** | Country mismatch is the serious one. A US persona posting from a non-US exit IP will get flagged. Fix it by reassigning the proxy, not by changing the persona. Timezone mismatch matters because the Device Warmup workflow sets GPS from the phone's own city, so a wrong timezone means GPS, IP and locale disagree at the same moment. City-level drift is normal for ISP proxies and is logged for pattern-spotting only. |

Implementation note that matters: Geelark returns `equipmentInfo.countryName` as a country **name** ("United States") while ipapi.is returns a two-letter **code** ("US"). The country tier therefore compares the proxy code against `EXPECTED_COUNTRY` and carries the device name through as evidence, rather than trying to normalise two different vocabularies. If a non-US group is ever added to the fleet, `EXPECTED_COUNTRY` becomes wrong and this check needs a per-group expectation instead of a single constant.

Baseline: all 24 phones are in the Geelark group `US Accounts` (group id 609461453010763886), so the expected country for every profile is US until a non-US group appears.

### P4, proxy churn since the last run

| Field | Value |
|---|---|
| **Question** | Did any profile's proxy change since the last audit? |
| **Source** | Current run from `phone/list`. Previous run from the audit's own snapshot table `proxy_audit_log`, matched on `env_id` and falling back to `profile_name` |
| **Rule** | Join current to the most recent prior row per `env_id`. Fire **warn** when `proxy_host` or `proxy_port` differs. Fire **info** when only `proxy_type` differs. Report both the old and new value, and note when the new exit is on a hosting ASN (`dc_class === "hosting_asn"`). |
| **Severity** | warn on IP or port change, info on protocol change |
| **What to do** | A proxy change nobody made is a vendor rotating the pool underneath you, which means the account's apparent location just moved without warning. Confirm whether the change was intentional. If it was not, that vendor is not supplying static IPs and the accounts on it should be treated as higher risk. A change onto a hosting ASN is a P2 critical on the next line anyway. |

**This check produces nothing on the first run.** It needs at least two snapshots. That is expected, not a failure.

### P5, unassigned or missing proxy on an active profile

| Field | Value |
|---|---|
| **Question** | Is any live profile running with no proxy at all, or is the account paying for proxies nothing is using? |
| **Source** | `phone/list` `proxy` object. `POST /open/v1/proxy/list`, body `{"page":1,"pageSize":100}` (both `page` and `pageSize` are required on this endpoint), reading `data.list[]` fields `id`, `server`, `port` |
| **Rule** | Fire **critical** for any phone where `proxy` is null, or `proxy.server` is empty, or `proxy.port` is missing. Fire **info** for every entry in `proxy/list` whose `server` plus `port` pair does not appear on any phone in `phone/list`. Report the orphan count against the total. |
| **Severity** | critical for a phone with no proxy, info for an orphaned proxy |
| **What to do** | A phone with no proxy is posting from Geelark's own datacenter egress. Stop that profile and assign a proxy before it posts again. Orphaned proxies are either leftovers from deleted profiles or paid capacity sitting idle. Reassign them to new profiles or cancel them. |

Baseline: zero phones without a proxy. 32 proxies exist against 24 assigned, so 8 are orphaned.

### P6, dead cluster correlation

This is the highest-value check in the document. Everything else describes state. This one asks whether the state is killing accounts.

| Field | Value |
|---|---|
| **Question** | Do banned, muted or inactive accounts cluster on particular proxies, subnets, vendors or device models? |
| **Source** | Geelark `phone/list` for the proxy dimension. Supabase `proxy_audit_log` for the historical proxy assignment of accounts that no longer exist in Geelark. Supabase `accounts` (`geelark_profile`, `username`, `platform`, `is_active`, `health_status`, `warmup_source`). Supabase `account_events` (`event_type`, `event_date`, `geelark_profile`, `username`, `warmup_source`). Supabase `geelark_health_log` (`profile_name`, `env_id`, `handle`, `verdict`, `fail_code`, `checked_at`) |
| **Join** | Start from the live Geelark phone list, never from Supabase. `phone/list.items[].id` equals `geelark_health_log.env_id`. `phone/list.items[].serialName` equals `geelark_health_log.profile_name` and equals `accounts.geelark_profile`. Strip a leading `@` from `geelark_health_log.handle` before grouping, because the same profile is stored both as `nia_thriving` and `@nia_thriving`. Left join, so a dead profile still appears via the snapshot table. |
| **Rule** | For every proxy `server:port`, every /24 subnet, every `deviceModel` and every `warmup_source`, compute a death rate as `dead / (dead + alive)`. Dead means the account has a `banned` or `shadowban_detected` event (`DEAD_EVENT_TYPES`), or `accounts.is_active = false`, or a `geelark_health_log` verdict in `DEAD_VERDICTS` inside `DEATH_LOOKBACK_DAYS`. Fire **critical** when a group has `DEATH_CLUSTER_MIN_CRITICAL` (3) or more accounts and a death rate at or above `DEATH_RATE_THRESHOLD` (0.50). Fire **warn** when a group has `DEATH_CLUSTER_MIN_WARN` (2) accounts and clears the same rate. Suppress groups of 1, they carry no signal. Always print the full table at **info**, sorted by death rate, so trends are visible before they cross a threshold. |
| **Severity** | critical at n>=3 and death rate >=50%, warn at n=2 and death rate >=50%, info for the full table always |
| **What to do** | A hot proxy or subnet means the network itself is burned, not the content. Retire every account on that proxy in an orderly way rather than replacing them one at a time, and stop buying from that vendor block. A hot device model means the fingerprint is the problem and the fix is a factory reset with a different model, which the `[Ops] Factory Reset - On Demand` workflow can do. A hot `warmup_source` confirms or refutes the July 4 finding that Geelark Automation warmup was 100% fatal across 6 accounts. |

The subject universe is the live Geelark fleet plus every profile recovered from `proxy_audit_log` that Geelark no longer has. That recovery is the only way a deleted profile keeps contributing to the death rate of the proxy that killed it. **On the first run `proxy_audit_log` is empty, so P6 sees live profiles only.** It gets stronger every run after that.

Honest caveat that must stay in the email footer: cohort sizes here are single digits. A 100% death rate on 3 accounts is a strong hint, not proof. Read it as a direction to investigate.

### P7, dead proxy

| Field | Value |
|---|---|
| **Question** | Does the proxy actually answer when you dial it? |
| **Source** | `POST /open/v1/proxy/check`, one call per distinct `server:port`, reading `data.detectStatus` |
| **Rule** | Fire **critical** for any profile whose proxy was dialled and returned `detectStatus` false. Profiles that were not dialled are not reported, so turning `RUN_PROXY_CHECK` off silences this check rather than filling the email with false positives. |
| **Severity** | **critical** |
| **What to do** | A proxy that does not answer means every task on that profile either fails outright or falls back to the real IP, which is worse. Replace the proxy before the profile runs another task. |

This check exists only in the workflow, not in the original ten. It is kept because `proxy/check` is being called anyway for P3 and the exit IP, so the liveness verdict is free.

---

## 3. Account health checks

These six exist to catch things nothing else is watching. They deliberately do not recompute anything the View-Collapse Detector already owns. See section 4.

### H1, new bans and flags since the last run

| Field | Value |
|---|---|
| **Question** | Which accounts died, got flagged or got locked out since the last audit? |
| **Source** | Supabase `account_events` (`event_type`, `event_date`, `username`, `geelark_profile`, `warmup_source`, `detail`, `source`). Supabase `geelark_health_log` (`verdict`, `checked_at`, `profile_name`, `handle`, `fail_code`). Fail code meanings from `geelark_fail_codes` (`code`, `category`, `meaning`) |
| **Rule** | Select every `account_events` row with `event_type` in `H1_EVENT_TYPES` (`banned`, `shadowban_detected`, `collapse_detected`) and `event_date` after the previous audit run timestamp. **The column is `event_date`. There is no `occurred_at` column on that table.** Select every `geelark_health_log` row with a verdict outside `ALIVE_VERDICTS`, excluding `UNKNOWN`, and `checked_at` after the previous run. Deduplicate by handle after stripping a leading `@`. Join each `fail_code` to `geelark_fail_codes` for a plain-English meaning. Fire **critical** on any `banned` event or `BANNED` verdict. Fire **warn** on `shadowban_detected`, `collapse_detected`, `FLAGGED` or `LOGIN_ISSUE`. Fire **info** on `OTHER_FAILURE`. |
| **Severity** | critical for bans, warn for flags and login issues, info for other failures |
| **What to do** | For each newly dead account, immediately record which proxy it was on before the profile is deleted, because once the Geelark profile goes the proxy history goes with it. Then check whether its proxy appears in P1, P2 or P6. If it does, the other accounts on that proxy are the next to go. |

**Why this reads `account_events` and not just the health log.** `geelark_health_log` has never recorded a `BANNED` verdict. Its only verdicts to date are `ALIVE`, `OTHER_FAILURE` and `UNKNOWN`. A health-log-only ban check structurally cannot surface a real ban, no matter how correct its schema is. `account_events` holds 25 real `banned` rows across 26 distinct handles, and it is the only source of actual ban data we have.

"Since the last run" means since the newest `checked_at` in `proxy_audit_log`. When there is no previous run, the window falls back to `H1_FALLBACK_LOOKBACK_DAYS` (14) and the email says so in the finding title.

This check reports events. It does not write to `account_events`, `accounts.is_active` or `accounts.health_status`. Those columns already have owners.

### H2, fail-code distribution and new codes

| Field | Value |
|---|---|
| **Question** | What is failing, and has a failure mode appeared that we have never seen before? |
| **Source** | Supabase `geelark_tasks` (`fail_code`, `fail_desc`, `status`, `task_category`, `source_workflow`, `created_at`). Supabase `geelark_health_log` (`fail_code`). Lookup table `geelark_fail_codes` (`code`, `category`, `meaning`) |
| **Rule** | Over the trailing `FAILCODE_LOOKBACK_DAYS` (14), count `geelark_tasks` rows grouped by `fail_code` and by `source_workflow`. Fire **critical** for any `fail_code` present in `geelark_tasks` or `geelark_health_log` with no matching row in `geelark_fail_codes`, because an unmapped code means a failure mode nobody has classified. Fire **critical** when any code whose category is in `HARD_BAN_CATEGORIES` appears at all. Fire **warn** when any single `source_workflow` has a hard-fail rate (`status = 4` over all its rows) above `WORKFLOW_FAILRATE_THRESHOLD` (0.25) across at least `WORKFLOW_FAILRATE_MIN_TASKS` (20) tasks. Print the full distribution at **info**. |
| **Severity** | critical for an unmapped code or any hard-ban code, warn for a workflow above 25% hard-fail, info for the distribution |
| **What to do** | An unmapped fail code needs a human to look it up in the Geelark docs and add a row to `geelark_fail_codes` so it classifies automatically next time. A hard-ban code means an account is gone, so cross-reference it against P6 immediately. A workflow above 25% hard-fail is broken plumbing, not bad luck. |

The rate is per `source_workflow`, not per profile. A profile-level rate answers "is this account struggling", which H5 and H6 already cover. A workflow-level rate answers "is this pipeline broken", which nothing else asks.

Baseline as of 2026-07-22, over the trailing 14 days:

| source_workflow | tasks | hard fails | rate |
|---|---|---|---|
| `unified-posting-agent` | 523 | 148 | 28.3% |
| `unified-warmup-scheduler` | 375 | 8 | 2.1% |
| `device-warmup-auto` | 63 | 0 | 0.0% |

`unified-posting-agent` is **above** the 25% threshold and will fire a warn on the first run. That is a real finding, not a bug. Group on the literal `source_workflow` value, not the n8n display name.

Unmapped codes present today: `20201`, `20230`, `20242`, `20268`, `29997`, `29998`. All six appear in `geelark_tasks` and none has a row in `geelark_fail_codes`, so all six will fire critical on the first run. That is correct behaviour and the fix is to add them to the table. `geelark_fail_codes` currently holds 51 rows across six categories: `ACCOUNT_RESTRICTED`, `CAPTCHA`, `HARD_BAN`, `LOGIN`, `POST_ERROR`, `TRANSIENT`. There is still no `PROXY`, `NETWORK` or `ENVIRONMENT` category.

### H3, data-integrity checks on the known-broken plumbing

| Field | Value |
|---|---|
| **Question** | Is our own telemetry lying to us? |
| **Source** | Supabase `geelark_tasks` (`detail_polled_at`, `status`, `fail_code`, `created_at`). Supabase `accounts` (`account_created_on`, `geelark_profile`, `is_active`). Supabase `account_events` (`account_age_days`). Supabase `geelark_health_log` (`checked_at`) |
| **Rule** | Four sub-checks. **H3a**: count `geelark_tasks` rows where `detail_polled_at IS NOT NULL` and `status IS NULL`. Fire **warn** above `UNPOLLED_TASKS_WARN` (25), **critical** above `UNPOLLED_TASKS_CRITICAL` (100), **info** with the current count otherwise. This is the exact signature of the poller failing silently, which is what happened between 2026-06-21 and 2026-07-04. **H3b**: count active accounts where `account_created_on IS NULL`. Fire **warn** when any exist, because account lifespan by warmup method is not computable without it. **H3c**: count `account_events` rows where `account_age_days IS NULL`. Fire **info**, same reason. **H3d**: check the newest `checked_at` in `geelark_health_log`. Fire **critical** if it is more than `HEALTHLOG_STALE_DAYS` (5) old. |
| **Severity** | H3a info then warn then critical, H3b warn, H3c info, H3d critical |
| **What to do** | H3a means the Geelark Task Detail Poller has lost its credential or hit signature failures again. Check workflow `ARmIDPrV77c0k4zA` and confirm it is still pointed at the `Geelark API 2` credential. H3b and H3c are the reason we still cannot answer "how fast do accounts die by warmup method", which is the single most valuable unanswered question in the July 4 brief. H3d means the audit is reading stale data and every other health finding this run is suspect. |

H3a is deliberately **not** date-filtered. A task that got stuck three months ago is still stuck, and windowing it to 14 days would hide exactly the backlog this check exists to find. It uses its own Supabase read, `Read Unpolled Tasks`, rather than the 14-day task read.

Baseline as of 2026-07-22: H3a sits at **28 rows**, above the warn line of 25, so it fires warn on the first run. H3b is 0. H3c is 62 of 62 `account_events` rows, so every event row is missing an age.

### H4, roster drift between Geelark and Supabase

| Field | Value |
|---|---|
| **Question** | Do the two systems agree on which accounts exist? |
| **Source** | Geelark `phone/list` `items[].serialName` and `items[].id`. Supabase `accounts.geelark_profile` where `is_active = true`. Supabase `geelark_health_log.profile_name` |
| **Rule** | Three directions. **H4a, ghost profiles**: a `serialName` in Geelark with no matching `accounts.geelark_profile` row. Fire **warn**. These are phones nobody is tracking, and they are still burning proxy and phone spend. **H4b, orphan roster rows**: an active `accounts` row whose `geelark_profile` does not appear in `phone/list`. Fire **warn**. The account exists on paper but has no device. **H4c**: a `profile_name` that appears in `geelark_health_log` history but not in the current `phone/list`. Fire **info**, this is normal profile deletion, but list them so the P6 snapshot can preserve their last known proxy. |
| **Severity** | warn for both drift directions, info for deleted profiles |
| **What to do** | Ghost profiles either get added to `accounts` or shut down. Orphan roster rows either get a device or get marked inactive. Do not fix these by hand in a way that races the health checks, both of which already write `accounts.is_active`. |

Baseline: 10 profiles (11, 13, 15, 19, 23, 24, 25, 26, 27, 34) appear in `geelark_health_log` but no longer exist in Geelark. `accounts` holds 32 rows, 18 of them active, against 24 live phones.

### H5, per-profile health-check staleness

| Field | Value |
|---|---|
| **Question** | Is any live profile going unchecked? |
| **Source** | Geelark `phone/list` joined to the newest `geelark_health_log` row per profile |
| **Rule** | Fire **warn** for any live Geelark profile whose newest verdict is older than `PROFILE_HEALTH_STALE_DAYS` (7), or which has never appeared in a health-check run at all. |
| **Severity** | **warn** |
| **What to do** | Silent profiles are the ones that turn out to be banned. Find out why `Account Health Check (IG and TT)` is skipping them. |

This is the per-profile version. H3d is the table-wide version, and they answer different questions: H3d says the whole health check stopped, H5 says it is running but missing specific profiles.

### H6, already flagged unhealthy in Supabase

| Field | Value |
|---|---|
| **Question** | Which accounts does the rest of the system already consider sick? |
| **Source** | Supabase `accounts.health_status` and `accounts.zero_view_streak` |
| **Rule** | Fire **info** when `health_status` is in `BAD_HEALTH_STATUSES` (`banned`, `muted`, `collapsing`) or `zero_view_streak` is at or above `ZERO_VIEW_STREAK_WARN` (3). |
| **Severity** | **info** |
| **What to do** | Nothing on its own. This is repeated here purely so the proxy evidence sits next to it in one email. The View-Collapse Detector owns these columns and owns the action. |

Deliberately info, never warn. Raising it higher would double-alert on something another email already alerted on that week.

---

## 4. What this audit does NOT check

Written down so nobody rebuilds work that already runs, and so the email never contradicts another email that lands the same morning.

| Not checked here | Who owns it | Where |
|---|---|---|
| View collapse, median views 7d versus 28d, zero-view streaks, shadowban scoring | `[Health] View-Collapse Detector` | n8n `2Goujvw8qSvVzIfo`, Tue and Fri, same recipients. It calls the Supabase RPC `run_account_health_check`. Do not recompute any of it. H6 reads its output and never recomputes it. |
| Live account liveness probing (starting a Geelark warmup or RPA task to see if the account still works) | `Account Health Check (IG and TT)` | n8n `CXVxRMOUkLluRdBc`, Tue and Fri 07:00. This audit **reads** its output in `geelark_health_log` and never fires its own probe. A third prober would add automation footprint to every profile and cost Geelark task budget. |
| Backfilling task detail from Geelark into `geelark_tasks` | `Geelark Task Detail Poller` | n8n `ARmIDPrV77c0k4zA`, hourly, verified working. This audit only measures whether it is still working (H3a). |
| Writing `accounts.is_active` or `accounts.health_status` | Two workflows already write those columns | A third writer would race them. This audit is read-only against `accounts`. |
| Writing `account_events` | The detector RPC | Read-only here. |
| Flipping Posted to Failed on Geelark status 4 or 7 | `[Reconcile] Nightly Failed Posts` | n8n `gHoiFBpQkrkGvTto`, nightly 02:00 ET. |
| n8n webhook documentation drift | `biweekly-check.js` plus the Vercel cron on `peptide-n8n-docs` | Different domain entirely. Not this audit's job. |
| Content quality, hooks, compliance, risk gating | The content audit and risk gate workflows | Not infrastructure. |
| Proxy vendor billing, invoices, spend reconciliation | Nobody yet | P5 reports orphan count so a human can act, but this audit does not touch any billing system. |
| Anything that changes Geelark state | Nothing here writes to Geelark | Every Geelark call in this audit is a read. No phone starts, no phone stops, no factory reset, no proxy reassignment. All remediation is manual. |

---

## 5. Data sources and auth

Credentials are referenced by name and id only. No secret value appears in this document, in the n8n workflow, in the snapshot table or in the email.

### Geelark

- Base URL `https://openapi.geelark.com/open/v1/`
- **Every endpoint is POST with a JSON body, including pure reads. There are no GET endpoints.**
- Headers: `Content-Type: application/json`, `traceId`, plus `Authorization: Bearer <token>` supplied by the stored n8n credential
- n8n credential: **`Geelark API 2`**, id `U3SEidE2CFbMXD8e`, type `httpBearerAuth`. This is the empirically working one. `Geelark API` (id `iM0g58GFlfrXfB6y`) is the same type and also valid.
- Endpoints used: `phone/list`, `proxy/list`, `proxy/check`
- Rate limits: 200 requests per minute, 24,000 per hour, per API. Exceeding a limit locks that API for **two hours**. Do not loop `proxy/check` unthrottled.

**Mandatory guard.** Geelark returns HTTP 200 even when auth fails. A bad token returns `200` with body `{"code":40003,"msg":"signature verification failure"}`. The n8n HTTP Request node will not throw on that. The workflow asserts `$json.code === 0` after the `phone/list` call and hard-fails the run if it does not hold, in the node `Assert Geelark OK & Flatten Phones`. Without this guard a broken credential produces a cheerful all-clear email.

`traceId` is documented as required but is not actually enforced. Send it anyway so Geelark support can trace a call.

### IP enrichment

- `POST https://api.ipapi.is/` with `Content-Type: application/json` and body `{"ips":[...]}`, maximum 100 IPs per call
- No API key, no credential, 1,000 requests per day on the free tier. One bulk POST of 22 IPs is one request.
- The bulk response is keyed by IP string and contains one extra non-IP key, `total_elapsed_ms`, which must be skipped when iterating.
- Single-IP fallback: `GET https://api.ipapi.is/?q={ip}`, same quota.
- `ip-api.com` was tested and rejected. Its free tier is HTTP only and it reported `hosting: false` for both `162.244.211.30` (Rockion LLC) and `166.88.179.33` (Ace Data Centers II), which are exactly the IPs this audit exists to catch.

### Supabase

- Project `story-finder`, id `qlcmgxgwpzmiebzxflai`
- n8n credential: the stored **`supabaseApi`** credential **`Supabase Service Role`**, id `BpJOuYVDTTtsYa5o`, referenced via `nodeCredentialType`. The workflow sticky note names the same credential, so the two artifacts agree on which one to bind. **Never hardcode a JWT in a header parameter.** Three existing workflows do this today and it is a known defect, not a pattern to copy.
- Tables read: `accounts`, `account_events`, `geelark_health_log`, `geelark_tasks`, `geelark_fail_codes`, and `proxy_audit_log` for the previous run
- Table written: `proxy_audit_log` only. Insert-only, one row per profile per run.

There are seven Supabase read nodes and one write node. All eight must use the same credential. A node with a missing or wrong credential returns an empty array rather than throwing, which silently turns a check into "nothing to report".

#### `proxy_audit_log`

This is the audit's own snapshot table, and the only record of a profile's proxy and device assignment that survives Geelark profile deletion. It is what P4 diffs against and what lets P6 keep counting a dead account against the proxy that killed it.

Live columns as of 2026-07-22, 20 in total:

| Column | Type |
|---|---|
| `id` | bigint, generated |
| `run_id` | text, not null |
| `checked_at` | timestamptz, not null |
| `env_id` | text |
| `profile_name` | text |
| `handle` | text |
| `platform` | text |
| `proxy_ip` | text |
| `proxy_host` | text |
| `proxy_port` | integer |
| `proxy_country` | text |
| `proxy_city` | text |
| `asn` | text |
| `asn_org` | text |
| `is_datacenter` | boolean |
| `created_at` | timestamptz, not null |
| `device_model` | text |
| `group_name` | text |
| `proxy_type` | text |
| `timezone` | text |

The last four were added by migration `proxy_audit_log_add_p6_dimensions` on 2026-07-22. Without them every run permanently lost the dimensions P6 groups on, and that history cannot be backfilled after the fact.

RLS is **enabled** on this table with zero policies, so anon and authenticated are denied and only the service role can read or write it.

### What is never persisted or displayed

`phone/list` and `proxy/list` both return **plaintext proxy usernames and passwords**. The workflow carries them in memory only so `proxy/check` can dial, and selects only `type`, `server` and `port` downstream. Those credential fields must never reach `proxy_audit_log`, the email body, an n8n execution log that gets shared, or this document.

### Email

- Gmail credential `Gmail account`, id `VEDXx0wMDEvcGCLu`
- Sender name `Peptide Health Bot`, `appendAttribution: false`
- The Gmail node does not hardcode addresses. It uses the n8n instance variables `{{ $vars.CZED_EMAIL }}` for `sendTo` and `{{ $vars.GARRETH_EMAIL }}` for `ccList`, matching the View-Collapse Detector so a recipient change lands in one place for both emails.
- On this instance those resolve to `czedrickjhake.cc@gmail.com` and `garrethdottin@gmail.com`. **`garrethdottin@gmail.com` is the confirmed correct CC address.** Earlier drafts of this document and of the workflow's sticky note said `garreth@cryptomiami.net`, which was wrong.

---

## 6. How to change a threshold

Every number in this document lives in one place: a `CONFIG` object at the top of the Code node named **`Run Audit Checks`**. Change the value there, save, and the whole audit follows. There is no node called `Audit Config`, and there never was.

| Constant | Default | Governs |
|---|---|---|
| `SHARED_PROXY_MIN_PROFILES` | `2` | P1 exact `server:port` collision |
| `SUBNET_CLUSTER_MIN_PROFILES` | `3` | P1 /24 clustering |
| `SHARED_PROXY_INTENTIONAL` | `true` | P1 exact-match severity. `true` reports it at info (sharing is deliberate), `false` restores critical |
| `DATACENTER_RULE` | `{use_is_datacenter: true, use_asn_type_hosting: true, use_company_type_hosting: true}` | P2, one switch per leg. The legs no longer OR into one critical: `asn_type_hosting` drives critical, `company_type_hosting` drives warn, `is_datacenter` drives info |
| `REPUTATION_FLAGS` | `['is_vpn','is_proxy','is_abuser','is_tor']` | P2 info flags |
| `EXPECTED_COUNTRY` | `'US'` | P3 country tier |
| `GEO_CHECK_TIMEZONE` | `true` | P3 timezone tier on or off |
| `GEO_CHECK_CITY` | `true` | P3 city tier on or off |
| `DEATH_RATE_THRESHOLD` | `0.50` | P6 |
| `DEATH_CLUSTER_MIN_CRITICAL` | `3` | P6 group size for critical |
| `DEATH_CLUSTER_MIN_WARN` | `2` | P6 group size for warn, and the minimum group printed in the info table |
| `DEATH_LOOKBACK_DAYS` | `30` | P6 window for counting a health-log verdict as dead |
| `DEAD_VERDICTS` | `['BANNED','FLAGGED','LOGIN_ISSUE']` | P6 which verdicts mean dead |
| `DEAD_EVENT_TYPES` | `['banned','shadowban_detected']` | P6 which `account_events` types mean dead |
| `ALIVE_VERDICTS` | `['ALIVE']` | H1, anything else is reportable |
| `H1_EVENT_TYPES` | `['banned','shadowban_detected','collapse_detected']` | H1 event selection |
| `H1_FALLBACK_LOOKBACK_DAYS` | `14` | H1 window when there is no previous run |
| `FAILCODE_LOOKBACK_DAYS` | `14` | H2 window |
| `WORKFLOW_FAILRATE_THRESHOLD` | `0.25` | H2 per-`source_workflow` hard-fail rate |
| `WORKFLOW_FAILRATE_MIN_TASKS` | `20` | H2 minimum sample before the rate is reported |
| `HARD_BAN_CATEGORIES` | `['HARD_BAN']` | H2 which `geelark_fail_codes.category` values are critical on sight |
| `UNPOLLED_TASKS_WARN` | `25` | H3a |
| `UNPOLLED_TASKS_CRITICAL` | `100` | H3a |
| `HEALTHLOG_STALE_DAYS` | `5` | H3d |
| `PROFILE_HEALTH_STALE_DAYS` | `7` | H5 |
| `ZERO_VIEW_STREAK_WARN` | `3` | H6 |
| `BAD_HEALTH_STATUSES` | `['banned','muted','collapsing']` | H6 |

**Two settings deliberately do not live in `CONFIG`, because they act upstream of that node and would do nothing there.**

| Setting | Where it lives | Notes |
|---|---|---|
| `RUN_PROXY_CHECK` | `const` on the first line of the Code node `Build Proxy Check List` | Set to `false` to skip the live proxy dial entirely. P7 then reports nothing and P3 falls back to the ipapi.is location instead of the real outbound IP. |
| proxy/check throttle | HTTP node `Geelark — Proxy Check`, options, batching | Currently 5 requests every 2000 ms, so 150 per minute worst case against Geelark's limit of 200. |

Also not in `CONFIG` and not to be moved there: the credential ids, which belong to n8n's credential store, and the email recipients, which resolve from instance variables on the Gmail node.

### Schedule

The audit runs **Monday at 14:00 UTC, every other week**.

n8n cron cannot express "every two weeks", so this is built in two parts:

1. The Schedule Trigger `Every Monday 14:00 UTC` fires **weekly** on cron `0 14 * * 1`.
2. The Code node `Biweekly Parity Gate` discards odd weeks. The rule is `(ISO-8601 week number % 2) === PARITY`, with `PARITY = 0`. To flip which weeks run, change `PARITY` to `1` in that node.

The workflow timezone is **pinned to `UTC`** in workflow settings. This matters: without the pin the trigger inherits the n8n instance default and fires 4 to 5 hours away from the documented time while every node name and comment still says UTC.

Monday 14:00 UTC was chosen because it collides with nothing. `[Health] View-Collapse Detector` is `0 8 * * 2,5`, `Account Health Check (IG and TT)` is `0 7 * * 2,5`, `Account Health Check (For Posting)` is daily at 03:00, and the task poller is hourly. An earlier draft of this document said the audit ran on a later slot on Tuesday and Friday. That was wrong, and Monday is the better answer.

Accepted edge case: ISO week numbers restart at 1 each year, so the gap across a New Year boundary is once either 1 or 3 weeks instead of 2. This is harmless. Every check is an independent point-in-time snapshot, nothing accumulates, and no cursor is persisted, because a cursor would silently skip a run forever if one execution failed.

Manual runs and the webhook `POST /webhook/proxy-account-audit` bypass the parity gate entirely.

---

## 7. Known limitations

Stated plainly. Nothing here is implied to work that has not been shown to work.

**Confirmed live on 2026-07-21.** Geelark Bearer token auth, `phone/list`, `proxy/list` and `proxy/check` were all called successfully from this machine and returned `code: 0` with real data. The ipapi.is bulk enrichment was called with 22 real IPs. The Supabase join keys were verified by matching Profile 21 to `env_id` 621895755384225962 in both systems. The numbers in the baseline tables above are real, not illustrative.

**Confirmed on 2026-07-22.** Every Supabase column, table and baseline count cited in this document was re-queried against the live database. The workflow's check ids were re-read from the live JSON and diffed against this document one by one.

**Confirmed on 2026-07-26.** The workflow executed end to end for the first time (manual exec `119089`, status success). The persist node wrote 29 rows to `proxy_audit_log` and the report emailed. The workflow was then activated. Items 1 and 18 below are now resolved and kept only for history.

**Not confirmed.**

1. **~~The workflow has never executed, not once, end to end.~~ RESOLVED 2026-07-26.** It ran clean end to end (exec `119089`). Everything below the reads that was "reasoned rather than observed" has now been observed once.
2. **P4 has never run.** Proxy churn needs two snapshots and `proxy_audit_log` is empty. The first audit run creates the baseline and reports nothing for P4. The second run is the first real churn check.
3. **P6's deleted-profile recovery has never run**, for the same reason. Until `proxy_audit_log` has history, P6 sees only profiles that still exist in Geelark, which is exactly the population least likely to be dead. Its death rates will be understated on the first run and will get more honest every run after.
4. **The P6 and H1 ban side is untested against the health log.** `geelark_health_log` has existed only since 2026-07-04 and has recorded exactly three verdicts: `ALIVE`, `OTHER_FAILURE` and `UNKNOWN`. **No `BANNED` verdict has ever landed.** The `account_events` side does hold 25 real ban rows, 15 of which were backfilled on 2026-07-03 with the same date, so event timestamps before that date are not trustworthy.
5. **Cohort sizes are tiny.** The July 4 finding that Geelark Automation warmup was 100% fatal is 6 accounts. P6 will regularly produce 100% death rates on groups of 2 or 3. Treat those as a direction to look, not a conclusion.
6. **The /24 heuristic is an assumption.** Grouping by the first three octets is a reasonable proxy for "same infrastructure" but we have not verified that Instagram or TikTok actually cluster at /24. It may be too wide or too narrow.
7. **P3's country tier compares against a single constant.** `EXPECTED_COUNTRY` is `US` for the whole fleet because every phone is in the `US Accounts` group. The moment a non-US group is added, this check starts firing false criticals and needs a per-group expectation instead.
8. **P3's timezone and city tiers depend on fields Geelark may not populate.** If `equipmentInfo.timeZone` or `equipmentInfo.city` is empty on a profile, that profile is skipped for those tiers rather than flagged. Silent skips are possible.
9. **`proxy/check` costs real time.** Each call physically dials the proxy and takes 1 to 3 seconds. Twenty-four calls is roughly a minute of wall clock. If the fleet grows past about 100 profiles this needs batching or the n8n execution will time out.
10. **`outboundIP` equals `server` for every proxy sampled.** These are static ISP proxies, so the gateway address is a safe stand-in for the exit IP today. If a rotating or residential pool is ever introduced, `proxy.server` stops being the real exit IP and P1 through P3 will silently measure the wrong address. `proxy/check` is the only thing that catches this, which is why `RUN_PROXY_CHECK` defaults to true.
11. **Geelark does not label proxy class at all.** `proxy.type` is the protocol only, socks5 or http or https. Residential versus datacenter is entirely an external inference from ipapi.is. Since 2026-07-26 P2 keys its critical off `asn.type === "hosting"` specifically, so a wrong ipapi.is ASN classification changes the P2 result, and we have no second source we trust, since ip-api.com was tested and failed.
12. **The `phone/list` `status` enum is contradictory.** Geelark's markdown docs say `0=Started, 1=Starting, 2=Shut down`. Their openapi.yaml says `0=stopped, 1=starting, 2=running`. All 24 phones currently report `2`. The audit therefore does **not** alert on phone power state, because we cannot tell whether 2 means running or shut down.
13. **Geelark Key-mode auth is unavailable.** There is no App ID stored locally, only a token. Token mode works, so this is not blocking, but if Geelark ever deprecates token auth the audit stops until someone supplies the Team AppId.
14. **Deleted profiles take their proxy history with them.** Once a Geelark profile is deleted, its proxy assignment is gone from Geelark forever. `proxy_audit_log` is the only place that history will survive, and it only starts from the first run of this audit. Everything before that date is unrecoverable.
15. **The Supabase credential binding could not be verified through the n8n MCP API**, which redacts credential references on every read path. The two nodes added on 2026-07-22, `Read Account Events` and `Read Unpolled Tasks`, must be opened by hand and confirmed to use the same `supabaseApi` credential as the other six, `Supabase Service Role`, id `BpJOuYVDTTtsYa5o`. An unbound node returns an empty array instead of erroring, which would silently disable H1, H3a and half of P6.
16. **RLS is still disabled on roughly 60 public tables** including every table this audit reads except `accounts` and `proxy_audit_log`. That is a separate open critical risk, unchanged since 2026-07-04. `proxy_audit_log` itself has RLS enabled with zero policies.
17. **The audit is read-only and will not fix anything.** Every finding requires a human to act in Geelark. There is deliberately no auto-remediation.
18. **~~Nothing has been emailed and nothing should be until a human reviews the workflow. The workflow is saved inactive.~~ RESOLVED 2026-07-26.** Reviewed, test-run, and activated. It now emails `czedrickjhake.cc@gmail.com` and `garrethdottin@gmail.com` on every run. First email went out 2026-07-26.

---

## 8. Related

- [[00 — Geelark Warmup & Account Health — Investigation Brief]]. The 2026-07-04 evidence pack this audit was built to answer.
- n8n `FknqQM7GNJJmViRP` `[Audit] Proxy & Account Health — Biweekly`. The workflow this document specifies.
- n8n `2Goujvw8qSvVzIfo` `[Health] View-Collapse Detector`. The email pattern and recipient list this audit copies.
- n8n `CXVxRMOUkLluRdBc` `Account Health Check (IG and TT)`. Writes the `geelark_health_log` rows this audit reads.
- n8n `ARmIDPrV77c0k4zA` `Geelark Task Detail Poller`. Writes the `geelark_tasks` detail this audit reads, and is what H3a watches.
- n8n `ZWQ4kUJHB4pL5d2X` `Geelark - Account Ban Analysis`. Inactive and never run, but its `phoneSlim()` function and proxy fail-code list were the starting point for the proxy checks.
- n8n `aB24JEEA8COgeoeA` `[Ops] Factory Reset - On Demand`. The remediation lever P6 recommends for a burned device fingerprint.

---

## 9. Reconciliation log, 2026-07-22

This document and workflow `FknqQM7GNJJmViRP` were built within minutes of each other and disagreed on almost everything that mattered. Recorded here so the same drift is visible if it happens again.

### The check ids meant different things in each artifact

The workflow had invented its own taxonomy. Every id below now means what this document says it means.

| id | This document said | The workflow said | Resolution |
|---|---|---|---|
| P1 | proxy sharing | datacenter IPs | Document wins. Workflow renumbered. |
| P2 | datacenter | shared proxy | Document wins. Workflow renumbered. |
| P3 | geo coherence | no proxy assigned | Document wins. The old workflow P8, exit outside the expected country, was folded in as P3's country tier. |
| P5 | missing or orphaned proxy | orphaned proxy only | Merged. The old workflow P3, no proxy assigned, became P5's critical leg. |
| P6 | dead-cluster correlation | Geelark and Supabase roster drift | Document wins. The workflow's roster drift was really H4, and moved there. |
| P7 | did not exist | dead proxy | Kept, added to this document as P7. |
| H1 | bans from `account_events` and the health log | latest verdict not ALIVE | Document wins. The health-log-only version could not detect a real ban. |
| H2 | fail codes per `source_workflow` | health check stale | Document wins. The old workflow H2 became H5. |
| H3 | telemetry integrity | task failures per profile | Document wins. The per-profile rate was replaced by the per-`source_workflow` rate in H2. |
| H4 | roster drift | already flagged in `accounts` | Document wins. The old workflow H4 became H6. |
| H5, H6 | did not exist | per-profile staleness, already flagged | Kept, added to this document as H5 and H6. |

### Checks this document promised that the workflow did not perform

All now implemented in the `Run Audit Checks` node.

- **P6 dead-cluster correlation.** Was entirely absent, despite this document calling it the highest-value check. `account_events` was not read by any node.
- **H1 real ban detection.** The implemented version read only `geelark_health_log`, which has never recorded a `BANNED` verdict, so it structurally could not surface a ban.
- **H3a unpolled-task watchdog.** `detail_polled_at` was not selected by any node, so the detector for the June 21 to July 4 silent poller failure did not exist.
- **H2 unmapped fail codes**, and the hard-fail rate moved from per-profile at 20% over 5 tasks to per-`source_workflow` at 25% over 20 tasks.
- **P1 /24 clustering, P3 timezone and city tiers, P2 reputation flags, H3b, H3c, H4c.**

### Where the workflow was right and this document was wrong

- **The schedule.** This document said Tuesday and Friday on alternating weeks. The workflow runs Monday 14:00, which avoids all four existing health jobs. The document was corrected. The workflow's timezone was pinned to UTC so the documented time is the real time.
- **The snapshot table.** This document referenced a table `geelark_proxy_snapshot` seven times and built P4 on it. That table was never created and does not exist. The real table is `proxy_audit_log`. Every reference was corrected and the real column list is now in section 5.
- **Section 6.** This document claimed every threshold lived in a Code node called `Audit Config` and listed 17 constants. No such node existed and 16 of the 17 names appeared nowhere in the workflow, so the runbook was unfollowable. Section 6 now names the real node and the real constants, and states plainly which two settings live elsewhere.

### Fixes applied to the workflow beyond the check list

- **Severity taxonomy.** The workflow rendered critical, high, medium and low. The two findings this document ranks critical were both rendering as "High". It now renders critical, warn and info only, and info never triggers the warning subject.
- **Schema.** `proxy_audit_log` was missing `device_model`, `group_name`, `proxy_type` and `timezone`, which are four of the dimensions P6 groups on. Since the snapshot is the only record that survives profile deletion, every run was permanently losing history that could not be backfilled. Migration `proxy_audit_log_add_p6_dimensions` added them as nullable columns. RLS was not touched.
- **Item fan-out.** The Supabase reads are chained in a line, and each returns an array that n8n splits into one item per row, so each read fired once per row of the previous read. 141 health-log rows would have triggered 141 `accounts` reads and then thousands of task reads. Every independent read now carries `executeOnce`.
- **The sticky note.** It asserted that this specification "did NOT exist when this was built" and told the reader to treat the workflow's own list as the working definition. That is the first thing a human reads before activating, and it would have suppressed exactly this reconciliation. It has been removed and replaced with a pointer to this file.
- **The recipient note.** The sticky note said the CC address was `garreth@cryptomiami.net`. The instance variable actually resolves to `garrethdottin@gmail.com`, which is correct. The recipients were left alone and the note was fixed.

---

## 10. Change log, 2026-07-26

First activation day. Four changes, all live on active version `ddced05b`.

### Persist node fixed, then the workflow was activated

The `Persist Snapshot to proxy_audit_log` node sent `Prefer: return=minimal` (Supabase replies with an empty `201` body) but had `responseFormat: json`, so it ran `JSON.parse("")` and threw a `TypeError` on every run. Two suppressors, `neverError: true` and `onError: continueRegularOutput`, swallowed the throw, so the run still reported success while a *real* write failure would have looked identical. Fixed by setting `responseFormat: text`, `neverError: false`, `onError: stopWorkflow`. A genuine 4xx/5xx now fails the run loudly. Verified with manual exec `119089`: status success, persist node no error, 29 rows written, `proxy_audit_log` went 24 → 53. The workflow was then activated. It now runs on the biweekly parity gate, next run Monday 2026-08-03.

### P2 severity re-ranked off `asn.type`, not `is_datacenter`

The old P2 fired critical on `is_datacenter === true`, which flags every ISP proxy, because ISP proxies are datacenter-hosted by design. The 6 criticals from the first run were mostly the fleet's intended Comcast/Lumina ISP proxies. P2 now classifies each exit into `dc_class` and reports by tier: critical on `asn.type === "hosting"`, warn on `company.type === "hosting"` over an ISP ASN, info on a bare `is_datacenter` flag. Recomputed against real enrichment data, the 10 `is_datacenter` hits collapse to **1 critical** (Rockion/WebNet, also a VPN exit), 2 warn (Ace Data Centers), 7 info. The earlier "Comcast AS33652" justification for OR-ing all three legs was wrong (the ASNs are Comcast, RCN, Lumina, WebNet, not one AS) and has been removed.

### P1 exact-match sharing downgraded to info

Profiles deliberately share proxies in this fleet, so the exact `server:port` collision is not a ban vector for us. It is now gated behind the new `SHARED_PROXY_INTENTIONAL` config flag (default `true` → info). Flip to `false` to restore the critical. The /24 clustering warn is unchanged.

### Snapshot gained an in-memory `dc_class`

`Run Audit Checks` now computes `dc_class` per profile for the P2 tiers. It is **not** persisted: `snapshotRows` is an explicit column whitelist and `proxy_audit_log` was not altered. `is_datacenter` is still stored as the raw ipapi.is boolean.
