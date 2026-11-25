#!/usr/bin/env bash
# Builds "<plugin>-daemon" copies of every installed plugin that uses Atlassian MCP v1, patched to v2.
# Usage: build-patched-plugins.sh OUTPUT_DIR   (OUTPUT_DIR must be new or empty)
# Searches all of ~/.claude/plugins (synced, marketplaces, cache). Publish each output folder from
# your own computer: open Claude Code there and ask it to publish the folder to the organisation.
set -euo pipefail
out="${1:?Usage: $0 OUTPUT_DIR}"
here=$(cd "$(dirname "$0")" && pwd)
root="$HOME/.claude/plugins"
[ -d "$root" ] || { echo "ERROR: $root not found. Start Claude Code once so plugins sync, then re-run."; exit 1; }
mkdir -p "$out"; [ -z "$(ls -A "$out")" ] || { echo "ERROR: OUTPUT_DIR must be empty"; exit 1; }
n=0
# every .mcp.json holding a v1 endpoint marks a plugin root (its folder)
while IFS= read -r f; do
  d=$(dirname "$f"); name=$(basename "$d")
  [ -f "$d/.claude-plugin/plugin.json" ] || continue
  [ -d "$out/$name-daemon" ] && continue          # already built (de-duplicates cached versions)
  mkdir -p "$out/$name-daemon"
  tar -C "$d" --exclude=.in_use --exclude=.git -cf - . | tar -C "$out/$name-daemon" -xf -
  sed -i -E "0,/\"name\": \"[^\"]+\"/s//\"name\": \"$name-daemon\"/" "$out/$name-daemon/.claude-plugin/plugin.json"
  n=$((n+1))
done < <(grep -rIlE "mcp\.atlassian\.com/v1/" "$root" --include=.mcp.json 2>/dev/null)
[ "$n" -gt 0 ] || { echo "ERROR: no plugins with Atlassian v1 endpoints found under $root."; exit 1; }
"$here/migrate.sh" --apply "$out" | tail -1
echo "Built $n patched plugins in $out:"; ls "$out"
