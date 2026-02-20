#!/usr/bin/env zsh

# ─────────────────────────────────────────────
# TOPIC LIST
# ─────────────────────────────────────────────

LANGUAGES_STR="bash sh zsh python js node ts java cpp c lua"
COMMANDS_STR="git find sed awk xargs mv curl tr cat ls chmod chown"

all_options_list=$(
  printf "%s %s" "$LANGUAGES_STR" "$COMMANDS_STR" | tr ' ' '\n'
)

# ─────────────────────────────────────────────
# FZF TOPIC SELECTOR
# ─────────────────────────────────────────────

selected=$(
  printf '%s\n' "$all_options_list" |
    fzf --prompt="Select topic: " --height=50%
)

[[ -z "$selected" ]] && { echo "Cancelled."; exit 1; }

# ─────────────────────────────────────────────
# QUERY → GOOGLE SEARCH
# ─────────────────────────────────────────────

read "query?Query: "
[[ -z "$query" ]] && { echo "No query entered."; exit 1; }

search="${selected} ${query}"
search="${search// /+}"
url="https://www.google.com/search?q=$search"

echo "🌐 Opening: $url"

if command -v open >/dev/null; then
  open "$url"
else
  xdg-open "$url"
fi

exit 0
