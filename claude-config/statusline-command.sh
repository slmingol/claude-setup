#!/bin/bash
input=$(cat)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')
input_tokens=$(echo "$input" | jq -r '(.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0)')
session_id=$(echo "$input" | jq -r '.session_id // ""')

status_parts=()
status_parts+=("$model_name")
[ -n "$cwd" ] && status_parts+=("$(basename "$cwd")")

tok_in=""
tok_out=""
if [ -n "$input_tokens" ] && [ "$input_tokens" != "0" ] && [ "$input_tokens" -gt 0 ] 2>/dev/null; then
  if [ "$input_tokens" -ge 1000 ]; then
    tok_in=$(awk "BEGIN {printf \"%.1fk\", $input_tokens/1000}")
  else
    tok_in="$input_tokens"
  fi
fi

out_tokens_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.session-out-tokens.json"
if [ -n "$session_id" ] && [ -f "$out_tokens_file" ]; then
  stored_id=$(jq -r '.session_id // ""' "$out_tokens_file" 2>/dev/null)
  if [ "$stored_id" = "$session_id" ]; then
    raw_out=$(jq -r '.output_tokens // 0' "$out_tokens_file" 2>/dev/null)
    if [ -n "$raw_out" ] && [ "$raw_out" -gt 0 ] 2>/dev/null; then
      if [ "$raw_out" -ge 1000 ]; then
        tok_out=$(awk "BEGIN {printf \"%.1fk\", $raw_out/1000}")
      else
        tok_out="$raw_out"
      fi
    fi
  fi
fi

tok_str="${tok_in:-0} in / ${tok_out:-0} out"
status_parts+=("$tok_str")

if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  bar_width=20
  filled=$(( used_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  status_parts+=("[${bar}] ${used_int}%")
fi

printf "%s" "${status_parts[0]}"
for ((i=1; i<${#status_parts[@]}; i++)); do
  printf " | %s" "${status_parts[$i]}"
done

FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
if [ ! -L "$FLAG" ] && [ -f "$FLAG" ]; then
  MODE=$(head -c 64 "$FLAG" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]')
  MODE=$(printf '%s' "$MODE" | tr -cd 'a-z0-9-')
  case "$MODE" in
    off|lite|full|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress)
      if [ -z "$MODE" ] || [ "$MODE" = "full" ]; then
        printf ' | \033[38;5;172m[CAVEMAN]\033[0m'
      else
        SUFFIX=$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')
        printf ' | \033[38;5;172m[CAVEMAN:%s]\033[0m' "$SUFFIX"
      fi
      ;;
  esac
fi

printf "\n"
