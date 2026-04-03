---
name: prune
description: Review weak knowledge cards — surface low-strength findings for review, merge, or retirement
disable-model-invocation: true
---

# Theoria Prune — Knowledge Base Health Check

Review the health of your knowledge base and manage weak or stale cards.

## Knowledge Base Scan

Compute effective strength for all cards by applying Ebbinghaus decay:

!`
CARDS_DIR="$HOME/.theoria/knowledge/cards"
if [ ! -d "$CARDS_DIR" ] || [ -z "$(ls "$CARDS_DIR"/*.md 2>/dev/null)" ]; then
  echo "NO_CARDS"
else
  NOW=$(date +%s)
  echo "SCAN_START"
  for card in "$CARDS_DIR"/*.md; do
    # Extract frontmatter fields using grep/sed
    ID=$(grep '^id:' "$card" | head -1 | sed 's/^id: *//')
    DOMAIN=$(grep '^domain:' "$card" | head -1 | sed 's/^domain: *//')
    STATUS=$(grep '^status:' "$card" | head -1 | sed 's/^status: *//')
    STRENGTH=$(grep '  strength:' "$card" | head -1 | sed 's/.*strength: *//')
    ACCESS_COUNT=$(grep '  access_count:' "$card" | head -1 | sed 's/.*access_count: *//')
    LAST_ACCESSED=$(grep '  last_accessed:' "$card" | head -1 | sed 's/.*last_accessed: *//')
    CREATED_STRENGTH=$(grep '  created_strength:' "$card" | head -1 | sed 's/.*created_strength: *//')
    DECAY_RATE=$(grep '  decay_rate:' "$card" | head -1 | sed 's/.*decay_rate: *//')
    CREATED_AT=$(grep '^created_at:' "$card" | head -1 | sed 's/^created_at: *//')
    TITLE=$(grep '^# ' "$card" | head -1 | sed 's/^# //')

    # Default values
    STRENGTH=${STRENGTH:-0.5}
    ACCESS_COUNT=${ACCESS_COUNT:-0}
    DECAY_RATE=${DECAY_RATE:-0.02}
    LAST_ACCESSED=${LAST_ACCESSED:-$CREATED_AT}

    # Compute days since last access
    if [ -n "$LAST_ACCESSED" ] && [ "$LAST_ACCESSED" != "null" ]; then
      LAST_TS=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$LAST_ACCESSED" +%s 2>/dev/null || date -d "$LAST_ACCESSED" +%s 2>/dev/null || echo "$NOW")
      DAYS_SINCE=$(( (NOW - LAST_TS) / 86400 ))
    else
      DAYS_SINCE=0
    fi

    echo "CARD|$ID|$DOMAIN|$STATUS|$STRENGTH|$ACCESS_COUNT|$DAYS_SINCE|$DECAY_RATE|$CREATED_STRENGTH|$TITLE"
  done
  echo "SCAN_END"
fi
`

## Graph Stats

!`cat "$HOME/.theoria/knowledge/graph.json" 2>/dev/null || echo "NO_GRAPH"`

---

## Analysis

Based on the scan output above, present the knowledge base health dashboard. Use the Ebbinghaus decay formula to compute effective (current) strength for each card:

```
effective_strength = stored_strength * (1 - decay_rate) ^ days_since_last_access
```

### Dashboard

Display a table of ALL cards with columns:
| Card ID | Title | Domain | Effective Strength | Access Count | Days Since Access | Status |

Sort by effective strength (ascending, weakest first).

Color-code (use text markers):
- `[WEAK]` — effective strength < 0.3 (retirement candidate)
- `[STALE]` — last accessed > 60 days ago
- `[HEALTHY]` — effective strength >= 0.5
- `[MODERATE]` — effective strength 0.3-0.49

### Summary Statistics

- **Total cards**: count
- **Average effective strength**: mean across all cards
- **Domain distribution**: count per domain
- **Weak cards** (strength < 0.3): count and list
- **Stale cards** (60+ days): count and list
- **Strongest card**: the card with highest effective strength
- **Most accessed**: the card with highest access_count

### Retirement Candidates

For each card with effective strength < 0.3, show:
- Card ID and title
- Original strength vs. current effective strength
- Last accessed date
- Access count
- Why it weakened (low initial strength, time decay, or both)

### Stale Candidates

For each card not accessed in 60+ days (regardless of strength), show:
- Card ID and title
- Effective strength
- Days since last access
- Whether it's still above the retirement threshold

## User Actions

Present the following options:

> Your knowledge base has **N total cards**, **N weak**, **N stale**.
>
> Available actions:
> 1. **Keep** a card — reset its decay timer (updates `last_accessed` to now, preserving current strength)
> 2. **Merge** two cards — combine findings into one card, retire the other
> 3. **Retire** a card — move to `~/.theoria/knowledge/archive/` (preserved but excluded from orient searches)
> 4. **Boost** a card — manually increase strength (e.g., after re-validating findings)
> 5. **Done** — exit prune
>
> Which cards would you like to act on? (e.g., "retire theoria-2026-03-15-...", "keep theoria-2026-04-01-...")

## Action Handlers

### Keep

Reset the card's decay timer without changing its strength:

```bash
CARD_FILE="$HOME/.theoria/knowledge/cards/<card_id>.md"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# Update last_accessed in the YAML frontmatter
sed -i '' "s/  last_accessed:.*/  last_accessed: $NOW/" "$CARD_FILE"
echo "Kept: <card_id> — decay timer reset to now."
```

### Merge

When the user wants to merge card A into card B:

1. Read both cards fully
2. Combine key findings (deduplicate, keep the more specific version of overlapping findings)
3. Union the limitations, methods, tags, and papers_referenced
4. Set the merged card's strength to `max(strength_A, strength_B)`
5. Update `access_count` to `access_count_A + access_count_B`
6. Update `last_accessed` to `max(last_accessed_A, last_accessed_B)`
7. Add a note to the merged card's `## Connections` section noting the merge
8. Move the absorbed card to `~/.theoria/knowledge/archive/`
9. Update `~/.theoria/knowledge/graph.json`: redirect edges from the absorbed card to the merged card, add a `supersedes` edge

```bash
mkdir -p "$HOME/.theoria/knowledge/archive"
mv "$HOME/.theoria/knowledge/cards/<absorbed_id>.md" "$HOME/.theoria/knowledge/archive/"
echo "Merged <absorbed_id> into <target_id>. Absorbed card archived."
```

### Retire

Move the card to the archive directory:

```bash
mkdir -p "$HOME/.theoria/knowledge/archive"
mv "$HOME/.theoria/knowledge/cards/<card_id>.md" "$HOME/.theoria/knowledge/archive/"
# Update graph.json: mark the card as retired, preserve edges for historical reference
echo "Retired: <card_id> — moved to archive. Knowledge graph edges preserved for history."
```

### Boost

Manually increase a card's strength (e.g., after re-validating findings in a new session):

```bash
CARD_FILE="$HOME/.theoria/knowledge/cards/<card_id>.md"
NEW_STRENGTH="<user-specified or default 0.7>"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
sed -i '' "s/  strength:.*/  strength: $NEW_STRENGTH/" "$CARD_FILE"
sed -i '' "s/  last_accessed:.*/  last_accessed: $NOW/" "$CARD_FILE"
echo "Boosted: <card_id> — strength set to $NEW_STRENGTH, decay timer reset."
```

## No Cards Found

If the scan shows `NO_CARDS`, display:

> Your knowledge base is empty. Run `/theoria:explore` to conduct a research session — knowledge cards are created automatically during the COMPOUND stage.
