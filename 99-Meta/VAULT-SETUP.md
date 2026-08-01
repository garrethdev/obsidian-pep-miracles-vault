# Moving this vault to another machine

The vault is a git repo. Everything in it is plain markdown, so a clone is all you need.

## On the new machine

```bash
git clone <remote-url> "$HOME/Desktop/AI Video Generation /peptidemiracle"
cd "$HOME/Desktop/AI Video Generation /peptidemiracle"
./scripts/setup.sh
```

Then open the folder in Obsidian as a vault.

`setup.sh` does two things: recreates the `04-AI-Memory` symlink and installs the pre-commit hook.

## What is deliberately not in the repo

**`04-AI-Memory`** is a symlink into Claude's memory folder at
`~/.claude/projects/-Users-<you>-Claude/memory`. It is gitignored on purpose. The memory
files are the source of truth and live with Claude, not with the vault. Committing them
would give you two copies that drift apart.

That memory folder does **not** sync with your Claude account. It is plain files on disk.
Copy it across by hand when you move machines. Its name encodes the project path, so
`/Users/garreth/Claude` becomes `-Users-garreth-Claude`. If the username differs on the
new machine, rename the folder to match or Claude will not find it.

**Obsidian per-machine state** (`workspace.json`, `graph.json`) is ignored so the two
machines do not fight over window layout.

## What else does not live here

Nothing in this vault is a credential. Keys live in `~/.config/peptide-secrets/.env`,
which is not in any repo and has to be moved by hand. A pre-commit hook blocks anything
that looks like a key from being committed. Override with `git commit --no-verify` if it
is a false positive.

Render scripts live in their own repo, `garrethdev/content-render-scripts`.

## The folder name has a trailing space

`AI Video Generation ` ends with a space. It is left that way because other scripts
reference the path. Quote it in every command.
