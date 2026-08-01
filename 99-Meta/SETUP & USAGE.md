---
tags: [meta, guide]
---
# Setup & Usage — peptidemiracle vault

A plain-English guide. No coding needed. If you can open an app and type, you can use this.

---

## What this is
A notebook stored as plain text files on the Mac. It's where notes about **AI Video Generation** and **Peptide Miracles** live — and it also shows what the AI assistant remembers between sessions (the `04-AI-Memory` folder).

---

## Part 1 — Setup (one time)

### If Obsidian is already installed on this Mac
1. Open **Obsidian** (Applications folder, or Spotlight: press `Cmd+Space`, type "Obsidian").
2. If it opens straight to notes — you're done.
3. If it asks which vault to open: click **Open folder as vault** → choose
   `Desktop / AI Video Generation / peptidemiracle`.

### If Obsidian is NOT installed (new computer)
1. Go to **https://obsidian.md** → click **Download** → install it (drag to Applications).
2. Copy the whole **`peptidemiracle`** folder onto the new computer.
3. Open Obsidian → **Open folder as vault** → select that `peptidemiracle` folder.

### After first open — turn the plugins on
1. Press `Cmd+,` to open Settings.
2. Click **Community plugins** in the sidebar → toggle **Dataview** and **Templater** ON.
   (They're already downloaded; this just activates them.)
3. Close settings. Done — you never do this again.

> Note: the AI-memory folder (`04-AI-Memory`) only works on the original Mac, because it's a live link to the assistant's files. On a copied vault it may show empty — that's normal.

---

## Part 2 — How to use it day to day

### The folders (what goes where)
- **00-Inbox** — dump any quick thought here. Sort it later. Don't overthink.
- **01-Daily** — one note per day, like a journal of what you did/learned.
- **02-Learning** — the keeper notes. Two areas: *AI Video Generation* and *Peptide Miracles*.
- **03-Projects** — notes about active work.
- **04-AI-Memory** — what the assistant remembers (read it to see; edit it to correct it).
- **99-Meta** — this guide, the README, and templates.

### The 4 things you'll actually do
1. **Make a note:** `Cmd+N`. Type a title, start writing.
2. **Find anything:** `Cmd+O` (jump to a note by name) or `Cmd+Shift+F` (search all text).
3. **Link notes together:** type `[[` and the name of another note. This is the magic — it
   builds a web of connected ideas. Click the **graph icon** on the left to see the web.
4. **Daily note:** click the calendar/"Daily note" icon (or `Cmd+P` → type "daily") to start today's entry from a template.

### The one habit that makes it worth it
Write **one note a week in your own words** about something you learned. Link it to related
notes with `[[ ]]`. That's the whole system. The tool does nothing on its own — the writing is the value.

---

## If something looks broken
- **Plugins not working?** `Cmd+R` to reload, or quit and reopen Obsidian.
- **Vault won't open?** In Obsidian click the vault name (bottom-left) → **Open another vault**
  → **Open folder as vault** → pick the `peptidemiracle` folder again.
- **Notes look like raw text with symbols?** You're in source mode — that's fine, it still works.
  Toggle reading view with the book icon (top-right) if you prefer the clean look.

---

## What this is NOT (so no one is confused)
- Not where passwords/keys live (those are stored separately and securely on the Mac).
- Not where the actual video/carousel data lives (that's in Supabase/n8n).
- Just a place to *think, learn, and see what the AI remembers.*
