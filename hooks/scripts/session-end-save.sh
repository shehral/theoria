#!/bin/bash
# Stop hook — saves final session state when the conversation ends.
# Ensures audit log is flushed, session timestamp is updated, and outputs a summary.

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_DIR="$HOME/.theoria"
mkdir -p "$LOG_DIR"

# Log session end event
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"session_end\"}" >> "$LOG_DIR/audit.log"

# Find the most recent active session (project-local) and update its timestamp
SESSION_BASE=".theoria/sessions"
SUMMARY=""
if [ -d "$SESSION_BASE" ]; then
  LATEST=$(ls -t "$SESSION_BASE/" 2>/dev/null | grep -v archive | head -1)
  if [ -n "$LATEST" ] && [ -f "$SESSION_BASE/$LATEST/state.json" ]; then
    # Update the updated_at timestamp in session state
    TMP=$(mktemp)
    jq --arg ts "$TIMESTAMP" '.updated_at = $ts' "$SESSION_BASE/$LATEST/state.json" > "$TMP" 2>/dev/null && mv "$TMP" "$SESSION_BASE/$LATEST/state.json"

    # Build summary from session state
    STAGE=$(jq -r '.stage // "unknown"' "$SESSION_BASE/$LATEST/state.json" 2>/dev/null || echo "unknown")
    TOPIC=$(jq -r '.topic // "unknown"' "$SESSION_BASE/$LATEST/state.json" 2>/dev/null || echo "unknown")
    SUMMARY="Session '$LATEST' saved at stage $STAGE (topic: $TOPIC)."
  fi
fi

# Count audit log entries for this session
AUDIT_LINES=0
if [ -f "$LOG_DIR/audit.log" ]; then
  AUDIT_LINES=$(wc -l < "$LOG_DIR/audit.log" 2>/dev/null | tr -d ' ')
fi

# Output session summary
if [ -n "$SUMMARY" ]; then
  echo "SESSION END: $SUMMARY Audit log: $AUDIT_LINES entries. Use /theoria:resume to continue."
else
  echo "SESSION END: No active session found. Audit log: $AUDIT_LINES entries."
fi
