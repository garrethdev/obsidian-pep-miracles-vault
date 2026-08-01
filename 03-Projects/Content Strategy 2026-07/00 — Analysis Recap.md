---
tags: [strategy, recap, handoff]
updated: 2026-07-04
status: handoff — pick up elsewhere
---
# Content Analysis Recap — July 2026

*One-doc summary of the content/performance analysis. Detail lives in the three sibling notes: [[Performance — What Works & What Dies]], [[Content Lineup & Characters]], [[Winning Hooks Playbook]]. This is the pick-up-from-here doc.*

---

## 1. The question we were answering
Across 21 faceless GLP-1 accounts and ~3 AI characters, which content types actually earn attention, which quietly die, and where should the whole operation point next? We looked at our own `post_performance` + `tt_post_performance` (May–July 2026) plus outside signal from Virlo (small-channel outliers) and a Social Growth Engineers harvest (56 rules).

## 2. The one finding that reframes everything
**Content types don't differ in their floor — they differ in how often they break out.** Every account gets ~110–140 views by default no matter what we post. The right metric is **breakout rate** (how often a post clears 500, then 1,000 views), not median views. Judging by average buried our real winners in noise.

## 3. What wins vs. what dies (our own data)

| Format | Posts | Breaks 500+ | Breaks 1k+ | Engagement | Verdict |
|---|---|---|---|---|---|
| **Dating (honesty rant)** | 25 | **12%** | 4% | **1.6%** | Best engagement — keep, needs sources |
| **Before/After 2-slide** | 140 | 10.7% | **6.4%** | 0.75% | **The backbone** |
| BA journey | 38 | 2.6% | 2.6% | ~0 | Weak — drop the "journey" framing |
| Eat Whatever | 51 | **0%** | 0% | ~0 | Dead — 51 posts, none over 400 views |
| Grandma B/A | 35 | **0%** | 0% | ~0 | Content likely fine; **accounts are dead** |
| Carousels | (34% of all volume) | — | 1.7% | 0.1–0.6% | **Dumped 2026-07-03** |

**Wins share one shape:** first-person confession + one concrete detail + **a witness inside the story** (the husband, the brunch friend, the woman who noticed the fork). Viewers are watching *other people be forced to acknowledge her* — not the transformation itself. That's the engine.

**Dies:** carousels, "eat whatever," abstract motivation ("journey / consistency / showing up"), and any hook that opens in third person ("She…").

## 4. The impressive part — the outlier discovery
The biggest outliers in the entire pull came from **tiny channels, not big ones.** The algorithm rewards the hook, not the follower count.

- **Small channels (<50k followers): median 33–74× their follower count.** Big accounts (200k+): ~1.2×. A 5k-follower account routinely out-reaches a 200k one.
- **Question/explainer hook** — *"What are peptides… and why is everyone suddenly using them?"* → **3,378× reach on a 5-follower account.** The single most striking outlier we found.
- **Judgment-first, then disprove it** — *"But you don't look like you struggled with your weight"* → **56M views across 3 videos.**
- **"(tell no one)" refrain carousel** — repeat the secret each slide, break it on the last → **3.1M at 104× the account median.**
- **Dated / unresolved story-tease** ("For 6 months…", a bare date) → **over-indexed 5.5×** on small channels — and this maps directly onto our before/after format.

**Why it matters for us:** our whole network *is* small channels. We treated that as the problem; the data says it's the advantage — small is where the lottery tickets pay out, *if the hook does the work.* Our own best original (capri-dress, 29k) is the same pattern. We're at the right table with the right hand — the job is to repeat it hundreds of times.

## 5. The winning hook playbook (short version)
1. **Repetition beats novelty.** Lock ONE format, run it hundreds of times across accounts. Stop inventing angles; duplicate winners.
2. **Confession + one concrete detail + a witness.** Highest-evidence rule, confirmed on our own data.
3. **Product stays OUT of the video.** Hook does the emotional setup; CTA soft in caption / pinned comment.
4. **Openers that outlier:** dated story-tease · judgment-then-reveal · institution-as-villain ("my doctor swore it was just menopause") · concede-then-reframe (baits a comment war) · question hook (for explainers).
5. **Comment-engineering (esp. Dating):** withhold the name → "what's it called?" in pinned reply; plant a slightly-wrong claim so the correction spreads it; let a third party's own words (a dating profile, a doctor's dismissal) be the villain.

## 6. Content lineup going forward
- **B/A — Character 2** (woman 30s–50s) = the backbone. Proven format, most volume. Generated from real transformation **stories**.
- **Embarrassed — Character 3** (same face as Eat Whatever + Dating).
- **Dating — Character 3.** Best engagement of anything; **starving for source clips** — top refill priority.
- **Grandma Cooking Conspiracy — Character 4** (being built; 33 stories written).
- **Grandma Yoga / Divorce-over-Yoga — Character 4** (being built).
- **Filler** = account-health / diversity cover, judged on account survival + spillover, not views. Target 50% of pushed content (down from ~70%).

⚠️ **Two B/A generators, don't confuse them:** Character-2 = "[2-slide BA] Scriptwriter" (stories, voice 30s–50s). Grandma = "[BA Older Woman] Hook Generator" (seeds, voice 50–63). Both write to `ba_2slide_content`, so the table looks mixed — voice is the only separator.

## 7. What changed this session (already done)
- **Dumped all carousels** — generators off, registry off, stripped from Character-2 accounts.
- **Fixed character routing** — C2 = B/A, C3 = Eat-Whatever + Dating + Embarrassed, C4 = Grandma.
- **Repointed the Character-2 B/A scriptwriter** to read stories from the Supabase `stories` table (the old Google Sheet had gone empty). Verified working.
- **Account health:** built the View-Collapse Detector, consolidated to ONE twice-weekly email (Tue/Fri). Ban forensics: Geelark auto-warmup accounts are ~100% dead; manual-warmup accounts are the healthy ones.
- **Ran a fresh Character-2 B/A batch** (~100 hooks from ~30 stories).

## 8. Honest caveats (read before betting on this)
- **1k views is a win at our scale** — medians are 100–150. Best original ever = 29k. The 121k "hit" was borrowed filler, not ours.
- **Grandma B/A's 0% is mostly dead accounts, not bad content** — the same content gets normal reach on a healthy account (maya_strong_23).
- **TikTok is under-tested, not proven bad** — a third of our TT own-content went to shadowbanned (invisible) accounts. Healthy TT accounts already hit 700–1,850 on tiny volume.
- **No funnel tracking exists.** Nothing measures clicks / conversions / revenue. Views are faith until that's built — and the outlier data itself shows huge-view / near-zero-download cases (one at 4.1M views). Chase conversion, not the vanity number.

## 9. Where to pick up
1. **Refill Dating sources** (top priority) — it has the best engagement and is starving. Need a roster of Black-woman dating-storytime creators (ashleiwithani is a style template but is mostly a news creator).
2. **Build the Grandma Cooking Conspiracy + Yoga posting lanes** (conspiracy has 33 stories, no render/post path yet).
3. **Fix posting plumbing** — carousel "Phase B" was never built; the Scheduled→Posted write-back is broken (runway numbers overstate); Profile 30 (simone_rise) is alive but not being fed by the scheduler.
4. **Stand up funnel tracking** so we can grade on conversion, not views.
5. **Harden the C2 scriptwriter** — ~2 malformed `2BA-000` rows per run (UUID id → NaN pick); delete null-source_pick rows after each run until fixed.
