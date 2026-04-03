#!/bin/bash
# PostToolUse hook (async) — logs tool usage for audit trail.
# Fires after Bash, Write, and Edit tool invocations.
# Async: does not block the main conversation.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_DIR="$HOME/.theoria"
mkdir -p "$LOG_DIR"
echo "{\"timestamp\": \"$TIMESTAMP\", \"tool\": \"$TOOL\", \"event\": \"tool_use\"}" >> "$LOG_DIR/audit.log"
