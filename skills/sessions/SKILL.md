---
name: sessions
description: List, clean, and archive Theoria research sessions
argument-hint: "[list|clean|clean --all|archive <name>|delete <name>]"
disable-model-invocation: true
---

# Theoria Sessions

## Current Sessions

!`ls ".theoria/sessions" 2>/dev/null | grep -v archive || echo "No sessions yet. Run /theoria:explore to start one."`

## Session Details

Read the session directories at `.theoria/sessions/` to display details. For each session directory (excluding `archive/`), read its `state.json` and show: name, topic, current stage, completed stages count, created/updated dates.

## Archived Sessions

!`ls ".theoria/sessions/archive" 2>/dev/null || echo "No archived sessions."`

## Commands

Based on the user's request ($ARGUMENTS):

### `list` (default)
Show the session list above with details. Include the topic, current stage, and number of completed stages.

### `clean`
Archive sessions older than 30 days:
```bash
BASE=".theoria/sessions"
ARCHIVE=".theoria/sessions/archive"
mkdir -p "$ARCHIVE"
CUTOFF=$(date -v-30d +%s 2>/dev/null || date -d "30 days ago" +%s)
for d in "$BASE"/*/; do
  [ -d "$d" ] || continue
  [ "$(basename "$d")" = "archive" ] && continue
  UPDATED=$(jq -r '.updated_at // "1970-01-01"' "$d/state.json" 2>/dev/null)
  UPDATED_TS=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$UPDATED" +%s 2>/dev/null || date -d "$UPDATED" +%s 2>/dev/null || echo "0")
  if [ "$UPDATED_TS" -lt "$CUTOFF" ]; then
    mv "$d" "$ARCHIVE/"
    echo "Archived: $(basename "$d")"
  fi
done
```

### `clean --all`
Archive ALL sessions except the most recently updated:
```bash
BASE=".theoria/sessions"
ARCHIVE=".theoria/sessions/archive"
mkdir -p "$ARCHIVE"
# Keep only the most recent
LATEST=$(ls -t "$BASE" 2>/dev/null | grep -v archive | head -1)
for d in "$BASE"/*/; do
  [ -d "$d" ] || continue
  NAME=$(basename "$d")
  [ "$NAME" = "archive" ] && continue
  [ "$NAME" = "$LATEST" ] && continue
  mv "$d" "$ARCHIVE/"
  echo "Archived: $NAME"
done
echo "Kept: $LATEST (most recent)"
```

### `delete <name>`
Permanently delete a session (ask for confirmation first):
```bash
SESSION_DIR=".theoria/sessions/<name>"
if [ -d "$SESSION_DIR" ]; then
  rm -rf "$SESSION_DIR"
  echo "Deleted session: <name>"
else
  echo "Session not found: <name>"
fi
```

### `archive <name>`
Move a specific session to the archive:
```bash
mkdir -p ".theoria/sessions/archive"
mv ".theoria/sessions/<name>" ".theoria/sessions/archive/"
echo "Archived: <name>"
```

**Note:** Knowledge cards from archived/deleted sessions are NOT removed. Knowledge persists in `~/.theoria/knowledge/` independently of session artifacts.
