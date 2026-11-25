#!/usr/bin/env bash
# Builds "<plugin>-daemon" copies of every synced plugin that uses Atlassian MCP v1, patched to v2.
# Usage: build-patched-plugins.sh OUTPUT_DIR   (OUTPUT_DIR must be new or empty)
# Then publish each folder from your own computer: open Claude Code there and ask it to
# "publish <folder> to the organisation" (the publish tool is not offered in cloud sessions).
set -euo pipefail
out="${1:?Usage: $0 OUTPUT_DIR}"
src=$(ls -d "$HOME"/.claude/plugins/synced/*/ | head -1)
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$out"; [ -z "$(ls -A "$out")" ] || { echo "OUTPUT_DIR must be empty"; exit 1; }
cd "$src"
for p in $(grep -rIl "mcp.atlassian.com/v1" --include=.mcp.json . | cut -d/ -f2); do
  mkdir -p "$out/$p-daemon"
  tar -C "$p" --exclude=.in_use -cf - . | tar -C "$out/$p-daemon" -xf -
  sed -i -E "0,/\"name\": \"$p\"/s//\"name\": \"$p-daemon\"/" "$out/$p-daemon/.claude-plugin/plugin.json"
done
"$here/migrate.sh" --apply "$out"
ls "$out"
