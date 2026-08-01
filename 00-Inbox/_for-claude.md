# For Claude — standing notes

Write anything here you want me (Claude) to know at the start of every new chat.
This file is auto-loaded into my context each session.

## Current priorities

- **Biweekly proxy and account health audit.** Built 2026-07-21 as n8n workflow `FknqQM7GNJJmViRP`,
  "[Audit] Proxy and Account Health, Biweekly". It is saved but NOT active, waiting on a human review run.
  The rule by rule spec is `~/Claude/proxy-audit/AUDIT_SPEC.md`, mirrored in the vault at
  `03-Projects/Account Health & Warmup 2026-07/01 — Proxy & Account Health Audit — What We Check.md`.
  Read the spec before changing the workflow. They are meant to stay in sync.

- **Proxy data lives only in Geelark.** There is no proxy column and no ip column anywhere in Supabase.
  Any proxy question has to hit the Geelark API. Do not go looking for it in the database.

## Reminders / preferences

- **Session hook loads a fixed list.** `~/.claude/hooks/obsidian-context.sh` injects only this file, both Hub
  notes, the newest `01-Daily` note, and anything else in `00-Inbox`. It never loads `03-Projects`.
  So a new project note is invisible to future sessions unless it gets linked from a Hub or pointed to here.
  Each file is also cut off at 8,000 characters, so keep the Hubs tight.

- **Start from the Hubs.** `02-Learning/AI-Video-Generation/AI Video Generation - Hub.md` now links the current
  system state notes: architecture, n8n as of 2026-07-21, and the API docs.

- **The architecture docs in `~/Claude/Projects/AI Video Generation/` are stale.** They still say 9 Geelark cloud
  phones when the live roster is 32, and they do not mention the account health telemetry tables at all.
  Trust live systems over those docs, and see the Architecture note's "Doc drift" section.

- **Vault scope.** This vault is for AI video generation and peptide work. It is for thinking and learning.
  It is not where keys live and not where pipeline data lives. That is Supabase and n8n.

- **Style.** Plain language, short sentences, lead with the point. No em dashes and no ampersands in prose.
