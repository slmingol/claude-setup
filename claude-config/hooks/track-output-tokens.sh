#!/bin/bash
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

[ -z "$session_id" ] && exit 0
[ -z "$transcript_path" ] && exit 0
[ ! -f "$transcript_path" ] && exit 0

out_tokens=$(jq -r 'select(.message.usage.output_tokens != null) | .message.usage.output_tokens' "$transcript_path" 2>/dev/null | awk '{s+=$1} END {print s+0}')

echo "{\"session_id\":\"$session_id\",\"output_tokens\":$out_tokens}" > "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.session-out-tokens.json"
