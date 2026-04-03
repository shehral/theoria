#!/bin/bash
# PreCompact hook — saves critical session state before context compaction.
LOG_DIR="$HOME/.theoria"
SESSION_BASE=".theoria/sessions"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"pre_compact\"}" >> "$LOG_DIR/audit.log"

# Output the current taste profile and active session state so they survive compaction
TASTE=$(cat "$LOG_DIR/taste.json" 2>/dev/null || echo '{}')

# Find most recent active session (project-local)
ACTIVE_SESSION=""
if [ -d "$SESSION_BASE" ]; then
  ACTIVE_SESSION=$(ls -t "$SESSION_BASE/" 2>/dev/null | head -1)
fi

if [ -n "$ACTIVE_SESSION" ]; then
  STATE=$(cat "$SESSION_BASE/$ACTIVE_SESSION/state.json" 2>/dev/null || echo '{}')
  STAGE=$(echo "$STATE" | jq -r '.stage // "unknown"' 2>/dev/null || echo "unknown")
  DOMAINS=$(echo "$TASTE" | jq -r '.researcher.domains // [] | join(", ")' 2>/dev/null || echo "unknown")
  echo "THEORIA CONTEXT (survives compaction): Active session=$ACTIVE_SESSION, Stage=$STAGE. Taste domains: $DOMAINS."
else
  DOMAINS=$(echo "$TASTE" | jq -r '.researcher.domains // [] | join(", ")' 2>/dev/null || echo "unknown")
  echo "THEORIA CONTEXT: No active session. Taste domains: $DOMAINS."
fi
