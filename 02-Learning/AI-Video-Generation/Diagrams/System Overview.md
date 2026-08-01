---
tags: [diagram, architecture, overview, pipeline, n8n, supabase, geelark, curated]
description: "The whole Peptide Miracles spine end to end: generate, store, schedule, post, warm up, watch health."
updated: 2026-07-23
status: curated, hand-maintained overview

---


# System Overview

*Hand-authored overview of the Peptide Miracles pipeline, grounded in the live n8n estate and the account-ops Supabase project (`qlcmgxgwpzmiebzxflai`) as of 2026-07-23. This is the money diagram. It shows the planes and the main arrows, not every workflow. For a single workflow, open its graph under [[_Workflows — Index]]. For the tables, see [[Account Ops Data Model]].*

The loop in one sentence: n8n writers generate content into Supabase, a scheduling agent decides what posts when, a posting agent drives Geelark cloud phones to post to Instagram and TikTok, a warmup job keeps the phones alive, and two health signals watch what happens and write the verdict back onto the accounts.

Read it top to bottom. Each box is a plane, not a single script. Colors follow the house palette: blue is content generation, green is a Supabase table, yellow is scheduling, purple is posting and the Geelark device layer, red is health and monitoring, grey is an outside service.

```mermaid
flowchart TB
    classDef gen    fill:#DCE7FB,stroke:#2E5AAC,color:#10233F,stroke-width:1.5px;
    classDef store  fill:#DDF3E4,stroke:#2E8B57,color:#14331F,stroke-width:1.5px;
    classDef sched  fill:#FFF1CC,stroke:#C8860A,color:#3A2A05,stroke-width:1.5px;
    classDef post   fill:#F3E1F7,stroke:#8A3FA0,color:#331338,stroke-width:1.5px;
    classDef health fill:#FBE0E0,stroke:#C0392B,color:#3A1010,stroke-width:1.5px;
    classDef ext    fill:#E9ECEF,stroke:#6C757D,color:#212529,stroke-width:1.5px;

    subgraph sg_gen["1 - Content generation (n8n, per character)"]
    direction LR
    g_c2["Character 2 writers<br/>2-Slide BA, Embarrassed"]
    g_c3["Character 3 writers<br/>Eat Whatever, Dating"]
    g_c4["Character 4 writers<br/>Divorce, Conspiracy"]
    g_ce["Covered Eye writers"]
    g_gu["Glow-Up writers"]
    g_fil["Filler ingest and stage"]
    end

    subgraph sg_store["2 - Supabase content tables"]
    t_content[("Content tables<br/>ba_2slide_content, glowup_decks,<br/>carousel_copy, divorce_story_content")]
    end

    subgraph sg_sched["3 - Scheduling (n8n)"]
    direction LR
    s_inv["[Unified] Inventory Monitor"]
    s_agent["[Unified] Scheduling Agent"]
    end

    subgraph sg_post["4 - Posting (n8n to Geelark to platform)"]
    p_agent["[Unified] Posting Agent"]
    p_car["Carousel posters<br/>2 BA Slider, BA Journey"]
    p_geelark["Geelark API"]
    p_phones["Cloud phones<br/>one account each"]
    p_receipt["[Geelark] Save Receipt"]
    p_poller["Geelark Task Detail Poller"]
    t_tasks[("geelark_tasks")]
    p_recon["[Reconcile] Nightly Failed Posts"]
    end

    subgraph sg_warm["5 - Warmup (n8n to Geelark)"]
    w_warm["Device Warmup - Auto<br/>GPS drift, power cycle"]
    end

    subgraph sg_plat["Platforms"]
    direction LR
    x_ig["Instagram"]
    x_tt["TikTok"]
    end

    subgraph sg_health["6 - Health and monitoring"]
    h_scrape["ScrapeCreators"]
    t_perf[("post_performance<br/>tt_post_performance")]
    h_detect["[Health] View-Collapse Detector"]
    t_accounts[("accounts")]
    t_events[("account_events")]
    h_email["Health email, twice a week"]
    h_check["Account Health Check<br/>IG+TT, For-Posting"]
    t_hlog[("geelark_health_log")]
    h_audit["[Audit] Proxy and Account Health<br/>biweekly, inactive"]
    t_proxy[("proxy_audit_log")]
    end

    g_c2 --> t_content
    g_c3 --> t_content
    g_c4 --> t_content
    g_ce --> t_content
    g_gu --> t_content
    g_fil --> t_content

    t_content --> s_agent
    s_inv -.->|"runway digest"| s_agent
    s_agent -->|"picks eligible accounts"| p_agent
    t_content -->|"carousels"| p_car
    t_accounts -.->|"is_active, health_status"| p_agent

    p_agent -->|"~20% hard-fail"| p_geelark
    p_car --> p_geelark
    w_warm --> p_geelark
    p_geelark --> p_phones
    p_phones --> x_ig
    p_phones --> x_tt

    p_agent -->|"logs task"| p_receipt
    p_receipt --> t_tasks
    p_poller -.->|"enriches hourly"| t_tasks
    p_recon -.->|"Posted to Failed"| t_tasks

    x_ig -.->|"views"| h_scrape
    x_tt -.->|"views"| h_scrape
    h_scrape --> t_perf
    t_perf --> h_detect
    h_detect -->|"infers bans from view collapse"| t_accounts
    h_detect --> t_events
    h_detect --> h_email
    p_phones -.->|"login probe"| h_check
    h_check --> t_hlog
    h_audit -.-> t_proxy
    h_audit -.->|"reads proxies and health"| t_accounts

    class g_c2,g_c3,g_c4,g_ce,g_gu,g_fil gen;
    class t_content,t_tasks,t_perf,t_accounts,t_events,t_hlog,t_proxy store;
    class s_inv,s_agent sched;
    class p_agent,p_car,p_geelark,p_phones,p_receipt,p_poller,p_recon,w_warm post;
    class h_detect,h_check,h_audit,h_email health;
    class x_ig,x_tt,h_scrape ext;
```

## How to read the breaks

Three places this loop is known to break, all visible above.

- Posting is not clean. Roughly one in five posts through the Posting Agent hard-fails at the Geelark step. That is the `~20% hard-fail` edge.
- Bans are guessed, not confirmed. The `infers bans from view collapse` edge is the only ban signal. Geelark never tells us an account is banned, so the detector infers it from views dropping.
- Two health signals disagree by design. The login probe writes `geelark_health_log` and can say ALIVE while the detector has already marked the same account banned in `accounts`. They measure different things.

## Related

- [[Account Ops & Geelark Flow]]: the same posting and health path, zoomed in
- [[Content Pipelines by Character]]: what feeds plane 1
- [[Account Ops Data Model]]: the tables and their string join keys
- [[Diagrams]]: index for this folder
- [[Architecture — How The System Fits Together]]: the prose version of this loop
