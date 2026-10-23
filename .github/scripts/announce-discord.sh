#!/usr/bin/env bash
# Announces a release on Discord: the version's section of CHANGELOG.md, linked to CurseForge and to the GitHub
# release. Run from the repository root by the release workflow, or by the "Announce on Discord" workflow to post one
# again. Needs DISCORD_WEBHOOK_URL (the webhook of the channel to post in) and GITHUB_REPOSITORY; without the webhook,
# nothing is posted.
# Usage: bash .github/scripts/announce-discord.sh <version>
set -euo pipefail

version="$1"
if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
  echo "No DISCORD_WEBHOOK_URL secret: nothing posted."
  exit 0
fi

# The version's section without its heading line, the same way the release workflow cuts it for CurseForge.
notes=$(awk -v heading="## [$version]" '
  index($0, heading) == 1 { found = 1; next }
  found && (/^## \[/ || /^\[[^]]*\]: /) { exit }
  found { print }
' CHANGELOG.md | sed '/./,$!d')
if [ -z "$notes" ]; then
  echo "::error::CHANGELOG.md has no section for $version"
  exit 1
fi
# An embed's description holds at most 4096 characters.
if [ "${#notes}" -gt 3900 ]; then notes="${notes:0:3900}…"; fi

url="https://www.curseforge.com/wow/addons/flag-up"
release="https://github.com/$GITHUB_REPOSITORY/releases/tag/$version"
jq -n --arg title "Flag Up $version" --arg url "$url" --arg release "$release" --arg notes "$notes" '{
  embeds: [{
    title: $title,
    url: $url,
    description: ($notes + "\n\n[Download on CurseForge](" + $url + ")\n[GitHub release](" + $release + ")"),
    color: 6732799
  }]
}' | curl -fsS -H "Content-Type: application/json" -d @- "$DISCORD_WEBHOOK_URL"
echo "Posted Flag Up $version on Discord."
