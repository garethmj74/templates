#!/usr/bin/env bash
# Builds "<plugin>-daemon" copies of the 12 org plugins that use Atlassian MCP v1, patched to v2.
# Sources are the public Apache-2.0 repos: anthropics/knowledge-work-plugins and anthropics/claude-for-legal.
# No local plugin sync is needed. Requires git and network access to github.com.
# Usage: build-patched-plugins.sh OUTPUT_DIR   (OUTPUT_DIR must be new or empty)
# Then publish each output folder from your own computer: open Claude Code there and ask it to
# publish the folder to the organisation.
set -euo pipefail
out="${1:?Usage: $0 OUTPUT_DIR}"
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$out"; [ -z "$(ls -A "$out")" ] || { echo "ERROR: OUTPUT_DIR must be empty"; exit 1; }
work=$(mktemp -d)
git clone -q --depth 1 https://github.com/anthropics/knowledge-work-plugins.git "$work/kwp"
git clone -q --depth 1 https://github.com/anthropics/claude-for-legal.git "$work/cfl"
# source folder (relative to $work) : plugin name
plugins=(
  kwp/data:data kwp/design:design kwp/engineering:engineering kwp/enterprise-search:enterprise-search
  kwp/human-resources:human-resources kwp/legal:legal kwp/operations:operations
  kwp/product-management:product-management kwp/productivity:productivity kwp/sales:sales
  kwp/partner-built/brand-voice:brand-voice cfl/product-legal:product-legal
)
n=0
for entry in "${plugins[@]}"; do
  src="$work/${entry%%:*}"; name="${entry##*:}"; dst="$out/$name-daemon"
  [ -f "$src/.claude-plugin/plugin.json" ] || { echo "ERROR: $src is not a plugin"; exit 1; }
  mkdir -p "$dst"
  tar -C "$src" --exclude=.git -cf - . | tar -C "$dst" -xf -
  sed -i -E "0,/\"name\": \"[^\"]+\"/s//\"name\": \"$name-daemon\"/" "$dst/.claude-plugin/plugin.json"
  n=$((n+1))
done
"$here/migrate.sh" --apply "$out" | tail -1
echo "Built $n patched plugins in $out:"; ls "$out"
