---
tags: [diagram, account-ops, geelark, posting, health, curated]
description: "How a post travels through Geelark, how receipts enrich it, how warmup runs, and how health is judged."
updated: 2026-07-23
status: curated, hand-maintained

---


# Account Ops & Geelark Flow

*Hand-authored close-up of the account-ops layer, grounded in the live n8n estate and the Supabase project (`qlcmgxgwpzmiebzxflai`) as of 2026-07-23. This zooms into planes 4, 5, and 6 of the [[System Overview]]. For the tables behind it, see [[Account Ops Data Model]]. For a single workflow, open its graph under [[_Workflows — Index]].*

Follow one post from left to right. The Scheduling Agent picks an eligible account, the Posting Agent fires it at the Geelark API, the Geelark API drives the one cloud phone that runs that account, and the phone posts to Instagram or TikTok. On the way out, Save Receipt logs the task and the Poller enriches it. On the way back, two separate health checks judge the account and write the verdict onto `accounts`.

Two things this diagram is built to make obvious. First, posting is lossy: about one in five posts hard-fails at Geelark. Second, a ban is never confirmed at Geelark. It is inferred from views collapsing, by a different workflow than the one that checks whether the phone can still log in.

```mermaid
flowchart LR
    classDef store  fill:#DDF3E4,stroke:#2E8B57,color:#14331F,stroke-width:1.5px;
    classDef sched  fill:#FFF1CC,stroke:#C8860A,color:#3A2A05,stroke-width:1.5px;
    classDef post   fill:#F3E1F7,stroke:#8A3FA0,color:#331338,stroke-width:1.5px;
    classDef health fill:#FBE0E0,stroke:#C0392B,color:#3A1010,stroke-width:1.5px;
    classDef ext    fill:#E9ECEF,stroke:#6C757D,color:#212529,stroke-width:1.5px;

    subgraph sg_decide["Decide what posts"]
    direction TB
    a_inv["[Unified] Inventory Monitor"]
    a_sched["[Unified] Scheduling Agent"]
    t_accounts[("accounts")]
    end

    subgraph sg_send["Send the post"]
    direction TB
    a_post["[Unified] Posting Agent"]
    a_car["Carousel posters<br/>2 BA Slider, BA Journey"]
    a_geelark["Geelark API"]
    a_phone["Cloud phone<br/>one account"]
    a_plat["Instagram / TikTok"]
    end

    subgraph sg_receipt["Log and enrich the task"]
    direction TB
    a_save["[Geelark] Save Receipt<br/>webhook"]
    t_tasks[("geelark_tasks")]
    a_poller["Geelark Task Detail Poller<br/>hourly"]
    a_recon["[Reconcile] Nightly Failed Posts"]
    end

    subgraph sg_warm["Keep phones alive"]
    a_warm["Device Warmup - Auto<br/>GPS drift, power cycle"]
    end

    subgraph sg_health["Judge health, write it back"]
    direction TB
    h_scrape["ScrapeCreators"]
    t_perf[("post_performance")]
    h_detect["[Health] View-Collapse Detector"]
    t_events[("account_events")]
    h_check["Account Health Check<br/>IG+TT, For-Posting"]
    t_hlog[("geelark_health_log")]
    h_audit["[Audit] Proxy and Account Health<br/>biweekly, inactive"]
    t_proxy[("proxy_audit_log")]
    end

    a_inv -.->|"runway digest"| a_sched
    a_sched -->|"picks eligible accounts"| a_post
    t_accounts -.->|"is_active, health_status"| a_post

    a_post -->|"~20% hard-fail"| a_geelark
    a_car --> a_geelark
    a_warm -->|"warmup task"| a_geelark
    a_geelark --> a_phone
    a_phone --> a_plat

    a_post -->|"logs task"| a_save
    a_save -->|"inserts"| t_tasks
    a_poller -.->|"status, fail_desc"| t_tasks
    a_recon -.->|"Posted to Failed on status 4/7"| t_tasks

    a_plat -.->|"views"| h_scrape
    h_scrape --> t_perf
    t_perf --> h_detect
    h_detect -->|"infers bans from views, not Geelark"| t_accounts
    h_detect --> t_events
    a_phone -.->|"login probe"| h_check
    h_check -->|"ALIVE / UNKNOWN / FAILURE"| t_hlog
    h_audit -.-> t_proxy
    h_audit -.->|"reads proxies and health"| t_accounts

    class t_accounts,t_tasks,t_perf,t_events,t_hlog,t_proxy store;
    class a_inv,a_sched sched;
    class a_post,a_car,a_geelark,a_phone,a_save,a_poller,a_recon,a_warm post;
    class h_scrape,a_plat ext;
    class h_detect,h_check,h_audit health;
```

## The details that matter

- The join key is one string. Everything hangs off `accounts.geelark_profile` in the form `Profile N`. `geelark_tasks.serial_name` carries that same string. Do not join on `env_id`, which is Geelark's numeric device id and matches nothing in accounts.
- Receipts come in two writes. Save Receipt inserts the task row when the post is queued. The Poller updates that same row hourly with the real outcome, `fail_code`, and `fail_desc`. Prefer `fail_desc` for the human reason, since the fail-code lookup is incomplete.
- Warmup is one workflow, not a subsystem. Only Device Warmup - Auto runs live. Every other warmup-named workflow is switched off.
- The two health signals are independent. Login liveness lands in `geelark_health_log` and has never returned BANNED, because a login probe cannot see a ban. Ban inference lands in `account_events` and `accounts.health_status`, written by the View-Collapse Detector from view collapse. A phone can log in fine while its account is effectively dead.
- The proxy audit is built but parked. The biweekly audit that would snapshot proxies into `proxy_audit_log` exists but is inactive.

## Related

- [[System Overview]]: the whole spine, one level up
- [[Account Ops Data Model]]: tables, string join keys, writer provenance
- [[Unified Posting Agent]]: the live node graph of the posting workflow
- [[Health View-Collapse Detector]]: the live node graph of the ban recorder
- [[account-health-system]]: the AI-memory note on this layer
