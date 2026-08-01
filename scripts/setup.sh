#!/usr/bin/env bash
# Run once after cloning this vault on a new machine.
set -euo pipefail

VAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEM="$HOME/.claude/projects/-Users-$(whoami)-Claude/memory"
LINK="$VAULT/04-AI-Memory"

echo "vault:  $VAULT"
echo "memory: $MEM"

if [ ! -d "$MEM" ]; then
  echo
  echo "Claude's memory folder is not at that path."
  echo "It is named after the project directory, e.g. /Users/<you>/Claude becomes -Users-<you>-Claude."
  echo "Copy the memory folder from the old machine to:"
  echo "  $MEM"
  exit 1
fi

if [ -L "$LINK" ]; then
  rm "$LINK"
elif [ -e "$LINK" ]; then
  echo "04-AI-Memory exists and is not a symlink. Move it aside first."
  exit 1
fi

ln -s "$MEM" "$LINK"
echo "linked 04-AI-Memory -> $MEM"

HOOK="$VAULT/.git/hooks/pre-commit"
cp "$VAULT/scripts/pre-commit" "$HOOK"
chmod +x "$HOOK"
echo "installed the no-secrets pre-commit hook"
echo "done"
