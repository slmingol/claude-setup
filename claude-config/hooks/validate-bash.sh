#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

block() {
  echo "{\"decision\": \"block\", \"reason\": \"$1\"}"
  exit 0
}

# rm -rf /
echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+/(\s|$|\*)' \
  && block "rm -rf / is blocked for safety"

# git push --force (but allow --force-with-lease)
echo "$COMMAND" | grep -qE 'git\s+push\s+.*(--force([^-]|$)|-f\b)' \
  && block "git push --force is blocked. Use --force-with-lease"

# git add -A / git add .
echo "$COMMAND" | grep -qE 'git\s+add\s+(-A|--all|\.)(\s|$)' \
  && block "git add -A is blocked. Stage specific files instead"

# sudo
echo "$COMMAND" | grep -qE '(^|[;&|]\s*)sudo\s' \
  && block "sudo is blocked in automated mode"

exit 0
