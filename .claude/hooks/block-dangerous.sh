#!/bin/bash
# PreToolUse guardrail: hard-block catastrophic commands regardless of permission mode.
# exit 2 = block the tool call; exit 0 = allow (normal permission rules still apply after).
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
if echo "$cmd" | grep -qiE 'rm -rf (/|~|\$HOME)|mkfs|dd if=|:\(\)\{|drop database|drop table'; then
  echo "Blocked: destructive command" >&2
  exit 2
fi
exit 0
