# PeptideMiracles — How this vault works

A plain-text, local-first knowledge base. Every note is a markdown file on disk you fully own — no lock-in, survives any app.

## The folders
- **00-Inbox** — capture fast, sort later. New notes land here by default.
- **01-Daily** — append-only log. One note per day. Your thinking diary.
- **02-Learning** — durable notes you revisit. Two hubs:
  - [[AI Video Generation - Hub]]
  - [[Peptide Miracles - Hub]]
- **03-Projects** — active work; links out to code in `~/Claude`.
- **04-AI-Memory** — ⚡ live symlink to Claude's memory folder. The AI writes here; you can read/edit the same files. This is the bridge between your notes and the assistant's memory.
- **99-Meta** — this file, templates, attachments.

## The loop (the part that actually makes you learn)
1. **Capture** anything into 00-Inbox or today's daily note. Don't organize yet.
2. **Link** ideas with `[[double brackets]]`. Connections > folders.
3. **Revisit** — open the Graph view weekly. Notes you keep returning to get promoted into 02-Learning as durable notes in *your own words*.
4. **Teach the AI** — anything worth Claude remembering, drop into `04-AI-Memory` (or just tell Claude; it writes there).

## How Claude sees this vault

A hook at `~/.claude/hooks/obsidian-context.sh` runs at the start of every Claude Code session.
Since 2026-07-22 it loads a map, not the whole vault:

- **Full text** for `00-Inbox/_for-claude.md`, both hubs, the newest daily note, and any loose inbox capture.
- **An index line** for every other note: name, size, last updated, and a one line description.
  Claude reads those from disk only when they are relevant.

Two things follow from that:

1. **Nothing is invisible any more.** A new note anywhere in the vault shows up in the index automatically.
   Nobody has to edit the hook again.
2. **The hubs and `_for-claude.md` are the expensive slots.** They load in full, every session, capped at
   8,000 characters each. Keep them as indexes that point at detail, not as places to store the detail.

To give Claude a description in the index, add `description:` to a note's frontmatter. Otherwise it uses the
first real line of prose.

## Shortcuts
- `Cmd+O` — jump to any note
- `Cmd+Shift+F` — search everything
- `Cmd+P` — command palette
- Click the graph icon — see how ideas connect
