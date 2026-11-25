#!/usr/bin/env bash
# Rewrites Atlassian MCP v1 endpoints (/v1/mcp and /v1/sse) to https://mcp.atlassian.com/v2/mcp.
# Usage: migrate.sh [--apply] [root ...]   (default: dry run over ~/.claude/plugins and ~/.claude.json)
set -euo pipefail
apply=0; [ "${1:-}" = "--apply" ] && { apply=1; shift; }
roots=("$@"); [ ${#roots[@]} -eq 0 ] && roots=("$HOME/.claude/plugins" "$HOME/.claude.json" ".")
pat='https://mcp\.atlassian\.com/v1/(mcp|sse)'
files=$(grep -rIlE "$pat" "${roots[@]}" --include='*.json' --include='*.md' --include='*.toml' --include='*.yaml' --include='*.yml' 2>/dev/null | grep -v '/node_modules/' || true)
[ -z "$files" ] && { echo "No Atlassian v1 endpoints found."; exit 0; }
echo "$files" | while read -r f; do
  grep -nE "$pat" "$f" | sed "s|^|$f:|"
  [ $apply -eq 1 ] && sed -i -E "s#$pat#https://mcp.atlassian.com/v2/mcp#g" "$f"
done
if [ $apply -eq 1 ]; then
  left=$(grep -rIlE "$pat" "${roots[@]}" 2>/dev/null | grep -v '/node_modules/' || true)
  [ -n "$left" ] && { echo "FAILED, still v1:"; echo "$left"; exit 1; }
  echo "Migrated and verified: no v1 references remain."
else
  echo "Dry run only. Re-run with --apply."
fi
